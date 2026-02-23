import 'package:logger/logger.dart';
import 'package:vantedge/core/api/interceptors/dio_client.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import 'package:vantedge/features/transactions/data/models/transaction_history_model.dart';
import '../models/loan_model.dart';
import '../models/loan_application.dart';
import '../models/loan_statement.dart';
import '../models/loan_search.dart';
import 'loan_repository.dart';

// ---------------------------------------------------------------------------
// Endpoint constants – same style as ApiConstantsExtension in the project.
// Kept file-private since they are an implementation detail of this class.
// ---------------------------------------------------------------------------

class _Endpoints {
  _Endpoints._();

  static const String _base = '/api/loans';

  // ── Fixed paths ──
  static const String myLoans         = '$_base/my-loans';
  static const String pendingApproval = '$_base/pending-approval';
  static const String apply           = '$_base/apply';
  static const String search          = '$_base/search';
  static const String allLoans        = _base;

  // ── Parameterised paths ──
  static String byId(String loanId)      => '$_base/$loanId';
  static String statement(String loanId) => '$_base/$loanId/statement';
  static String repay(String loanId)     => '$_base/$loanId/repay';
  static String approve(String loanId)   => '$_base/$loanId/approve';
  static String reject(String loanId)    => '$_base/$loanId/reject';
  static String disburse(String loanId)  => '$_base/$loanId/disburse';
  static String foreclose(String loanId) => '$_base/$loanId/foreclose';
  static String byCustomer(String id)    => '$_base/customer/$id';
}

// ---------------------------------------------------------------------------

class LoanRepositoryImpl implements LoanRepository {
  final DioClient _dioClient;
  final Logger _logger = Logger();

  /// Maximum number of automatic retries for transient errors.
  static const int _maxRetries = 2;

  /// Base retry delay – multiplied by attempt index (exponential back-off).
  static const Duration _retryDelay = Duration(milliseconds: 500);

  LoanRepositoryImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  // ── Customer-facing endpoints ────────────────────────────────────────────

  @override
  Future<List<LoanListItemModel>> getMyLoans() {
    return _executeWithRetry(
      operationName: 'getMyLoans',
      operation: () async {
        _logger.i('Fetching my loans');

        final response = await _dioClient.get<Map<String, dynamic>>(
          _Endpoints.myLoans,
        );

        final List<dynamic> raw = response['data'] as List<dynamic>;
        final loans = raw
            .map((e) => LoanListItemModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _logger.i('Fetched ${loans.length} loans');
        return loans;
      },
    );
  }

  @override
  Future<LoanResponseModel> getLoanById(String loanId) {
    return _executeWithRetry(
      operationName: 'getLoanById',
      operation: () async {
        _logger.i('Fetching loan: $loanId');

        final response = await _dioClient.get<Map<String, dynamic>>(
          _Endpoints.byId(loanId),
        );

        final loan = LoanResponseModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i('Loan fetched: $loanId');
        return loan;
      },
      onError: (e) => _handleLoanError(e, loanId),
    );
  }

  @override
  Future<LoanStatementModel> getLoanStatement(String loanId) {
    return _executeWithRetry(
      operationName: 'getLoanStatement',
      operation: () async {
        _logger.i('Fetching statement for loan: $loanId');

        final response = await _dioClient.get<Map<String, dynamic>>(
          _Endpoints.statement(loanId),
        );

        final statement = LoanStatementModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i(
          'Statement fetched for loan: $loanId '
          '(${statement.totalInstallments} installments, '
          '${statement.disbursementHistory.length} disbursements)',
        );
        return statement;
      },
      onError: (e) => _handleLoanError(e, loanId),
    );
  }

  @override
  Future<LoanResponseModel> applyForLoan(LoanApplicationModel request) {
    return _executeWithRetry(
      operationName: 'applyForLoan',
      operation: () async {
        _logger.i(
          'Submitting loan application — '
          'customer: ${request.customerId}, '
          'type: ${request.loanType.displayName}, '
          'amount: ${request.loanAmount}',
        );

        final response = await _dioClient.post<Map<String, dynamic>>(
          _Endpoints.apply,
          data: request.toJson(),
        );

        final loan = LoanResponseModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i('Loan application created: ${loan.loanId}');
        return loan;
      },
    );
  }

  /// `POST /api/loans/{loanId}/repay`
  ///
  /// The backend returns a TransactionResponseDTO (not a LoanResponseDTO),
  /// which maps to the existing [TransactionHistoryModel] on the frontend.
  @override
  Future<TransactionHistoryModel> repayLoan(
    String loanId,
    LoanRepaymentRequestModel request,
  ) {
    return _executeWithRetry(
      operationName: 'repayLoan',
      operation: () async {
        _logger.i(
          'Processing repayment for loan: $loanId '
          '— amount: ${request.paymentAmount}, '
          'mode: ${request.paymentMode.displayName}',
        );

        // The backend reads loanId from @PathVariable and also validates it
        // from the @RequestBody (the DTO has @NotBlank loanId). We inject it
        // into the body map so the DTO validation passes.
        final body = Map<String, dynamic>.from(request.toJson())
          ..['loanId'] = loanId;

        final response = await _dioClient.post<Map<String, dynamic>>(
          _Endpoints.repay(loanId),
          data: body,
        );

        final txn = TransactionHistoryModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i(
          'Repayment processed for loan: $loanId '
          '— txn: ${txn.transactionId}',
        );
        return txn;
      },
      onError: (e) => _handleLoanError(e, loanId),
    );
  }

  @override
  Future<LoanResponseModel> forecloseLoan(
    String loanId,
    LoanForeclosureRequestModel request,
  ) {
    return _executeWithRetry(
      operationName: 'forecloseLoan',
      operation: () async {
        _logger.i('Initiating foreclosure for loan: $loanId');

        final body = Map<String, dynamic>.from(request.toJson())
          ..['loanId'] = loanId;

        final response = await _dioClient.post<Map<String, dynamic>>(
          _Endpoints.foreclose(loanId),
          data: body,
        );

        final loan = LoanResponseModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i('Loan foreclosed: $loanId');
        return loan;
      },
      onError: (e) => _handleLoanError(e, loanId),
    );
  }

  // ── Staff / officer / admin endpoints ────────────────────────────────────

  @override
  Future<List<LoanListItemModel>> getPendingApprovalLoans() {
    return _executeWithRetry(
      operationName: 'getPendingApprovalLoans',
      operation: () async {
        _logger.i('Fetching pending-approval loans');

        final response = await _dioClient.get<Map<String, dynamic>>(
          _Endpoints.pendingApproval,
        );

        final List<dynamic> raw = response['data'] as List<dynamic>;
        final loans = raw
            .map((e) => LoanListItemModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _logger.i('Fetched ${loans.length} pending-approval loans');
        return loans;
      },
    );
  }

  @override
  Future<List<LoanListItemModel>> getLoansByCustomerId(String customerId) {
    return _executeWithRetry(
      operationName: 'getLoansByCustomerId',
      operation: () async {
        _logger.i('Fetching loans for customer: $customerId');

        final response = await _dioClient.get<Map<String, dynamic>>(
          _Endpoints.byCustomer(customerId),
        );

        final List<dynamic> raw = response['data'] as List<dynamic>;
        final loans = raw
            .map((e) => LoanListItemModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _logger.i(
          'Fetched ${loans.length} loans for customer: $customerId',
        );
        return loans;
      },
    );
  }

  @override
  Future<LoanSearchResponseModel> getAllLoans({
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return _executeWithRetry(
      operationName: 'getAllLoans',
      operation: () async {
        _logger.i(
          'Fetching all loans — page: $pageNumber, size: $pageSize',
        );

        final response = await _dioClient.get<Map<String, dynamic>>(
          _Endpoints.allLoans,
          queryParameters: {
            'pageNumber': pageNumber,
            'pageSize': pageSize,
          },
        );

        final result = LoanSearchResponseModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i(
          'Fetched ${result.loans.length} loans '
          '(total: ${result.totalCount}, '
          'page ${result.pageNumber}/${result.totalPages})',
        );
        return result;
      },
    );
  }

  @override
  Future<LoanSearchResponseModel> searchLoans(
    LoanSearchRequestModel request,
  ) {
    return _executeWithRetry(
      operationName: 'searchLoans',
      operation: () async {
        _logger.i(
          'Searching loans — '
          'customer: ${request.customerId}, '
          'status: ${request.loanStatus?.displayName}, '
          'type: ${request.loanType?.displayName}, '
          'page: ${request.pageNumber}/${request.pageSize}',
        );

        final response = await _dioClient.post<Map<String, dynamic>>(
          _Endpoints.search,
          data: request.toJson(),
        );

        final result = LoanSearchResponseModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i(
          'Search returned ${result.loans.length} loans '
          '(total: ${result.totalCount})',
        );
        return result;
      },
    );
  }

  /// `POST /api/loans/{loanId}/approve`
  ///
  /// Backend's @PostMapping handler calls request.setApprovalStatus("APPROVED")
  /// server-side. We still include it in the body so the DTO @NotBlank
  /// validation passes (backend reads loanId + approvalStatus from body too).
  @override
  Future<LoanResponseModel> approveLoan(
    String loanId,
    LoanApprovalRequestModel request,
  ) {
    return _executeWithRetry(
      operationName: 'approveLoan',
      operation: () async {
        _logger.i('Approving loan: $loanId');

        final body = Map<String, dynamic>.from(request.toJson())
          ..['loanId'] = loanId
          ..['approvalStatus'] = 'APPROVED';

        final response = await _dioClient.post<Map<String, dynamic>>(
          _Endpoints.approve(loanId),
          data: body,
        );

        final loan = LoanResponseModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i('Loan approved: $loanId');
        return loan;
      },
      onError: (e) => _handleLoanError(e, loanId),
    );
  }

  /// `POST /api/loans/{loanId}/reject`
  ///
  /// Backend's @PostMapping handler calls request.setApprovalStatus("REJECTED")
  /// server-side. Same body injection rationale as [approveLoan].
  @override
  Future<LoanResponseModel> rejectLoan(
    String loanId,
    LoanApprovalRequestModel request,
  ) {
    return _executeWithRetry(
      operationName: 'rejectLoan',
      operation: () async {
        _logger.i('Rejecting loan: $loanId');

        final body = Map<String, dynamic>.from(request.toJson())
          ..['loanId'] = loanId
          ..['approvalStatus'] = 'REJECTED';

        final response = await _dioClient.post<Map<String, dynamic>>(
          _Endpoints.reject(loanId),
          data: body,
        );

        final loan = LoanResponseModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i('Loan rejected: $loanId');
        return loan;
      },
      onError: (e) => _handleLoanError(e, loanId),
    );
  }

  @override
  Future<LoanResponseModel> disburseLoan(
    String loanId,
    LoanDisbursementRequestModel request,
  ) {
    return _executeWithRetry(
      operationName: 'disburseLoan',
      operation: () async {
        _logger.i(
          'Disbursing loan: $loanId '
          '— amount: ${request.disbursementAmount}, '
          'account: ${request.accountNumber}',
        );

        final body = Map<String, dynamic>.from(request.toJson())
          ..['loanId'] = loanId;

        final response = await _dioClient.post<Map<String, dynamic>>(
          _Endpoints.disburse(loanId),
          data: body,
        );

        final loan = LoanResponseModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i('Loan disbursed: $loanId');
        return loan;
      },
      onError: (e) => _handleLoanError(e, loanId),
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Runs [operation] with automatic exponential-backoff retry on transient
  /// network / service-unavailable errors, matching [AccountRepositoryImpl].
  ///
  /// [onError] is an optional synchronous hook invoked before the retry
  /// decision. It may throw a more specific typed exception to short-circuit
  /// retry for non-retryable errors (e.g. 404, 403).
  Future<T> _executeWithRetry<T>({
    required String operationName,
    required Future<T> Function() operation,
    void Function(dynamic error)? onError,
  }) async {
    int retryCount = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        // Allow caller to remap or re-throw a more specific exception first.
        if (onError != null) {
          onError(e);
        }

        final isRetryable = _isRetryableError(e);
        final shouldRetry = isRetryable && retryCount < _maxRetries;

        if (shouldRetry) {
          retryCount++;
          _logger.w(
            '$operationName failed '
            '(attempt $retryCount/$_maxRetries), '
            'retrying after ${_retryDelay.inMilliseconds * retryCount}ms: $e',
          );
          await Future.delayed(_retryDelay * retryCount);
          continue;
        }

        _logger.e('$operationName failed after $retryCount retries: $e');
        rethrow;
      }
    }
  }

  bool _isRetryableError(dynamic error) {
    return error is NetworkException ||
        error is TimeoutException ||
        (error is ApiException && error.statusCode == 503);
  }

  /// Translates generic 404/403/401 API exceptions into typed loan exceptions
  /// before the retry decision runs.
  void _handleLoanError(dynamic error, String loanId) {
    if (error is NotFoundException) {
      _logger.e('Loan not found: $loanId');
      throw LoanNotFoundException.forLoanId(
        loanId,
        data: error.data,
        stackTrace: error.stackTrace,
      );
    }

    if (error is ForbiddenException) {
      _logger.w('Access denied for loan: $loanId — ${error.message}');
      throw ForbiddenException(
        message: error.message.isNotEmpty
            ? error.message
            : 'You do not have permission to access this loan.',
        data: error.data,
        stackTrace: error.stackTrace,
      );
    }

    if (error is UnauthorizedException) {
      _logger.w('Unauthorised access to loan: $loanId');
      throw error;
    }

    if (error is BadRequestException) {
      _logger.w('Bad request for loan $loanId: ${error.message}');
      throw error;
    }

    if (error is ConflictException) {
      _logger.w('Conflict for loan $loanId: ${error.message}');
      throw error;
    }

    if (error is ApiException) {
      _logger.e('API error for loan $loanId: ${error.message}');
      throw error;
    }
  }
}

// ---------------------------------------------------------------------------
// Typed domain exception — follows the AccountNotFoundException pattern.
// ---------------------------------------------------------------------------

/// Thrown when a loan cannot be located by its ID.
class LoanNotFoundException extends NotFoundException {
  final String? loanId;

  const LoanNotFoundException({
    super.message = 'Loan not found',
    this.loanId,
    super.data,
    super.stackTrace,
  }) : super(resourceType: 'Loan', resourceId: loanId);

  factory LoanNotFoundException.forLoanId(
    String loanId, {
    String? customMessage,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    return LoanNotFoundException(
      message: customMessage ?? 'Loan with ID "$loanId" not found',
      loanId: loanId,
      data: data,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('LoanNotFoundException: $message');
    if (loanId != null) buffer.write(' (Loan ID: $loanId)');
    if (data != null) buffer.write('\nAdditional Data: $data');
    return buffer.toString();
  }
}
