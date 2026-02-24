import 'package:logger/logger.dart';
import 'package:vantedge/core/api/interceptors/dio_client.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import 'dps_model.dart';
import 'dps_installment_model.dart';
import 'dps_statement_model.dart';
import 'maturity_calculation_model.dart';

class _Endpoints {
  _Endpoints._();

  static const String _base = '/api/dps';

  static const String create = _base;
  static const String payInstallment = '$_base/pay-installment';

  static String byCustomer(String customerId) => '$_base/customer/$customerId';
  static String byNumber(String dpsNumber) => '$_base/number/$dpsNumber';
  static String statement(String dpsNumber) => '$_base/statement/$dpsNumber';
  static String close(String dpsNumber) => '$_base/$dpsNumber/close';
  static String calculateMaturity() => '$_base/calculate-maturity';
}

class DpsRepository {
  final DioClient _dioClient;
  final Logger _logger = Logger();

  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  DpsRepository({required DioClient dioClient}) : _dioClient = dioClient {
    print('🏗️  [DpsRepository] Constructor called');
    print('🏗️  [DpsRepository] DioClient instance: $dioClient');
    _logger.i('[DpsRepository] Initialized with DioClient: $dioClient');
  }

  // ---------------------------------------------------------------------------
  // GET /api/dps/customer/{customerId}
  // ---------------------------------------------------------------------------

  Future<List<DpsModel>> getMyDps(String customerId) {
    print('📋 [DpsRepository.getMyDps] Called with customerId: $customerId');
    _logger.d('[DpsRepository.getMyDps] customerId=$customerId');

    return _executeWithRetry(
      operationName: 'getMyDps',
      operation: () async {
        final endpoint = _Endpoints.byCustomer(customerId);
        print('📋 [DpsRepository.getMyDps] Hitting endpoint: $endpoint');
        _logger.i('[DpsRepository.getMyDps] GET $endpoint');

        Map<String, dynamic> response;
        try {
          response = await _dioClient.get<Map<String, dynamic>>(endpoint);
          print(
            '📋 [DpsRepository.getMyDps] Raw response keys: ${response.keys.toList()}',
          );
          _logger.d('[DpsRepository.getMyDps] Raw response: $response');
        } catch (e, st) {
          print('❌ [DpsRepository.getMyDps] HTTP call threw: $e');
          print('❌ [DpsRepository.getMyDps] Stack: $st');
          rethrow;
        }

        final rawData = response['data'];
        print(
          '📋 [DpsRepository.getMyDps] response[data] type: ${rawData.runtimeType}',
        );
        print('📋 [DpsRepository.getMyDps] response[data] value: $rawData');

        if (rawData == null) {
          print(
            '⚠️  [DpsRepository.getMyDps] data is null — returning empty list',
          );
          return [];
        }

        final List<dynamic> raw = rawData as List<dynamic>;
        print('📋 [DpsRepository.getMyDps] Parsing ${raw.length} items');

        final accounts = raw.asMap().entries.map((entry) {
          print(
            '📋 [DpsRepository.getMyDps] Parsing item[${entry.key}]: ${entry.value}',
          );
          return DpsModel.fromJson(entry.value as Map<String, dynamic>);
        }).toList();

        print(
          '✅ [DpsRepository.getMyDps] Successfully parsed ${accounts.length} DPS accounts',
        );
        _logger.i(
          '[DpsRepository.getMyDps] Fetched ${accounts.length} accounts',
        );
        return accounts;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // GET /api/dps/number/{dpsNumber}
  // ---------------------------------------------------------------------------

  Future<DpsModel> getDpsByNumber(String dpsNumber) {
    print(
      '🔍 [DpsRepository.getDpsByNumber] Called with dpsNumber: $dpsNumber',
    );
    _logger.d('[DpsRepository.getDpsByNumber] dpsNumber=$dpsNumber');

    return _executeWithRetry(
      operationName: 'getDpsByNumber',
      operation: () async {
        final endpoint = _Endpoints.byNumber(dpsNumber);
        print('🔍 [DpsRepository.getDpsByNumber] Hitting endpoint: $endpoint');

        Map<String, dynamic> response;
        try {
          response = await _dioClient.get<Map<String, dynamic>>(endpoint);
          print(
            '🔍 [DpsRepository.getDpsByNumber] Raw response keys: ${response.keys.toList()}',
          );
        } catch (e, st) {
          print('❌ [DpsRepository.getDpsByNumber] HTTP call threw: $e');
          print('❌ [DpsRepository.getDpsByNumber] Stack: $st');
          rethrow;
        }

        final rawData = response['data'];
        print(
          '🔍 [DpsRepository.getDpsByNumber] response[data] type: ${rawData.runtimeType}',
        );
        print(
          '🔍 [DpsRepository.getDpsByNumber] response[data] value: $rawData',
        );

        final dps = DpsModel.fromJson(rawData as Map<String, dynamic>);
        print('✅ [DpsRepository.getDpsByNumber] Parsed DPS: ${dps.dpsNumber}');
        return dps;
      },
      onError: (e) => _handleDpsError(e, dpsNumber),
    );
  }

  // ---------------------------------------------------------------------------
  // GET /api/dps/statement/{dpsNumber} — installments only
  // ---------------------------------------------------------------------------

  Future<List<DpsInstallmentModel>> getInstallments(String dpsNumber) {
    print(
      '📅 [DpsRepository.getInstallments] Called with dpsNumber: $dpsNumber',
    );

    return _executeWithRetry(
      operationName: 'getInstallments',
      operation: () async {
        final endpoint = _Endpoints.statement(dpsNumber);
        print('📅 [DpsRepository.getInstallments] Hitting endpoint: $endpoint');

        Map<String, dynamic> response;
        try {
          response = await _dioClient.get<Map<String, dynamic>>(endpoint);
          print(
            '📅 [DpsRepository.getInstallments] Raw response keys: ${response.keys.toList()}',
          );
        } catch (e, st) {
          print('❌ [DpsRepository.getInstallments] HTTP call threw: $e');
          print('❌ [DpsRepository.getInstallments] Stack: $st');
          rethrow;
        }

        final rawData = response['data'];
        print(
          '📅 [DpsRepository.getInstallments] response[data] type: ${rawData.runtimeType}',
        );

        final data = rawData as Map<String, dynamic>;
        final rawInstallments = data['installments'];
        print(
          '📅 [DpsRepository.getInstallments] installments type: ${rawInstallments.runtimeType}',
        );
        print(
          '📅 [DpsRepository.getInstallments] installments value: $rawInstallments',
        );

        final raw = rawInstallments as List<dynamic>? ?? [];
        print(
          '📅 [DpsRepository.getInstallments] Parsing ${raw.length} installments',
        );

        final installments = raw.asMap().entries.map((entry) {
          print(
            '📅 [DpsRepository.getInstallments] Parsing installment[${entry.key}]: ${entry.value}',
          );
          return DpsInstallmentModel.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }).toList();

        print(
          '✅ [DpsRepository.getInstallments] Parsed ${installments.length} installments',
        );
        return installments;
      },
      onError: (e) => _handleDpsError(e, dpsNumber),
    );
  }

  // ---------------------------------------------------------------------------
  // GET /api/dps/statement/{dpsNumber} — full statement
  // ---------------------------------------------------------------------------

  Future<DpsStatementModel> getDpsStatement(String dpsNumber) {
    print(
      '📄 [DpsRepository.getDpsStatement] Called with dpsNumber: $dpsNumber',
    );

    return _executeWithRetry(
      operationName: 'getDpsStatement',
      operation: () async {
        final endpoint = _Endpoints.statement(dpsNumber);
        print('📄 [DpsRepository.getDpsStatement] Hitting endpoint: $endpoint');

        Map<String, dynamic> response;
        try {
          response = await _dioClient.get<Map<String, dynamic>>(endpoint);
          print(
            '📄 [DpsRepository.getDpsStatement] Raw response keys: ${response.keys.toList()}',
          );
        } catch (e, st) {
          print('❌ [DpsRepository.getDpsStatement] HTTP call threw: $e');
          print('❌ [DpsRepository.getDpsStatement] Stack: $st');
          rethrow;
        }

        final rawData = response['data'];
        print(
          '📄 [DpsRepository.getDpsStatement] response[data] type: ${rawData.runtimeType}',
        );
        print(
          '📄 [DpsRepository.getDpsStatement] response[data] value: $rawData',
        );

        final statement = DpsStatementModel.fromJson(
          rawData as Map<String, dynamic>,
        );
        print(
          '✅ [DpsRepository.getDpsStatement] Parsed statement with ${statement.totalInstallments} installments',
        );
        return statement;
      },
      onError: (e) => _handleDpsError(e, dpsNumber),
    );
  }

  // ---------------------------------------------------------------------------
  // GET /api/dps/calculate-maturity
  // ---------------------------------------------------------------------------

  Future<MaturityCalculationModel> calculateMaturity({
    required double monthlyInstallment,
    required int tenureMonths,
    required double interestRate,
  }) {
    print(
      '🧮 [DpsRepository.calculateMaturity] Called — installment: $monthlyInstallment, tenure: $tenureMonths, rate: $interestRate',
    );

    return _executeWithRetry(
      operationName: 'calculateMaturity',
      operation: () async {
        final endpoint = _Endpoints.calculateMaturity();
        final params = {
          'monthlyInstallment': monthlyInstallment,
          'tenureMonths': tenureMonths,
          'interestRate': interestRate,
        };
        print(
          '🧮 [DpsRepository.calculateMaturity] Hitting endpoint: $endpoint',
        );
        print('🧮 [DpsRepository.calculateMaturity] Query params: $params');

        Map<String, dynamic> response;
        try {
          response = await _dioClient.get<Map<String, dynamic>>(
            endpoint,
            queryParameters: params,
          );
          print(
            '🧮 [DpsRepository.calculateMaturity] Raw response keys: ${response.keys.toList()}',
          );
        } catch (e, st) {
          print('❌ [DpsRepository.calculateMaturity] HTTP call threw: $e');
          print('❌ [DpsRepository.calculateMaturity] Stack: $st');
          rethrow;
        }

        final rawData = response['data'];
        print(
          '🧮 [DpsRepository.calculateMaturity] response[data] type: ${rawData.runtimeType}',
        );
        print(
          '🧮 [DpsRepository.calculateMaturity] response[data] value: $rawData',
        );

        final result = MaturityCalculationModel.fromJson(
          rawData as Map<String, dynamic>,
        );
        print(
          '✅ [DpsRepository.calculateMaturity] Maturity amount: ${result.maturityAmount}',
        );
        return result;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // POST /api/dps
  // ---------------------------------------------------------------------------

  Future<DpsModel> createDps(Map<String, dynamic> body) {
    print('➕ [DpsRepository.createDps] Called with body: $body');

    return _executeWithRetry(
      operationName: 'createDps',
      operation: () async {
        print(
          '➕ [DpsRepository.createDps] Hitting endpoint: ${_Endpoints.create}',
        );
        print('➕ [DpsRepository.createDps] Request body: $body');

        Map<String, dynamic> response;
        try {
          response = await _dioClient.post<Map<String, dynamic>>(
            _Endpoints.create,
            data: body,
          );
          print(
            '➕ [DpsRepository.createDps] Raw response keys: ${response.keys.toList()}',
          );
        } catch (e, st) {
          print('❌ [DpsRepository.createDps] HTTP call threw: $e');
          print('❌ [DpsRepository.createDps] Stack: $st');
          rethrow;
        }

        final rawData = response['data'];
        print(
          '➕ [DpsRepository.createDps] response[data] type: ${rawData.runtimeType}',
        );
        print('➕ [DpsRepository.createDps] response[data] value: $rawData');

        final dps = DpsModel.fromJson(rawData as Map<String, dynamic>);
        print('✅ [DpsRepository.createDps] Created DPS: ${dps.dpsNumber}');
        return dps;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // POST /api/dps/pay-installment
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> payInstallment(Map<String, dynamic> body) {
    print('💳 [DpsRepository.payInstallment] Called with body: $body');

    return _executeWithRetry(
      operationName: 'payInstallment',
      operation: () async {
        print(
          '💳 [DpsRepository.payInstallment] Hitting endpoint: ${_Endpoints.payInstallment}',
        );

        Map<String, dynamic> response;
        try {
          response = await _dioClient.post<Map<String, dynamic>>(
            _Endpoints.payInstallment,
            data: body,
          );
          print(
            '💳 [DpsRepository.payInstallment] Raw response keys: ${response.keys.toList()}',
          );
        } catch (e, st) {
          print('❌ [DpsRepository.payInstallment] HTTP call threw: $e');
          print('❌ [DpsRepository.payInstallment] Stack: $st');
          rethrow;
        }

        final rawData = response['data'];
        print(
          '💳 [DpsRepository.payInstallment] response[data] type: ${rawData.runtimeType}',
        );
        print(
          '💳 [DpsRepository.payInstallment] response[data] value: $rawData',
        );

        final data = rawData as Map<String, dynamic>;
        print(
          '✅ [DpsRepository.payInstallment] Payment successful for: ${body['dpsNumber']}',
        );
        return data;
      },
      onError: (e) =>
          _handleDpsError(e, body['dpsNumber']?.toString() ?? 'unknown'),
    );
  }

  // ---------------------------------------------------------------------------
  // PATCH /api/dps/{dpsNumber}/close
  // ---------------------------------------------------------------------------

  Future<DpsModel> closeDps(String dpsNumber, {String? reason}) {
    print(
      '🔒 [DpsRepository.closeDps] Called — dpsNumber: $dpsNumber, reason: $reason',
    );

    return _executeWithRetry(
      operationName: 'closeDps',
      operation: () async {
        final endpoint = _Endpoints.close(dpsNumber);
        final params = reason != null ? {'reason': reason} : null;
        print('🔒 [DpsRepository.closeDps] Hitting endpoint: $endpoint');
        print('🔒 [DpsRepository.closeDps] Query params: $params');

        Map<String, dynamic> response;
        try {
          response = await _dioClient.patch<Map<String, dynamic>>(
            endpoint,
            queryParameters: params,
          );
          print(
            '🔒 [DpsRepository.closeDps] Raw response keys: ${response.keys.toList()}',
          );
        } catch (e, st) {
          print('❌ [DpsRepository.closeDps] HTTP call threw: $e');
          print('❌ [DpsRepository.closeDps] Stack: $st');
          rethrow;
        }

        final rawData = response['data'];
        print(
          '🔒 [DpsRepository.closeDps] response[data] type: ${rawData.runtimeType}',
        );
        print('🔒 [DpsRepository.closeDps] response[data] value: $rawData');

        final dps = DpsModel.fromJson(rawData as Map<String, dynamic>);
        print('✅ [DpsRepository.closeDps] DPS closed: ${dps.dpsNumber}');
        return dps;
      },
      onError: (e) => _handleDpsError(e, dpsNumber),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<T> _executeWithRetry<T>({
    required String operationName,
    required Future<T> Function() operation,
    void Function(dynamic error)? onError,
  }) async {
    int retryCount = 0;
    print('⚙️  [DpsRepository._executeWithRetry] Starting: $operationName');

    while (true) {
      try {
        final result = await operation();
        print(
          '⚙️  [DpsRepository._executeWithRetry] $operationName succeeded on attempt ${retryCount + 1}',
        );
        return result;
      } catch (e, st) {
        print(
          '⚙️  [DpsRepository._executeWithRetry] $operationName threw: ${e.runtimeType}: $e',
        );
        print('⚙️  [DpsRepository._executeWithRetry] Stack trace: $st');

        if (onError != null) {
          print(
            '⚙️  [DpsRepository._executeWithRetry] Calling onError handler for: $operationName',
          );
          try {
            onError(e);
          } catch (transformedError) {
            print(
              '⚙️  [DpsRepository._executeWithRetry] onError re-threw: ${transformedError.runtimeType}: $transformedError',
            );
            rethrow;
          }
        }

        final isRetryable = _isRetryableError(e);
        final shouldRetry = isRetryable && retryCount < _maxRetries;
        print(
          '⚙️  [DpsRepository._executeWithRetry] isRetryable: $isRetryable, retryCount: $retryCount/$_maxRetries, shouldRetry: $shouldRetry',
        );

        if (shouldRetry) {
          retryCount++;
          final delay = _retryDelay * retryCount;
          print(
            '⚙️  [DpsRepository._executeWithRetry] Retrying $operationName in ${delay.inMilliseconds}ms (attempt $retryCount/$_maxRetries)',
          );
          _logger.w(
            '$operationName retry $retryCount/$_maxRetries after ${delay.inMilliseconds}ms: $e',
          );
          await Future.delayed(delay);
          continue;
        }

        print(
          '❌ [DpsRepository._executeWithRetry] $operationName failed permanently after $retryCount retries',
        );
        _logger.e('$operationName failed after $retryCount retries: $e');
        rethrow;
      }
    }
  }

  bool _isRetryableError(dynamic error) {
    final result =
        error is NetworkException ||
        error is TimeoutException ||
        (error is ApiException && error.statusCode == 503);
    print(
      '⚙️  [DpsRepository._isRetryableError] ${error.runtimeType} → retryable: $result',
    );
    return result;
  }

  void _handleDpsError(dynamic error, String dpsNumber) {
    print(
      '🚨 [DpsRepository._handleDpsError] Handling ${error.runtimeType} for DPS: $dpsNumber',
    );
    print('🚨 [DpsRepository._handleDpsError] Error details: $error');

    if (error is NotFoundException) {
      print(
        '🚨 [DpsRepository._handleDpsError] → NotFoundException — throwing DpsNotFoundException',
      );
      _logger.e('DPS not found: $dpsNumber');
      throw DpsNotFoundException.forDpsNumber(
        dpsNumber,
        data: error.data,
        stackTrace: error.stackTrace,
      );
    }

    if (error is ForbiddenException) {
      print('🚨 [DpsRepository._handleDpsError] → ForbiddenException');
      _logger.w('Access denied for DPS: $dpsNumber — ${error.message}');
      throw ForbiddenException(
        message: error.message.isNotEmpty
            ? error.message
            : 'You do not have permission to access this DPS account.',
        data: error.data,
        stackTrace: error.stackTrace,
      );
    }

    if (error is UnauthorizedException) {
      print(
        '🚨 [DpsRepository._handleDpsError] → UnauthorizedException — rethrowing',
      );
      _logger.w('Unauthorised access to DPS: $dpsNumber');
      throw error;
    }

    if (error is BadRequestException) {
      print(
        '🚨 [DpsRepository._handleDpsError] → BadRequestException: ${error.message}',
      );
      _logger.w('Bad request for DPS $dpsNumber: ${error.message}');
      throw error;
    }

    if (error is ConflictException) {
      print(
        '🚨 [DpsRepository._handleDpsError] → ConflictException: ${error.message}',
      );
      _logger.w('Conflict for DPS $dpsNumber: ${error.message}');
      throw error;
    }

    if (error is ApiException) {
      print(
        '🚨 [DpsRepository._handleDpsError] → ApiException: ${error.message}',
      );
      _logger.e('API error for DPS $dpsNumber: ${error.message}');
      throw error;
    }

    print(
      '🚨 [DpsRepository._handleDpsError] → Unhandled error type: ${error.runtimeType} — not rethrowing from handler',
    );
  }
}

// ---------------------------------------------------------------------------
// Domain exception
// ---------------------------------------------------------------------------

class DpsNotFoundException extends NotFoundException {
  final String? dpsNumber;

  const DpsNotFoundException({
    super.message = 'DPS account not found',
    this.dpsNumber,
    super.data,
    super.stackTrace,
  }) : super(resourceType: 'DPS', resourceId: dpsNumber);

  factory DpsNotFoundException.forDpsNumber(
    String dpsNumber, {
    String? customMessage,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return DpsNotFoundException(
      message: customMessage ?? 'DPS account "$dpsNumber" not found',
      dpsNumber: dpsNumber,
      data: data,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('DpsNotFoundException: $message');
    if (dpsNumber != null) buffer.write(' (DPS Number: $dpsNumber)');
    if (data != null) buffer.write('\nAdditional Data: $data');
    return buffer.toString();
  }
}

// import 'package:logger/logger.dart';
// import 'package:vantedge/core/api/interceptors/dio_client.dart';
// import 'package:vantedge/core/exceptions/api_exceptions.dart';
// import 'dps_model.dart';
// import 'dps_installment_model.dart';
// import 'dps_statement_model.dart';
// import 'maturity_calculation_model.dart';

// class _Endpoints {
//   _Endpoints._();

//   static const String _base = '/api/dps';

//   static const String create          = _base;
//   static const String payInstallment  = '$_base/pay-installment';

//   static String byCustomer(String customerId) => '$_base/customer/$customerId';
//   static String byNumber(String dpsNumber)    => '$_base/number/$dpsNumber';
//   static String statement(String dpsNumber)   => '$_base/statement/$dpsNumber';
//   static String close(String dpsNumber)       => '$_base/$dpsNumber/close';
//   static String calculateMaturity()           => '$_base/calculate-maturity';
// }

// class DpsRepository {
//   final DioClient _dioClient;
//   final Logger _logger = Logger();

//   static const int _maxRetries = 2;
//   static const Duration _retryDelay = Duration(milliseconds: 500);

//   DpsRepository({required DioClient dioClient}) : _dioClient = dioClient;

//   /// GET /api/dps/customer/{customerId}
//   Future<List<DpsModel>> getMyDps(String customerId) {
//     return _executeWithRetry(
//       operationName: 'getMyDps',
//       operation: () async {
//         _logger.i('Fetching DPS accounts for customer: $customerId');

//         final response = await _dioClient.get<Map<String, dynamic>>(
//           _Endpoints.byCustomer(customerId),
//         );

//         final List<dynamic> raw = response['data'] as List<dynamic>;
//         final accounts = raw
//             .map((e) => DpsModel.fromJson(e as Map<String, dynamic>))
//             .toList();

//         _logger.i('Fetched ${accounts.length} DPS accounts for customer: $customerId');
//         return accounts;
//       },
//     );
//   }

//   /// GET /api/dps/number/{dpsNumber}
//   Future<DpsModel> getDpsByNumber(String dpsNumber) {
//     return _executeWithRetry(
//       operationName: 'getDpsByNumber',
//       operation: () async {
//         _logger.i('Fetching DPS by number: $dpsNumber');

//         final response = await _dioClient.get<Map<String, dynamic>>(
//           _Endpoints.byNumber(dpsNumber),
//         );

//         final dps = DpsModel.fromJson(response['data'] as Map<String, dynamic>);

//         _logger.i('Fetched DPS: $dpsNumber');
//         return dps;
//       },
//       onError: (e) => _handleDpsError(e, dpsNumber),
//     );
//   }

//   /// GET /api/dps/statement/{dpsNumber} — returns only the installments list
//   Future<List<DpsInstallmentModel>> getInstallments(String dpsNumber) {
//     return _executeWithRetry(
//       operationName: 'getInstallments',
//       operation: () async {
//         _logger.i('Fetching installments for DPS: $dpsNumber');

//         final response = await _dioClient.get<Map<String, dynamic>>(
//           _Endpoints.statement(dpsNumber),
//         );

//         final data = response['data'] as Map<String, dynamic>;
//         final raw = data['installments'] as List<dynamic>? ?? [];
//         final installments = raw
//             .map((e) => DpsInstallmentModel.fromJson(e as Map<String, dynamic>))
//             .toList();

//         _logger.i('Fetched ${installments.length} installments for DPS: $dpsNumber');
//         return installments;
//       },
//       onError: (e) => _handleDpsError(e, dpsNumber),
//     );
//   }

//   /// GET /api/dps/statement/{dpsNumber}
//   Future<DpsStatementModel> getDpsStatement(String dpsNumber) {
//     return _executeWithRetry(
//       operationName: 'getDpsStatement',
//       operation: () async {
//         _logger.i('Fetching statement for DPS: $dpsNumber');

//         final response = await _dioClient.get<Map<String, dynamic>>(
//           _Endpoints.statement(dpsNumber),
//         );

//         final statement = DpsStatementModel.fromJson(
//           response['data'] as Map<String, dynamic>,
//         );

//         _logger.i(
//           'Statement fetched for DPS: $dpsNumber '
//           '(${statement.totalInstallments} installments)',
//         );
//         return statement;
//       },
//       onError: (e) => _handleDpsError(e, dpsNumber),
//     );
//   }

//   /// GET /api/dps/calculate-maturity?monthlyInstallment=&tenureMonths=&interestRate=
//   Future<MaturityCalculationModel> calculateMaturity({
//     required double monthlyInstallment,
//     required int tenureMonths,
//     required double interestRate,
//   }) {
//     return _executeWithRetry(
//       operationName: 'calculateMaturity',
//       operation: () async {
//         _logger.i(
//           'Calculating maturity — installment: $monthlyInstallment, '
//           'tenure: $tenureMonths months, rate: $interestRate%',
//         );

//         final response = await _dioClient.get<Map<String, dynamic>>(
//           _Endpoints.calculateMaturity(),
//           queryParameters: {
//             'monthlyInstallment': monthlyInstallment,
//             'tenureMonths': tenureMonths,
//             'interestRate': interestRate,
//           },
//         );

//         final result = MaturityCalculationModel.fromJson(
//           response['data'] as Map<String, dynamic>,
//         );

//         _logger.i('Maturity calculated: ${result.maturityAmount}');
//         return result;
//       },
//     );
//   }

//   /// POST /api/dps
//   Future<DpsModel> createDps(Map<String, dynamic> body) {
//     return _executeWithRetry(
//       operationName: 'createDps',
//       operation: () async {
//         _logger.i('Creating DPS for customer: ${body['customerId']}');

//         final response = await _dioClient.post<Map<String, dynamic>>(
//           _Endpoints.create,
//           data: body,
//         );

//         final dps = DpsModel.fromJson(response['data'] as Map<String, dynamic>);

//         _logger.i('DPS created: ${dps.dpsNumber}');
//         return dps;
//       },
//     );
//   }

//   /// POST /api/dps/pay-installment
//   Future<Map<String, dynamic>> payInstallment(Map<String, dynamic> body) {
//     return _executeWithRetry(
//       operationName: 'payInstallment',
//       operation: () async {
//         _logger.i('Paying DPS installment for DPS: ${body['dpsNumber']}');

//         final response = await _dioClient.post<Map<String, dynamic>>(
//           _Endpoints.payInstallment,
//           data: body,
//         );

//         final data = response['data'] as Map<String, dynamic>;

//         _logger.i('Installment payment successful for DPS: ${body['dpsNumber']}');
//         return data;
//       },
//       onError: (e) => _handleDpsError(e, body['dpsNumber']?.toString() ?? 'unknown'),
//     );
//   }

//   /// PATCH /api/dps/{dpsNumber}/close?reason={reason}
//   Future<DpsModel> closeDps(String dpsNumber, {String? reason}) {
//     return _executeWithRetry(
//       operationName: 'closeDps',
//       operation: () async {
//         _logger.i('Closing DPS: $dpsNumber${reason != null ? ' — reason: $reason' : ''}');

//         final response = await _dioClient.patch<Map<String, dynamic>>(
//           _Endpoints.close(dpsNumber),
//           queryParameters: {
//             'reason': ?reason,
//           },
//         );

//         final dps = DpsModel.fromJson(response['data'] as Map<String, dynamic>);

//         _logger.i('DPS closed: $dpsNumber');
//         return dps;
//       },
//       onError: (e) => _handleDpsError(e, dpsNumber),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // Private helpers
//   // ---------------------------------------------------------------------------

//   Future<T> _executeWithRetry<T>({
//     required String operationName,
//     required Future<T> Function() operation,
//     void Function(dynamic error)? onError,
//   }) async {
//     int retryCount = 0;

//     while (true) {
//       try {
//         return await operation();
//       } catch (e) {
//         if (onError != null) {
//           onError(e);
//         }

//         final isRetryable = _isRetryableError(e);
//         final shouldRetry = isRetryable && retryCount < _maxRetries;

//         if (shouldRetry) {
//           retryCount++;
//           _logger.w(
//             '$operationName failed '
//             '(attempt $retryCount/$_maxRetries), '
//             'retrying after ${_retryDelay.inMilliseconds * retryCount}ms: $e',
//           );
//           await Future.delayed(_retryDelay * retryCount);
//           continue;
//         }

//         _logger.e('$operationName failed after $retryCount retries: $e');
//         rethrow;
//       }
//     }
//   }

//   bool _isRetryableError(dynamic error) {
//     return error is NetworkException ||
//         error is TimeoutException ||
//         (error is ApiException && error.statusCode == 503);
//   }

//   void _handleDpsError(dynamic error, String dpsNumber) {
//     if (error is NotFoundException) {
//       _logger.e('DPS not found: $dpsNumber');
//       throw DpsNotFoundException.forDpsNumber(
//         dpsNumber,
//         data: error.data,
//         stackTrace: error.stackTrace,
//       );
//     }

//     if (error is ForbiddenException) {
//       _logger.w('Access denied for DPS: $dpsNumber — ${error.message}');
//       throw ForbiddenException(
//         message: error.message.isNotEmpty
//             ? error.message
//             : 'You do not have permission to access this DPS account.',
//         data: error.data,
//         stackTrace: error.stackTrace,
//       );
//     }

//     if (error is UnauthorizedException) {
//       _logger.w('Unauthorised access to DPS: $dpsNumber');
//       throw error;
//     }

//     if (error is BadRequestException) {
//       _logger.w('Bad request for DPS $dpsNumber: ${error.message}');
//       throw error;
//     }

//     if (error is ConflictException) {
//       _logger.w('Conflict for DPS $dpsNumber: ${error.message}');
//       throw error;
//     }

//     if (error is ApiException) {
//       _logger.e('API error for DPS $dpsNumber: ${error.message}');
//       throw error;
//     }
//   }
// }

// // ---------------------------------------------------------------------------
// // Domain exception
// // ---------------------------------------------------------------------------

// class DpsNotFoundException extends NotFoundException {
//   final String? dpsNumber;

//   const DpsNotFoundException({
//     super.message = 'DPS account not found',
//     this.dpsNumber,
//     super.data,
//     super.stackTrace,
//   }) : super(resourceType: 'DPS', resourceId: dpsNumber);

//   factory DpsNotFoundException.forDpsNumber(
//     String dpsNumber, {
//     String? customMessage,
//     dynamic data,
//     StackTrace? stackTrace,
//   }) {
//     return DpsNotFoundException(
//       message: customMessage ?? 'DPS account "$dpsNumber" not found',
//       dpsNumber: dpsNumber,
//       data: data,
//       stackTrace: stackTrace,
//     );
//   }

//   @override
//   String toString() {
//     final buffer = StringBuffer('DpsNotFoundException: $message');
//     if (dpsNumber != null) buffer.write(' (DPS Number: $dpsNumber)');
//     if (data != null) buffer.write('\nAdditional Data: $data');
//     return buffer.toString();
//   }
// }
