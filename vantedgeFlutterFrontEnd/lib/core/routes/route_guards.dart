// import 'package:vantedge/features/auth/domain/entities/user_role.dart';
// import 'app_routes.dart';

// /// Route guards for authentication and authorization
// /// Provides security checks and role-based routing logic
// class RouteGuards {
//   RouteGuards._();

//   /// Check if user is authenticated
//   /// Returns true if user has a valid session
//   static bool isAuthenticated() {
//     // TODO: Implement actual authentication check
//     // This should check if user has valid token in secure storage
//     // For now, returning false as default
//     // 
//     // Example implementation:
//     // final storage = FlutterSecureStorage();
//     // final token = await storage.read(key: 'auth_token');
//     // return token != null && token.isNotEmpty;
    
//     return false;
//   }

//   /// Get home route based on user role
//   /// Returns appropriate dashboard route for each role
//   static String getHomeRoute(UserRole role) {
//     switch (role) {
//       case UserRole.customer:
//         return AppRoutes.customerHome;
//       case UserRole.employee:
//         return AppRoutes.employeeHome;
//       case UserRole.admin:
//         return AppRoutes.adminHome;
//       case UserRole.branchManager:
//         return AppRoutes.branchManagerHome;
//       case UserRole.loanOfficer:
//         return AppRoutes.loanOfficerHome;
//       case UserRole.cardOfficer:
//         return AppRoutes.cardOfficerHome;
//       case UserRole.superAdmin:
//         return AppRoutes.superAdminHome;
//       default:
//         return AppRoutes.home;
//     }
//   }

//   /// Check if user has permission to access a route
//   /// Returns true if user's role allows access to the route
//   static bool hasPermission(UserRole userRole, String route) {
//     // Public routes accessible to everyone
//     if (AppRoutes.isPublicRoute(route)) {
//       return true;
//     }

//     // Customer routes
//     final customerRoutes = [
//       AppRoutes.customerHome,
//       AppRoutes.accounts,
//       AppRoutes.accountDetails,
//       AppRoutes.transactions,
//       AppRoutes.transactionDetails,
//       AppRoutes.transfer,
//       AppRoutes.deposit,
//       AppRoutes.withdrawal,
//       AppRoutes.cards,
//       AppRoutes.cardDetails,
//       AppRoutes.loans,
//       AppRoutes.loanDetails,
//       AppRoutes.loanApplication,
//       AppRoutes.dps,
//       AppRoutes.dpsDetails,
//       AppRoutes.profile,
//       AppRoutes.settings,
//       AppRoutes.editProfile,
//       AppRoutes.changePassword,
//       AppRoutes.notifications,
//     ];

//     // Employee routes
//     final employeeRoutes = [
//       AppRoutes.employeeHome,
//       AppRoutes.customerManagement,
//       AppRoutes.customerDetails,
//       AppRoutes.accountManagement,
//       AppRoutes.transactionManagement,
//       AppRoutes.profile,
//       AppRoutes.settings,
//       AppRoutes.notifications,
//     ];

//     // Admin routes
//     final adminRoutes = [
//       AppRoutes.adminHome,
//       AppRoutes.userManagement,
//       AppRoutes.branchManagement,
//       AppRoutes.reports,
//       AppRoutes.analytics,
//       AppRoutes.systemSettings,
//       AppRoutes.customerManagement,
//       AppRoutes.accountManagement,
//       AppRoutes.transactionManagement,
//       AppRoutes.profile,
//       AppRoutes.settings,
//       AppRoutes.notifications,
//     ];

//     // Branch Manager routes (Admin + Employee routes)
//     final branchManagerRoutes = [
//       AppRoutes.branchManagerHome,
//       ...employeeRoutes,
//       ...adminRoutes,
//     ];

//     // Loan Officer routes
//     final loanOfficerRoutes = [
//       AppRoutes.loanOfficerHome,
//       AppRoutes.loanApplications,
//       AppRoutes.loanApproval,
//       AppRoutes.loans,
//       AppRoutes.loanDetails,
//       AppRoutes.customerDetails,
//       AppRoutes.profile,
//       AppRoutes.settings,
//       AppRoutes.notifications,
//     ];

//     // Card Officer routes
//     final cardOfficerRoutes = [
//       AppRoutes.cardOfficerHome,
//       AppRoutes.cardApplications,
//       AppRoutes.cardManagement,
//       AppRoutes.cards,
//       AppRoutes.cardDetails,
//       AppRoutes.customerDetails,
//       AppRoutes.profile,
//       AppRoutes.settings,
//       AppRoutes.notifications,
//     ];

//     // Super Admin routes (All routes)
//     final superAdminRoutes = [
//       AppRoutes.superAdminHome,
//       ...customerRoutes,
//       ...employeeRoutes,
//       ...adminRoutes,
//       ...loanOfficerRoutes,
//       ...cardOfficerRoutes,
//     ];

//     // Check permissions based on role
//     switch (userRole) {
//       case UserRole.customer:
//         return customerRoutes.contains(route);
//       case UserRole.employee:
//         return employeeRoutes.contains(route);
//       case UserRole.admin:
//         return adminRoutes.contains(route);
//       case UserRole.branchManager:
//         return branchManagerRoutes.contains(route);
//       case UserRole.loanOfficer:
//         return loanOfficerRoutes.contains(route);
//       case UserRole.cardOfficer:
//         return cardOfficerRoutes.contains(route);
//       case UserRole.superAdmin:
//         return superAdminRoutes.contains(route);
//       default:
//         return false;
//     }
//   }

//   /// Get redirect route if user doesn't have permission
//   /// Returns appropriate route based on user's role
//   static String getRedirectRoute(UserRole? userRole) {
//     if (userRole == null) {
//       return AppRoutes.login;
//     }

//     return getHomeRoute(userRole);
//   }

//   /// Check if route requires authentication
//   /// Returns true if route is protected
//   static bool requiresAuth(String route) {
//     return !AppRoutes.isPublicRoute(route);
//   }

//   /// Validate route navigation
//   /// Returns error message if navigation is not allowed, null otherwise
//   static String? validateNavigation({
//     required String route,
//     required bool isAuthenticated,
//     UserRole? userRole,
//   }) {
//     // Check if route requires authentication
//     if (requiresAuth(route) && !isAuthenticated) {
//       return 'Authentication required';
//     }

//     // Check if user has permission for protected routes
//     if (isAuthenticated && userRole != null) {
//       if (!hasPermission(userRole, route)) {
//         return 'Access denied: Insufficient permissions';
//       }
//     }

//     return null;
//   }

//   /// Get initial route based on authentication status
//   /// Returns appropriate starting route
//   static String getInitialRoute({
//     required bool isAuthenticated,
//     required bool hasCompletedOnboarding,
//     UserRole? userRole,
//   }) {
//     if (!hasCompletedOnboarding) {
//       return AppRoutes.onboarding;
//     }

//     if (!isAuthenticated) {
//       return AppRoutes.login;
//     }

//     if (userRole != null) {
//       return getHomeRoute(userRole);
//     }

//     return AppRoutes.home;
//   }
// }