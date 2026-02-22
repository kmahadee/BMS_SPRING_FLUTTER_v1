class AppRoutes {
  AppRoutes._();

  // ── Auth ───────────────────────────────────────────────────────────────────
  // static const String splash = '/';
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // ── Home / Role-based dashboards ───────────────────────────────────────────
  static const String home = '/home';
  static const String customerHome = '/home/customer';
  static const String employeeHome = '/home/employee';
  static const String adminHome = '/home/admin';
  static const String superAdminHome = '/home/super-admin';
  static const String branchManagerHome = '/home/branch-manager';
  static const String loanOfficerHome = '/home/loan-officer';
  static const String cardOfficerHome = '/home/card-officer';

  // ── Accounts ───────────────────────────────────────────────────────────────
  static const String accounts = '/accounts';
  static const String accountDetails = '/accounts/details';
  static const String accountManagement = '/accounts/manage';

  // ── Transactions ───────────────────────────────────────────────────────────
  static const String transactions = '/transactions';
  static const String transactionDetails = '/transactions/details';
  static const String transactionHistory = '/transactions/history';
  static const String transactionManagement = '/transactions/manage';
  static const String transfer = '/transfer';
  static const String deposit = '/deposit';
  static const String withdrawal = '/withdrawal';

  // ── Cards ──────────────────────────────────────────────────────────────────
  static const String cards = '/cards';
  static const String cardDetails = '/cards/details';
  static const String cardApplications = '/cards/applications';
  static const String cardManagement = '/cards/manage';

  // ── Loans ──────────────────────────────────────────────────────────────────
  static const String loans = '/loans';
  static const String loanDetails = '/loans/details';
  static const String loanApplication = '/loans/apply';
  static const String loanApplications = '/loans/applications';
  static const String loanApproval = '/loans/approval';

  // ── DPS ────────────────────────────────────────────────────────────────────
  static const String dps = '/dps';
  static const String dpsDetails = '/dps/details';

  // ── Profile / Settings ─────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  // ── Customer / User management ─────────────────────────────────────────────
  static const String customerManagement = '/customers';
  static const String customerDetails = '/customers/details';
  static const String userManagement = '/admin/users';

  // ── Admin ──────────────────────────────────────────────────────────────────
  static const String branchManagement = '/admin/branches';
  static const String reports = '/admin/reports';
  static const String analytics = '/admin/analytics';
  static const String systemSettings = '/admin/settings';
  static const String auditLogs = '/admin/audit-logs';

  // ── Support / Legal ────────────────────────────────────────────────────────
  static const String help = '/help';
  static const String faq = '/faq';
  static const String contactSupport = '/contact-support';
  static const String termsAndConditions = '/terms';
  static const String privacyPolicy = '/privacy';

  // ── Errors ─────────────────────────────────────────────────────────────────
  static const String error404 = '/error/404';
  static const String errorGeneric = '/error';

  // ── Route classification helpers ───────────────────────────────────────────

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

  // ── Display names (for debug / breadcrumbs) ────────────────────────────────

  static String getDisplayName(String route) {
    const names = {
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
      loans: 'Loans',
      loanDetails: 'Loan Details',
      loanApplication: 'Loan Application',
      loanApplications: 'Loan Applications',
      loanApproval: 'Loan Approval',
      dps: 'DPS',
      dpsDetails: 'DPS Details',
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



/// Canonical single source of truth for all named routes in the app.
/// This file must NOT be re-declared anywhere else (especially not in
/// route_guard.dart, which previously contained an empty `class AppRoutes {}`
/// that caused the "name is defined in two libraries" compile error).
// class AppRoutes {
//   AppRoutes._();

//   // ── Auth ──────────────────────────────────────────────────────────────────
//   static const String splash = '/';
//   static const String onboarding = '/onboarding';
//   static const String login = '/login';
//   static const String signup = '/signup';
//   static const String forgotPassword = '/forgot-password';
//   static const String resetPassword = '/reset-password';

//   // ── Role-based home routes ────────────────────────────────────────────────
//   static const String home = '/home';
//   static const String customerHome = '/home/customer';
//   static const String employeeHome = '/home/employee';
//   static const String adminHome = '/home/admin';
//   static const String superAdminHome = '/home/super-admin'; // kept separate so
//                                                             // super-admin can
//                                                             // have its own shell
//   static const String branchManagerHome = '/home/branch-manager';
//   static const String loanOfficerHome = '/home/loan-officer';
//   static const String cardOfficerHome = '/home/card-officer';

//   // ── Accounts ──────────────────────────────────────────────────────────────
//   static const String accounts = '/accounts';
//   static const String accountDetails = '/accounts/details';
//   static const String accountManagement = '/accounts/manage';

//   // ── Transactions ──────────────────────────────────────────────────────────
//   static const String transactions = '/transactions';
//   static const String transactionDetails = '/transactions/details';
//   static const String transactionManagement = '/transactions/manage';
//   static const String transfer = '/transfer';
//   static const String deposit = '/deposit';
//   static const String withdrawal = '/withdrawal';

//   // ── Cards ─────────────────────────────────────────────────────────────────
//   static const String cards = '/cards';
//   static const String cardDetails = '/cards/details';
//   static const String cardApplications = '/cards/applications';
//   static const String cardManagement = '/cards/manage';

//   // ── Loans ─────────────────────────────────────────────────────────────────
//   static const String loans = '/loans';
//   static const String loanDetails = '/loans/details';
//   static const String loanApplication = '/loans/apply';
//   static const String loanApplications = '/loans/applications';
//   static const String loanApproval = '/loans/approval';

//   // ── DPS ───────────────────────────────────────────────────────────────────
//   static const String dps = '/dps';
//   static const String dpsDetails = '/dps/details';

//   // ── Profile & Settings ────────────────────────────────────────────────────
//   static const String profile = '/profile';
//   static const String editProfile = '/profile/edit';
//   static const String changePassword = '/profile/change-password';
//   static const String settings = '/settings';
//   static const String notifications = '/notifications';

//   // ── Customer / User management ────────────────────────────────────────────
//   static const String customerManagement = '/customers';
//   static const String customerDetails = '/customers/details';
//   static const String userManagement = '/admin/users';

//   // ── Branch / Admin ────────────────────────────────────────────────────────
//   static const String branchManagement = '/admin/branches';
//   static const String reports = '/admin/reports';
//   static const String analytics = '/admin/analytics';
//   static const String systemSettings = '/admin/settings';
//   static const String auditLogs = '/admin/audit-logs';

//   // ── Help / Legal ──────────────────────────────────────────────────────────
//   static const String help = '/help';
//   static const String faq = '/faq';
//   static const String contactSupport = '/contact-support';
//   static const String termsAndConditions = '/terms';
//   static const String privacyPolicy = '/privacy';

//   // ── Errors ────────────────────────────────────────────────────────────────
//   static const String error404 = '/error/404';
//   static const String errorGeneric = '/error';

//   // ── Helpers ───────────────────────────────────────────────────────────────

//   /// Routes that do not require authentication.
//   static bool isPublicRoute(String route) {
//     return _publicRoutes.contains(route);
//   }

//   static const Set<String> _publicRoutes = {
//     splash,
//     onboarding,
//     login,
//     signup,
//     forgotPassword,
//     resetPassword,
//     help,
//     faq,
//     termsAndConditions,
//     privacyPolicy,
//   };

//   /// Returns true when [route] is one of the role-based home screens.
//   static bool isHomeRoute(String route) {
//     return _homeRoutes.contains(route);
//   }

//   static const Set<String> _homeRoutes = {
//     home,
//     customerHome,
//     employeeHome,
//     adminHome,
//     superAdminHome,
//     branchManagerHome,
//     loanOfficerHome,
//     cardOfficerHome,
//   };

//   static String getDisplayName(String route) {
//     const names = {
//       splash: 'Splash',
//       onboarding: 'Onboarding',
//       login: 'Login',
//       signup: 'Sign Up',
//       forgotPassword: 'Forgot Password',
//       home: 'Home',
//       customerHome: 'Dashboard',
//       employeeHome: 'Dashboard',
//       adminHome: 'Dashboard',
//       superAdminHome: 'Dashboard',
//       branchManagerHome: 'Dashboard',
//       loanOfficerHome: 'Dashboard',
//       cardOfficerHome: 'Dashboard',
//       accounts: 'Accounts',
//       transactions: 'Transactions',
//       transfer: 'Transfer',
//       cards: 'Cards',
//       loans: 'Loans',
//       dps: 'DPS',
//       profile: 'Profile',
//       settings: 'Settings',
//       notifications: 'Notifications',
//       reports: 'Reports',
//       analytics: 'Analytics',
//       userManagement: 'User Management',
//       branchManagement: 'Branch Management',
//       systemSettings: 'System Settings',
//       auditLogs: 'Audit Logs',
//     };
//     return names[route] ?? 'Unknown';
//   }
// }

// /// App route constants
// /// Centralized location for all route paths in the application
// class AppRoutes {
//   AppRoutes._();

//   // Authentication Routes
//   static const String splash = '/';
//   static const String onboarding = '/onboarding';
//   static const String login = '/login';
//   static const String signup = '/signup';
//   static const String forgotPassword = '/forgot-password';
//   static const String resetPassword = '/reset-password';

//   // Main Home Routes
//   static const String home = '/home';

//   // Role-based Home Routes
//   static const String customerHome = '/home/customer';
//   static const String employeeHome = '/home/employee';
//   static const String adminHome = '/home/admin';
//   static const String branchManagerHome = '/home/branch-manager';
//   static const String loanOfficerHome = '/home/loan-officer';
//   static const String cardOfficerHome = '/home/card-officer';
//   static const String superAdminHome = '/home/super-admin';

//   // Customer Routes
//   static const String accounts = '/accounts';
//   static const String accountDetails = '/accounts/details';
//   static const String transactions = '/transactions';
//   static const String transactionDetails = '/transactions/details';
//   static const String transfer = '/transfer';
//   static const String deposit = '/deposit';
//   static const String withdrawal = '/withdrawal';
//   static const String cards = '/cards';
//   static const String cardDetails = '/cards/details';
//   static const String loans = '/loans';
//   static const String loanDetails = '/loans/details';
//   static const String loanApplication = '/loans/apply';
//   static const String dps = '/dps';
//   static const String dpsDetails = '/dps/details';

//   // Profile & Settings Routes
//   static const String profile = '/profile';
//   static const String settings = '/settings';
//   static const String editProfile = '/profile/edit';
//   static const String changePassword = '/profile/change-password';
//   static const String notifications = '/notifications';

//   // Employee Routes
//   static const String customerManagement = '/customers';
//   static const String customerDetails = '/customers/details';
//   static const String accountManagement = '/accounts/manage';
//   static const String transactionManagement = '/transactions/manage';

//   // Admin Routes
//   static const String userManagement = '/admin/users';
//   static const String branchManagement = '/admin/branches';
//   static const String reports = '/admin/reports';
//   static const String analytics = '/admin/analytics';
//   static const String systemSettings = '/admin/settings';

//   // Loan Officer Routes
//   static const String loanApplications = '/loans/applications';
//   static const String loanApproval = '/loans/approval';

//   // Card Officer Routes
//   static const String cardApplications = '/cards/applications';
//   static const String cardManagement = '/cards/manage';

//   // Support Routes
//   static const String help = '/help';
//   static const String faq = '/faq';
//   static const String contactSupport = '/contact-support';
//   static const String termsAndConditions = '/terms';
//   static const String privacyPolicy = '/privacy';

//   // Error Routes
//   static const String error404 = '/error/404';
//   static const String errorGeneric = '/error';

//   /// Check if a route is public (doesn't require authentication)
//   static bool isPublicRoute(String route) {
//     return [
//       splash,
//       onboarding,
//       login,
//       signup,
//       forgotPassword,
//       resetPassword,
//       help,
//       faq,
//       termsAndConditions,
//       privacyPolicy,
//     ].contains(route);
//   }

//   /// Check if a route is a home route
//   static bool isHomeRoute(String route) {
//     return [
//       home,
//       customerHome,
//       employeeHome,
//       adminHome,
//       branchManagerHome,
//       loanOfficerHome,
//       cardOfficerHome,
//       superAdminHome,
//     ].contains(route);
//   }

//   /// Get route display name
//   static String getDisplayName(String route) {
//     final names = {
//       splash: 'Splash',
//       onboarding: 'Onboarding',
//       login: 'Login',
//       signup: 'Sign Up',
//       forgotPassword: 'Forgot Password',
//       home: 'Home',
//       customerHome: 'Dashboard',
//       employeeHome: 'Dashboard',
//       adminHome: 'Dashboard',
//       accounts: 'Accounts',
//       transactions: 'Transactions',
//       transfer: 'Transfer',
//       cards: 'Cards',
//       loans: 'Loans',
//       profile: 'Profile',
//       settings: 'Settings',
//     };

//     return names[route] ?? 'Unknown';
//   }
// }