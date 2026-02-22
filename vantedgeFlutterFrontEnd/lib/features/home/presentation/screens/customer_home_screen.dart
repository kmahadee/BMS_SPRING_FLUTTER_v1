import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/core/theme/app_colors.dart';
import 'package:vantedge/core/theme/app_text_styles.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/shared/providers/badge_count_provider.dart';
import 'package:vantedge/shared/widgets/main_scaffold.dart';

/// Customer home screen
/// Main dashboard for customer users
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('\n👤 [CustomerHomeScreen] 🔨 BUILD METHOD CALLED');
    print('  - Route: ${ModalRoute.of(context)?.settings.name ?? 'unknown'}');
    print('  - Arguments: ${ModalRoute.of(context)?.settings.arguments}');
    
    return Consumer2<AuthProvider, BadgeCountProvider>(
      builder: (context, authProvider, badgeProvider, child) {
        final user = authProvider.user;
        
        print('👤 [CustomerHomeScreen] Consumer builder called');
        print('  - AuthProvider.isLoading: ${authProvider.isLoading}');
        print('  - AuthProvider.isAuthenticated: ${authProvider.isAuthenticated}');
        print('  - User: ${user?.email ?? 'null'}');
        print('  - User role: ${user?.role ?? 'null'}');
        print('  - User ID: ${user?.id ?? 'null'}');
        print('  - User fullName: ${user?.fullName ?? 'null'}');

        if (user == null) {
          print('⚠️ [CustomerHomeScreen] User is null! Showing error state');
          return const SimpleScaffold(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text('No user data available'),
                  SizedBox(height: 24),
                  Text(
                    'Debug: User is null in CustomerHomeScreen',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        print('✅ [CustomerHomeScreen] User data available, building customer dashboard');
        
        // Use MainScaffold which includes the drawer and bottom nav
        return MainScaffold(
          currentRoute: ModalRoute.of(context)?.settings.name ?? AppRoutes.customerHome,
          title: 'Customer Dashboard',
          showAppBar: true,
          showDrawer: true,
          showBottomNav: true,
          showNotifications: true,
          // notificationCount: badgeProvider.totalNotificationCount,
          onNotificationTap: () {
            print('👤 [CustomerHomeScreen] Navigating to notifications from app bar');
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.gradientBlue,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.fullName,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.account_balance_wallet,
                              label: 'Accounts',
                              color: AppColors.primary,
                              onTap: () {
                                print('👤 [CustomerHomeScreen] Quick action: Accounts');
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.accounts,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.swap_horiz,
                              label: 'Transfer',
                              color: AppColors.secondary,
                              onTap: () {
                                print('👤 [CustomerHomeScreen] Quick action: Transfer');
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.transfer,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.credit_card,
                              label: 'Cards',
                              color: AppColors.tertiary,
                              onTap: () {
                                print('👤 [CustomerHomeScreen] Quick action: Cards');
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.cards,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.account_balance,
                              label: 'Loans',
                              color: AppColors.warning,
                              onTap: () {
                                print('👤 [CustomerHomeScreen] Quick action: Loans');
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.loans,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // User Info Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Account Information',
                                style: AppTextStyles.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(
                            label: 'User ID',
                            value: user.id.toString(),
                          ),
                          _InfoRow(
                            label: 'Username',
                            value: user.username,
                          ),
                          _InfoRow(
                            label: 'Email',
                            value: user.email,
                          ),
                          _InfoRow(
                            label: 'Role',
                            value: user.role.displayName,
                          ),
                          if (user.customerId != null)
                            _InfoRow(
                              label: 'Customer ID',
                              value: user.customerId!,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text('User ID: ${user.id}', style: const TextStyle(fontSize: 10)),
                        Text('Username: ${user.username}', style: const TextStyle(fontSize: 10)),
                        Text('Email: ${user.email}', style: const TextStyle(fontSize: 10)),
                        Text('Role: ${user.role}', style: const TextStyle(fontSize: 10)),
                        Text('FullName: ${user.fullName}', style: const TextStyle(fontSize: 10)),
                        Text('CustomerId: ${user.customerId}', style: const TextStyle(fontSize: 10)),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: AppTextStyles.labelLarge,
                textAlign: TextAlign.center,
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

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
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

// /// Customer home screen
// /// Main dashboard for customer users
// class CustomerHomeScreen extends StatelessWidget {
//   const CustomerHomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Customer Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_outlined),
//             onPressed: () {
//               Navigator.pushNamed(context, AppRoutes.notifications);
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.settings_outlined),
//             onPressed: () {
//               Navigator.pushNamed(context, AppRoutes.settings);
//             },
//           ),
//         ],
//       ),
//       body: Consumer<AuthProvider>(
//         builder: (context, authProvider, child) {
//           final user = authProvider.user;

//           if (user == null) {
//             return const Center(
//               child: Text('No user data available'),
//             );
//           }

//           return SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Welcome Section
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: AppColors.gradientBlue,
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Welcome back,',
//                         style: AppTextStyles.bodyLarge.copyWith(
//                           color: Colors.white.withOpacity(0.9),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         user.fullName,
//                         style: AppTextStyles.headlineMedium.copyWith(
//                           color: Colors.white,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         user.email,
//                         style: AppTextStyles.bodyMedium.copyWith(
//                           color: Colors.white.withOpacity(0.8),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 24),

//                 // Quick Actions
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
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _QuickActionCard(
//                               icon: Icons.account_balance_wallet,
//                               label: 'Accounts',
//                               color: AppColors.primary,
//                               onTap: () => Navigator.pushNamed(
//                                 context,
//                                 AppRoutes.accounts,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: _QuickActionCard(
//                               icon: Icons.swap_horiz,
//                               label: 'Transfer',
//                               color: AppColors.secondary,
//                               onTap: () => Navigator.pushNamed(
//                                 context,
//                                 AppRoutes.transfer,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _QuickActionCard(
//                               icon: Icons.credit_card,
//                               label: 'Cards',
//                               color: AppColors.tertiary,
//                               onTap: () => Navigator.pushNamed(
//                                 context,
//                                 AppRoutes.cards,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: _QuickActionCard(
//                               icon: Icons.account_balance,
//                               label: 'Loans',
//                               color: AppColors.warning,
//                               onTap: () => Navigator.pushNamed(
//                                 context,
//                                 AppRoutes.loans,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 32),

//                 // User Info Card
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Account Information',
//                             style: AppTextStyles.titleMedium,
//                           ),
//                           const SizedBox(height: 16),
//                           _InfoRow(
//                             label: 'User ID',
//                             value: user.id.toString(),
//                           ),
//                           _InfoRow(
//                             label: 'Username',
//                             value: user.username,
//                           ),
//                           _InfoRow(
//                             label: 'Email',
//                             value: user.email,
//                           ),
//                           _InfoRow(
//                             label: 'Role',
//                             value: user.role.displayName,
//                           ),
//                           if (user.customerId != null)
//                             _InfoRow(
//                               label: 'Customer ID',
//                               value: user.customerId!,
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 24),

//                 // Logout Button
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: SizedBox(
//                     width: double.infinity,
//                     child: OutlinedButton.icon(
//                       onPressed: () => _handleLogout(context, authProvider),
//                       icon: const Icon(Icons.logout),
//                       label: const Text('Logout'),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.red,
//                         side: const BorderSide(color: Colors.red),
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 24),
//               ],
//             ),
//           );
//         },
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
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Logout'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       await authProvider.logout();
//       if (context.mounted) {
//         Navigator.pushReplacementNamed(context, AppRoutes.login);
//       }
//     }
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
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   icon,
//                   size: 32,
//                   color: color,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 label,
//                 style: AppTextStyles.labelLarge,
//                 textAlign: TextAlign.center,
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
//             width: 120,
//             child: Text(
//               label,
//               style: AppTextStyles.bodyMedium.copyWith(
//                 color: AppColors.textSecondary,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: AppTextStyles.bodyMedium.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }