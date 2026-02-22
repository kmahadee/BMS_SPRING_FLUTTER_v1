import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/core/theme/app_colors.dart';
import 'package:vantedge/core/theme/app_text_styles.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/features/auth/domain/entities/user_role.dart';
import 'package:vantedge/shared/providers/badge_count_provider.dart';
import 'package:vantedge/shared/widgets/main_scaffold.dart';

/// Generic home screen that adapts to user role
/// Displays role-specific content and actions
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('\n🏠 [HomeScreen] 🔨 BUILD METHOD CALLED');
    print('  - Route: ${ModalRoute.of(context)?.settings.name ?? 'unknown'}');
    print('  - Arguments: ${ModalRoute.of(context)?.settings.arguments}');

    return Consumer2<AuthProvider, BadgeCountProvider>(
      builder: (context, authProvider, badgeProvider, child) {
        final user = authProvider.user;

        print('🏠 [HomeScreen] Consumer builder called');
        print('  - AuthProvider.isLoading: ${authProvider.isLoading}');
        print(
          '  - AuthProvider.isAuthenticated: ${authProvider.isAuthenticated}',
        );
        print('  - User: ${user?.email ?? 'null'}');
        print('  - User role: ${user?.role ?? 'null'}');
        print('  - User ID: ${user?.id ?? 'null'}');
        print('  - User fullName: ${user?.fullName ?? 'null'}');

        if (user == null) {
          print('⚠️ [HomeScreen] User is null! Showing error state');
          return const SimpleScaffold(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('No user data available'),
                  SizedBox(height: 24),
                  Text(
                    'Debug: User is null in HomeScreen',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        print(
          '✅ [HomeScreen] User data available, building dashboard for role: ${user.role}',
        );

        // Use MainScaffold which includes the drawer and bottom nav
        return MainScaffold(
          currentRoute: ModalRoute.of(context)?.settings.name ?? AppRoutes.home,
          title: '${user.role.displayName} Dashboard',
          showAppBar: true,
          showDrawer: true,
          showBottomNav: true,
          showNotifications: true,
          // notificationCount: badgeProvider.totalNotificationCount,
          onNotificationTap: () {
            print('🏠 [HomeScreen] Navigating to notifications from app bar');
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                _buildWelcomeHeader(
                  user.fullName ?? 'User',
                  user.email,
                  user.role,
                ),

                const SizedBox(height: 24),

                // Quick Actions (Role-based)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Actions', style: AppTextStyles.titleLarge),
                      const SizedBox(height: 16),
                      _buildQuickActions(context, user.role),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // User Information
                _buildUserInfoCard(user),

                const SizedBox(height: 24),

                // Debug info (only in debug mode)
                if (const bool.fromEnvironment('dart.vm.product') == false)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[200],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Info:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'User ID: ${user.id}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        Text(
                          'Username: ${user.username}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        Text(
                          'Email: ${user.email}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        Text(
                          'Role: ${user.role}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        Text(
                          'FullName: ${user.fullName}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        Text(
                          'CustomerId: ${user.customerId}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(String name, String email, UserRole role) {
    print('🏠 [HomeScreen] Building welcome header for: $name');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getRoleGradient(role),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Text(
                  _getInitials(name),
                  style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role.displayName,
              style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, UserRole role) {
    final actions = _getQuickActionsForRole(role);
    print(
      '🏠 [HomeScreen] Building quick actions for role: $role, count: ${actions.length}',
    );

    if (actions.isEmpty) {
      print('⚠️ [HomeScreen] No quick actions for role: $role');
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _QuickActionCard(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          color: action['color'] as Color,
          onTap: () {
            print(
              '🏠 [HomeScreen] Quick action tapped: ${action['label']} -> ${action['route']}',
            );
            Navigator.pushNamed(context, action['route'] as String);
          },
        );
      },
    );
  }

  Widget _buildUserInfoCard(user) {
    print('🏠 [HomeScreen] Building user info card');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Account Information', style: AppTextStyles.titleMedium),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'User ID', value: user.id.toString()),
              _InfoRow(label: 'Username', value: user.username),
              _InfoRow(label: 'Email', value: user.email),
              _InfoRow(label: 'Role', value: user.role.displayName),
              if (user.customerId != null)
                _InfoRow(label: 'Customer ID', value: user.customerId!),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getRoleGradient(UserRole role) {
    print('🏠 [HomeScreen] Getting gradient for role: $role');
    switch (role) {
      case UserRole.customer:
        return AppColors.gradientBlue;
      case UserRole.employee:
        return AppColors.gradientGreen;
      case UserRole.admin:
      case UserRole.superAdmin:
        return AppColors.gradientPurple;
      case UserRole.branchManager:
        return AppColors.gradientPurple;
      case UserRole.loanOfficer:
        return AppColors.gradientGold;
      case UserRole.cardOfficer:
        return AppColors.gradientBlue;
      default:
        return AppColors.gradientBlue;
    }
  }

  List<Map<String, dynamic>> _getQuickActionsForRole(UserRole role) {
    print('🏠 [HomeScreen] Getting quick actions for role: $role');
    switch (role) {
      case UserRole.customer:
        return [
          {
            'icon': Icons.account_balance_wallet,
            'label': 'Accounts',
            'color': AppColors.primary,
            'route': AppRoutes.accounts,
          },
          {
            'icon': Icons.swap_horiz,
            'label': 'Transfer',
            'color': AppColors.secondary,
            'route': AppRoutes.transfer,
          },
          {
            'icon': Icons.credit_card,
            'label': 'Cards',
            'color': AppColors.tertiary,
            'route': AppRoutes.cards,
          },
          {
            'icon': Icons.account_balance,
            'label': 'Loans',
            'color': AppColors.warning,
            'route': AppRoutes.loans,
          },
        ];

      case UserRole.employee:
        return [
          {
            'icon': Icons.people,
            'label': 'Customers',
            'color': AppColors.primary,
            'route': AppRoutes.customerManagement,
          },
          {
            'icon': Icons.account_balance_wallet,
            'label': 'Accounts',
            'color': AppColors.tertiary,
            'route': AppRoutes.accountManagement,
          },
          {
            'icon': Icons.receipt_long,
            'label': 'Transactions',
            'color': AppColors.secondary,
            'route': AppRoutes.transactionManagement,
          },
          {
            'icon': Icons.assessment,
            'label': 'Reports',
            'color': AppColors.info,
            'route': AppRoutes.reports,
          },
        ];

      case UserRole.admin:
      case UserRole.superAdmin:
        return [
          {
            'icon': Icons.people,
            'label': 'Users',
            'color': AppColors.primary,
            'route': AppRoutes.userManagement,
          },
          {
            'icon': Icons.business,
            'label': 'Branches',
            'color': AppColors.tertiary,
            'route': AppRoutes.branchManagement,
          },
          {
            'icon': Icons.analytics,
            'label': 'Analytics',
            'color': AppColors.info,
            'route': AppRoutes.analytics,
          },
          {
            'icon': Icons.settings,
            'label': 'Settings',
            'color': AppColors.warning,
            'route': AppRoutes.systemSettings,
          },
        ];

      case UserRole.branchManager:
        return [
          {
            'icon': Icons.people,
            'label': 'Customers',
            'color': AppColors.primary,
            'route': AppRoutes.customerManagement,
          },
          {
            'icon': Icons.analytics,
            'label': 'Analytics',
            'color': AppColors.info,
            'route': AppRoutes.analytics,
          },
          {
            'icon': Icons.assessment,
            'label': 'Reports',
            'color': AppColors.secondary,
            'route': AppRoutes.reports,
          },
          {
            'icon': Icons.business,
            'label': 'Branch',
            'color': AppColors.tertiary,
            'route': AppRoutes.branchManagement,
          },
        ];

      case UserRole.loanOfficer:
        return [
          {
            'icon': Icons.assignment,
            'label': 'Applications',
            'color': AppColors.primary,
            'route': AppRoutes.loanApplications,
          },
          {
            'icon': Icons.check_circle,
            'label': 'Approvals',
            'color': AppColors.success,
            'route': AppRoutes.loanApproval,
          },
          {
            'icon': Icons.account_balance,
            'label': 'Loans',
            'color': AppColors.warning,
            'route': AppRoutes.loans,
          },
          {
            'icon': Icons.people,
            'label': 'Customers',
            'color': AppColors.tertiary,
            'route': AppRoutes.customerManagement,
          },
        ];

      case UserRole.cardOfficer:
        return [
          {
            'icon': Icons.assignment,
            'label': 'Applications',
            'color': AppColors.primary,
            'route': AppRoutes.cardApplications,
          },
          {
            'icon': Icons.credit_card,
            'label': 'Cards',
            'color': AppColors.secondary,
            'route': AppRoutes.cardManagement,
          },
          {
            'icon': Icons.people,
            'label': 'Customers',
            'color': AppColors.tertiary,
            'route': AppRoutes.customerManagement,
          },
          {
            'icon': Icons.assessment,
            'label': 'Reports',
            'color': AppColors.info,
            'route': AppRoutes.reports,
          },
        ];

      default:
        print('⚠️ [HomeScreen] Unknown role: $role, returning empty actions');
        return [];
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'User') return '?';
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: AppTextStyles.labelLarge,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:vantedge/core/routes/app_routes.dart';
// import 'package:vantedge/core/theme/app_colors.dart';
// import 'package:vantedge/core/theme/app_text_styles.dart';
// import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
// import 'package:vantedge/features/auth/domain/entities/user_role.dart';

// /// Generic home screen that adapts to user role
// /// Displays role-specific content and actions
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthProvider>(
//       builder: (context, authProvider, child) {
//         final user = authProvider.user;

//         if (user == null) {
//           return Scaffold(
//             body: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(
//                     Icons.error_outline,
//                     size: 64,
//                     color: Colors.red,
//                   ),
//                   const SizedBox(height: 16),
//                   const Text('No user data available'),
//                   const SizedBox(height: 24),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.pushReplacementNamed(context, AppRoutes.login);
//                     },
//                     child: const Text('Go to Login'),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         return Scaffold(
//           appBar: AppBar(
//             title: Text('${user.role.displayName} Dashboard'),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.notifications_outlined),
//                 onPressed: () {
//                   Navigator.pushNamed(context, AppRoutes.notifications);
//                 },
//               ),
//               IconButton(
//                 icon: const Icon(Icons.settings_outlined),
//                 onPressed: () {
//                   Navigator.pushNamed(context, AppRoutes.settings);
//                 },
//               ),
//             ],
//           ),
//           body: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Welcome Header
//                 _buildWelcomeHeader(user.fullName, user.email, user.role),

//                 const SizedBox(height: 24),

//                 // Quick Actions (Role-based)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Quick Actions',
//                         style: AppTextStyles.titleLarge,
//                       ),
//                       const SizedBox(height: 16),
//                       _buildQuickActions(context, user.role),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 32),

//                 // User Information
//                 _buildUserInfoCard(user),

//                 const SizedBox(height: 24),

//                 // Logout Button
//                 _buildLogoutButton(context, authProvider),

//                 const SizedBox(height: 24),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildWelcomeHeader(String name, String email, UserRole role) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: _getRoleGradient(role),
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               CircleAvatar(
//                 radius: 32,
//                 backgroundColor: Colors.white.withOpacity(0.3),
//                 child: Text(
//                   _getInitials(name),
//                   style: AppTextStyles.titleLarge.copyWith(
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Welcome back,',
//                       style: AppTextStyles.bodyMedium.copyWith(
//                         color: Colors.white.withOpacity(0.9),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       name,
//                       style: AppTextStyles.headlineSmall.copyWith(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(
//               role.displayName,
//               style: AppTextStyles.labelMedium.copyWith(
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActions(BuildContext context, UserRole role) {
//     final actions = _getQuickActionsForRole(role);

//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 12,
//         mainAxisSpacing: 12,
//         childAspectRatio: 1.2,
//       ),
//       itemCount: actions.length,
//       itemBuilder: (context, index) {
//         final action = actions[index];
//         return _QuickActionCard(
//           icon: action['icon'] as IconData,
//           label: action['label'] as String,
//           color: action['color'] as Color,
//           onTap: () => Navigator.pushNamed(
//             context,
//             action['route'] as String,
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildUserInfoCard(user) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     Icons.person_outline,
//                     color: AppColors.primary,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Account Information',
//                     style: AppTextStyles.titleMedium,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               _InfoRow(label: 'User ID', value: user.id.toString()),
//               _InfoRow(label: 'Username', value: user.username),
//               _InfoRow(label: 'Email', value: user.email),
//               _InfoRow(label: 'Role', value: user.role.displayName),
//               if (user.customerId != null)
//                 _InfoRow(label: 'Customer ID', value: user.customerId!),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: SizedBox(
//         width: double.infinity,
//         child: OutlinedButton.icon(
//           onPressed: () => _handleLogout(context, authProvider),
//           icon: const Icon(Icons.logout),
//           label: const Text('Logout'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: Colors.red,
//             side: const BorderSide(color: Colors.red),
//             padding: const EdgeInsets.symmetric(vertical: 16),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _handleLogout(
//     BuildContext context,
//     AuthProvider authProvider,
//   ) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Logout'),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//             ),
//             child: const Text('Logout'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       await authProvider.logout();
//       if (context.mounted) {
//         Navigator.pushNamedAndRemoveUntil(
//           context,
//           AppRoutes.login,
//           (route) => false,
//         );
//       }
//     }
//   }

//   List<Color> _getRoleGradient(UserRole role) {
//     switch (role) {
//       case UserRole.customer:
//         return AppColors.gradientBlue;
//       case UserRole.employee:
//         return AppColors.gradientGreen;
//       case UserRole.admin:
//       case UserRole.superAdmin:
//         return AppColors.gradientPurple;
//       case UserRole.branchManager:
//         return AppColors.gradientPurple;
//       case UserRole.loanOfficer:
//         return AppColors.gradientGold;
//       case UserRole.cardOfficer:
//         return AppColors.gradientBlue;
//       default:
//         return AppColors.gradientBlue;
//     }
//   }

//   List<Map<String, dynamic>> _getQuickActionsForRole(UserRole role) {
//     switch (role) {
//       case UserRole.customer:
//         return [
//           {
//             'icon': Icons.account_balance_wallet,
//             'label': 'Accounts',
//             'color': AppColors.primary,
//             'route': AppRoutes.accounts,
//           },
//           {
//             'icon': Icons.swap_horiz,
//             'label': 'Transfer',
//             'color': AppColors.secondary,
//             'route': AppRoutes.transfer,
//           },
//           {
//             'icon': Icons.credit_card,
//             'label': 'Cards',
//             'color': AppColors.tertiary,
//             'route': AppRoutes.cards,
//           },
//           {
//             'icon': Icons.account_balance,
//             'label': 'Loans',
//             'color': AppColors.warning,
//             'route': AppRoutes.loans,
//           },
//         ];

//       case UserRole.employee:
//         return [
//           {
//             'icon': Icons.people,
//             'label': 'Customers',
//             'color': AppColors.primary,
//             'route': AppRoutes.customerManagement,
//           },
//           {
//             'icon': Icons.account_balance_wallet,
//             'label': 'Accounts',
//             'color': AppColors.tertiary,
//             'route': AppRoutes.accountManagement,
//           },
//           {
//             'icon': Icons.receipt_long,
//             'label': 'Transactions',
//             'color': AppColors.secondary,
//             'route': AppRoutes.transactionManagement,
//           },
//           {
//             'icon': Icons.assessment,
//             'label': 'Reports',
//             'color': AppColors.info,
//             'route': AppRoutes.reports,
//           },
//         ];

//       case UserRole.admin:
//       case UserRole.superAdmin:
//         return [
//           {
//             'icon': Icons.people,
//             'label': 'Users',
//             'color': AppColors.primary,
//             'route': AppRoutes.userManagement,
//           },
//           {
//             'icon': Icons.business,
//             'label': 'Branches',
//             'color': AppColors.tertiary,
//             'route': AppRoutes.branchManagement,
//           },
//           {
//             'icon': Icons.analytics,
//             'label': 'Analytics',
//             'color': AppColors.info,
//             'route': AppRoutes.analytics,
//           },
//           {
//             'icon': Icons.settings,
//             'label': 'Settings',
//             'color': AppColors.warning,
//             'route': AppRoutes.systemSettings,
//           },
//         ];

//       case UserRole.branchManager:
//         return [
//           {
//             'icon': Icons.people,
//             'label': 'Customers',
//             'color': AppColors.primary,
//             'route': AppRoutes.customerManagement,
//           },
//           {
//             'icon': Icons.analytics,
//             'label': 'Analytics',
//             'color': AppColors.info,
//             'route': AppRoutes.analytics,
//           },
//           {
//             'icon': Icons.assessment,
//             'label': 'Reports',
//             'color': AppColors.secondary,
//             'route': AppRoutes.reports,
//           },
//           {
//             'icon': Icons.business,
//             'label': 'Branch',
//             'color': AppColors.tertiary,
//             'route': AppRoutes.branchManagement,
//           },
//         ];

//       case UserRole.loanOfficer:
//         return [
//           {
//             'icon': Icons.assignment,
//             'label': 'Applications',
//             'color': AppColors.primary,
//             'route': AppRoutes.loanApplications,
//           },
//           {
//             'icon': Icons.check_circle,
//             'label': 'Approvals',
//             'color': AppColors.success,
//             'route': AppRoutes.loanApproval,
//           },
//           {
//             'icon': Icons.account_balance,
//             'label': 'Loans',
//             'color': AppColors.warning,
//             'route': AppRoutes.loans,
//           },
//           {
//             'icon': Icons.people,
//             'label': 'Customers',
//             'color': AppColors.tertiary,
//             'route': AppRoutes.customerManagement,
//           },
//         ];

//       case UserRole.cardOfficer:
//         return [
//           {
//             'icon': Icons.assignment,
//             'label': 'Applications',
//             'color': AppColors.primary,
//             'route': AppRoutes.cardApplications,
//           },
//           {
//             'icon': Icons.credit_card,
//             'label': 'Cards',
//             'color': AppColors.secondary,
//             'route': AppRoutes.cardManagement,
//           },
//           {
//             'icon': Icons.people,
//             'label': 'Customers',
//             'color': AppColors.tertiary,
//             'route': AppRoutes.customerManagement,
//           },
//           {
//             'icon': Icons.assessment,
//             'label': 'Reports',
//             'color': AppColors.info,
//             'route': AppRoutes.reports,
//           },
//         ];

//       default:
//         return [];
//     }
//   }

//   String _getInitials(String name) {
//     final parts = name.trim().split(' ');
//     if (parts.isEmpty) return '?';
//     if (parts.length == 1) {
//       return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
//     }
//     return (parts.first[0] + parts.last[0]).toUpperCase();
//   }
// }

// class _QuickActionCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;

//   const _QuickActionCard({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   icon,
//                   size: 28,
//                   color: color,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 label,
//                 style: AppTextStyles.labelLarge,
//                 textAlign: TextAlign.center,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _InfoRow extends StatelessWidget {
//   final String label;
//   final String value;

//   const _InfoRow({
//     required this.label,
//     required this.value,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 110,
//             child: Text(
//               label,
//               style: AppTextStyles.bodyMedium.copyWith(
//                 color: AppColors.textSecondary,
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               value,
//               style: AppTextStyles.bodyMedium.copyWith(
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.textPrimary,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }