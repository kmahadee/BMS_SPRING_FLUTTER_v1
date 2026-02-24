import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import '../../data/models/account_list_item_dto.dart';
import '../../data/models/account_response_dto.dart';
import '../../data/models/account_balance_dto.dart';
import '../../data/models/account_statement_dto.dart';
import '../../data/repositories/account_repository.dart';
import 'package:vantedge/features/accounts/data/domain/exceptions/account_inactive_exception.dart';
import 'package:vantedge/features/accounts/data/domain/exceptions/account_not_found_exception.dart';

class AccountProvider extends ChangeNotifier {
  final AccountRepository _repository;
  final Logger _logger = Logger();

  List<AccountListItemDTO> _accounts = [];
  AccountResponseDTO? _selectedAccount;
  AccountBalanceDTO? _currentBalance;
  AccountStatementDTO? _currentStatement;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastRefresh;

  Timer? _autoRefreshTimer;
  static const Duration _autoRefreshInterval = Duration(minutes: 5);
  bool _autoRefreshEnabled = false;

  final Set<String> _activeRequests = {};

  AccountProvider({required AccountRepository repository})
    : _repository = repository {
    _logger.i('AccountProvider initialized');
  }

  List<AccountListItemDTO> get accounts => List.unmodifiable(_accounts);
  AccountResponseDTO? get selectedAccount => _selectedAccount;
  AccountBalanceDTO? get currentBalance => _currentBalance;
  AccountStatementDTO? get currentStatement => _currentStatement;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastRefresh => _lastRefresh;
  bool get hasAccounts => _accounts.isNotEmpty;
  bool get hasError => _errorMessage != null;
  bool get autoRefreshEnabled => _autoRefreshEnabled;

  double get totalBalance {
    return _accounts.fold(0.0, (sum, account) => sum + account.currentBalance);
  }

  double get totalAvailableBalance {
    return _accounts.fold(
      0.0,
      (sum, account) => sum + account.availableBalance,
    );
  }

  int get activeAccountsCount {
    return _accounts.where((account) => account.status.canTransact).length;
  }

  // Future<void> fetchMyAccounts() async {
  //   final requestId = 'fetchMyAccounts';

  //   if (_activeRequests.contains(requestId)) {
  //     _logger.d('Request already in progress: $requestId');
  //     return;
  //   }

  //   try {
  //     _activeRequests.add(requestId);
  //     _setLoading(true);
  //     _clearError();

  //     _logger.i('Fetching user accounts');

  //     final accounts = await _repository.getMyAccounts();

  //     _accounts = accounts;
  //     _lastRefresh = DateTime.now();
  //     _setLoading(false);

  //     _logger.i('Fetched ${accounts.length} accounts successfully');

  //     if (_autoRefreshEnabled) {
  //       _startAutoRefresh();
  //     }
  //   } on NetworkException catch (e) {
  //     _logger.e('Network error fetching accounts: ${e.message}');
  //     _setError('No internet connection. Please check your network.');
  //     _setLoading(false);
  //   } on UnauthorizedException catch (e) {
  //     _logger.e('Unauthorized error: ${e.message}');
  //     _setError('Session expired. Please login again.');
  //     _setLoading(false);
  //   } on TimeoutException catch (e) {
  //     _logger.e('Timeout error: ${e.message}');
  //     _setError('Request timed out. Please try again.');
  //     _setLoading(false);
  //   } on ApiException catch (e) {
  //     _logger.e('API error fetching accounts: ${e.message}');
  //     _setError(e.message);
  //     _setLoading(false);
  //   } catch (e) {
  //     _logger.e('Unexpected error fetching accounts: $e');
  //     _setError('Failed to load accounts. Please try again.');
  //     _setLoading(false);
  //   } finally {
  //     _activeRequests.remove(requestId);
  //   }
  // }

  Future<void> fetchMyAccounts(String customerId) async {
    final requestId = 'fetchMyAccounts';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Fetching user accounts');

      final accounts = await _repository.getMyAccounts(customerId);

      _accounts = accounts;
      _lastRefresh = DateTime.now();
      _setLoading(false);

      _logger.i('Fetched ${accounts.length} accounts successfully');

      if (_autoRefreshEnabled) {
        _startAutoRefresh();
      }
    } on NetworkException catch (e) {
      _logger.e('Network error fetching accounts: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized error: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on TimeoutException catch (e) {
      _logger.e('Timeout error: ${e.message}');
      _setError('Request timed out. Please try again.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error fetching accounts: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error fetching accounts: $e');
      _setError('Failed to load accounts. Please try again.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  Future<void> fetchAccountDetails(String accountNumber) async {
    final requestId = 'fetchAccountDetails_$accountNumber';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i('Fetching account details for: $accountNumber');

      final account = await _repository.getAccountByNumber(accountNumber);

      _selectedAccount = account;
      _setLoading(false);

      _logger.i('Account details fetched successfully: $accountNumber');

      await refreshBalance(accountNumber);
    } on AccountNotFoundException catch (e) {
      _logger.e('Account not found: ${e.accountNumber}');
      _setError('Account not found. Please check the account number.');
      _setLoading(false);
    } on AccountInactiveException catch (e) {
      _logger.e('Account inactive: ${e.accountNumber} - ${e.accountStatus}');
      _setError('Account is ${e.accountStatus}. Please contact support.');
      _setLoading(false);
    } on NetworkException catch (e) {
      _logger.e('Network error: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized: ${e.message}');
      _setError('You are not authorized to view this account.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error: $e');
      _setError('Failed to load account details.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  Future<void> refreshBalance(String accountNumber) async {
    final requestId = 'refreshBalance_$accountNumber';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _clearError();

      _logger.i('Refreshing balance for: $accountNumber');

      final balance = await _repository.getAccountBalance(accountNumber);

      _currentBalance = balance;

      final index = _accounts.indexWhere(
        (a) => a.accountNumber == accountNumber,
      );
      if (index != -1) {
        _accounts[index] = _accounts[index].copyWith(
          currentBalance: balance.currentBalance,
          availableBalance: balance.availableBalance,
        );
      }

      if (_selectedAccount?.accountNumber == accountNumber) {
        _selectedAccount = _selectedAccount!.copyWith(
          currentBalance: balance.currentBalance,
          availableBalance: balance.availableBalance,
        );
      }

      notifyListeners();

      _logger.i('Balance refreshed successfully for: $accountNumber');
    } on AccountNotFoundException catch (e) {
      _logger.e('Account not found: ${e.accountNumber}');
      _setError('Account not found.');
    } on AccountInactiveException catch (e) {
      _logger.e('Account inactive: ${e.accountNumber}');
      _setError('Account is ${e.accountStatus}.');
    } on NetworkException catch (e) {
      _logger.w('Network error refreshing balance: ${e.message}');
    } on ApiException catch (e) {
      _logger.w('Error refreshing balance: ${e.message}');
    } catch (e) {
      _logger.e('Unexpected error refreshing balance: $e');
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  Future<void> generateStatement(
    String accountNumber,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final requestId = 'generateStatement_$accountNumber';

    if (_activeRequests.contains(requestId)) {
      _logger.d('Request already in progress: $requestId');
      return;
    }

    try {
      _activeRequests.add(requestId);
      _setLoading(true);
      _clearError();

      _logger.i(
        'Generating statement for $accountNumber from ${fromDate.toIso8601String()} to ${toDate.toIso8601String()}',
      );

      final statement = await _repository.generateStatement(
        accountNumber,
        fromDate,
        toDate,
      );

      _currentStatement = statement;
      _setLoading(false);

      _logger.i(
        'Statement generated successfully: ${statement.transactions.length} transactions',
      );
    } on AccountNotFoundException catch (e) {
      _logger.e('Account not found: ${e.accountNumber}');
      _setError('Account not found.');
      _setLoading(false);
    } on BadRequestException catch (e) {
      _logger.e('Invalid date range: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } on NetworkException catch (e) {
      _logger.e('Network error: ${e.message}');
      _setError('No internet connection.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('Error generating statement: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error generating statement: $e');
      _setError('Failed to generate statement.');
      _setLoading(false);
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  void selectAccount(AccountListItemDTO account) {
    _logger.d('Selecting account: ${account.accountNumber}');

    _selectedAccount = null;
    _currentBalance = null;
    _currentStatement = null;

    notifyListeners();

    fetchAccountDetails(account.accountNumber);
  }

  void clearSelectedAccount() {
    _logger.d('Clearing selected account');
    _selectedAccount = null;
    _currentBalance = null;
    _currentStatement = null;
    notifyListeners();
  }

  void clearStatement() {
    _logger.d('Clearing statement');
    _currentStatement = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _logger.d('Clearing error message');
      _errorMessage = null;
      notifyListeners();
    }
  }

  void enableAutoRefresh() {
    if (!_autoRefreshEnabled) {
      _logger.i('Enabling auto-refresh');
      _autoRefreshEnabled = true;
      _startAutoRefresh();
    }
  }

  void disableAutoRefresh() {
    if (_autoRefreshEnabled) {
      _logger.i('Disabling auto-refresh');
      _autoRefreshEnabled = false;
      _stopAutoRefresh();
    }
  }

  void _startAutoRefresh() {
    _stopAutoRefresh(); // Stop any existing timer

    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      _logger.d('Auto-refresh triggered');

      if (_selectedAccount != null) {
        refreshBalance(_selectedAccount!.accountNumber);
      }
    });

    _logger.d(
      'Auto-refresh timer started (${_autoRefreshInterval.inMinutes} minutes)',
    );
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    _logger.d('Auto-refresh timer stopped');
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _logger.d('AccountProvider disposed');
    _stopAutoRefresh();
    _activeRequests.clear();
    super.dispose();
  }
}
