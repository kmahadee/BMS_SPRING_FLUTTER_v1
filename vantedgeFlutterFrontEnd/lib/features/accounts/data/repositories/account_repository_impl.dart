import 'package:logger/logger.dart';
import 'package:vantedge/core/api/interceptors/dio_client.dart';
import 'package:vantedge/core/constants/api_constants_extension.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import '../models/account_list_item_dto.dart';
import '../models/account_response_dto.dart';
import '../models/account_balance_dto.dart';
import '../models/account_statement_dto.dart';
import '../domain/exceptions/account_not_found_exception.dart';
import '../domain/exceptions/account_inactive_exception.dart';
import 'account_repository.dart';

/// Implementation of [AccountRepository] for account-related operations
///
/// This implementation uses [DioClient] to make HTTP requests to the backend API.
/// It includes comprehensive error handling, logging, and retry logic for failed requests.
class AccountRepositoryImpl implements AccountRepository {
  final DioClient _dioClient;
  final Logger _logger = Logger();

  /// Maximum number of retry attempts for failed requests
  static const int _maxRetries = 2;

  /// Delay between retry attempts
  static const Duration _retryDelay = Duration(milliseconds: 500);

  AccountRepositoryImpl({required DioClient dioClient})
    : _dioClient = dioClient;

  @override
  Future<List<AccountListItemDTO>> getMyAccounts() async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching user accounts');

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.myAccounts,
        );

        final List<dynamic> accountsList = response['data'] as List<dynamic>;
        final accounts = accountsList
            .map(
              (json) =>
                  AccountListItemDTO.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        _logger.i('Fetched ${accounts.length} accounts');
        return accounts;
      },
      operationName: 'getMyAccounts',
    );
  }

  @override
  Future<AccountResponseDTO> getAccountByNumber(String accountNumber) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching account details for: $accountNumber');

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.getAccountByNumber(accountNumber),
        );

        final account = AccountResponseDTO.fromJson(response['data']);

        _logger.i('Account details fetched successfully: $accountNumber');
        return account;
      },
      operationName: 'getAccountByNumber',
      onError: (error) => _handleAccountError(error, accountNumber),
    );
  }

  @override
  Future<AccountBalanceDTO> getAccountBalance(String accountNumber) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching balance for account: $accountNumber');

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.getAccountBalance(accountNumber),
        );

        final balance = AccountBalanceDTO.fromJson(response['data']);

        _logger.i('Balance fetched successfully for: $accountNumber');
        return balance;
      },
      operationName: 'getAccountBalance',
      onError: (error) => _handleAccountError(error, accountNumber),
    );
  }

  @override
  Future<AccountStatementDTO> generateStatement(
    String accountNumber,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i(
          'Generating statement for $accountNumber from ${fromDate.toIso8601String()} to ${toDate.toIso8601String()}',
        );

        // Validate date range
        if (toDate.isBefore(fromDate)) {
          throw const BadRequestException(
            message: 'End date must be after start date',
          );
        }

        final requestData = {
          'accountNumber': accountNumber,
          'fromDate': fromDate.toIso8601String().split(
            'T',
          )[0], // YYYY-MM-DD format
          'toDate': toDate.toIso8601String().split('T')[0],
        };

        final response = await _dioClient.post<Map<String, dynamic>>(
          ApiConstantsExtension.accountStatement,
          data: requestData,
        );

        final statement = AccountStatementDTO.fromJson(response['data']);

        _logger.i(
          'Statement generated successfully for $accountNumber (${statement.transactions.length} transactions)',
        );
        return statement;
      },
      operationName: 'generateStatement',
      onError: (error) => _handleAccountError(error, accountNumber),
    );
  }

  @override
  Future<List<AccountListItemDTO>> getAccountsByCustomerId(
    int customerId,
  ) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching accounts for customer ID: $customerId');

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.getAccountsByCustomer(customerId),
        );

        final List<dynamic> accountsList = response['data'] as List<dynamic>;
        final accounts = accountsList
            .map(
              (json) =>
                  AccountListItemDTO.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        _logger.i(
          'Fetched ${accounts.length} accounts for customer: $customerId',
        );
        return accounts;
      },
      operationName: 'getAccountsByCustomerId',
    );
  }

  @override
  Future<AccountResponseDTO> freezeAccount(String accountNumber) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Freezing account: $accountNumber');

        final response = await _dioClient.put<Map<String, dynamic>>(
          ApiConstantsExtension.getFreezeAccount(accountNumber),
        );

        final account = AccountResponseDTO.fromJson(response['data']);

        _logger.i('Account frozen successfully: $accountNumber');
        return account;
      },
      operationName: 'freezeAccount',
      onError: (error) => _handleAccountError(error, accountNumber),
    );
  }

  @override
  Future<AccountResponseDTO> unfreezeAccount(String accountNumber) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Unfreezing account: $accountNumber');

        final response = await _dioClient.put<Map<String, dynamic>>(
          ApiConstantsExtension.getUnfreezeAccount(accountNumber),
        );

        final account = AccountResponseDTO.fromJson(response['data']);

        _logger.i('Account unfrozen successfully: $accountNumber');
        return account;
      },
      operationName: 'unfreezeAccount',
      onError: (error) => _handleAccountError(error, accountNumber),
    );
  }

  @override
  Future<List<AccountListItemDTO>> getAccountsByStatus(String status) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching accounts with status: $status');

        final response = await _dioClient.get<Map<String, dynamic>>(
          ApiConstantsExtension.getAccountsByStatus(status),
        );

        final List<dynamic> accountsList = response['data'] as List<dynamic>;
        final accounts = accountsList
            .map(
              (json) =>
                  AccountListItemDTO.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        _logger.i('Fetched ${accounts.length} accounts with status: $status');
        return accounts;
      },
      operationName: 'getAccountsByStatus',
    );
  }

  /// Executes an operation with retry logic for transient failures
  ///
  /// [operation] The async operation to execute
  /// [operationName] Name of the operation for logging
  /// [onError] Optional error handler for custom error transformation
  ///
  /// Retries the operation up to [_maxRetries] times for network and timeout errors.
  /// Non-retryable errors are thrown immediately.
  Future<T> _executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    void Function(dynamic error)? onError,
  }) async {
    int retryCount = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        // Handle custom error transformation
        if (onError != null) {
          onError(e);
        }

        // Determine if error is retryable
        final isRetryable = _isRetryableError(e);
        final shouldRetry = isRetryable && retryCount < _maxRetries;

        if (shouldRetry) {
          retryCount++;
          _logger.w(
            '$operationName failed (attempt $retryCount/$_maxRetries), retrying after ${_retryDelay.inMilliseconds}ms: $e',
          );
          await Future.delayed(_retryDelay * retryCount); // Exponential backoff
          continue;
        }

        // Not retryable or max retries reached
        _logger.e('$operationName failed after $retryCount retries: $e');
        rethrow;
      }
    }
  }

  /// Determines if an error is retryable
  ///
  /// Returns true for network errors and timeouts, false for other errors.
  bool _isRetryableError(dynamic error) {
    return error is NetworkException ||
        error is TimeoutException ||
        (error is ApiException &&
            error.statusCode == 503); // Service Unavailable
  }

  /// Handles account-specific errors and transforms them into appropriate exceptions
  ///
  /// [error] The error to handle
  /// [accountNumber] The account number associated with the error
  void _handleAccountError(dynamic error, String accountNumber) {
    if (error is NotFoundException) {
      throw AccountNotFoundException.forAccount(
        accountNumber,
        data: error.data,
        stackTrace: error.stackTrace,
      );
    }

    if (error is ForbiddenException) {
      // Check if the error is due to account being inactive
      final errorMessage = error.message.toLowerCase();
      if (errorMessage.contains('inactive') ||
          errorMessage.contains('dormant') ||
          errorMessage.contains('blocked')) {
        // Try to extract status from error data
        String? status;
        if (error.data is Map) {
          status = error.data['status'] as String?;
        }

        if (errorMessage.contains('blocked')) {
          throw AccountInactiveException.blocked(
            accountNumber,
            data: error.data,
            stackTrace: error.stackTrace,
          );
        } else if (errorMessage.contains('dormant')) {
          throw AccountInactiveException.dormant(
            accountNumber,
            data: error.data,
            stackTrace: error.stackTrace,
          );
        } else {
          throw AccountInactiveException.forAccount(
            accountNumber,
            status ?? 'INACTIVE',
            data: error.data,
            stackTrace: error.stackTrace,
          );
        }
      }
      // Re-throw if not account-specific
      throw error;
    }

    // Handle BadRequestException for validation errors
    if (error is BadRequestException) {
      _logger.w(
        'Validation error for account $accountNumber: ${error.message}',
      );
      throw error;
    }

    // Handle UnauthorizedException
    if (error is UnauthorizedException) {
      _logger.w('Unauthorized access to account $accountNumber');
      throw error;
    }

    // For other errors, just throw
    if (error is ApiException) {
      _logger.e('API error for account $accountNumber: ${error.message}');
      throw error;
    }
  }
}
