import 'package:flutter/material.dart';
import 'package:vantedge/features/auth/domain/entities/user_role.dart';
import 'package:vantedge/features/auth/domain/entities/user_entity.dart';

import 'package:vantedge/core/routes/app_routes.dart';

class RouteGuard {
  RouteGuard._();

  /// Check if user has permission to access a route.
  static bool hasPermission(UserRole userRole, String route) {
    final permissions = _rolePermissions[userRole] ?? [];

    if (permissions.contains(route)) {
      return true;
    }

    // Allow any sub-route of a permitted base route.
    for (final allowedRoute in permissions) {
      if (route.startsWith(allowedRoute)) {
        return true;
      }
    }

    return false;
  }

  /// Returns the home route for [role].
  ///
  /// FIX: Added missing `employee` case and gave `superAdmin` its own distinct
  /// home route (AppRoutes.superAdminHome) instead of silently falling through
  /// to adminHome.
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
        // FIX: superAdmin was previously falling through to adminHome because
        // the switch combined both cases. Now it points to its dedicated route.
        return AppRoutes.superAdminHome;
      case UserRole.employee:
        // FIX: employee case was missing, causing a non-exhaustive switch
        // warning and a runtime fallthrough to the default (which didn't exist).
        return AppRoutes.employeeHome;
    }
  }

  /// Get redirect route based on authentication status and role.
  static String getRedirectRoute(bool isAuthenticated, UserRole? userRole) {
    if (!isAuthenticated || userRole == null) {
      return AppRoutes.login;
    }
    return getHomeRoute(userRole);
  }

  /// Check if a route is public (doesn't require authentication).
  static bool isPublicRoute(String route) {
    return AppRoutes.isPublicRoute(route);
  }

  /// Validate route access and return the appropriate route string.
  static String? validateRouteAccess({
    required String requestedRoute,
    required bool isAuthenticated,
    UserRole? userRole,
  }) {
    if (isPublicRoute(requestedRoute)) {
      return requestedRoute;
    }

    if (!isAuthenticated) {
      return AppRoutes.login;
    }

    if (userRole != null && !hasPermission(userRole, requestedRoute)) {
      return getHomeRoute(userRole);
    }

    return requestedRoute;
  }

  // ── Role permission map ────────────────────────────────────────────────────

  static final Map<UserRole, List<String>> _rolePermissions = {
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
      AppRoutes.loans,
      AppRoutes.loanDetails,
      AppRoutes.loanApplication,
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
    UserRole.employee: [
      // FIX: employee permissions were previously missing from this map,
      // causing hasPermission() to always return false for employees and
      // redirecting them to their home on every navigation attempt.
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
      AppRoutes.loanApproval,
      AppRoutes.loanApplications,
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
    UserRole.loanOfficer: [
      AppRoutes.loanOfficerHome,
      AppRoutes.home,
      AppRoutes.loanApplications,
      AppRoutes.loanApproval,
      AppRoutes.loans,
      AppRoutes.loanDetails,
      AppRoutes.loanApplication,
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
    UserRole.superAdmin: [
      // FIX: superAdmin now has its own home route in the list.
      AppRoutes.superAdminHome,
      AppRoutes.adminHome, // superAdmin can also use the admin shell
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

  // ── Convenience helpers ───────────────────────────────────────────────────

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

  static bool isCustomerRole(UserRole role) {
    return role == UserRole.customer;
  }
}

// ── RouteGuardWidget ──────────────────────────────────────────────────────────

/// Wraps a screen widget and enforces authentication + role-based access.
/// This widget is purely declarative — it does not navigate itself; the parent
/// [AppRouter._buildAuthenticatedRoute] triggers navigation via [onUnauthorized].
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
    if (RouteGuard.isPublicRoute(route)) {
      return child;
    }

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
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.login),
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