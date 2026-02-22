/// Application-wide constants for the banking application.
///
/// This file contains constants for user roles, validation rules,
/// error messages, success messages, and other app-wide configurations.
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ==================== User Roles ====================

  /// Super Admin role - highest level of access
  static const String roleSuperAdmin = 'SUPER_ADMIN';

  /// Admin role - administrative access
  static const String roleAdmin = 'ADMIN';

  /// Customer role - regular customer access
  static const String roleCustomer = 'CUSTOMER';

  /// Employee role - general employee access
  static const String roleEmployee = 'EMPLOYEE';

  /// Branch Manager role - manages a specific branch
  static const String roleBranchManager = 'BRANCH_MANAGER';

  /// Loan Officer role - handles loan operations
  static const String roleLoanOfficer = 'LOAN_OFFICER';

  /// Card Officer role - handles card operations
  static const String roleCardOfficer = 'CARD_OFFICER';

  /// List of all available user roles
  static const List<String> allRoles = [
    roleSuperAdmin,
    roleAdmin,
    roleCustomer,
    roleEmployee,
    roleBranchManager,
    roleLoanOfficer,
    roleCardOfficer,
  ];

  /// List of admin roles (Super Admin and Admin)
  static const List<String> adminRoles = [
    roleSuperAdmin,
    roleAdmin,
  ];

  /// List of staff roles (all roles except Customer)
  static const List<String> staffRoles = [
    roleSuperAdmin,
    roleAdmin,
    roleEmployee,
    roleBranchManager,
    roleLoanOfficer,
    roleCardOfficer,
  ];

  // ==================== User Status ====================

  /// User status: Pending approval
  static const String userStatusPending = 'PENDING';

  /// User status: Active and approved
  static const String userStatusActive = 'ACTIVE';

  /// User status: Inactive or suspended
  static const String userStatusInactive = 'INACTIVE';

  /// List of all user statuses
  static const List<String> allUserStatuses = [
    userStatusPending,
    userStatusActive,
    userStatusInactive,
  ];

  // ==================== Account Types ====================

  /// Savings account type
  static const String accountTypeSavings = 'SAVINGS';

  /// Current/Checking account type
  static const String accountTypeCurrent = 'CURRENT';

  /// Fixed deposit account type
  static const String accountTypeFixed = 'FIXED_DEPOSIT';

  /// List of all account types
  static const List<String> allAccountTypes = [
    accountTypeSavings,
    accountTypeCurrent,
    accountTypeFixed,
  ];

  // ==================== Account Status ====================

  /// Account status: Active
  static const String accountStatusActive = 'ACTIVE';

  /// Account status: Inactive
  static const String accountStatusInactive = 'INACTIVE';

  /// Account status: Closed
  static const String accountStatusClosed = 'CLOSED';

  /// Account status: Frozen
  static const String accountStatusFrozen = 'FROZEN';

  // ==================== Card Types ====================

  /// Debit card type
  static const String cardTypeDebit = 'DEBIT';

  /// Credit card type
  static const String cardTypeCredit = 'CREDIT';

  // ==================== Card Status ====================

  /// Card status: Active
  static const String cardStatusActive = 'ACTIVE';

  /// Card status: Blocked
  static const String cardStatusBlocked = 'BLOCKED';

  /// Card status: Expired
  static const String cardStatusExpired = 'EXPIRED';

  // ==================== Loan Types ====================

  /// Personal loan type
  static const String loanTypePersonal = 'PERSONAL';

  /// Home loan type
  static const String loanTypeHome = 'HOME';

  /// Car loan type
  static const String loanTypeCar = 'CAR';

  /// Education loan type
  static const String loanTypeEducation = 'EDUCATION';

  /// Business loan type
  static const String loanTypeBusiness = 'BUSINESS';

  // ==================== Loan Status ====================

  /// Loan status: Pending approval
  static const String loanStatusPending = 'PENDING';

  /// Loan status: Approved
  static const String loanStatusApproved = 'APPROVED';

  /// Loan status: Rejected
  static const String loanStatusRejected = 'REJECTED';

  /// Loan status: Disbursed
  static const String loanStatusDisbursed = 'DISBURSED';

  /// Loan status: Active
  static const String loanStatusActive = 'ACTIVE';

  /// Loan status: Closed
  static const String loanStatusClosed = 'CLOSED';

  // ==================== Transaction Types ====================

  /// Transaction type: Deposit
  static const String transactionTypeDeposit = 'DEPOSIT';

  /// Transaction type: Withdrawal
  static const String transactionTypeWithdrawal = 'WITHDRAWAL';

  /// Transaction type: Transfer
  static const String transactionTypeTransfer = 'TRANSFER';

  /// Transaction type: Loan repayment
  static const String transactionTypeLoanRepayment = 'LOAN_REPAYMENT';

  /// Transaction type: DPS installment
  static const String transactionTypeDpsInstallment = 'DPS_INSTALLMENT';

  // ==================== Validation Constants ====================

  /// Minimum password length
  static const int passwordMinLength = 6;

  /// Maximum password length
  static const int passwordMaxLength = 50;

  /// Minimum username length
  static const int usernameMinLength = 4;

  /// Maximum username length
  static const int usernameMaxLength = 50;

  /// Minimum name length
  static const int nameMinLength = 2;

  /// Maximum name length
  static const int nameMaxLength = 100;

  /// Minimum age for account opening (general)
  static const int minAge = 18;

  /// Minimum age for loan application
  static const int minAgeForLoan = 21;

  /// Maximum age for loan application
  static const int maxAgeForLoan = 65;

  /// Minimum deposit amount
  static const double minDepositAmount = 1.0;

  /// Minimum withdrawal amount
  static const double minWithdrawalAmount = 1.0;

  /// Minimum transfer amount
  static const double minTransferAmount = 1.0;

  /// Minimum loan amount
  static const double minLoanAmount = 1000.0;

  /// Maximum loan amount
  static const double maxLoanAmount = 10000000.0;

  // ==================== Regular Expressions ====================

  /// Phone number regex pattern
  /// Matches international phone numbers (E.164 format)
  /// Examples: +1234567890, +919876543210, 1234567890
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';

  /// Email regex pattern
  /// Basic email validation pattern
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  /// Zip/Postal code regex pattern
  /// Matches 3 to 10 digit postal codes
  static const String zipRegex = r'^\d{3,10}$';

  /// Username regex pattern
  /// Alphanumeric with underscores and dots, 4-50 characters
  static const String usernameRegex = r'^[a-zA-Z0-9._]{4,50}$';

  /// Account number regex pattern
  /// Typically 10-16 digits
  static const String accountNumberRegex = r'^\d{10,16}$';

  /// Card number regex pattern
  /// Typically 16 digits (can include spaces or hyphens)
  static const String cardNumberRegex = r'^\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}$';

  /// CVV regex pattern
  /// 3 or 4 digits
  static const String cvvRegex = r'^\d{3,4}$';

  // ==================== Compiled RegExp Objects ====================

  /// Compiled phone number regex
  static final RegExp phoneRegExp = RegExp(phoneRegex);

  /// Compiled email regex
  static final RegExp emailRegExp = RegExp(emailRegex);

  /// Compiled zip code regex
  static final RegExp zipRegExp = RegExp(zipRegex);

  /// Compiled username regex
  static final RegExp usernameRegExp = RegExp(usernameRegex);

  /// Compiled account number regex
  static final RegExp accountNumberRegExp = RegExp(accountNumberRegex);

  /// Compiled card number regex
  static final RegExp cardNumberRegExp = RegExp(cardNumberRegex);

  /// Compiled CVV regex
  static final RegExp cvvRegExp = RegExp(cvvRegex);

  // ==================== Error Messages ====================

  /// Generic error message
  static const String errorGeneric = 'An error occurred. Please try again.';

  /// Network error message
  static const String errorNetwork =
      'Network error. Please check your internet connection.';

  /// Server error message
  static const String errorServer = 'Server error. Please try again later.';

  /// Unauthorized error message
  static const String errorUnauthorized =
      'Unauthorized access. Please login again.';

  /// Forbidden error message
  static const String errorForbidden =
      'You do not have permission to perform this action.';

  /// Not found error message
  static const String errorNotFound = 'Resource not found.';

  /// Timeout error message
  static const String errorTimeout = 'Request timeout. Please try again.';

  /// Invalid credentials error message
  static const String errorInvalidCredentials =
      'Invalid username or password.';

  /// Session expired error message
  static const String errorSessionExpired = 'Session expired. Please login again.';

  /// Insufficient balance error message
  static const String errorInsufficientBalance = 'Insufficient account balance.';

  /// Invalid amount error message
  static const String errorInvalidAmount = 'Invalid amount entered.';

  /// Account not found error message
  static const String errorAccountNotFound = 'Account not found.';

  /// User not found error message
  static const String errorUserNotFound = 'User not found.';

  /// Invalid phone number error message
  static const String errorInvalidPhone = 'Invalid phone number format.';

  /// Invalid email error message
  static const String errorInvalidEmail = 'Invalid email address format.';

  /// Invalid zip code error message
  static const String errorInvalidZip = 'Invalid zip/postal code format.';

  /// Password too short error message
  static const String errorPasswordTooShort =
      'Password must be at least $passwordMinLength characters.';

  /// Username too short error message
  static const String errorUsernameTooShort =
      'Username must be at least $usernameMinLength characters.';

  /// Username too long error message
  static const String errorUsernameTooLong =
      'Username must not exceed $usernameMaxLength characters.';

  /// Required field error message
  static const String errorRequiredField = 'This field is required.';

  /// Age restriction error message
  static const String errorAgeRestriction =
      'You must be at least $minAge years old.';

  /// Loan age restriction error message
  static const String errorLoanAgeRestriction =
      'You must be between $minAgeForLoan and $maxAgeForLoan years old to apply for a loan.';

  // ==================== Success Messages ====================

  /// Generic success message
  static const String successGeneric = 'Operation completed successfully.';

  /// Login success message
  static const String successLogin = 'Login successful. Welcome back!';

  /// Registration success message
  static const String successRegistration =
      'Registration successful. Please wait for approval.';

  /// Logout success message
  static const String successLogout = 'Logged out successfully.';

  /// Profile update success message
  static const String successProfileUpdate = 'Profile updated successfully.';

  /// Password change success message
  static const String successPasswordChange = 'Password changed successfully.';

  /// Account created success message
  static const String successAccountCreated = 'Account created successfully.';

  /// Transaction success message
  static const String successTransaction = 'Transaction completed successfully.';

  /// Deposit success message
  static const String successDeposit = 'Deposit completed successfully.';

  /// Withdrawal success message
  static const String successWithdrawal = 'Withdrawal completed successfully.';

  /// Transfer success message
  static const String successTransfer = 'Transfer completed successfully.';

  /// Loan application success message
  static const String successLoanApplication =
      'Loan application submitted successfully.';

  /// Loan approval success message
  static const String successLoanApproval = 'Loan approved successfully.';

  /// Loan repayment success message
  static const String successLoanRepayment = 'Loan repayment completed successfully.';

  /// Card created success message
  static const String successCardCreated = 'Card created successfully.';

  /// Card blocked success message
  static const String successCardBlocked = 'Card blocked successfully.';

  /// Card unblocked success message
  static const String successCardUnblocked = 'Card unblocked successfully.';

  // ==================== Informational Messages ====================

  /// Loading message
  static const String infoLoading = 'Loading...';

  /// Processing message
  static const String infoProcessing = 'Processing...';

  /// Please wait message
  static const String infoPleaseWait = 'Please wait...';

  /// No data found message
  static const String infoNoData = 'No data found.';

  /// No transactions message
  static const String infoNoTransactions = 'No transactions found.';

  /// No accounts message
  static const String infoNoAccounts = 'No accounts found.';

  /// No loans message
  static const String infoNoLoans = 'No loans found.';

  /// No cards message
  static const String infoNoCards = 'No cards found.';

  /// Pending approval message
  static const String infoPendingApproval =
      'Your account is pending approval. Please wait for an administrator to approve your account.';

  // ==================== Confirmation Messages ====================

  /// Logout confirmation
  static const String confirmLogout = 'Are you sure you want to logout?';

  /// Delete confirmation
  static const String confirmDelete = 'Are you sure you want to delete this item?';

  /// Cancel confirmation
  static const String confirmCancel = 'Are you sure you want to cancel?';

  /// Block card confirmation
  static const String confirmBlockCard = 'Are you sure you want to block this card?';

  /// Close account confirmation
  static const String confirmCloseAccount =
      'Are you sure you want to close this account? This action cannot be undone.';

  // ==================== Date & Time Formats ====================

  /// Date format: yyyy-MM-dd
  static const String dateFormat = 'yyyy-MM-dd';

  /// Date time format: yyyy-MM-dd HH:mm:ss
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  /// Display date format: MMM dd, yyyy (e.g., Jan 01, 2024)
  static const String displayDateFormat = 'MMM dd, yyyy';

  /// Display date time format: MMM dd, yyyy hh:mm a (e.g., Jan 01, 2024 02:30 PM)
  static const String displayDateTimeFormat = 'MMM dd, yyyy hh:mm a';

  // ==================== Pagination ====================

  /// Default page size for paginated lists
  static const int defaultPageSize = 20;

  /// Maximum page size for paginated lists
  static const int maxPageSize = 100;

  // ==================== Currency ====================

  /// Default currency symbol
  static const String currencySymbol = '৳';
  // static const String currencySymbol = '\$';

  /// Default currency code
  static const String currencyCode = 'TK';
  // static const String currencyCode = 'USD';

  /// Number of decimal places for currency
  static const int currencyDecimalPlaces = 2;

  // ==================== Helper Methods ====================

  /// Checks if a role is an admin role
  static bool isAdminRole(String role) => adminRoles.contains(role);

  /// Checks if a role is a staff role
  static bool isStaffRole(String role) => staffRoles.contains(role);

  /// Checks if a role is a customer role
  static bool isCustomerRole(String role) => role == roleCustomer;

  /// Validates phone number format
  static bool isValidPhone(String phone) => phoneRegExp.hasMatch(phone);

  /// Validates email format
  static bool isValidEmail(String email) => emailRegExp.hasMatch(email);

  /// Validates zip code format
  static bool isValidZip(String zip) => zipRegExp.hasMatch(zip);

  /// Validates username format
  static bool isValidUsername(String username) => usernameRegExp.hasMatch(username);

  /// Validates password length
  static bool isValidPassword(String password) =>
      password.length >= passwordMinLength && password.length <= passwordMaxLength;

  /// Validates age for general account opening
  static bool isValidAge(int age) => age >= minAge;

  /// Validates age for loan application
  static bool isValidAgeForLoan(int age) =>
      age >= minAgeForLoan && age <= maxAgeForLoan;

  /// Formats currency amount
  static String formatCurrency(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(currencyDecimalPlaces)}';
  }

  /// Gets display name for user role
  static String getRoleDisplayName(String role) {
    switch (role) {
      case roleSuperAdmin:
        return 'Super Admin';
      case roleAdmin:
        return 'Admin';
      case roleCustomer:
        return 'Customer';
      case roleEmployee:
        return 'Employee';
      case roleBranchManager:
        return 'Branch Manager';
      case roleLoanOfficer:
        return 'Loan Officer';
      case roleCardOfficer:
        return 'Card Officer';
      default:
        return role;
    }
  }

  /// Gets display name for user status
  static String getUserStatusDisplayName(String status) {
    switch (status) {
      case userStatusPending:
        return 'Pending';
      case userStatusActive:
        return 'Active';
      case userStatusInactive:
        return 'Inactive';
      default:
        return status;
    }
  }
}
