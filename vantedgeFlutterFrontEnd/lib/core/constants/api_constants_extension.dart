/// Extension to ApiConstants for account and branch related endpoints
///
/// This file extends the existing ApiConstants class with additional
/// endpoints for account management, branch operations, and dashboard features.
class ApiConstantsExtension {
  ApiConstantsExtension._();

  // ==================== ACCOUNT ENDPOINTS ====================

  /// Base path for account operations
  static const String accountsBase = '/accounts';

  /// Get all accounts for the authenticated user
  /// GET /api/accounts/my-accounts
  static const String myAccounts = '/api$accountsBase/my-accounts';

  /// Get accounts by customer ID
  /// GET /api/accounts/customer/{customerId}
  static const String _accountsByCustomerTemplate =
      '/api$accountsBase/customer/{customerId}';

  /// Get account by account number
  /// GET /api/accounts/account-number/{accountNumber}
  static const String _accountByNumberTemplate =
      '/api$accountsBase/account-number/{accountNumber}';

  /// Get account balance by account number
  /// GET /api/accounts/{accountNumber}/balance
  static const String _accountBalanceTemplate =
      '/api$accountsBase/{accountNumber}/balance';

  /// Generate account statement
  /// POST /api/accounts/statement
  static const String accountStatement = '/api$accountsBase/statement';

  /// Freeze account
  /// PUT /api/accounts/{accountNumber}/freeze
  static const String _freezeAccountTemplate =
      '/api$accountsBase/{accountNumber}/freeze';

  /// Unfreeze account
  /// PUT /api/accounts/{accountNumber}/unfreeze
  static const String _unfreezeAccountTemplate =
      '/api$accountsBase/{accountNumber}/unfreeze';

  /// Get accounts by status
  /// GET /api/accounts/status/{status}
  static const String _accountsByStatusTemplate =
      '/api$accountsBase/status/{status}';

  /// Get account by ID
  /// GET /api/accounts/{id}
  static const String _accountByIdTemplate = '/api$accountsBase/{id}';

  // ==================== BRANCH ENDPOINTS ====================

  /// Base path for branch operations
  static const String branchesBase = '/branches';

  /// Get all branches
  /// GET /api/branches
  static const String allBranches = '/api$branchesBase';

  /// Get branch by ID
  /// GET /api/branches/{id}
  static const String _branchByIdTemplate = '/api$branchesBase/{id}';

  /// Get branch statistics
  /// GET /api/branches/{id}/statistics
  static const String _branchStatisticsTemplate =
      '/api$branchesBase/{id}/statistics';

  /// Get branches by city
  /// GET /api/branches/city/{city}
  static const String _branchesByCityTemplate = '/api$branchesBase/city/{city}';

  /// Get branch by IFSC code
  /// GET /api/branches/ifsc/{ifscCode}
  static const String _branchByIfscTemplate =
      '/api$branchesBase/ifsc/{ifscCode}';

  /// Get branch by branch code
  /// GET /api/branches/code/{branchCode}
  static const String _branchByCodeTemplate =
      '/api$branchesBase/code/{branchCode}';

  /// Get branches by status
  /// GET /api/branches/status/{status}
  static const String _branchesByStatusTemplate =
      '/api$branchesBase/status/{status}';

  /// Get bank-wide statistics
  /// GET /api/branches/statistics/bank
  static const String bankStatistics = '/api$branchesBase/statistics/bank';

  // ==================== HELPER METHODS ====================

  /// Get URL for accounts by customer ID
  // static String getAccountsByCustomer(int customerId) {
  //   return _accountsByCustomerTemplate.replaceAll('{customerId}', customerId.toString());
  // }
  static String getAccountsByCustomer(String customerId) {
    return _accountsByCustomerTemplate.replaceAll('{customerId}', customerId);
  }

  /// Get URL for account by account number
  static String getAccountByNumber(String accountNumber) {
    return _accountByNumberTemplate.replaceAll(
      '{accountNumber}',
      accountNumber,
    );
  }

  /// Get URL for account balance
  static String getAccountBalance(String accountNumber) {
    return _accountBalanceTemplate.replaceAll('{accountNumber}', accountNumber);
  }

  /// Get URL for freeze account
  static String getFreezeAccount(String accountNumber) {
    return _freezeAccountTemplate.replaceAll('{accountNumber}', accountNumber);
  }

  /// Get URL for unfreeze account
  static String getUnfreezeAccount(String accountNumber) {
    return _unfreezeAccountTemplate.replaceAll(
      '{accountNumber}',
      accountNumber,
    );
  }

  /// Get URL for accounts by status
  static String getAccountsByStatus(String status) {
    return _accountsByStatusTemplate.replaceAll('{status}', status);
  }

  /// Get URL for account by ID
  static String getAccountById(int id) {
    return _accountByIdTemplate.replaceAll('{id}', id.toString());
  }

  /// Get URL for branch by ID
  static String getBranchById(int id) {
    return _branchByIdTemplate.replaceAll('{id}', id.toString());
  }

  /// Get URL for branch statistics
  static String getBranchStatistics(int branchId) {
    return _branchStatisticsTemplate.replaceAll('{id}', branchId.toString());
  }

  /// Get URL for branches by city
  static String getBranchesByCity(String city) {
    return _branchesByCityTemplate.replaceAll('{city}', city);
  }

  /// Get URL for branch by IFSC code
  static String getBranchByIfsc(String ifscCode) {
    return _branchByIfscTemplate.replaceAll('{ifscCode}', ifscCode);
  }

  /// Get URL for branch by branch code
  static String getBranchByCode(String branchCode) {
    return _branchByCodeTemplate.replaceAll('{branchCode}', branchCode);
  }

  /// Get URL for branches by status
  static String getBranchesByStatus(String status) {
    return _branchesByStatusTemplate.replaceAll('{status}', status);
  }
}

/// Extension methods on the existing ApiConstants class
/// Usage: import this file and use ApiConstants.getAccountByNumber(accountNumber)
extension ApiConstantsAccountExtension on Type {
  // Account endpoints
  String get myAccounts => ApiConstantsExtension.myAccounts;
  String accountsByCustomer(String customerId) =>
      ApiConstantsExtension.getAccountsByCustomer(customerId);
  String accountByNumber(String accountNumber) =>
      ApiConstantsExtension.getAccountByNumber(accountNumber);
  String accountBalance(String accountNumber) =>
      ApiConstantsExtension.getAccountBalance(accountNumber);
  String get accountStatement => ApiConstantsExtension.accountStatement;
  String freezeAccount(String accountNumber) =>
      ApiConstantsExtension.getFreezeAccount(accountNumber);
  String unfreezeAccount(String accountNumber) =>
      ApiConstantsExtension.getUnfreezeAccount(accountNumber);
  String accountsByStatus(String status) =>
      ApiConstantsExtension.getAccountsByStatus(status);
  String accountById(int id) => ApiConstantsExtension.getAccountById(id);

  // Branch endpoints
  String get allBranches => ApiConstantsExtension.allBranches;
  String branchById(int id) => ApiConstantsExtension.getBranchById(id);
  String branchStatistics(int branchId) =>
      ApiConstantsExtension.getBranchStatistics(branchId);
  String branchesByCity(String city) =>
      ApiConstantsExtension.getBranchesByCity(city);
  String branchByIfsc(String ifscCode) =>
      ApiConstantsExtension.getBranchByIfsc(ifscCode);
  String branchByCode(String branchCode) =>
      ApiConstantsExtension.getBranchByCode(branchCode);
  String branchesByStatus(String status) =>
      ApiConstantsExtension.getBranchesByStatus(status);
  String get bankStatistics => ApiConstantsExtension.bankStatistics;
}
