class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://192.168.0.115:8080';

  static const String apiPrefix = '/api';

  static const String apiBaseUrl = '$baseUrl$apiPrefix';

  static const int timeoutSeconds = 30;

  static const Duration timeout = Duration(seconds: timeoutSeconds);

  static const Duration connectTimeout = Duration(seconds: timeoutSeconds);

  static const Duration receiveTimeout = Duration(seconds: timeoutSeconds);

  static const String authorizationHeader = 'Authorization';

  static const String bearerPrefix = 'Bearer';

  static const String contentTypeHeader = 'Content-Type';

  static const String jsonContentType = 'application/json';

  static const String acceptHeader = 'Accept';

  static const String authBase = '/auth';

  static const String login = '$apiPrefix$authBase/login';

  static const String register = '$apiPrefix$authBase/register';

  static const String refreshToken = '$apiPrefix$authBase/refresh';

  static const String logout = '$apiPrefix$authBase/logout';

  static const String customersBase = '/customers';

  static const String createCustomer = '$apiPrefix$customersBase';

  static const String validateToken = '$apiPrefix$authBase/validate';

  static const String usersBase = '/users';

  static const String getAllUsers = '$apiPrefix$usersBase';

  static const String _getUserByIdTemplate = '$apiPrefix$usersBase/{id}';

  static const String _updateUserTemplate = '$apiPrefix$usersBase/{id}';

  static const String _deleteUserTemplate = '$apiPrefix$usersBase/{id}';

  static const String approveUser = '$apiPrefix$usersBase/approve';

  static const String accountsBase = '/accounts';

  static const String getAllAccounts = '$apiPrefix$accountsBase';

  static const String createAccount = '$apiPrefix$accountsBase';

  static const String _getAccountByIdTemplate = '$apiPrefix$accountsBase/{id}';

  static const String _updateAccountTemplate = '$apiPrefix$accountsBase/{id}';

  static const String _deleteAccountTemplate = '$apiPrefix$accountsBase/{id}';

  static const String _getAccountStatementTemplate =
      '$apiPrefix$accountsBase/{id}/statement';

  static const String transactionsBase = '/transactions';

  static const String getAllTransactions = '$apiPrefix$transactionsBase';

  static const String deposit = '$apiPrefix$transactionsBase/deposit';

  static const String withdraw = '$apiPrefix$transactionsBase/withdraw';

  static const String transfer = '$apiPrefix$transactionsBase/transfer';

  static const String _getTransactionHistoryTemplate =
      '$apiPrefix$transactionsBase/history/{accountId}';

  static const String cardsBase = '/cards';

  static const String getAllCards = '$apiPrefix$cardsBase';

  static const String createCard = '$apiPrefix$cardsBase';

  static const String _getCardByIdTemplate = '$apiPrefix$cardsBase/{id}';

  static const String _updateCardLimitTemplate =
      '$apiPrefix$cardsBase/{id}/limit';

  static const String _blockCardTemplate = '$apiPrefix$cardsBase/{id}/block';

  static const String _unblockCardTemplate =
      '$apiPrefix$cardsBase/{id}/unblock';

  static const String loansBase = '/loans';

  static const String getAllLoans = '$apiPrefix$loansBase';

  static const String applyForLoan = '$apiPrefix$loansBase/apply';

  static const String _getLoanByIdTemplate = '$apiPrefix$loansBase/{id}';

  static const String _approveLoanTemplate =
      '$apiPrefix$loansBase/{id}/approve';

  static const String _rejectLoanTemplate = '$apiPrefix$loansBase/{id}/reject';

  static const String _disburseLoanTemplate =
      '$apiPrefix$loansBase/{id}/disburse';

  static const String repayLoan = '$apiPrefix$loansBase/repay';

  static const String _getLoanStatementTemplate =
      '$apiPrefix$loansBase/{id}/statement';

  static const String _getRepaymentScheduleTemplate =
      '$apiPrefix$loansBase/{id}/repayment-schedule';

  static const String dpsBase = '/dps';

  static const String getAllDps = '$apiPrefix$dpsBase';

  static const String createDps = '$apiPrefix$dpsBase';

  static const String _getDpsByIdTemplate = '$apiPrefix$dpsBase/{id}';

  static const String _payDpsInstallmentTemplate =
      '$apiPrefix$dpsBase/{id}/installment';

  static const String _matureDpsTemplate = '$apiPrefix$dpsBase/{id}/mature';

  static const String _calculateDpsMaturityTemplate =
      '$apiPrefix$dpsBase/{id}/calculate-maturity';

  static const String branchesBase = '/branches';

  static const String getAllBranches = '$apiPrefix$branchesBase';

  static const String createBranch = '$apiPrefix$branchesBase';

  static const String _getBranchByIdTemplate = '$apiPrefix$branchesBase/{id}';

  static const String _updateBranchTemplate = '$apiPrefix$branchesBase/{id}';

  static const String _deleteBranchTemplate = '$apiPrefix$branchesBase/{id}';

  static const String _getBranchStatisticsTemplate =
      '$apiPrefix$branchesBase/{id}/statistics';

  // static const String customersBase = '/customers';

  static const String getAllCustomers = '$apiPrefix$customersBase';

  static const String _getCustomerByIdTemplate =
      '$apiPrefix$customersBase/{id}';

  static const String _updateCustomerTemplate = '$apiPrefix$customersBase/{id}';

  static const String changePassword =
      '$apiPrefix$customersBase/change-password';

  static String getCustomerById(int id) => '$apiPrefix$customersBase/$id';

  static String getCustomerByCustomerId(String customerId) =>
      '$apiPrefix$customersBase/customer-id/$customerId';

  static String getCustomersByStatus(String status) =>
      '$apiPrefix$customersBase/status/$status';

  static String getCustomersByKycStatus(String kycStatus) =>
      '$apiPrefix$customersBase/kyc-status/$kycStatus';

  static const String searchCustomers = '$apiPrefix$customersBase/search';

  static String updateCustomer(int id) => '$apiPrefix$customersBase/$id';

  static String updateKycStatus(String customerId) =>
      '$apiPrefix$customersBase/$customerId/kyc-status';

  static String deleteCustomer(int id) => '$apiPrefix$customersBase/$id';

  static String hardDeleteCustomer(int id) =>
      '$apiPrefix$customersBase/$id/permanent';

  static String getUserById(int id) =>
      _getUserByIdTemplate.replaceAll('{id}', id.toString());

  static String updateUser(int id) =>
      _updateUserTemplate.replaceAll('{id}', id.toString());

  static String deleteUser(int id) =>
      _deleteUserTemplate.replaceAll('{id}', id.toString());

  static String getAccountById(int id) =>
      _getAccountByIdTemplate.replaceAll('{id}', id.toString());

  static String updateAccount(int id) =>
      _updateAccountTemplate.replaceAll('{id}', id.toString());

  static String deleteAccount(int id) =>
      _deleteAccountTemplate.replaceAll('{id}', id.toString());

  static String getAccountStatement(int id) =>
      _getAccountStatementTemplate.replaceAll('{id}', id.toString());

  static String getTransactionHistory(int accountId) =>
      _getTransactionHistoryTemplate.replaceAll(
        '{accountId}',
        accountId.toString(),
      );

  static String getCardById(int id) =>
      _getCardByIdTemplate.replaceAll('{id}', id.toString());

  static String updateCardLimit(int id) =>
      _updateCardLimitTemplate.replaceAll('{id}', id.toString());

  static String blockCard(int id) =>
      _blockCardTemplate.replaceAll('{id}', id.toString());

  static String unblockCard(int id) =>
      _unblockCardTemplate.replaceAll('{id}', id.toString());

  static String getLoanById(int id) =>
      _getLoanByIdTemplate.replaceAll('{id}', id.toString());

  static String approveLoan(int id) =>
      _approveLoanTemplate.replaceAll('{id}', id.toString());

  static String rejectLoan(int id) =>
      _rejectLoanTemplate.replaceAll('{id}', id.toString());

  static String disburseLoan(int id) =>
      _disburseLoanTemplate.replaceAll('{id}', id.toString());

  static String getLoanStatement(int id) =>
      _getLoanStatementTemplate.replaceAll('{id}', id.toString());

  static String getRepaymentSchedule(int id) =>
      _getRepaymentScheduleTemplate.replaceAll('{id}', id.toString());

  static String getDpsById(int id) =>
      _getDpsByIdTemplate.replaceAll('{id}', id.toString());

  static String payDpsInstallment(int id) =>
      _payDpsInstallmentTemplate.replaceAll('{id}', id.toString());

  static String matureDps(int id) =>
      _matureDpsTemplate.replaceAll('{id}', id.toString());

  static String calculateDpsMaturity(int id) =>
      _calculateDpsMaturityTemplate.replaceAll('{id}', id.toString());

  static String getBranchById(int id) =>
      _getBranchByIdTemplate.replaceAll('{id}', id.toString());

  static String updateBranch(int id) =>
      _updateBranchTemplate.replaceAll('{id}', id.toString());

  static String deleteBranch(int id) =>
      _deleteBranchTemplate.replaceAll('{id}', id.toString());

  static String getBranchStatistics(int id) =>
      _getBranchStatisticsTemplate.replaceAll('{id}', id.toString());

  static String getFullUrl(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }
    return '$baseUrl$endpoint';
  }

  static String getBearerToken(String token) => '$bearerPrefix $token';

  static Map<String, String> getDefaultHeaders({String? token}) {
    final headers = <String, String>{
      contentTypeHeader: jsonContentType,
      acceptHeader: jsonContentType,
    };

    if (token != null && token.isNotEmpty) {
      headers[authorizationHeader] = getBearerToken(token);
    }

    return headers;
  }
}
