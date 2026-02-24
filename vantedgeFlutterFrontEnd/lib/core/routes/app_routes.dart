// lib/core/routes/app_routes.dart

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  static const String home = '/home';
  static const String customerHome = '/home/customer';
  static const String employeeHome = '/home/employee';
  static const String adminHome = '/home/admin';
  static const String superAdminHome = '/home/super-admin';
  static const String branchManagerHome = '/home/branch-manager';
  static const String loanOfficerHome = '/home/loan-officer';
  static const String cardOfficerHome = '/home/card-officer';

  static const String accounts = '/accounts';
  static const String accountDetails = '/accounts/details';
  static const String accountManagement = '/accounts/manage';

  static const String transactions = '/transactions';
  static const String transactionDetails = '/transactions/details';
  static const String transactionHistory = '/transactions/history';
  static const String transactionManagement = '/transactions/manage';
  static const String transfer = '/transfer';
  static const String deposit = '/deposit';
  static const String withdrawal = '/withdrawal';

  static const String cards = '/cards';
  static const String cardDetails = '/cards/details';
  static const String cardApplications = '/cards/applications';
  static const String cardManagement = '/cards/manage';

  // ── Customer-facing loan routes ──────────────────────────────────────────
  /// List of the current user's loans.
  static const String loans = '/loans';

  /// Loan application form.
  static const String loanApplication = '/loans/apply';

  /// Loan applications list (officer / manager).
  static const String loanApplications = '/loans/applications';

  /// Loan detail view (arg: loanId String).
  static const String loanDetails = '/loans/details';

  /// Repayment schedule (arg: loanId String).
  static const String loanRepaymentSchedule = '/loans/schedule';

  /// Make a payment (arg: loanId String).
  static const String loanPayment = '/loans/pay';

  /// Legacy approval queue alias kept for existing drawer items.
  static const String loanApproval = '/loans/approval';

  // ── Officer-only routes (role-guarded) ──────────────────────────────────
  /// Pending-approval queue for loan officers.
  static const String officerLoanQueue = '/officer/loans';

  /// Full review + approve/reject form (arg: loanId String).
  static const String officerLoanApprove = '/officer/loans/approve';

  /// Disburse an approved loan (arg: loanId String).
  static const String officerLoanDisburse = '/officer/loans/disburse';

  /// Advanced search across all loans.
  static const String officerLoanSearch = '/officer/loans/search';
  // ─────────────────────────────────────────────────────────────────────────

  static const String dps = '/dps';
  static const String dpsDetails = '/dps/details';
  static const String dpsCreate = '/dps/create';
  static const String dpsInstallments = '/dps/installments';
  static const String dpsPay = '/dps/pay';
  static const String dpsCalculator = '/dps/calculator';

  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  static const String customerManagement = '/customers';
  static const String customerDetails = '/customers/details';
  static const String userManagement = '/admin/users';

  static const String branchManagement = '/admin/branches';
  static const String reports = '/admin/reports';
  static const String analytics = '/admin/analytics';
  static const String systemSettings = '/admin/settings';
  static const String auditLogs = '/admin/audit-logs';

  static const String help = '/help';
  static const String faq = '/faq';
  static const String contactSupport = '/contact-support';
  static const String termsAndConditions = '/terms';
  static const String privacyPolicy = '/privacy';

  static const String error404 = '/error/404';
  static const String errorGeneric = '/error';

  static bool isPublicRoute(String route) => _publicRoutes.contains(route);

  static const Set<String> _publicRoutes = {
    splash,
    onboarding,
    login,
    signup,
    forgotPassword,
    resetPassword,
    help,
    faq,
    termsAndConditions,
    privacyPolicy,
  };

  static bool isHomeRoute(String route) => _homeRoutes.contains(route);

  static const Set<String> _homeRoutes = {
    home,
    customerHome,
    employeeHome,
    adminHome,
    superAdminHome,
    branchManagerHome,
    loanOfficerHome,
    cardOfficerHome,
  };

  static String getDisplayName(String route) {
    const names = <String, String>{
      splash: 'Splash',
      onboarding: 'Onboarding',
      login: 'Login',
      signup: 'Sign Up',
      forgotPassword: 'Forgot Password',
      home: 'Home',
      customerHome: 'Dashboard',
      employeeHome: 'Dashboard',
      adminHome: 'Dashboard',
      superAdminHome: 'Dashboard',
      branchManagerHome: 'Dashboard',
      loanOfficerHome: 'Dashboard',
      cardOfficerHome: 'Dashboard',
      accounts: 'Accounts',
      accountDetails: 'Account Details',
      accountManagement: 'Account Management',
      transactions: 'Transactions',
      transactionDetails: 'Transaction Details',
      transactionHistory: 'Transaction History',
      transactionManagement: 'Transaction Management',
      transfer: 'Transfer',
      deposit: 'Deposit',
      withdrawal: 'Withdraw',
      cards: 'Cards',
      cardDetails: 'Card Details',
      cardApplications: 'Card Applications',
      cardManagement: 'Card Management',
      loans: 'My Loans',
      loanDetails: 'Loan Details',
      loanApplication: 'Loan Application',
      loanApplications: 'Loan Applications',
      loanApproval: 'Loan Approval',
      loanRepaymentSchedule: 'Repayment Schedule',
      loanPayment: 'Make Payment',
      officerLoanQueue: 'Approval Queue',
      officerLoanApprove: 'Review Loan',
      officerLoanDisburse: 'Disburse Loan',
      officerLoanSearch: 'Search Loans',

      dps: 'DPS',
      dpsDetails: 'DPS Details',
      dpsCreate: 'Open DPS',
      dpsInstallments: 'Installment History',
      dpsPay: 'Pay Installment',
      dpsCalculator: 'DPS Calculator',

      profile: 'Profile',
      editProfile: 'Edit Profile',
      changePassword: 'Change Password',
      settings: 'Settings',
      notifications: 'Notifications',
      customerManagement: 'Customer Management',
      customerDetails: 'Customer Details',
      userManagement: 'User Management',
      branchManagement: 'Branch Management',
      reports: 'Reports',
      analytics: 'Analytics',
      systemSettings: 'System Settings',
      auditLogs: 'Audit Logs',
      help: 'Help',
      faq: 'FAQ',
      contactSupport: 'Contact Support',
      termsAndConditions: 'Terms & Conditions',
      privacyPolicy: 'Privacy Policy',
    };
    return names[route] ?? 'Unknown';
  }
}
