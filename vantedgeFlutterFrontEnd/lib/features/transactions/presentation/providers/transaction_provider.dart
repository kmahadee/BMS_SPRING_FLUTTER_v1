import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import 'package:vantedge/features/accounts/data/domain/exceptions/account_inactive_exception.dart';
import 'package:vantedge/features/accounts/data/domain/exceptions/account_not_found_exception.dart';
import 'package:vantedge/features/transactions/data/exceptions/insufficient_balance_exception.dart';
import 'package:vantedge/features/transactions/data/models/account_balance_model.dart';
import 'package:vantedge/features/transactions/data/models/account_statement_model.dart';
import 'package:vantedge/features/transactions/data/models/deposit_request.dart';
import 'package:vantedge/features/transactions/data/models/transaction_history_model.dart';
import 'package:vantedge/features/transactions/data/models/transaction_model.dart';
import 'package:vantedge/features/transactions/data/models/transfer_request.dart';
import 'package:vantedge/features/transactions/data/models/withdraw_request.dart';
import 'package:vantedge/features/transactions/data/repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repository;
  final Logger _logger = Logger();


  TransactionModel? _lastTransaction;

  List<TransactionHistoryModel> _transactionHistory = [];

  AccountStatementModel? _currentStatement;

  AccountBalanceModel? _currentBalance;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _successMessage;

  final Set<String> _activeRequests = {};


  TransactionProvider({required TransactionRepository repository})
      : _repository = repository {
    _logger.i('TransactionProvider initialized');
  }


  TransactionModel? get lastTransaction => _lastTransaction;

  List<TransactionHistoryModel> get transactionHistory =>
      List.unmodifiable(_transactionHistory);

  AccountStatementModel? get currentStatement => _currentStatement;

  AccountBalanceModel? get currentBalance => _currentBalance;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isSuccess => _isSuccess;

  String? get successMessage => _successMessage;

  bool get hasError => _errorMessage != null;

  bool get hasStatement => _currentStatement != null;

  bool get hasBalance => _currentBalance != null;


  Future<bool> transfer(TransferRequest request) async {
    const requestId = 'transfer';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return false;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();
      _clearSuccess();

      _logger.i(
        'Initiating transfer: ${request.fromAccountNumber} → '
        '${request.toAccountNumber}, amount: ${request.amount}',
      );

      final transaction = await _repository.transfer(request);

      _lastTransaction = transaction;
      _setSuccess('Transfer of ${request.amount} completed successfully.');
      _setLoading(false);

      _logger.i(
        'Transfer successful. Transaction ID: ${transaction.transactionId}, '
        'Ref: ${transaction.referenceNumber}',
      );

      return true;
    } on InsufficientBalanceException catch (e) {
      _logger.e('Insufficient balance: ${e.message}');
      _setError(
        e.availableBalance != null
            ? 'Insufficient balance. Available: '
                '${e.availableBalance!.toStringAsFixed(2)}.'
            : 'Insufficient balance to complete this transfer.',
      );
      _setLoading(false);
      return false;
    } on AccountInactiveException catch (e) {
      _logger.e('Account inactive: ${e.accountNumber} — ${e.accountStatus}');
      _setError('Account ${e.accountNumber} is ${e.accountStatus}. '
          'Please contact support.');
      _setLoading(false);
      return false;
    } on AccountNotFoundException catch (e) {
      _logger.e('Account not found: ${e.accountNumber}');
      _setError('Account not found. Please check the account number.');
      _setLoading(false);
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error during transfer: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized transfer attempt: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _logger.e('API error during transfer: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _logger.e('Unexpected error during transfer: $e');
      _setError('Transfer failed. Please try again.');
      _setLoading(false);
      return false;
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  Future<bool> deposit(DepositRequest request) async {
    const requestId = 'deposit';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return false;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();
      _clearSuccess();

      _logger.i(
        'Initiating deposit to account: ${request.accountNumber}, '
        'amount: ${request.amount}',
      );

      final transaction = await _repository.deposit(request);

      _lastTransaction = transaction;
      _setSuccess('Deposit of ${request.amount} completed successfully.');
      _setLoading(false);

      _logger.i(
        'Deposit successful. Transaction ID: ${transaction.transactionId}',
      );

      return true;
    } on InsufficientBalanceException catch (e) {
      _logger.e('Insufficient balance during deposit: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } on AccountInactiveException catch (e) {
      _logger.e('Account inactive: ${e.accountNumber} — ${e.accountStatus}');
      _setError('Account ${e.accountNumber} is ${e.accountStatus}. '
          'Please contact support.');
      _setLoading(false);
      return false;
    } on AccountNotFoundException catch (e) {
      _logger.e('Account not found: ${e.accountNumber}');
      _setError('Account not found. Please check the account number.');
      _setLoading(false);
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error during deposit: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized deposit attempt: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _logger.e('API error during deposit: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _logger.e('Unexpected error during deposit: $e');
      _setError('Deposit failed. Please try again.');
      _setLoading(false);
      return false;
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  Future<bool> withdraw(WithdrawRequest request) async {
    const requestId = 'withdraw';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return false;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();
      _clearSuccess();

      _logger.i(
        'Initiating withdrawal from account: ${request.accountNumber}, '
        'amount: ${request.amount}',
      );

      final transaction = await _repository.withdraw(request);

      _lastTransaction = transaction;
      _setSuccess('Withdrawal of ${request.amount} completed successfully.');
      _setLoading(false);

      _logger.i(
        'Withdrawal successful. Transaction ID: ${transaction.transactionId}',
      );

      return true;
    } on InsufficientBalanceException catch (e) {
      _logger.e('Insufficient balance: ${e.message}');
      _setError(
        e.availableBalance != null
            ? 'Insufficient balance. Available: '
                '${e.availableBalance!.toStringAsFixed(2)}.'
            : 'Insufficient balance to complete this withdrawal.',
      );
      _setLoading(false);
      return false;
    } on AccountInactiveException catch (e) {
      _logger.e('Account inactive: ${e.accountNumber} — ${e.accountStatus}');
      _setError('Account ${e.accountNumber} is ${e.accountStatus}. '
          'Please contact support.');
      _setLoading(false);
      return false;
    } on AccountNotFoundException catch (e) {
      _logger.e('Account not found: ${e.accountNumber}');
      _setError('Account not found. Please check the account number.');
      _setLoading(false);
      return false;
    } on NetworkException catch (e) {
      _logger.e('Network error during withdrawal: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
      return false;
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized withdrawal attempt: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _logger.e('API error during withdrawal: ${e.message}');
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _logger.e('Unexpected error during withdrawal: $e');
      _setError('Withdrawal failed. Please try again.');
      _setLoading(false);
      return false;
    } finally {
      _activeRequests.remove(requestId);
    }
  }


  Future<void> loadStatement(
    String accountNumber,
    DateTime start,
    DateTime end,
  ) async {
    final requestId = 'loadStatement_$accountNumber';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i(
        'Loading statement for $accountNumber: '
        '${start.toIso8601String()} → ${end.toIso8601String()}',
      );

      final statement = await _repository.getStatement(
        accountNumber,
        start,
        end,
      );

      _currentStatement = statement;
      _transactionHistory = List.of(statement.transactions);
      _setLoading(false);

      _logger.i(
        'Statement loaded successfully: '
        '${statement.transactions.length} transactions',
      );
    } on AccountNotFoundException catch (e) {
      _logger.e('Account not found: ${e.accountNumber}');
      _setError('Account not found. Please check the account number.');
      _setLoading(false);
    } on AccountInactiveException catch (e) {
      _logger.e('Account inactive: ${e.accountNumber}');
      _setError('Account is ${e.accountStatus}. Please contact support.');
      _setLoading(false);
    } on NetworkException catch (e) {
      _logger.e('Network error loading statement: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized statement request: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error loading statement: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error loading statement: $e');
      _setError('Failed to load statement. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  Future<void> loadBalance(String accountNumber) async {
    final requestId = 'loadBalance_$accountNumber';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _clearError();

      _logger.i('Loading balance for: $accountNumber');

      final balance = await _repository.getBalance(accountNumber);

      _currentBalance = balance;
      notifyListeners();

      _logger.i(
        'Balance loaded successfully for $accountNumber: ${balance.balance}',
      );
    } on AccountNotFoundException catch (e) {
      _logger.e('Account not found: ${e.accountNumber}');
      _setError('Account not found.');
    } on AccountInactiveException catch (e) {
      _logger.e('Account inactive: ${e.accountNumber}');
      _setError('Account is ${e.accountStatus}.');
    } on NetworkException catch (e) {
      _logger.w('Network error loading balance: ${e.message}');
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized balance request: ${e.message}');
      _setError('Session expired. Please login again.');
    } on ApiException catch (e) {
      _logger.w('API error loading balance: ${e.message}');
    } catch (e) {
      _logger.e('Unexpected error loading balance: $e');
    } finally {
      _activeRequests.remove(requestId);
    }
  }


  void clearError() {
    if (_errorMessage != null) {
      _logger.d('Clearing error message');
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearSuccess() {
    if (_isSuccess || _successMessage != null) {
      _logger.d('Clearing success state');
      _isSuccess = false;
      _successMessage = null;
      notifyListeners();
    }
  }

  void reset() {
    _logger.d('Resetting TransactionProvider');
    _lastTransaction = null;
    _transactionHistory = [];
    _currentStatement = null;
    _currentBalance = null;
    _isLoading = false;
    _errorMessage = null;
    _isSuccess = false;
    _successMessage = null;
    _activeRequests.clear();
    notifyListeners();
  }


  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _isSuccess = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setSuccess(String message) {
    _isSuccess = true;
    _successMessage = message;
    notifyListeners();
  }

  void _clearSuccess() {
    _isSuccess = false;
    _successMessage = null;
  }


  @override
  void dispose() {
    _logger.d('TransactionProvider disposed');
    _activeRequests.clear();
    super.dispose();
  }
}