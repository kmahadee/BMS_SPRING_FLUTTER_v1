// lib/shared/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/core/navigation/route_guard.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/shared/providers/badge_count_provider.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/domain/entities/user_role.dart';
import '../../../features/auth/domain/entities/user_entity.dart';

import 'package:package_info_plus/package_info_plus.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final String route;
  final int? badgeCount;
  final List<UserRole>? allowedRoles;

  const MenuItem({
    required this.title,
    required this.icon,
    required this.route,
    this.badgeCount,
    this.allowedRoles,
  });
}

class MenuSection {
  final String? title;
  final List<MenuItem> items;

  const MenuSection({this.title, required this.items});
}

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion =
            'v${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() => _appVersion = 'v1.0.0');
    }
  }

  List<MenuSection> _getMenuSections(
      UserRole role, BadgeCountProvider counts) {
    switch (role) {
      // ── Customer ──────────────────────────────────────────────────────────
      case UserRole.customer:
        return [
          MenuSection(
            items: [
              MenuItem(
                title: 'Dashboard',
                icon: Icons.dashboard,
                route: AppRoutes.customerHome,
              ),
            ],
          ),
          MenuSection(
            title: 'Banking',
            items: [
              MenuItem(
                title: 'My Accounts',
                icon: Icons.account_balance_wallet,
                route: AppRoutes.accounts,
              ),
              MenuItem(
                title: 'Transactions',
                icon: Icons.receipt_long,
                route: AppRoutes.transactions,
              ),
              MenuItem(
                title: 'Transfer',
                icon: Icons.send,
                route: AppRoutes.transfer,
              ),
            ],
          ),
          MenuSection(
            title: 'Products',
            items: [
              // ── My Loans entry for customers ──────────────────────────
              MenuItem(
                title: 'My Loans',
                icon: Icons.account_balance_rounded,
                route: AppRoutes.loans,
              ),
              // ─────────────────────────────────────────────────────────
              MenuItem(
                title: 'DPS',
                icon: Icons.savings,
                route: AppRoutes.dps,
              ),
              MenuItem(
                title: 'Cards',
                icon: Icons.credit_card,
                route: AppRoutes.cards,
              ),
            ],
          ),
          MenuSection(
            title: 'Information',
            items: [
              MenuItem(
                title: 'Branches',
                icon: Icons.location_on,
                route: AppRoutes.branchManagement,
              ),
              MenuItem(
                title: 'Help & Support',
                icon: Icons.help_outline,
                route: AppRoutes.help,
              ),
            ],
          ),
          MenuSection(
            title: 'Account',
            items: [
              MenuItem(
                title: 'Profile',
                icon: Icons.person,
                route: AppRoutes.profile,
              ),
              MenuItem(
                title: 'Settings',
                icon: Icons.settings,
                route: AppRoutes.settings,
              ),
            ],
          ),
        ];

      // ── Branch Manager ────────────────────────────────────────────────────
      case UserRole.branchManager:
        return [
          MenuSection(
            items: [
              MenuItem(
                title: 'Dashboard',
                icon: Icons.dashboard,
                route: AppRoutes.branchManagerHome,
              ),
            ],
          ),
          MenuSection(
            title: 'Management',
            items: [
              MenuItem(
                title: 'Branch Overview',
                icon: Icons.business,
                route: AppRoutes.branchManagement,
              ),
              MenuItem(
                title: 'Accounts',
                icon: Icons.account_balance_wallet,
                route: AppRoutes.accountManagement,
              ),
              MenuItem(
                title: 'Customers',
                icon: Icons.people,
                route: AppRoutes.customerManagement,
              ),
              MenuItem(
                title: 'Loan Approvals',
                icon: Icons.check_circle,
                route: AppRoutes.officerLoanQueue,
                badgeCount: counts.pendingLoanApprovals,
              ),
            ],
          ),
          // ── Loan Management section (also visible to branch managers) ───
          MenuSection(
            title: 'Loan Management',
            items: [
              MenuItem(
                title: 'Approval Queue',
                icon: Icons.pending_actions_rounded,
                route: AppRoutes.officerLoanQueue,
                badgeCount: counts.pendingLoanApprovals,
              ),
              MenuItem(
                title: 'Search Loans',
                icon: Icons.manage_search_rounded,
                route: AppRoutes.officerLoanSearch,
              ),
            ],
          ),
          // ──────────────────────────────────────────────────────────────
          MenuSection(
            title: 'Staff',
            items: [
              MenuItem(
                title: 'Staff Management',
                icon: Icons.groups,
                route: AppRoutes.userManagement,
              ),
            ],
          ),
          MenuSection(
            title: 'Reports',
            items: [
              MenuItem(
                title: 'Reports',
                icon: Icons.assessment,
                route: AppRoutes.reports,
              ),
              MenuItem(
                title: 'Analytics',
                icon: Icons.analytics,
                route: AppRoutes.analytics,
              ),
            ],
          ),
          MenuSection(
            title: 'Account',
            items: [
              MenuItem(
                title: 'Settings',
                icon: Icons.settings,
                route: AppRoutes.settings,
              ),
            ],
          ),
        ];

      // ── Loan Officer ───────────────────────────────────────────────────────
      case UserRole.loanOfficer:
        return [
          MenuSection(
            items: [
              MenuItem(
                title: 'Dashboard',
                icon: Icons.dashboard,
                route: AppRoutes.loanOfficerHome,
              ),
            ],
          ),
          // ── Loan Management section ──────────────────────────────────────
          MenuSection(
            title: 'Loan Management',
            items: [
              MenuItem(
                title: 'Approval Queue',
                icon: Icons.pending_actions_rounded,
                route: AppRoutes.officerLoanQueue,
                badgeCount: counts.pendingLoanApplications,
              ),
              MenuItem(
                title: 'Loan Portfolio',
                icon: Icons.account_balance_rounded,
                route: AppRoutes.loans,
              ),
              MenuItem(
                title: 'Search Loans',
                icon: Icons.manage_search_rounded,
                route: AppRoutes.officerLoanSearch,
              ),
            ],
          ),
          // ─────────────────────────────────────────────────────────────────
          MenuSection(
            title: 'Customers',
            items: [
              MenuItem(
                title: 'Customers',
                icon: Icons.people,
                route: AppRoutes.customerManagement,
              ),
            ],
          ),
          MenuSection(
            title: 'Reports',
            items: [
              MenuItem(
                title: 'Reports',
                icon: Icons.assessment,
                route: AppRoutes.reports,
              ),
            ],
          ),
          MenuSection(
            title: 'Account',
            items: [
              MenuItem(
                title: 'Settings',
                icon: Icons.settings,
                route: AppRoutes.settings,
              ),
            ],
          ),
        ];

      // ── Card Officer ──────────────────────────────────────────────────────
      case UserRole.cardOfficer:
        return [
          MenuSection(
            items: [
              MenuItem(
                title: 'Dashboard',
                icon: Icons.dashboard,
                route: AppRoutes.cardOfficerHome,
              ),
            ],
          ),
          MenuSection(
            title: 'Card Management',
            items: [
              MenuItem(
                title: 'Applications',
                icon: Icons.assignment,
                route: AppRoutes.cardApplications,
                badgeCount: counts.pendingCardApplications,
              ),
              MenuItem(
                title: 'Card Management',
                icon: Icons.credit_card,
                route: AppRoutes.cardManagement,
              ),
            ],
          ),
          MenuSection(
            title: 'Customers',
            items: [
              MenuItem(
                title: 'Customers',
                icon: Icons.people,
                route: AppRoutes.customerManagement,
              ),
            ],
          ),
          MenuSection(
            title: 'Reports',
            items: [
              MenuItem(
                title: 'Reports',
                icon: Icons.assessment,
                route: AppRoutes.reports,
              ),
            ],
          ),
          MenuSection(
            title: 'Account',
            items: [
              MenuItem(
                title: 'Settings',
                icon: Icons.settings,
                route: AppRoutes.settings,
              ),
            ],
          ),
        ];

      // ── Admin / Super Admin ───────────────────────────────────────────────
      case UserRole.admin:
      case UserRole.superAdmin:
        return [
          MenuSection(
            items: [
              MenuItem(
                title: 'Dashboard',
                icon: Icons.dashboard,
                route: AppRoutes.adminHome,
              ),
            ],
          ),
          MenuSection(
            title: 'Management',
            items: [
              MenuItem(
                title: 'Users',
                icon: Icons.people,
                route: AppRoutes.userManagement,
              ),
              MenuItem(
                title: 'Branches',
                icon: Icons.business,
                route: AppRoutes.branchManagement,
              ),
              MenuItem(
                title: 'Accounts',
                icon: Icons.account_balance_wallet,
                route: AppRoutes.accountManagement,
              ),
            ],
          ),
          // ── Loan Management section (admins also have access) ─────────────
          MenuSection(
            title: 'Loan Management',
            items: [
              MenuItem(
                title: 'Approval Queue',
                icon: Icons.pending_actions_rounded,
                route: AppRoutes.officerLoanQueue,
                badgeCount: counts.pendingLoanApprovals,
              ),
              MenuItem(
                title: 'Search Loans',
                icon: Icons.manage_search_rounded,
                route: AppRoutes.officerLoanSearch,
              ),
            ],
          ),
          // ──────────────────────────────────────────────────────────────────
          MenuSection(
            title: 'Reports & Analytics',
            items: [
              MenuItem(
                title: 'Reports',
                icon: Icons.assessment,
                route: AppRoutes.reports,
              ),
              MenuItem(
                title: 'Analytics',
                icon: Icons.analytics,
                route: AppRoutes.analytics,
              ),
            ],
          ),
          MenuSection(
            title: 'System',
            items: [
              MenuItem(
                title: 'System Settings',
                icon: Icons.settings,
                route: AppRoutes.systemSettings,
              ),
              if (role == UserRole.superAdmin)
                MenuItem(
                  title: 'Audit Logs',
                  icon: Icons.history,
                  route: AppRoutes.auditLogs,
                ),
            ],
          ),
        ];

      // ── Fallback ──────────────────────────────────────────────────────────
      default:
        return [
          MenuSection(
            items: [
              MenuItem(
                title: 'Dashboard',
                icon: Icons.dashboard,
                route: AppRoutes.home,
              ),
            ],
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        if (user == null) {
          return Drawer(
            child: Center(
              child: Text('Not logged in',
                  style: theme.textTheme.bodyLarge),
            ),
          );
        }

        final counts = context.watch<BadgeCountProvider>();
        final menuSections = _getMenuSections(user.role, counts);

        return Drawer(
          child: SafeArea(
            child: Column(
              children: [
                _buildUserHeader(context, user, colorScheme, theme),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: menuSections.length,
                    itemBuilder: (context, index) {
                      final section = menuSections[index];
                      return _buildMenuSection(
                        context,
                        section,
                        currentRoute,
                        colorScheme,
                        theme,
                      );
                    },
                  ),
                ),
                _buildLogoutButton(
                    context, authProvider, colorScheme, theme),
                _buildAppVersion(theme, colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserHeader(
    BuildContext context,
    UserEntity user,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8)
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: colorScheme.onPrimary,
                child: Text(
                  _getInitials(user.fullName),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.role.displayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    MenuSection section,
    String currentRoute,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              section.title!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        ...section.items.map(
          (item) => _buildMenuItem(
            context,
            item,
            currentRoute == item.route,
            colorScheme,
            theme,
          ),
        ),
        const Divider(height: 16),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    MenuItem item,
    bool isSelected,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: isSelected
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        item.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: item.badgeCount != null && item.badgeCount! > 0
          ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints:
                  const BoxConstraints(minWidth: 24, minHeight: 24),
              child: Text(
                item.badgeCount! > 99
                    ? '99+'
                    : '${item.badgeCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onError,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor:
          colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        Navigator.pop(context); // close drawer
        if (!isSelected) {
          Navigator.pushNamed(context, item.route);
        }
      },
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    AuthProvider authProvider,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content:
                  const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );

          if (confirm == true && context.mounted) {
            await authProvider.logout();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            }
          }
        },
        icon: Icon(Icons.logout, color: colorScheme.error),
        label: Text('Logout',
            style: TextStyle(color: colorScheme.error)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAppVersion(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        _appVersion,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
