import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:vantedge/core/exceptions/api_exceptions.dart';
import 'package:vantedge/features/auth/domain/entities/user_role.dart';
import 'package:vantedge/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:vantedge/features/dashboard/data/models/quick_action_model.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../branches/presentation/providers/branch_provider.dart';

/// Provider for managing dashboard state and role-based content
///
/// This provider coordinates with [AccountProvider] and [BranchProvider]
/// to aggregate data for the dashboard. It provides role-specific content
/// and quick actions based on the user's role.
class DashboardProvider extends ChangeNotifier {
  final AccountProvider? _accountProvider;
  final BranchProvider? _branchProvider;
  final Logger _logger = Logger();

  // State properties
  DashboardSummaryDTO? _dashboardSummary;
  List<QuickActionModel> _quickActions = [];
  UserRole _currentUserRole = UserRole.customer;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastRefresh;

  // Statistics for managers/officers
  Map<String, dynamic>? _roleSpecificData;

  DashboardProvider({
    AccountProvider? accountProvider,
    BranchProvider? branchProvider,
  }) : _accountProvider = accountProvider,
       _branchProvider = branchProvider {
    _logger.i('DashboardProvider initialized');

    // Listen to dependent providers
    _accountProvider?.addListener(_onAccountProviderUpdate);
    _branchProvider?.addListener(_onBranchProviderUpdate);
  }

  // Getters
  DashboardSummaryDTO? get dashboardSummary => _dashboardSummary;
  List<QuickActionModel> get quickActions => List.unmodifiable(_quickActions);
  UserRole get currentUserRole => _currentUserRole;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastRefresh => _lastRefresh;
  bool get hasError => _errorMessage != null;
  Map<String, dynamic>? get roleSpecificData => _roleSpecificData;

  /// Get summary statistics based on role
  Map<String, dynamic> get summaryStats {
    switch (_currentUserRole) {
      case UserRole.customer:
        return {
          'totalAccounts': _accountProvider?.accounts.length ?? 0,
          'totalBalance': _accountProvider?.totalBalance ?? 0.0,
          'activeAccounts': _accountProvider?.activeAccountsCount ?? 0,
        };
      case UserRole.branchManager:
        return {
          'totalBranches': _branchProvider?.branches.length ?? 0,
          'activeBranches': _branchProvider?.activeBranchesCount ?? 0,
          'selectedBranchStats': _branchProvider?.branchStats?.toJson() ?? {},
        };
      case UserRole.loanOfficer:
      case UserRole.cardOfficer:
      case UserRole.admin:
        return _roleSpecificData ?? {};
      default:
        return {};
    }
  }

  /// Loads the dashboard based on user role
  ///
  /// [role] The current user's role
  // Future<void> loadDashboard(UserRole role) async {
  Future<void> loadDashboard(UserRole role, {String? customerId}) async {
    try {
      _currentUserRole = role;
      _currentCustomerId = customerId;
      _setLoading(true);
      _clearError();

      _logger.i('Loading dashboard for role: ${role.name}');

      // Load role-specific data
      // await _loadRoleSpecificData(role);
      await _loadRoleSpecificData(role, customerId: customerId);

      // Build dashboard summary
      await _buildDashboardSummary();

      // Set quick actions
      _quickActions = getQuickActionsForRole(role);

      _lastRefresh = DateTime.now();
      _setLoading(false);

      _logger.i('Dashboard loaded successfully for role: ${role.name}');
    } on NetworkException catch (e) {
      _logger.e('Network error loading dashboard: ${e.message}');
      _setError('No internet connection. Please check your network.');
      _setLoading(false);
    } on UnauthorizedException catch (e) {
      _logger.e('Unauthorized error: ${e.message}');
      _setError('Session expired. Please login again.');
      _setLoading(false);
    } on ApiException catch (e) {
      _logger.e('API error loading dashboard: ${e.message}');
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _logger.e('Unexpected error loading dashboard: $e');
      _setError('Failed to load dashboard. Please try again.');
      _setLoading(false);
    }
  }

  /// Refreshes the current dashboard
  // Future<void> refreshDashboard() async {
  //   _logger.i('Refreshing dashboard');
  //   await loadDashboard(_currentUserRole);
  // }

  String? _currentCustomerId;

  Future<void> refreshDashboard() async {
    _logger.i('Refreshing dashboard');
    await loadDashboard(_currentUserRole, customerId: _currentCustomerId);
  }

  /// Returns quick actions specific to the user's role
  ///
  /// [role] The user role to get actions for
  List<QuickActionModel> getQuickActionsForRole(UserRole role) {
    _logger.d('Getting quick actions for role: ${role.name}');

    switch (role) {
      case UserRole.customer:
        return QuickActions.customerActions;
      case UserRole.branchManager:
        return QuickActions.branchManagerActions;
      case UserRole.loanOfficer:
        return QuickActions.loanOfficerActions;
      case UserRole.cardOfficer:
        return QuickActions.cardOfficerActions;
      case UserRole.admin:
        return QuickActions.adminActions;
      default:
        _logger.w('Unknown role, returning customer actions');
        return QuickActions.customerActions;
    }
  }

  /// Loads role-specific data from appropriate providers
  // Future<void> _loadRoleSpecificData(UserRole role) async {
  Future<void> _loadRoleSpecificData(
    UserRole role, {
    String? customerId,
  }) async {
    switch (role) {
      case UserRole.customer:
        // await _loadCustomerData();
        await _loadCustomerData(customerId: customerId);
        break;
      case UserRole.branchManager:
        await _loadBranchManagerData();
        break;
      case UserRole.loanOfficer:
        await _loadLoanOfficerData();
        break;
      case UserRole.cardOfficer:
        await _loadCardOfficerData();
        break;
      case UserRole.admin:
        // await _loadAdminData();
        await _loadAdminData(customerId: customerId);
        break;
      default:
        _logger.w('Unknown role, loading default customer data');
        await _loadCustomerData();
    }
  }

  /// Loads customer-specific dashboard data
  Future<void> _loadCustomerData({String? customerId}) async {
    _logger.d('Loading customer dashboard data');

    // Fetch accounts if not already loaded
    // if (_accountProvider != null && !_accountProvider.hasAccounts) {
    //   await _accountProvider.fetchMyAccounts();
    // }
    // Fetch accounts if not already loaded
    if (_accountProvider != null &&
        !_accountProvider.hasAccounts &&
        customerId != null) {
      await _accountProvider.fetchMyAccounts(customerId);
    }

    // Build customer-specific data
    _roleSpecificData = {
      'accountsCount': _accountProvider?.accounts.length ?? 0,
      'totalBalance': _accountProvider?.totalBalance ?? 0.0,
      'availableBalance': _accountProvider?.totalAvailableBalance ?? 0.0,
      'activeAccounts': _accountProvider?.activeAccountsCount ?? 0,
      'lastRefresh': _accountProvider?.lastRefresh?.toIso8601String(),
    };
  }

  /// Loads branch manager dashboard data
  Future<void> _loadBranchManagerData() async {
    _logger.d('Loading branch manager dashboard data');

    // Fetch branches if not already loaded
    if (_branchProvider != null && !_branchProvider.hasBranches) {
      await _branchProvider.fetchAllBranches();
    }

    // Fetch statistics for selected branch if available
    if (_branchProvider?.selectedBranch != null) {
      await _branchProvider!.fetchBranchStatistics(
        _branchProvider.selectedBranch!.id,
      );
    }

    _roleSpecificData = {
      'branchesCount': _branchProvider?.branches.length ?? 0,
      'activeBranches': _branchProvider?.activeBranchesCount ?? 0,
      'selectedBranch': _branchProvider?.selectedBranch?.branchName,
      'branchStats': _branchProvider?.branchStats?.toJson() ?? {},
      'cities': _branchProvider?.cities ?? [],
    };
  }

  /// Loads loan officer dashboard data
  Future<void> _loadLoanOfficerData() async {
    _logger.d('Loading loan officer dashboard data');

    // TODO: Implement when loan repository is available
    // This would fetch:
    // - Pending loan applications
    // - Approved loans awaiting disbursement
    // - Loan portfolio summary
    // - Approval queue

    _roleSpecificData = {
      'pendingApplications': 0,
      'approvedLoans': 0,
      'disbursementQueue': 0,
      'totalPortfolio': 0.0,
      'defaultRate': 0.0,
    };
  }

  /// Loads card officer dashboard data
  Future<void> _loadCardOfficerData() async {
    _logger.d('Loading card officer dashboard data');

    // TODO: Implement when card repository is available
    // This would fetch:
    // - Pending card applications
    // - Active cards
    // - Blocked cards
    // - Card issuance queue

    _roleSpecificData = {
      'pendingApplications': 0,
      'activeCards': 0,
      'blockedCards': 0,
      'issuanceQueue': 0,
    };
  }

  /// Loads admin dashboard data
  Future<void> _loadAdminData({String? customerId}) async {
    _logger.d('Loading admin dashboard data');

    // Load data from all providers
    // if (_accountProvider != null && !_accountProvider.hasAccounts) {
    //   await _accountProvider.fetchMyAccounts();
    // }
    if (_accountProvider != null &&
        !_accountProvider.hasAccounts &&
        customerId != null) {
      await _accountProvider.fetchMyAccounts(customerId);
    }
    if (_branchProvider != null && !_branchProvider.hasBranches) {
      await _branchProvider.fetchAllBranches();
    }

    // TODO: Fetch bank-wide statistics when available
    // await _branchProvider?.fetchBankStatistics();

    _roleSpecificData = {
      'totalBranches': _branchProvider?.branches.length ?? 0,
      'totalAccounts': _accountProvider?.accounts.length ?? 0,
      'activeBranches': _branchProvider?.activeBranchesCount ?? 0,
      'activeAccounts': _accountProvider?.activeAccountsCount ?? 0,
      'systemHealth': 'Operational',
    };
  }

  /// Builds dashboard summary from aggregated data
  Future<void> _buildDashboardSummary() async {
    _logger.d('Building dashboard summary');

    // Create accounts summary
    final accountsSummary = AccountsSummary(
      totalAccounts: _accountProvider?.accounts.length ?? 0,
      savingsAccounts:
          _accountProvider?.accounts
              .where((a) => a.accountType.value == 'SAVINGS')
              .length ??
          0,
      currentAccounts:
          _accountProvider?.accounts
              .where((a) => a.accountType.value == 'CURRENT')
              .length ??
          0,
      salaryAccounts:
          _accountProvider?.accounts
              .where((a) => a.accountType.value == 'SALARY')
              .length ??
          0,
      fdAccounts:
          _accountProvider?.accounts
              .where((a) => a.accountType.value == 'FD')
              .length ??
          0,
      savingsBalance: _accountProvider?.accounts
          .where((a) => a.accountType.value == 'SAVINGS')
          .fold<double>(0, (sum, a) => sum + a.currentBalance),
      currentBalance: _accountProvider?.accounts
          .where((a) => a.accountType.value == 'CURRENT')
          .fold<double>(0, (sum, a) => sum + a.currentBalance),
      fdBalance: _accountProvider?.accounts
          .where((a) => a.accountType.value == 'FD')
          .fold<double>(0, (sum, a) => sum + a.currentBalance),
    );

    // Create dashboard summary
    _dashboardSummary = DashboardSummaryDTO(
      accountsSummary: accountsSummary,
      recentTransactions: [], // Would come from transaction history
      alerts: _buildAlerts(),
      upcomingPayments: [], // Would come from loan/DPS data
      totalAvailableBalance: _accountProvider?.totalAvailableBalance,
      totalCurrentBalance: _accountProvider?.totalBalance,
      activeAccountsCount: _accountProvider?.activeAccountsCount,
      pendingApprovalsCount: _getPendingApprovalsCount(),
      generatedDate: DateTime.now(),
    );

    _logger.d('Dashboard summary built');
  }

  /// Builds alert items based on account status and activities
  List<AlertItem> _buildAlerts() {
    final List<AlertItem> alerts = [];

    // Check for inactive accounts
    final inactiveAccounts =
        _accountProvider?.accounts.where((a) => !a.status.canTransact).length ??
        0;

    if (inactiveAccounts > 0) {
      alerts.add(
        AlertItem(
          id: 'inactive_accounts',
          title: 'Inactive Accounts',
          message:
              'You have $inactiveAccounts inactive account(s). Please contact support.',
          type: 'WARNING',
          priority: 'MEDIUM',
          createdDate: DateTime.now(),
          actionRoute: '/accounts',
          actionLabel: 'View Accounts',
        ),
      );
    }

    // Add role-specific alerts
    if (_currentUserRole == UserRole.branchManager) {
      if (_branchProvider?.branchStats != null) {
        final stats = _branchProvider!.branchStats!;
        if (stats.pendingApprovals != null && stats.pendingApprovals! > 0) {
          alerts.add(
            AlertItem(
              id: 'pending_approvals',
              title: 'Pending Approvals',
              message:
                  'You have ${stats.pendingApprovals} pending approval(s).',
              type: 'INFO',
              priority: 'HIGH',
              createdDate: DateTime.now(),
              actionRoute: '/approvals',
              actionLabel: 'Review',
            ),
          );
        }
      }
    }

    return alerts;
  }

  /// Gets pending approvals count based on role
  int? _getPendingApprovalsCount() {
    switch (_currentUserRole) {
      case UserRole.branchManager:
        return _branchProvider?.branchStats?.pendingApprovals;
      case UserRole.loanOfficer:
      case UserRole.cardOfficer:
        return _roleSpecificData?['pendingApplications'] as int?;
      default:
        return null;
    }
  }

  /// Handler for account provider updates
  void _onAccountProviderUpdate() {
    if (_currentUserRole == UserRole.customer ||
        _currentUserRole == UserRole.admin) {
      _logger.d('Account provider updated, refreshing dashboard data');
      _buildDashboardSummary();
    }
  }

  /// Handler for branch provider updates
  void _onBranchProviderUpdate() {
    if (_currentUserRole == UserRole.branchManager ||
        _currentUserRole == UserRole.admin) {
      _logger.d('Branch provider updated, refreshing dashboard data');
      _buildDashboardSummary();
    }
  }

  /// Clears any error message
  void clearError() {
    if (_errorMessage != null) {
      _logger.d('Clearing error message');
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Sets loading state and notifies listeners
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Sets error message and notifies listeners
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clears error without notifying (used internally)
  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _logger.d('DashboardProvider disposed');
    _accountProvider?.removeListener(_onAccountProviderUpdate);
    _branchProvider?.removeListener(_onBranchProviderUpdate);
    super.dispose();
  }
}
