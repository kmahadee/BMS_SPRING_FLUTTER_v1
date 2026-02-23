// lib/core/navigation/route_guard.dart

import 'package:flutter/material.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/auth/domain/entities/user_role.dart';

class RouteGuard {
  RouteGuard._();

  static bool hasPermission(UserRole userRole, String route) {
    final permissions = _rolePermissions[userRole] ?? [];

    // Exact match
    if (permissions.contains(route)) return true;

    // Prefix match — allows any sub-route of a permitted parent.
    // e.g. permitting '/officer/loans' also allows '/officer/loans/approve'.
    for (final allowedRoute in permissions) {
      if (route.startsWith(allowedRoute)) return true;
    }

    return false;
  }

  static String getHomeRoute(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return AppRoutes.customerHome;
      case UserRole.branchManager:
        return AppRoutes.branchManagerHome;
      case UserRole.loanOfficer:
        return AppRoutes.loanOfficerHome;
      case UserRole.cardOfficer:
        return AppRoutes.cardOfficerHome;
      case UserRole.admin:
        return AppRoutes.adminHome;
      case UserRole.superAdmin:
        return AppRoutes.superAdminHome;
      case UserRole.employee:
        return AppRoutes.employeeHome;
    }
  }

  static String getRedirectRoute(bool isAuthenticated, UserRole? userRole) {
    if (!isAuthenticated || userRole == null) return AppRoutes.login;
    return getHomeRoute(userRole);
  }

  static bool isPublicRoute(String route) {
    return AppRoutes.isPublicRoute(route);
  }

  static String? validateRouteAccess({
    required String requestedRoute,
    required bool isAuthenticated,
    UserRole? userRole,
  }) {
    if (isPublicRoute(requestedRoute)) return requestedRoute;
    if (!isAuthenticated) return AppRoutes.login;
    if (userRole != null && !hasPermission(userRole, requestedRoute)) {
      return getHomeRoute(userRole);
    }
    return requestedRoute;
  }

  // ── Role permission tables ─────────────────────────────────────────────────

  static final Map<UserRole, List<String>> _rolePermissions = {
    // ── Customer ─────────────────────────────────────────────────────────────
    UserRole.customer: [
      AppRoutes.customerHome,
      AppRoutes.home,
      AppRoutes.accounts,
      AppRoutes.accountDetails,
      AppRoutes.transactions,
      AppRoutes.transactionDetails,
      AppRoutes.transfer,
      AppRoutes.deposit,
      AppRoutes.withdrawal,
      AppRoutes.cards,
      AppRoutes.cardDetails,
      // Loan routes accessible to customers
      AppRoutes.loans,
      AppRoutes.loanDetails,
      AppRoutes.loanApplication,
      AppRoutes.loanRepaymentSchedule,
      AppRoutes.loanPayment,
      AppRoutes.dps,
      AppRoutes.dpsDetails,
      AppRoutes.profile,
      AppRoutes.settings,
      AppRoutes.editProfile,
      AppRoutes.changePassword,
      AppRoutes.notifications,
      AppRoutes.branchManagement, // read-only branch locator
      AppRoutes.help,
      AppRoutes.faq,
      AppRoutes.contactSupport,
      AppRoutes.termsAndConditions,
      AppRoutes.privacyPolicy,
    ],

    // ── Employee ──────────────────────────────────────────────────────────────
    UserRole.employee: [
      AppRoutes.employeeHome,
      AppRoutes.home,
      AppRoutes.profile,
      AppRoutes.settings,
      AppRoutes.editProfile,
      AppRoutes.changePassword,
      AppRoutes.notifications,
      AppRoutes.help,
      AppRoutes.faq,
    ],

    // ── Branch Manager ────────────────────────────────────────────────────────
    UserRole.branchManager: [
      AppRoutes.branchManagerHome,
      AppRoutes.home,
      AppRoutes.branchManagement,
      AppRoutes.accountManagement,
      AppRoutes.accounts,
      AppRoutes.accountDetails,
      AppRoutes.customerManagement,
      AppRoutes.customerDetails,
      AppRoutes.transactionManagement,
      AppRoutes.transactions,
      AppRoutes.transactionDetails,
      // Loan management — branch managers can access all officer routes
      AppRoutes.loans,
      AppRoutes.loanDetails,
      AppRoutes.loanApplication,
      AppRoutes.loanApplications,
      AppRoutes.loanApproval,
      AppRoutes.loanRepaymentSchedule,
      AppRoutes.loanPayment,
      AppRoutes.officerLoanQueue,
      AppRoutes.officerLoanApprove,
      AppRoutes.officerLoanDisburse,
      AppRoutes.officerLoanSearch,
      AppRoutes.userManagement,
      AppRoutes.reports,
      AppRoutes.analytics,
      AppRoutes.profile,
      AppRoutes.settings,
      AppRoutes.editProfile,
      AppRoutes.changePassword,
      AppRoutes.notifications,
      AppRoutes.help,
      AppRoutes.faq,
    ],

    // ── Loan Officer ──────────────────────────────────────────────────────────
    UserRole.loanOfficer: [
      AppRoutes.loanOfficerHome,
      AppRoutes.home,
      // Customer-facing loan routes (read)
      AppRoutes.loans,
      AppRoutes.loanDetails,
      AppRoutes.loanApplication,
      AppRoutes.loanApplications,
      AppRoutes.loanRepaymentSchedule,
      AppRoutes.loanPayment,
      // Legacy approval alias
      AppRoutes.loanApproval,
      // Officer-only routes
      AppRoutes.officerLoanQueue,
      AppRoutes.officerLoanApprove,
      AppRoutes.officerLoanDisburse,
      AppRoutes.officerLoanSearch,
      AppRoutes.customerManagement,
      AppRoutes.customerDetails,
      AppRoutes.reports,
      AppRoutes.profile,
      AppRoutes.settings,
      AppRoutes.editProfile,
      AppRoutes.changePassword,
      AppRoutes.notifications,
      AppRoutes.help,
      AppRoutes.faq,
    ],

    // ── Card Officer ──────────────────────────────────────────────────────────
    UserRole.cardOfficer: [
      AppRoutes.cardOfficerHome,
      AppRoutes.home,
      AppRoutes.cardApplications,
      AppRoutes.cardManagement,
      AppRoutes.cards,
      AppRoutes.cardDetails,
      AppRoutes.customerManagement,
      AppRoutes.customerDetails,
      AppRoutes.reports,
      AppRoutes.profile,
      AppRoutes.settings,
      AppRoutes.editProfile,
      AppRoutes.changePassword,
      AppRoutes.notifications,
      AppRoutes.help,
      AppRoutes.faq,
    ],

    // ── Admin ─────────────────────────────────────────────────────────────────
    UserRole.admin: [
      AppRoutes.adminHome,
      AppRoutes.home,
      AppRoutes.userManagement,
      AppRoutes.branchManagement,
      AppRoutes.accountManagement,
      AppRoutes.accounts,
      AppRoutes.accountDetails,
      AppRoutes.customerManagement,
      AppRoutes.customerDetails,
      AppRoutes.transactionManagement,
      AppRoutes.transactions,
      AppRoutes.transactionDetails,
      // All loan routes
      AppRoutes.loans,
      AppRoutes.loanDetails,
      AppRoutes.loanApplication,
      AppRoutes.loanApplications,
      AppRoutes.loanApproval,
      AppRoutes.loanRepaymentSchedule,
      AppRoutes.loanPayment,
      AppRoutes.officerLoanQueue,
      AppRoutes.officerLoanApprove,
      AppRoutes.officerLoanDisburse,
      AppRoutes.officerLoanSearch,
      AppRoutes.reports,
      AppRoutes.analytics,
      AppRoutes.systemSettings,
      AppRoutes.profile,
      AppRoutes.settings,
      AppRoutes.editProfile,
      AppRoutes.changePassword,
      AppRoutes.notifications,
      AppRoutes.help,
      AppRoutes.faq,
      AppRoutes.contactSupport,
    ],

    // ── Super Admin ───────────────────────────────────────────────────────────
    UserRole.superAdmin: [
      AppRoutes.superAdminHome,
      AppRoutes.adminHome,
      AppRoutes.home,
      AppRoutes.userManagement,
      AppRoutes.branchManagement,
      AppRoutes.accountManagement,
      AppRoutes.accounts,
      AppRoutes.accountDetails,
      AppRoutes.customerManagement,
      AppRoutes.customerDetails,
      AppRoutes.transactionManagement,
      AppRoutes.transactions,
      AppRoutes.transactionDetails,
      // All loan routes
      AppRoutes.loans,
      AppRoutes.loanDetails,
      AppRoutes.loanApplication,
      AppRoutes.loanApplications,
      AppRoutes.loanApproval,
      AppRoutes.loanRepaymentSchedule,
      AppRoutes.loanPayment,
      AppRoutes.officerLoanQueue,
      AppRoutes.officerLoanApprove,
      AppRoutes.officerLoanDisburse,
      AppRoutes.officerLoanSearch,
      AppRoutes.reports,
      AppRoutes.analytics,
      AppRoutes.systemSettings,
      AppRoutes.auditLogs,
      AppRoutes.profile,
      AppRoutes.settings,
      AppRoutes.editProfile,
      AppRoutes.changePassword,
      AppRoutes.notifications,
      AppRoutes.help,
      AppRoutes.faq,
      AppRoutes.contactSupport,
    ],
  };

  // ── Convenience helpers ────────────────────────────────────────────────────

  static bool hasAccessToAnyRoute(UserRole userRole, List<String> routes) {
    return routes.any((route) => hasPermission(userRole, route));
  }

  static List<String> getAccessibleRoutes(UserRole role) {
    return _rolePermissions[role] ?? [];
  }

  static bool isAdminRole(UserRole role) {
    return role == UserRole.admin ||
        role == UserRole.superAdmin ||
        role == UserRole.branchManager;
  }

  static bool isStaffRole(UserRole role) {
    return role == UserRole.employee ||
        role == UserRole.branchManager ||
        role == UserRole.loanOfficer ||
        role == UserRole.cardOfficer;
  }

  static bool isCustomerRole(UserRole role) => role == UserRole.customer;

  /// Returns true for roles that are allowed to access officer loan routes.
  static bool isLoanOfficerRole(UserRole role) {
    return role == UserRole.loanOfficer ||
        role == UserRole.branchManager ||
        role == UserRole.admin ||
        role == UserRole.superAdmin;
  }
}

// ── RouteGuardWidget ──────────────────────────────────────────────────────────

class RouteGuardWidget extends StatelessWidget {
  final Widget child;
  final String route;
  final bool isAuthenticated;
  final UserRole? userRole;
  final Widget? unauthorizedWidget;
  final VoidCallback? onUnauthorized;

  const RouteGuardWidget({
    super.key,
    required this.child,
    required this.route,
    required this.isAuthenticated,
    this.userRole,
    this.unauthorizedWidget,
    this.onUnauthorized,
  });

  @override
  Widget build(BuildContext context) {
    if (RouteGuard.isPublicRoute(route)) return child;

    if (!isAuthenticated) {
      onUnauthorized?.call();
      return unauthorizedWidget ?? _buildUnauthorizedWidget(context);
    }

    if (userRole != null && !RouteGuard.hasPermission(userRole!, route)) {
      onUnauthorized?.call();
      return unauthorizedWidget ?? _buildForbiddenWidget(context);
    }

    return child;
  }

  Widget _buildUnauthorizedWidget(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Authentication Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please log in to access this page',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(
                  context, AppRoutes.login),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForbiddenWidget(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "You don't have permission to access this page",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final destination = userRole != null
                    ? RouteGuard.getHomeRoute(userRole!)
                    : AppRoutes.login;
                Navigator.pushReplacementNamed(context, destination);
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
