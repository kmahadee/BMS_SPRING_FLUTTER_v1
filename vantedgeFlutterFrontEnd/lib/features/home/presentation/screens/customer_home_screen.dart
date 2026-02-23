// lib/features/home/presentation/screens/customer_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/core/theme/app_colors.dart';
import 'package:vantedge/core/theme/app_text_styles.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/shared/providers/badge_count_provider.dart';
import 'package:vantedge/shared/widgets/main_scaffold.dart';

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
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
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

        print(
            '✅ [CustomerHomeScreen] User data available, building customer dashboard');

        return MainScaffold(
          currentRoute:
              ModalRoute.of(context)?.settings.name ?? AppRoutes.customerHome,
          title: 'Customer Dashboard',
          showAppBar: true,
          showDrawer: true,
          showBottomNav: true,
          showNotifications: true,
          onNotificationTap: () {
            print(
                '👤 [CustomerHomeScreen] Navigating to notifications from app bar');
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Welcome banner ────────────────────────────────────────
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

                // ── Quick Actions ─────────────────────────────────────────
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

                      // Row 1 — Accounts · Transfer
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.account_balance_wallet,
                              label: 'Accounts',
                              color: AppColors.primary,
                              onTap: () {
                                print(
                                    '👤 [CustomerHomeScreen] Quick action: Accounts');
                                Navigator.pushNamed(
                                    context, AppRoutes.accounts);
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
                                print(
                                    '👤 [CustomerHomeScreen] Quick action: Transfer');
                                Navigator.pushNamed(
                                    context, AppRoutes.transfer);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 2 — Cards · My Loans
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.credit_card,
                              label: 'Cards',
                              color: AppColors.tertiary,
                              onTap: () {
                                print(
                                    '👤 [CustomerHomeScreen] Quick action: Cards');
                                Navigator.pushNamed(
                                    context, AppRoutes.cards);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // ── MY LOANS entry point ──────────────────────
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.account_balance_rounded,
                              label: 'My Loans',
                              color: AppColors.warning,
                              onTap: () {
                                print(
                                    '👤 [CustomerHomeScreen] Quick action: My Loans');
                                Navigator.pushNamed(
                                    context, AppRoutes.loans);
                              },
                            ),
                          ),
                          // ─────────────────────────────────────────────
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 3 — DPS · (future slot)
                      // Kept as a single-card row so the layout stays balanced
                      // when more actions are added later.
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.savings_rounded,
                              label: 'DPS',
                              color: const Color(0xFF00897B), // teal-600
                              onTap: () {
                                print(
                                    '👤 [CustomerHomeScreen] Quick action: DPS');
                                Navigator.pushNamed(context, AppRoutes.dps);
                              },
                            ),
                          ),
                          // Empty expanded placeholder keeps the row's first card
                          // the same width as cards in the rows above.
                          const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Account Information card ───────────────────────────────
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
                              Icon(Icons.person_outline,
                                  color: AppColors.primary),
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

                // ── Debug panel (debug builds only) ───────────────────────
                if (const bool.fromEnvironment('dart.vm.product') == false)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[200],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Debug Info:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text('User ID: ${user.id}',
                            style: const TextStyle(fontSize: 10)),
                        Text('Username: ${user.username}',
                            style: const TextStyle(fontSize: 10)),
                        Text('Email: ${user.email}',
                            style: const TextStyle(fontSize: 10)),
                        Text('Role: ${user.role}',
                            style: const TextStyle(fontSize: 10)),
                        Text('FullName: ${user.fullName}',
                            style: const TextStyle(fontSize: 10)),
                        Text('CustomerId: ${user.customerId}',
                            style: const TextStyle(fontSize: 10)),
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

// ── _QuickActionCard ──────────────────────────────────────────────────────────

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
                child: Icon(icon, size: 32, color: color),
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

// ── _InfoRow ──────────────────────────────────────────────────────────────────

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
