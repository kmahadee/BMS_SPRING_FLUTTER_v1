import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/features/auth/domain/entities/user_role.dart';
import 'package:vantedge/shared/providers/badge_count_provider.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final int? badgeCount;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.badgeCount,
  });
}

class BottomNavBar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.currentRoute,
    required this.onItemTapped,
  });

  // List<NavItem> _getNavItems(UserRole role) {
  List<NavItem> _getNavItems(UserRole role, BadgeCountProvider counts) {
    switch (role) {
      case UserRole.customer:
        return [
          NavItem(
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            route: AppRoutes.customerHome,
          ),
          NavItem(
            label: 'Accounts',
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            route: AppRoutes.accounts,
          ),
          NavItem(
            label: 'Transactions',
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            route: AppRoutes.transactions,
          ),
          NavItem(
            label: 'More',
            icon: Icons.menu,
            activeIcon: Icons.menu,
            route: '', // This opens the drawer
          ),
        ];

      case UserRole.branchManager:
        return [
          NavItem(
            label: 'Home',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            route: AppRoutes.branchManagerHome,
          ),
          NavItem(
            label: 'Accounts',
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            route: AppRoutes.accountManagement,
          ),
          NavItem(
            label: 'Approvals',
            icon: Icons.check_circle_outline,
            activeIcon: Icons.check_circle,
            route: AppRoutes.loanApproval,
            // badgeCount: 5, // TODO: Load from provider
            badgeCount: counts.pendingLoanApprovals,
          ),
          NavItem(
            label: 'Reports',
            icon: Icons.assessment_outlined,
            activeIcon: Icons.assessment,
            route: AppRoutes.reports,
          ),
        ];

      case UserRole.loanOfficer:
        return [
          NavItem(
            label: 'Home',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            route: AppRoutes.loanOfficerHome,
          ),
          NavItem(
            label: 'Applications',
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            route: AppRoutes.loanApplications,
            // badgeCount: 15, // TODO: Load from provider
            badgeCount: counts.pendingLoanApplications,
          ),
          NavItem(
            label: 'Portfolio',
            icon: Icons.account_balance_outlined,
            activeIcon: Icons.account_balance,
            route: AppRoutes.loans,
          ),
          NavItem(
            label: 'More',
            icon: Icons.menu,
            activeIcon: Icons.menu,
            route: '', // This opens the drawer
          ),
        ];

      case UserRole.cardOfficer:
        return [
          NavItem(
            label: 'Home',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            route: AppRoutes.cardOfficerHome,
          ),
          NavItem(
            label: 'Applications',
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            route: AppRoutes.cardApplications,
            // badgeCount: 12, // TODO: Load from provider
            badgeCount: counts.pendingCardApplications,
          ),
          NavItem(
            label: 'Cards',
            icon: Icons.credit_card_outlined,
            activeIcon: Icons.credit_card,
            route: AppRoutes.cardManagement,
          ),
          NavItem(
            label: 'More',
            icon: Icons.menu,
            activeIcon: Icons.menu,
            route: '', // This opens the drawer
          ),
        ];

      case UserRole.admin:
      case UserRole.superAdmin:
        return [
          NavItem(
            label: 'Home',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            route: AppRoutes.adminHome,
          ),
          NavItem(
            label: 'Users',
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            route: AppRoutes.userManagement,
          ),
          NavItem(
            label: 'Branches',
            icon: Icons.business_outlined,
            activeIcon: Icons.business,
            route: AppRoutes.branchManagement,
          ),
          NavItem(
            label: 'Reports',
            icon: Icons.assessment_outlined,
            activeIcon: Icons.assessment,
            route: AppRoutes.reports,
          ),
        ];

      default:
        return [
          NavItem(
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            route: AppRoutes.home,
          ),
        ];
    }
  }

  int _getCurrentIndex(List<NavItem> items, String route) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].route == route) {
        return i;
      }
      // Check if current route starts with the nav item route (for nested routes)
      if (items[i].route.isNotEmpty && route.startsWith(items[i].route)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const SizedBox.shrink();
        }

        // final navItems = _getNavItems(user.role);
        final counts = context.watch<BadgeCountProvider>();
        final navItems = _getNavItems(user.role, counts);
        final currentIndex = _getCurrentIndex(navItems, currentRoute);

        return NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            final item = navItems[index];

            // If it's the "More" item (empty route), open the drawer
            if (item.route.isEmpty) {
              Scaffold.of(context).openDrawer();
            } else {
              onItemTapped(item.route);
            }
          },
          destinations: navItems.map((item) {
            final isSelected = navItems.indexOf(item) == currentIndex;

            return NavigationDestination(
              icon: _buildNavIcon(
                item.icon,
                item.badgeCount,
                colorScheme,
                false,
              ),
              selectedIcon: _buildNavIcon(
                item.activeIcon,
                item.badgeCount,
                colorScheme,
                true,
              ),
              label: item.label,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildNavIcon(
    IconData icon,
    int? badgeCount,
    ColorScheme colorScheme,
    bool isSelected,
  ) {
    if (badgeCount == null || badgeCount == 0) {
      return Icon(icon);
    }

    return Badge(
      label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
      backgroundColor: colorScheme.error,
      textColor: colorScheme.onError,
      child: Icon(icon),
    );
  }
}

// Alternative Bottom Navigation Bar using Material 2 style
class BottomNavBarMaterial2 extends StatelessWidget {
  final String currentRoute;
  final Function(String) onItemTapped;

  const BottomNavBarMaterial2({
    super.key,
    required this.currentRoute,
    required this.onItemTapped,
  });

  List<NavItem> _getNavItems(UserRole role) {
    // Same logic as above
    switch (role) {
      case UserRole.customer:
        return [
          NavItem(
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            route: AppRoutes.customerHome,
          ),
          NavItem(
            label: 'Accounts',
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            route: AppRoutes.accounts,
          ),
          NavItem(
            label: 'Transactions',
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            route: AppRoutes.transactions,
          ),
          NavItem(
            label: 'More',
            icon: Icons.menu,
            activeIcon: Icons.menu,
            route: '',
          ),
        ];

      default:
        return [
          NavItem(
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            route: AppRoutes.home,
          ),
        ];
    }
  }

  int _getCurrentIndex(List<NavItem> items, String route) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].route == route) {
        return i;
      }
      if (items[i].route.isNotEmpty && route.startsWith(items[i].route)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const SizedBox.shrink();
        }

        final navItems = _getNavItems(user.role);
        final currentIndex = _getCurrentIndex(navItems, currentRoute);

        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            final item = navItems[index];
            if (item.route.isEmpty) {
              Scaffold.of(context).openDrawer();
            } else {
              onItemTapped(item.route);
            }
          },
          type: BottomNavigationBarType.fixed,
          items: navItems.map((item) {
            return BottomNavigationBarItem(
              icon: _buildIconWithBadge(item.icon, item.badgeCount),
              activeIcon: _buildIconWithBadge(item.activeIcon, item.badgeCount),
              label: item.label,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildIconWithBadge(IconData icon, int? badgeCount) {
    if (badgeCount == null || badgeCount == 0) {
      return Icon(icon);
    }

    return Badge(
      label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
      child: Icon(icon),
    );
  }
}
