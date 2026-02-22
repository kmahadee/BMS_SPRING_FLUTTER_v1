import 'dart:async';

import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:vantedge/core/api/interceptors/dio_client.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import 'package:vantedge/features/accounts/data/domain/exceptions/account_inactive_exception.dart';
import 'package:vantedge/features/accounts/data/domain/exceptions/account_not_found_exception.dart';
import 'package:vantedge/features/transactions/data/exceptions/insufficient_balance_exception.dart';
import 'package:vantedge/features/transactions/data/exceptions/invalid_transaction_exception.dart';
import 'package:vantedge/features/transactions/data/exceptions/transaction_not_found_exception.dart';
import 'package:vantedge/features/transactions/data/models/transaction_model.dart';
import 'package:vantedge/features/transactions/data/models/transfer_request.dart';
import 'package:vantedge/features/transactions/data/models/deposit_request.dart';
import 'package:vantedge/features/transactions/data/models/withdraw_request.dart';
import 'package:vantedge/features/transactions/data/models/account_statement_model.dart';
import 'package:vantedge/features/transactions/data/models/account_balance_model.dart';
import 'transaction_repository.dart';

class _TxnEndpoints {
  _TxnEndpoints._();

  static const String _base = '/api/transactions';
  static const String _accountsBase = '/api/accounts';

  static const String transfer = '$_base/transfer';
  static const String deposit = '$_base/deposit';
  static const String withdraw = '$_base/withdraw';

  static String balance(String accountNumber) =>
      '$_base/balance/$accountNumber';

  static const String statement = '$_accountsBase/statement';
}

class TransactionRepositoryImpl implements TransactionRepository {
  final DioClient _dioClient;
  final Logger _logger = Logger();

  static const int _maxRetries = 2;

  static const Duration _retryDelay = Duration(milliseconds: 500);

  TransactionRepositoryImpl({required DioClient dioClient})
      : _dioClient = dioClient;


  @override
  Future<TransactionModel> transfer(TransferRequest request) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i(
          'Initiating transfer: ${request.fromAccountNumber} → '
          '${request.toAccountNumber}, amount: ${request.amount}',
        );

        final response = await _dioClient.post<Map<String, dynamic>>(
          _TxnEndpoints.transfer,
          data: request.toJson(),
        );

        final transaction = TransactionModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i(
          'Transfer completed. Transaction ID: ${transaction.transactionId}, '
          'Ref: ${transaction.referenceNumber}',
        );
        return transaction;
      },
      operationName: 'transfer',
      onError: (error) => _handleTransactionError(
        error,
        accountNumber: request.fromAccountNumber,
      ),
    );
  }

  @override
  Future<TransactionModel> deposit(DepositRequest request) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i(
          'Initiating deposit to account: ${request.accountNumber}, '
          'amount: ${request.amount}',
        );

        final response = await _dioClient.post<Map<String, dynamic>>(
          _TxnEndpoints.deposit,
          data: request.toJson(),
        );

        final transaction = TransactionModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i(
          'Deposit completed. Transaction ID: ${transaction.transactionId}',
        );
        return transaction;
      },
      operationName: 'deposit',
      onError: (error) => _handleTransactionError(
        error,
        accountNumber: request.accountNumber,
      ),
    );
  }

  @override
  Future<TransactionModel> withdraw(WithdrawRequest request) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i(
          'Initiating withdrawal from account: ${request.accountNumber}, '
          'amount: ${request.amount}',
        );

        final response = await _dioClient.post<Map<String, dynamic>>(
          _TxnEndpoints.withdraw,
          data: request.toJson(),
        );

        final transaction = TransactionModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i(
          'Withdrawal completed. Transaction ID: ${transaction.transactionId}',
        );
        return transaction;
      },
      operationName: 'withdraw',
      onError: (error) => _handleTransactionError(
        error,
        accountNumber: request.accountNumber,
      ),
    );
  }

  @override
  Future<AccountBalanceModel> getBalance(String accountNumber) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i('Fetching balance for account: $accountNumber');

        final response = await _dioClient.get<Map<String, dynamic>>(
          _TxnEndpoints.balance(accountNumber),
        );

        final balance = AccountBalanceModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i(
          'Balance fetched for $accountNumber: ${balance.balance}',
        );
        return balance;
      },
      operationName: 'getBalance',
      onError: (error) => _handleTransactionError(
        error,
        accountNumber: accountNumber,
      ),
    );
  }

  @override
  Future<AccountStatementModel> getStatement(
    String accountNumber,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _executeWithRetry(
      operation: () async {
        _logger.i(
          'Generating statement for $accountNumber: '
          '${startDate.toIso8601String()} → ${endDate.toIso8601String()}',
        );

        final requestBody = {
          'accountNumber': accountNumber,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        };

        final response = await _dioClient.post<Map<String, dynamic>>(
          _TxnEndpoints.statement,
          data: requestBody,
        );

        final statement = AccountStatementModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );

        _logger.i(
          'Statement generated for $accountNumber: '
          '${statement.transactions.length} transactions.',
        );
        return statement;
      },
      operationName: 'getStatement',
      onError: (error) => _handleTransactionError(
        error,
        accountNumber: accountNumber,
      ),
    );
  }


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
        if (onError != null) {
          onError(e);
        }

        final isRetryable = _isRetryableError(e);
        final shouldRetry = isRetryable && retryCount < _maxRetries;

        if (shouldRetry) {
          retryCount++;
          _logger.w(
            '$operationName failed (attempt $retryCount/$_maxRetries), '
            'retrying in ${(_retryDelay * retryCount).inMilliseconds}ms: $e',
          );
          await Future.delayed(_retryDelay * retryCount);
          continue;
        }

        _logger.e(
          '$operationName failed after $retryCount '
          '${retryCount == 1 ? "retry" : "retries"}: $e',
        );
        rethrow;
      }
    }
  }

  bool _isRetryableError(dynamic error) {
    return error is NetworkException ||
        error is TimeoutException ||
        (error is ApiException && error.statusCode == 503);
  }


  void _handleTransactionError(
    dynamic error, {
    String? accountNumber,
  }) {
    if (error is NotFoundException) {
      final msg = error.message.toLowerCase();

      if (msg.contains('transaction')) {
        throw TransactionNotFoundException.withMessage(
          error.message,
          data: error.data,
          stackTrace: error.stackTrace,
        );
      }

      throw AccountNotFoundException.forAccount(
        accountNumber ?? 'unknown',
        data: error.data,
        stackTrace: error.stackTrace,
      );
    }

    if (error is BadRequestException) {
      final msg = error.message.toLowerCase();

      if (msg.contains('insufficient balance') || msg.contains('insufficient funds')) {
        throw InsufficientBalanceException.fromMessage(
          error.message,
          accountNumber: accountNumber,
          data: error.data,
          stackTrace: error.stackTrace,
        );
      }

      throw InvalidTransactionException.withMessage(
        error.message,
        data: error.data,
        stackTrace: error.stackTrace,
      );
    }

    if (error is ForbiddenException) {
      final msg = error.message.toLowerCase();

      if (msg.contains('inactive') ||
          msg.contains('dormant') ||
          msg.contains('blocked') ||
          msg.contains('not active')) {
        if (accountNumber != null) {
          if (msg.contains('blocked')) {
            throw AccountInactiveException.blocked(
              accountNumber,
              data: error.data,
              stackTrace: error.stackTrace,
            );
          } else if (msg.contains('dormant')) {
            throw AccountInactiveException.dormant(
              accountNumber,
              data: error.data,
              stackTrace: error.stackTrace,
            );
          } else {
            throw AccountInactiveException.forAccount(
              accountNumber,
              _extractStatus(error.data) ?? 'INACTIVE',
              data: error.data,
              stackTrace: error.stackTrace,
            );
          }
        }
      }

      throw error;
    }

    if (error is UnauthorizedException) {
      _logger.w(
        'Unauthorized access${accountNumber != null ? " for account $accountNumber" : ""}',
      );
      throw error;
    }

    if (error is ApiException) {
      _logger.e(
        'API error${accountNumber != null ? " for account $accountNumber" : ""}: '
        '${error.message}',
      );
      throw error;
    }

    if (error is DioException) {
      _logger.e('Unhandled DioException in transaction repo: ${error.message}');
      throw NetworkException(
        message: error.message ?? 'Network error during transaction.',
        data: error,
        stackTrace: error.stackTrace,
      );
    }
  }


  String? _extractStatus(dynamic data) {
    if (data is Map) {
      return data['status'] as String?;
    }
    return null;
  }
}