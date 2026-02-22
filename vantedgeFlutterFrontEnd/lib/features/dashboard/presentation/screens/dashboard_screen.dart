import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/core/theme/app_colors.dart';
import 'package:vantedge/core/theme/app_text_styles.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/features/auth/domain/entities/user_role.dart';

/// Generic home screen that adapts to user role
/// Displays role-specific content and actions
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('\n🏠 [HomeScreen] 🔨 BUILD METHOD CALLED');
    print('  - Route: ${ModalRoute.of(context)?.settings.name ?? 'unknown'}');
    print('  - Arguments: ${ModalRoute.of(context)?.settings.arguments}');
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        print('🏠 [HomeScreen] Consumer builder called');
        print('  - AuthProvider.isLoading: ${authProvider.isLoading}');
        print('  - AuthProvider.isAuthenticated: ${authProvider.isAuthenticated}');
        print('  - User: ${user?.email ?? 'null'}');
        print('  - User role: ${user?.role ?? 'null'}');
        print('  - User ID: ${user?.id ?? 'null'}');
        print('  - User fullName: ${user?.fullName ?? 'null'}');

        if (user == null) {
          print('⚠️ [HomeScreen] User is null! Showing error state');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text('No user data available'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      print('🏠 [HomeScreen] Navigating to login from error state');
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                    child: const Text('Go to Login'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Debug: User is null in HomeScreen',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        print('✅ [HomeScreen] User data available, building dashboard for role: ${user.role}');
        
        return Scaffold(
          appBar: AppBar(
            title: Text('${user.role.displayName} Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  print('🏠 [HomeScreen] Navigating to notifications');
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  print('🏠 [HomeScreen] Navigating to settings');
                  Navigator.pushNamed(context, AppRoutes.settings);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                _buildWelcomeHeader(user.fullName ?? 'User', user.email, user.role),

                const SizedBox(height: 24),

                // Quick Actions (Role-based)
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
                      _buildQuickActions(context, user.role),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // User Information
                _buildUserInfoCard(user),

                const SizedBox(height: 24),

                // Logout Button
                _buildLogoutButton(context, authProvider),

                const SizedBox(height: 24),

                // Debug info
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
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                  ),
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
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, UserRole role) {
    final actions = _getQuickActionsForRole(role);
    print('🏠 [HomeScreen] Building quick actions for role: $role, count: ${actions.length}');
    
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
            print('🏠 [HomeScreen] Quick action tapped: ${action['label']} -> ${action['route']}');
            Navigator.pushNamed(
              context,
              action['route'] as String,
            );
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

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    print('🏠 [HomeScreen] Building logout button');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _handleLogout(context, authProvider),
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    print('🏠 [HomeScreen] Logout button pressed');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              print('🏠 [HomeScreen] Logout cancelled');
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              print('🏠 [HomeScreen] Logout confirmed');
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      print('🏠 [HomeScreen] Executing logout');
      await authProvider.logout();
      print('🏠 [HomeScreen] Logout completed, navigating to login');
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
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
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
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

// import 'package:vantedge/core/api/interceptors/dio_client.dart';
// import 'package:vantedge/core/constants/api_constants.dart';
// import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
// import 'package:vantedge/features/auth/domain/entities/user_role.dart';
// import 'package:vantedge/features/dashboard/data/models/dashboard_models.dart';
// import 'package:vantedge/features/dashboard/data/services/dashboard_service.dart';
// import '../widgets/account_summary_card.dart';
// import '../widgets/quick_action_button.dart';
// import '../widgets/recent_transactions_widget.dart';
// import '../widgets/alerts_widget.dart';
// import '../widgets/statistics_card.dart';
// import 'package:vantedge/core/widgets/shimmer_loader.dart';
// import 'package:vantedge/core/routes/app_routes.dart';


// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   late final DashboardService _dashboardService = DashboardService(
//     dioClient: context.read<DioClient>(),
//   );

//   bool _isRefreshing = false;
//   bool _isLoading = true;

//   Map<String, dynamic>? _accountsSummary;
//   List<CardListItem> _customerCards = [];
//   List<LoanListItem> _customerLoans = [];
//   List<TransactionItem> _recentTransactions = [];
//   bool _transactionsLoading = false;

//   DashboardStatistics? _branchStats;
//   DashboardStatistics? _bankStats;
//   DashboardStatistics? _loanStats;
//   DashboardStatistics? _cardStats;

//   String? _errorMessage;

//   // ── Lifecycle ──────────────────────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadDashboardData();
//     });
//   }

//   // ── Data Loading ───────────────────────────────────────────────────────────

//   Future<void> _loadDashboardData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final userRole = authProvider.user?.role;

//       switch (userRole) {
//         case UserRole.customer:
//           await _loadCustomerData();
//           break;
//         case UserRole.branchManager:
//           await _loadBranchManagerData();
//           break;
//         case UserRole.loanOfficer:
//           await _loadLoanOfficerData();
//           break;
//         case UserRole.cardOfficer:
//           await _loadCardOfficerData();
//           break;
//         case UserRole.admin:
//         case UserRole.superAdmin:
//           await _loadAdminData();
//           break;
//         default:
//           break;
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _loadCustomerData() async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final customerId = authProvider.user?.customerId;

//     if (customerId == null) throw Exception('Customer ID not found');

//     final results = await Future.wait([
//       _dashboardService.getCustomerAccountsSummary(customerId),
//       _dashboardService.getCustomerCards(customerId),
//       _dashboardService.getCustomerLoans(customerId),
//     ]);

//     setState(() {
//       _accountsSummary = results[0] as Map<String, dynamic>;
//       _customerCards = (results[1] as List)
//           .map((j) => CardListItem.fromJson(j))
//           .toList();
//       _customerLoans = (results[2] as List)
//           .map((j) => LoanListItem.fromJson(j))
//           .toList();
//     });

//     _loadRecentTransactions(customerId);
//   }

//   Future<void> _loadRecentTransactions(String customerId) async {
//     setState(() => _transactionsLoading = true);
//     try {
//       final dioClient = context.read<DioClient>();
//       final response = await dioClient.get(ApiConstants.getAllTransactions);

//       if (response.data['success'] == true) {
//         final all = List<Map<String, dynamic>>.from(
//           response.data['data'] ?? [],
//         );

//         final filtered = all
//             .where(
//               (tx) =>
//                   tx['customerId'] == customerId ||
//                   tx['fromCustomerId'] == customerId ||
//                   tx['toCustomerId'] == customerId,
//             )
//             .toList();

//         filtered.sort((a, b) {
//           final dateA = _parseDate(a);
//           final dateB = _parseDate(b);
//           return dateB.compareTo(dateA);
//         });

//         final recent = filtered.take(5).map((tx) {
//           final typeRaw =
//               (tx['transactionType'] ?? tx['type'] ?? 'TRANSFER') as String;
//           final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
//           final date = _parseDate(tx);
//           final isCredit =
//               typeRaw.toUpperCase().contains('DEPOSIT') ||
//               typeRaw.toUpperCase().contains('CREDIT') ||
//               (tx['toCustomerId'] == customerId &&
//                   typeRaw.toUpperCase().contains('TRANSFER'));

//           return TransactionItem(
//             type: _formatTransactionType(typeRaw),
//             amount: amount,
//             date: date,
//             description: (tx['description'] as String?) ?? typeRaw,
//             isCredit: isCredit,
//           );
//         }).toList();

//         setState(() => _recentTransactions = recent);
//       }
//     } catch (e) {
//       // Silently fail — recent transactions are non-critical
//     } finally {
//       if (mounted) setState(() => _transactionsLoading = false);
//     }
//   }

//   DateTime _parseDate(Map<String, dynamic> tx) {
//     final raw =
//         tx['transactionDate'] ??
//         tx['timestamp'] ??
//         tx['createdAt'] ??
//         tx['date'];
//     if (raw is String) {
//       return DateTime.tryParse(raw) ?? DateTime.now();
//     }
//     return DateTime.now();
//   }

//   String _formatTransactionType(String raw) {
//     return raw
//         .replaceAll('_', ' ')
//         .split(' ')
//         .map(
//           (w) => w.isEmpty
//               ? ''
//               : w[0].toUpperCase() + w.substring(1).toLowerCase(),
//         )
//         .join(' ');
//   }

//   Future<int?> _resolveBranchManagerBranchId() async {
//     try {
//       final dioClient = context.read<DioClient>();
//       final response = await dioClient.get(
//         '${ApiConstants.apiPrefix}/users/me',
//       );

//       if (response.data['success'] == true) {
//         final data = response.data['data'] as Map<String, dynamic>?;
//         final raw = data?['branchId'];
//         if (raw != null) return (raw as num).toInt();
//       }
//     } catch (_) {}
//     return null;
//   }

//   Future<void> _loadBranchManagerData() async {
//     final branchId = await _resolveBranchManagerBranchId();

//     if (branchId == null) {
//       setState(() {
//         _errorMessage =
//             'Could not determine your branch. Please contact your administrator.';
//       });
//       return;
//     }

//     final stats = await _dashboardService.calculateBranchStatistics(branchId);
//     setState(() {
//       _branchStats = DashboardStatistics.fromBranchData(stats);
//     });
//   }

//   Future<void> _loadLoanOfficerData() async {
//     final stats = await _dashboardService.calculateLoanStatistics();
//     setState(() {
//       _loanStats = DashboardStatistics.fromLoanData(stats);
//     });
//   }

//   Future<void> _loadCardOfficerData() async {
//     final stats = await _dashboardService.calculateCardStatistics();
//     setState(() {
//       _cardStats = DashboardStatistics.fromCardData(stats);
//     });
//   }

//   Future<void> _loadAdminData() async {
//     final stats = await _dashboardService.calculateBankStatistics();
//     setState(() {
//       _bankStats = DashboardStatistics.fromBankData(stats);
//     });
//   }

//   Future<void> _handleRefresh() async {
//     setState(() => _isRefreshing = true);
//     await _loadDashboardData();
//     setState(() => _isRefreshing = false);
//   }

//   // ── Shimmer ────────────────────────────────────────────────────────────────

//   Widget _buildShimmerLoader() {
//     return SingleChildScrollView(
//       child: Column(
//         children: List.generate(4, (index) => const ShimmerCard(height: 100)),
//       ),
//     );
//   }

//   // ── Root Build ─────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthProvider>(
//       builder: (context, authProvider, child) {
//         final user = authProvider.user;
//         final userRole = user?.role;

//         return Scaffold(
//           appBar: AppBar(
//             title: const Text('Dashboard'),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.notifications_outlined),
//                 onPressed: () =>
//                     Navigator.pushNamed(context, AppRoutes.notifications),
//               ),
//             ],
//           ),
//           body: RefreshIndicator(
//             onRefresh: _handleRefresh,
//             child: _isLoading
//                 ? _buildShimmerLoader()
//                 : _errorMessage != null
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(
//                           Icons.error_outline,
//                           size: 64,
//                           color: Colors.red,
//                         ),
//                         const SizedBox(height: 16),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 32),
//                           child: Text(
//                             _errorMessage!,
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(color: Colors.red),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: _loadDashboardData,
//                           child: const Text('Retry'),
//                         ),
//                       ],
//                     ),
//                   )
//                 : SingleChildScrollView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildGreetingSection(context, authProvider),
//                         const SizedBox(height: 8),
//                         if (userRole == UserRole.customer)
//                           _buildCustomerDashboard(context)
//                         else if (userRole == UserRole.branchManager)
//                           _buildBranchManagerDashboard(context)
//                         else if (userRole == UserRole.loanOfficer)
//                           _buildLoanOfficerDashboard(context)
//                         else if (userRole == UserRole.cardOfficer)
//                           _buildCardOfficerDashboard(context)
//                         else if (userRole == UserRole.admin ||
//                             userRole == UserRole.superAdmin)
//                           _buildAdminDashboard(context)
//                         else
//                           _buildDefaultDashboard(context),
//                         const SizedBox(height: 16),
//                       ],
//                     ),
//                   ),
//           ),
//         );
//       },
//     );
//   }

//   // ── Greeting ───────────────────────────────────────────────────────────────

//   Widget _buildGreetingSection(
//     BuildContext context,
//     AuthProvider authProvider,
//   ) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final hour = DateTime.now().hour;
//     final greeting = hour < 12
//         ? 'Good Morning'
//         : hour < 17
//         ? 'Good Afternoon'
//         : 'Good Evening';

//     final user = authProvider.user;
//     final displayName = user?.fullName ?? user?.username ?? 'User';
//     final userRole = user?.role;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   greeting,
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   displayName,
//                   style: theme.textTheme.headlineSmall?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 if (userRole != null) ...[
//                   const SizedBox(height: 4),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: colorScheme.primaryContainer,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       userRole.displayName,
//                       style: theme.textTheme.labelSmall?.copyWith(
//                         color: colorScheme.onPrimaryContainer,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: colorScheme.primary,
//             child: Text(
//               displayName[0].toUpperCase(),
//               style: theme.textTheme.headlineMedium?.copyWith(
//                 color: colorScheme.onPrimary,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Customer Dashboard ─────────────────────────────────────────────────────

//   Widget _buildCustomerDashboard(BuildContext context) {
//     final totalBalance = _accountsSummary?['totalBalance'] as double? ?? 0.0;
//     final accountCount = _accountsSummary?['accountCount'] as int? ?? 0;

//     return Column(
//       children: [
//         AccountSummaryCard(
//           totalBalance: totalBalance,
//           accountCount: accountCount,
//           isLoading: _isRefreshing,
//           onTap: () => Navigator.pushNamed(context, AppRoutes.accounts),
//         ),

//         // ── Quick Actions (wired) ────────────────────────────────────────────
//         _buildQuickActionsSection(context, [
//           QuickActionButton(
//             icon: Icons.swap_horiz_rounded,
//             label: 'Transfer',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.transfer),
//           ),
//           QuickActionButton(
//             icon: Icons.add_circle_outline_rounded,
//             label: 'Deposit',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.deposit),
//           ),
//           QuickActionButton(
//             icon: Icons.remove_circle_outline_rounded,
//             label: 'Withdraw',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.withdrawal),
//           ),
//           QuickActionButton(
//             icon: Icons.history_rounded,
//             label: 'History',
//             onTap: () =>
//                 Navigator.pushNamed(context, AppRoutes.transactionHistory),
//           ),
//         ]),

//         // ── Recent Transactions (wired) ─────────────────────────────────────
//         RecentTransactionsWidget(
//           transactions: _recentTransactions,
//           isLoading: _transactionsLoading,
//           onViewAll: () =>
//               Navigator.pushNamed(context, AppRoutes.transactionHistory),
//         ),

//         if (_customerCards.isNotEmpty) _buildCustomerCardsSection(context),
//         if (_customerLoans.isNotEmpty) _buildCustomerLoansSection(context),

//         AlertsWidget(
//           alerts: _getMockAlerts(),
//           isLoading: _isRefreshing,
//           onViewAll: () {},
//         ),
//       ],
//     );
//   }

//   // ── Customer Cards Section ─────────────────────────────────────────────────

//   Widget _buildCustomerCardsSection(BuildContext context) {
//     final theme = Theme.of(context);
//     final activeCards = _customerCards.where((c) => c.isActive).length;

//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'My Cards',
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _buildInfoTile(
//                     'Total Cards',
//                     _customerCards.length.toString(),
//                     Icons.credit_card,
//                   ),
//                   _buildInfoTile(
//                     'Active',
//                     activeCards.toString(),
//                     Icons.check_circle,
//                     color: Colors.green,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Customer Loans Section ─────────────────────────────────────────────────

//   Widget _buildCustomerLoansSection(BuildContext context) {
//     final theme = Theme.of(context);
//     final activeLoans = _customerLoans.where((l) => l.isDisbursed).length;
//     final totalOutstanding = _customerLoans
//         .where((l) => l.isDisbursed)
//         .fold(0.0, (sum, loan) => sum + loan.outstandingBalance);

//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'My Loans',
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _buildInfoTile(
//                     'Active Loans',
//                     activeLoans.toString(),
//                     Icons.account_balance,
//                   ),
//                   _buildInfoTile(
//                     'Outstanding',
//                     '৳${totalOutstanding.toStringAsFixed(0)}',
//                     Icons.trending_up,
//                     color: Colors.orange,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Info Tile ──────────────────────────────────────────────────────────────

//   Widget _buildInfoTile(
//     String label,
//     String value,
//     IconData icon, {
//     Color? color,
//   }) {
//     final theme = Theme.of(context);
//     final tileColor = color ?? theme.colorScheme.primary;
//     return Column(
//       children: [
//         Icon(icon, color: tileColor, size: 32),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: theme.textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: tileColor,
//           ),
//         ),
//         Text(
//           label,
//           style: theme.textTheme.bodySmall?.copyWith(
//             color: theme.colorScheme.onSurfaceVariant,
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Branch Manager Dashboard ───────────────────────────────────────────────

//   Widget _buildBranchManagerDashboard(BuildContext context) {
//     final theme = Theme.of(context);
//     final stats = _branchStats;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             'Branch Overview',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),

//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Accounts',
//               value: (stats?.totalAccounts ?? 0).toString(),
//               icon: Icons.account_balance_wallet,
//               onTap: () => Navigator.pushNamed(context, AppRoutes.accounts),
//             ),
//             StatisticsCard(
//               title: 'Active Accounts',
//               value: (stats?.activeAccounts ?? 0).toString(),
//               icon: Icons.check_circle,
//               color: Colors.green,
//               onTap: () => Navigator.pushNamed(context, AppRoutes.accounts),
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Deposits',
//               value: (stats?.totalDeposits ?? 0).toStringAsFixed(0),
//               icon: Icons.trending_up,
//               color: Colors.teal,
//               isCurrency: true,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Pending Actions',
//               value: '0',
//               icon: Icons.pending_actions,
//               color: Colors.orange,
//               onTap: () {},
//             ),
//           ],
//         ),

//         _buildQuickActionsSection(context, [
//           QuickActionButton(
//             icon: Icons.person_add,
//             label: 'New Customer',
//             onTap: () =>
//                 Navigator.pushNamed(context, AppRoutes.customerManagement),
//           ),
//           QuickActionButton(
//             icon: Icons.check_circle,
//             label: 'Approvals',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.loanApproval),
//           ),
//           QuickActionButton(
//             icon: Icons.assessment,
//             label: 'Reports',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
//           ),
//           QuickActionButton(
//             icon: Icons.people,
//             label: 'Staff',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.userManagement),
//           ),
//         ]),

//         AlertsWidget(
//           alerts: _getMockManagerAlerts(),
//           isLoading: _isRefreshing,
//         ),
//       ],
//     );
//   }

//   // ── Loan Officer Dashboard ─────────────────────────────────────────────────

//   Widget _buildLoanOfficerDashboard(BuildContext context) {
//     final theme = Theme.of(context);
//     final loanStats = _loanStats;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             'Loan Management',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),

//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Pending Applications',
//               value: (loanStats?.pendingLoans ?? 0).toString(),
//               icon: Icons.pending,
//               color: Colors.orange,
//               onTap: () =>
//                   Navigator.pushNamed(context, AppRoutes.loanApplications),
//             ),
//             StatisticsCard(
//               title: 'Approved Loans',
//               value: (loanStats?.approvedLoans ?? 0).toString(),
//               icon: Icons.check_circle,
//               color: Colors.green,
//               onTap: () =>
//                   Navigator.pushNamed(context, AppRoutes.loanApplications),
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Disbursed',
//               value: (loanStats?.disbursedLoans ?? 0).toString(),
//               icon: Icons.account_balance,
//               color: Colors.blue,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Total Disbursed',
//               value: (loanStats?.totalLoanAmount ?? 0).toStringAsFixed(0),
//               icon: Icons.payments,
//               color: Colors.purple,
//               isCurrency: true,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Loans',
//               value: (loanStats?.totalLoans ?? 0).toString(),
//               icon: Icons.assignment,
//               color: Colors.teal,
//               onTap: () => Navigator.pushNamed(context, AppRoutes.loans),
//             ),
//             StatisticsCard(
//               title: 'Outstanding',
//               value: (loanStats?.totalOutstanding ?? 0).toStringAsFixed(0),
//               icon: Icons.trending_up,
//               color: Colors.red,
//               isCurrency: true,
//               onTap: () {},
//             ),
//           ],
//         ),

//         _buildQuickActionsSection(context, [
//           QuickActionButton(
//             icon: Icons.add_circle,
//             label: 'New Loan',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.loanApplication),
//           ),
//           QuickActionButton(
//             icon: Icons.pending_actions,
//             label: 'Review',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.loanApproval),
//           ),
//           QuickActionButton(
//             icon: Icons.payment,
//             label: 'Disburse',
//             onTap: () =>
//                 Navigator.pushNamed(context, AppRoutes.loanApplications),
//           ),
//           QuickActionButton(
//             icon: Icons.history,
//             label: 'History',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.loans),
//           ),
//         ]),

//         AlertsWidget(alerts: _getMockLoanAlerts(), isLoading: _isRefreshing),
//       ],
//     );
//   }

//   // ── Card Officer Dashboard ─────────────────────────────────────────────────

//   Widget _buildCardOfficerDashboard(BuildContext context) {
//     final theme = Theme.of(context);
//     final cardStats = _cardStats;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             'Card Management',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),

//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Pending Requests',
//               value: (cardStats?.pendingCards ?? 0).toString(),
//               icon: Icons.pending,
//               color: Colors.orange,
//               onTap: () =>
//                   Navigator.pushNamed(context, AppRoutes.cardApplications),
//             ),
//             StatisticsCard(
//               title: 'Active Cards',
//               value: (cardStats?.activeCards ?? 0).toString(),
//               icon: Icons.credit_card,
//               color: Colors.green,
//               onTap: () => Navigator.pushNamed(context, AppRoutes.cards),
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Blocked Cards',
//               value: (cardStats?.blockedCards ?? 0).toString(),
//               icon: Icons.block,
//               color: Colors.red,
//               onTap: () => Navigator.pushNamed(context, AppRoutes.cards),
//             ),
//             StatisticsCard(
//               title: 'Total Cards',
//               value: (cardStats?.totalCards ?? 0).toString(),
//               icon: Icons.add_card,
//               color: Colors.blue,
//               onTap: () => Navigator.pushNamed(context, AppRoutes.cards),
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Credit Limit',
//               value: (cardStats?.totalCreditLimit ?? 0).toStringAsFixed(0),
//               icon: Icons.account_balance_wallet,
//               color: Colors.purple,
//               isCurrency: true,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'System Health',
//               value:
//                   '${((cardStats?.activeCards ?? 0) / (cardStats?.totalCards ?? 1) * 100).toStringAsFixed(0)}%',
//               icon: Icons.health_and_safety,
//               color: Colors.teal,
//               onTap: () {},
//             ),
//           ],
//         ),

//         _buildQuickActionsSection(context, [
//           QuickActionButton(
//             icon: Icons.add_card,
//             label: 'Issue Card',
//             onTap: () =>
//                 Navigator.pushNamed(context, AppRoutes.cardApplications),
//           ),
//           QuickActionButton(
//             icon: Icons.block,
//             label: 'Block Card',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.cardManagement),
//           ),
//           QuickActionButton(
//             icon: Icons.lock_reset,
//             label: 'Reset PIN',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.cardManagement),
//           ),
//           QuickActionButton(
//             icon: Icons.assignment,
//             label: 'Requests',
//             onTap: () =>
//                 Navigator.pushNamed(context, AppRoutes.cardApplications),
//           ),
//         ]),

//         AlertsWidget(alerts: _getMockCardAlerts(), isLoading: _isRefreshing),
//       ],
//     );
//   }

//   // ── Admin Dashboard ────────────────────────────────────────────────────────

//   Widget _buildAdminDashboard(BuildContext context) {
//     final theme = Theme.of(context);
//     final stats = _bankStats;
//     final txVolume = stats?.totalDeposits ?? 0.0;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             'System Overview',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),

//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Customers',
//               value: (stats?.totalCustomers ?? 0).toString(),
//               icon: Icons.people,
//               onTap: () =>
//                   Navigator.pushNamed(context, AppRoutes.customerManagement),
//             ),
//             StatisticsCard(
//               title: 'Active Branches',
//               value: (stats?.activeBranches ?? 0).toString(),
//               icon: Icons.location_on,
//               color: Colors.blue,
//               onTap: () =>
//                   Navigator.pushNamed(context, AppRoutes.branchManagement),
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Accounts',
//               value: (stats?.totalAccounts ?? 0).toString(),
//               icon: Icons.account_balance_wallet,
//               color: Colors.green,
//               onTap: () =>
//                   Navigator.pushNamed(context, AppRoutes.accountManagement),
//             ),
//             StatisticsCard(
//               title: 'Total Deposits',
//               value: (stats?.totalDeposits ?? 0).toStringAsFixed(0),
//               icon: Icons.trending_up,
//               color: Colors.purple,
//               isCurrency: true,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Active Loans',
//               value: (stats?.totalLoans ?? 0).toString(),
//               icon: Icons.account_balance,
//               color: Colors.teal,
//               onTap: () => Navigator.pushNamed(context, AppRoutes.loans),
//             ),
//             StatisticsCard(
//               title: 'Active Cards',
//               value: (stats?.totalCards ?? 0).toString(),
//               icon: Icons.credit_card,
//               color: Colors.orange,
//               onTap: () => Navigator.pushNamed(context, AppRoutes.cards),
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Branches',
//               value: (stats?.totalBranches ?? 0).toString(),
//               icon: Icons.location_city,
//               color: Colors.indigo,
//               onTap: () =>
//                   Navigator.pushNamed(context, AppRoutes.branchManagement),
//             ),
//             StatisticsCard(
//               title: 'Loan Portfolio',
//               value: (stats?.totalLoanAmount ?? 0).toStringAsFixed(0),
//               icon: Icons.pie_chart,
//               color: Colors.deepOrange,
//               isCurrency: true,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Transaction Volume',
//               value: txVolume.toStringAsFixed(0),
//               icon: Icons.swap_horiz,
//               color: Colors.cyan,
//               isCurrency: true,
//               onTap: () => Navigator.pushNamed(
//                   context, AppRoutes.transactionManagement),
//             ),
//             StatisticsCard(
//               title: 'Total Users',
//               value: (stats?.totalCustomers ?? 0).toString(),
//               icon: Icons.manage_accounts,
//               color: Colors.brown,
//               onTap: () =>
//                   Navigator.pushNamed(context, AppRoutes.userManagement),
//             ),
//           ],
//         ),

//         _buildQuickActionsSection(context, [
//           QuickActionButton(
//             icon: Icons.person_add,
//             label: 'Add User',
//             onTap: () =>
//                 Navigator.pushNamed(context, AppRoutes.userManagement),
//           ),
//           QuickActionButton(
//             icon: Icons.location_city,
//             label: 'Branches',
//             onTap: () =>
//                 Navigator.pushNamed(context, AppRoutes.branchManagement),
//           ),
//           QuickActionButton(
//             icon: Icons.analytics,
//             label: 'Analytics',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
//           ),
//           QuickActionButton(
//             icon: Icons.settings,
//             label: 'Settings',
//             onTap: () => Navigator.pushNamed(context, AppRoutes.systemSettings),
//           ),
//         ]),

//         AlertsWidget(alerts: _getMockAdminAlerts(), isLoading: _isRefreshing),
//       ],
//     );
//   }

//   // ── Default / Fallback Dashboard ───────────────────────────────────────────

//   Widget _buildDefaultDashboard(BuildContext context) {
//     return Column(
//       children: const [
//         SizedBox(height: 40),
//         Icon(Icons.dashboard, size: 80, color: Colors.grey),
//         SizedBox(height: 16),
//         Text(
//           'Dashboard',
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 8),
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 32),
//           child: Text(
//             'Your personalized dashboard will appear here',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Quick Actions Shell ────────────────────────────────────────────────────

//   Widget _buildQuickActionsSection(
//     BuildContext context,
//     List<QuickActionButton> actions,
//   ) {
//     final theme = Theme.of(context);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//           child: Text(
//             'Quick Actions',
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 4,
//             mainAxisSpacing: 12,
//             crossAxisSpacing: 12,
//             children: actions,
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Mock Alerts ────────────────────────────────────────────────────────────

//   List<AlertItem> _getMockAlerts() => [
//     AlertItem(
//       title: 'Payment Due',
//       message: 'Your credit card payment is due in 3 days',
//       type: AlertType.warning,
//       timestamp: DateTime.now(),
//     ),
//     AlertItem(
//       title: 'Low Balance',
//       message: 'Your savings account balance is below minimum',
//       type: AlertType.warning,
//       timestamp: DateTime.now().subtract(const Duration(hours: 2)),
//     ),
//   ];

//   List<AlertItem> _getMockManagerAlerts() => [
//     AlertItem(
//       title: 'Branch Accounts',
//       message:
//           '${_branchStats?.totalAccounts ?? 0} total accounts in your branch',
//       type: AlertType.info,
//       timestamp: DateTime.now(),
//     ),
//     AlertItem(
//       title: 'Active Status',
//       message:
//           '${_branchStats?.activeAccounts ?? 0} accounts are currently active',
//       type: AlertType.success,
//       timestamp: DateTime.now(),
//     ),
//   ];

//   List<AlertItem> _getMockLoanAlerts() => [
//     AlertItem(
//       title: 'New Applications',
//       message:
//           '${_loanStats?.pendingLoans ?? 0} loan applications awaiting review',
//       type: AlertType.warning,
//       timestamp: DateTime.now(),
//     ),
//     AlertItem(
//       title: 'Ready for Disbursement',
//       message: '${_loanStats?.approvedLoans ?? 0} loans approved and ready',
//       type: AlertType.success,
//       timestamp: DateTime.now(),
//     ),
//   ];

//   List<AlertItem> _getMockCardAlerts() => [
//     AlertItem(
//       title: 'Card Requests',
//       message: '${_cardStats?.pendingCards ?? 0} pending card requests',
//       type: AlertType.warning,
//       timestamp: DateTime.now(),
//     ),
//     AlertItem(
//       title: 'Blocked Cards',
//       message: '${_cardStats?.blockedCards ?? 0} cards currently blocked',
//       type: AlertType.error,
//       timestamp: DateTime.now(),
//     ),
//   ];

//   List<AlertItem> _getMockAdminAlerts() => [
//     AlertItem(
//       title: 'System Overview',
//       message:
//           '${_bankStats?.totalCustomers ?? 0} total customers across all branches',
//       type: AlertType.info,
//       timestamp: DateTime.now(),
//     ),
//     AlertItem(
//       title: 'Active Operations',
//       message:
//           '${_bankStats?.activeBranches ?? 0} branches actively operating',
//       type: AlertType.success,
//       timestamp: DateTime.now(),
//     ),
//   ];
// }











// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   late final DashboardService _dashboardService = DashboardService(
//     dioClient: context.read<DioClient>(),
//   );

//   bool _isRefreshing = false;
//   bool _isLoading = true;

//   // Customer
//   Map<String, dynamic>? _accountsSummary;
//   List<CardListItem> _customerCards = [];
//   List<LoanListItem> _customerLoans = [];
//   List<TransactionItem> _recentTransactions = [];
//   bool _transactionsLoading = false;

//   // Branch manager
//   DashboardStatistics? _branchStats;

//   // Bank-wide (admin)
//   DashboardStatistics? _bankStats;

//   // Loan officer
//   DashboardStatistics? _loanStats;

//   // Card officer
//   DashboardStatistics? _cardStats;

//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadDashboardData();
//     });
//   }

//   // ── Data loading ──────────────────────────────────────────────────────────

//   Future<void> _loadDashboardData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final userRole = authProvider.user?.role;

//       switch (userRole) {
//         case UserRole.customer:
//           await _loadCustomerData();
//           break;
//         case UserRole.branchManager:
//           await _loadBranchManagerData();
//           break;
//         case UserRole.loanOfficer:
//           await _loadLoanOfficerData();
//           break;
//         case UserRole.cardOfficer:
//           await _loadCardOfficerData();
//           break;
//         case UserRole.admin:
//         case UserRole.superAdmin:
//           await _loadAdminData();
//           break;
//         default:
//           break;
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _loadCustomerData() async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final customerId = authProvider.user?.customerId;

//     if (customerId == null) throw Exception('Customer ID not found');

//     final results = await Future.wait([
//       _dashboardService.getCustomerAccountsSummary(customerId),
//       _dashboardService.getCustomerCards(customerId),
//       _dashboardService.getCustomerLoans(customerId),
//     ]);

//     setState(() {
//       _accountsSummary = results[0] as Map<String, dynamic>;
//       _customerCards = (results[1] as List)
//           .map((j) => CardListItem.fromJson(j))
//           .toList();
//       _customerLoans = (results[2] as List)
//           .map((j) => LoanListItem.fromJson(j))
//           .toList();
//     });

//     // Load recent transactions separately so the main card shows immediately
//     _loadRecentTransactions(customerId);
//   }

//   /// Fetches the last 5 transactions for the customer.
//   /// Calls GET /api/transactions and filters client-side by customerId,
//   /// since there is no dedicated customer-transactions endpoint in this API.
//   Future<void> _loadRecentTransactions(String customerId) async {
//     setState(() => _transactionsLoading = true);
//     try {
//       final dioClient = context.read<DioClient>();
//       final response = await dioClient.get(ApiConstants.getAllTransactions);

//       if (response.data['success'] == true) {
//         final all = List<Map<String, dynamic>>.from(
//           response.data['data'] ?? [],
//         );

//         // Filter to this customer's transactions and take the 5 most recent
//         final filtered = all
//             .where(
//               (tx) =>
//                   tx['customerId'] == customerId ||
//                   tx['fromCustomerId'] == customerId ||
//                   tx['toCustomerId'] == customerId,
//             )
//             .toList();

//         // Sort descending by date (newest first)
//         filtered.sort((a, b) {
//           final dateA = _parseDate(a);
//           final dateB = _parseDate(b);
//           return dateB.compareTo(dateA);
//         });

//         final recent = filtered.take(5).map((tx) {
//           final typeRaw =
//               (tx['transactionType'] ?? tx['type'] ?? 'TRANSFER') as String;
//           final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
//           final date = _parseDate(tx);
//           final isCredit =
//               typeRaw.toUpperCase().contains('DEPOSIT') ||
//               typeRaw.toUpperCase().contains('CREDIT') ||
//               (tx['toCustomerId'] == customerId &&
//                   typeRaw.toUpperCase().contains('TRANSFER'));

//           return TransactionItem(
//             type: _formatTransactionType(typeRaw),
//             amount: amount,
//             date: date,
//             description: (tx['description'] as String?) ?? typeRaw,
//             isCredit: isCredit,
//           );
//         }).toList();

//         setState(() => _recentTransactions = recent);
//       }
//     } catch (e) {
//       // Non-fatal: just leave the list empty
//     } finally {
//       if (mounted) setState(() => _transactionsLoading = false);
//     }
//   }

//   DateTime _parseDate(Map<String, dynamic> tx) {
//     final raw =
//         tx['transactionDate'] ??
//         tx['timestamp'] ??
//         tx['createdAt'] ??
//         tx['date'];
//     if (raw is String) {
//       return DateTime.tryParse(raw) ?? DateTime.now();
//     }
//     return DateTime.now();
//   }

//   String _formatTransactionType(String raw) {
//     return raw
//         .replaceAll('_', ' ')
//         .split(' ')
//         .map(
//           (w) => w.isEmpty
//               ? ''
//               : w[0].toUpperCase() + w.substring(1).toLowerCase(),
//         )
//         .join(' ');
//   }

//   /// Resolves the branch manager's actual branchId from /api/users/me
//   /// instead of relying on the hardcoded placeholder value.
//   Future<int?> _resolveBranchManagerBranchId() async {
//     try {
//       final dioClient = context.read<DioClient>();
//       // GET /api/users/me — returns UserResponseDTO which includes branchId
//       final response = await dioClient.get(
//         '${ApiConstants.apiPrefix}/users/me',
//       );

//       if (response.data['success'] == true) {
//         final data = response.data['data'] as Map<String, dynamic>?;
//         final raw = data?['branchId'];
//         if (raw != null) return (raw as num).toInt();
//       }
//     } catch (_) {
//       // Fallback to null — the dashboard will show zeros rather than crash
//     }
//     return null;
//   }

//   Future<void> _loadBranchManagerData() async {
//     // ✅ Fixed: resolve actual branchId from the /me endpoint
//     final branchId = await _resolveBranchManagerBranchId();

//     if (branchId == null) {
//       // Could not determine branch — surface a helpful error rather than
//       // silently querying with branchId=1.
//       setState(() {
//         _errorMessage =
//             'Could not determine your branch. Please contact your administrator.';
//       });
//       return;
//     }

//     final stats = await _dashboardService.calculateBranchStatistics(branchId);
//     setState(() {
//       _branchStats = DashboardStatistics.fromBranchData(stats);
//     });
//   }

//   Future<void> _loadLoanOfficerData() async {
//     final stats = await _dashboardService.calculateLoanStatistics();
//     setState(() {
//       _loanStats = DashboardStatistics.fromLoanData(stats);
//     });
//   }

//   Future<void> _loadCardOfficerData() async {
//     final stats = await _dashboardService.calculateCardStatistics();
//     setState(() {
//       _cardStats = DashboardStatistics.fromCardData(stats);
//     });
//   }

//   Future<void> _loadAdminData() async {
//     final stats = await _dashboardService.calculateBankStatistics();
//     setState(() {
//       _bankStats = DashboardStatistics.fromBankData(stats);
//     });
//   }

//   Future<void> _handleRefresh() async {
//     setState(() => _isRefreshing = true);
//     await _loadDashboardData();
//     setState(() => _isRefreshing = false);
//   }

//   Widget _buildShimmerLoader() {
//   return SingleChildScrollView(
//     child: Column(
//       children: List.generate(4, (index) => const ShimmerCard(height: 100)),
//     ),
//   );
// }

//   // ── Build ─────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthProvider>(
//       builder: (context, authProvider, child) {
//         final user = authProvider.user;
//         final userRole = user?.role;

//         return Scaffold(
//           appBar: AppBar(
//             title: const Text('Dashboard'),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.notifications_outlined),
//                 onPressed: () {},
//               ),
//             ],
//           ),
//           body: RefreshIndicator(
//             onRefresh: _handleRefresh,
//             child: _isLoading
//                 ? _buildShimmerLoader()
//                 // ? const Center(child: CircularProgressIndicator())
//                 : _errorMessage != null
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(
//                           Icons.error_outline,
//                           size: 64,
//                           color: Colors.red,
//                         ),
//                         const SizedBox(height: 16),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 32),
//                           child: Text(
//                             _errorMessage!,
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(color: Colors.red),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: _loadDashboardData,
//                           child: const Text('Retry'),
//                         ),
//                       ],
//                     ),
//                   )
//                 : SingleChildScrollView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildGreetingSection(context, authProvider),
//                         const SizedBox(height: 8),
//                         if (userRole == UserRole.customer)
//                           _buildCustomerDashboard(context)
//                         else if (userRole == UserRole.branchManager)
//                           _buildBranchManagerDashboard(context)
//                         else if (userRole == UserRole.loanOfficer)
//                           _buildLoanOfficerDashboard(context)
//                         else if (userRole == UserRole.cardOfficer)
//                           _buildCardOfficerDashboard(context)
//                         else if (userRole == UserRole.admin ||
//                             userRole == UserRole.superAdmin)
//                           _buildAdminDashboard(context)
//                         else
//                           _buildDefaultDashboard(context),
//                         const SizedBox(height: 16),
//                       ],
//                     ),
//                   ),
//           ),
//         );
//       },
//     );
//   }

//   // ── Greeting ──────────────────────────────────────────────────────────────

//   Widget _buildGreetingSection(
//     BuildContext context,
//     AuthProvider authProvider,
//   ) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final hour = DateTime.now().hour;
//     final greeting = hour < 12
//         ? 'Good Morning'
//         : hour < 17
//         ? 'Good Afternoon'
//         : 'Good Evening';

//     final user = authProvider.user;
//     final displayName = user?.fullName ?? user?.username ?? 'User';
//     final userRole = user?.role;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   greeting,
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   displayName,
//                   style: theme.textTheme.headlineSmall?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 if (userRole != null) ...[
//                   const SizedBox(height: 4),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: colorScheme.primaryContainer,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       userRole.displayName,
//                       style: theme.textTheme.labelSmall?.copyWith(
//                         color: colorScheme.onPrimaryContainer,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: colorScheme.primary,
//             child: Text(
//               displayName[0].toUpperCase(),
//               style: theme.textTheme.headlineMedium?.copyWith(
//                 color: colorScheme.onPrimary,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Customer dashboard ────────────────────────────────────────────────────

//   Widget _buildCustomerDashboard(BuildContext context) {
//     final totalBalance = _accountsSummary?['totalBalance'] as double? ?? 0.0;
//     final accountCount = _accountsSummary?['accountCount'] as int? ?? 0;

//     return Column(
//       children: [
//         AccountSummaryCard(
//           totalBalance: totalBalance,
//           accountCount: accountCount,
//           isLoading: _isRefreshing,
//           onTap: () {},
//         ),

//         _buildQuickActionsSection(context, [
//           QuickActionButton(icon: Icons.send, label: 'Transfer', onTap: () {}),
//           QuickActionButton(
//             icon: Icons.payment,
//             label: 'Deposit',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.credit_card,
//             label: 'Cards',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.account_balance,
//             label: 'Loans',
//             onTap: () {},
//           ),
//         ]),

//         // ✅ RecentTransactionsWidget — now wired to actual API data
//         RecentTransactionsWidget(
//           transactions: _recentTransactions,
//           isLoading: _transactionsLoading,
//           onViewAll: () {
//             // Navigate to full transaction history screen when available
//           },
//         ),

//         if (_customerCards.isNotEmpty) _buildCustomerCardsSection(context),
//         if (_customerLoans.isNotEmpty) _buildCustomerLoansSection(context),

//         AlertsWidget(
//           alerts: _getMockAlerts(),
//           isLoading: _isRefreshing,
//           onViewAll: () {},
//         ),
//       ],
//     );
//   }

//   Widget _buildCustomerCardsSection(BuildContext context) {
//     final theme = Theme.of(context);
//     final activeCards = _customerCards.where((c) => c.isActive).length;

//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'My Cards',
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _buildInfoTile(
//                     'Total Cards',
//                     _customerCards.length.toString(),
//                     Icons.credit_card,
//                   ),
//                   _buildInfoTile(
//                     'Active',
//                     activeCards.toString(),
//                     Icons.check_circle,
//                     color: Colors.green,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCustomerLoansSection(BuildContext context) {
//     final theme = Theme.of(context);
//     final activeLoans = _customerLoans.where((l) => l.isDisbursed).length;
//     final totalOutstanding = _customerLoans
//         .where((l) => l.isDisbursed)
//         .fold(0.0, (sum, loan) => sum + loan.outstandingBalance);

//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'My Loans',
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _buildInfoTile(
//                     'Active Loans',
//                     activeLoans.toString(),
//                     Icons.account_balance,
//                   ),
//                   _buildInfoTile(
//                     'Outstanding',
//                     '৳${totalOutstanding.toStringAsFixed(0)}',
//                     Icons.trending_up,
//                     color: Colors.orange,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoTile(
//     String label,
//     String value,
//     IconData icon, {
//     Color? color,
//   }) {
//     final theme = Theme.of(context);
//     final tileColor = color ?? theme.colorScheme.primary;
//     return Column(
//       children: [
//         Icon(icon, color: tileColor, size: 32),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: theme.textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: tileColor,
//           ),
//         ),
//         Text(
//           label,
//           style: theme.textTheme.bodySmall?.copyWith(
//             color: theme.colorScheme.onSurfaceVariant,
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Branch Manager dashboard ──────────────────────────────────────────────

//   Widget _buildBranchManagerDashboard(BuildContext context) {
//     final theme = Theme.of(context);
//     final stats = _branchStats;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             'Branch Overview',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),

//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Accounts',
//               value: (stats?.totalAccounts ?? 0).toString(),
//               icon: Icons.account_balance_wallet,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Active Accounts',
//               value: (stats?.activeAccounts ?? 0).toString(),
//               icon: Icons.check_circle,
//               color: Colors.green,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Deposits',
//               value: (stats?.totalDeposits ?? 0).toStringAsFixed(0),
//               icon: Icons.trending_up,
//               color: Colors.teal,
//               isCurrency: true,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Pending Actions',
//               value: '0',
//               icon: Icons.pending_actions,
//               color: Colors.orange,
//               onTap: () {},
//             ),
//           ],
//         ),

//         _buildQuickActionsSection(context, [
//           QuickActionButton(
//             icon: Icons.person_add,
//             label: 'New Customer',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.check_circle,
//             label: 'Approvals',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.assessment,
//             label: 'Reports',
//             onTap: () {},
//           ),
//           QuickActionButton(icon: Icons.people, label: 'Staff', onTap: () {}),
//         ]),

//         AlertsWidget(alerts: _getMockManagerAlerts(), isLoading: _isRefreshing),
//       ],
//     );
//   }

//   // ── Loan Officer dashboard ────────────────────────────────────────────────

//   Widget _buildLoanOfficerDashboard(BuildContext context) {
//     final theme = Theme.of(context);
//     final loanStats = _loanStats;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             'Loan Management',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),

//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Pending Applications',
//               value: (loanStats?.pendingLoans ?? 0).toString(),
//               icon: Icons.pending,
//               color: Colors.orange,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Approved Loans',
//               value: (loanStats?.approvedLoans ?? 0).toString(),
//               icon: Icons.check_circle,
//               color: Colors.green,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Disbursed',
//               value: (loanStats?.disbursedLoans ?? 0).toString(),
//               icon: Icons.account_balance,
//               color: Colors.blue,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Total Disbursed',
//               value: (loanStats?.totalLoanAmount ?? 0).toStringAsFixed(0),
//               icon: Icons.payments,
//               color: Colors.purple,
//               isCurrency: true,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Loans',
//               value: (loanStats?.totalLoans ?? 0).toString(),
//               icon: Icons.assignment,
//               color: Colors.teal,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Outstanding',
//               value: (loanStats?.totalOutstanding ?? 0).toStringAsFixed(0),
//               icon: Icons.trending_up,
//               color: Colors.red,
//               isCurrency: true,
//               onTap: () {},
//             ),
//           ],
//         ),

//         _buildQuickActionsSection(context, [
//           QuickActionButton(
//             icon: Icons.add_circle,
//             label: 'New Loan',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.pending_actions,
//             label: 'Review',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.payment,
//             label: 'Disburse',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.history,
//             label: 'History',
//             onTap: () {},
//           ),
//         ]),

//         AlertsWidget(alerts: _getMockLoanAlerts(), isLoading: _isRefreshing),
//       ],
//     );
//   }

//   // ── Card Officer dashboard ────────────────────────────────────────────────

//   Widget _buildCardOfficerDashboard(BuildContext context) {
//     final theme = Theme.of(context);
//     final cardStats = _cardStats;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             'Card Management',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),

//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Pending Requests',
//               value: (cardStats?.pendingCards ?? 0).toString(),
//               icon: Icons.pending,
//               color: Colors.orange,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Active Cards',
//               value: (cardStats?.activeCards ?? 0).toString(),
//               icon: Icons.credit_card,
//               color: Colors.green,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Blocked Cards',
//               value: (cardStats?.blockedCards ?? 0).toString(),
//               icon: Icons.block,
//               color: Colors.red,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Total Cards',
//               value: (cardStats?.totalCards ?? 0).toString(),
//               icon: Icons.add_card,
//               color: Colors.blue,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Credit Limit',
//               value: (cardStats?.totalCreditLimit ?? 0).toStringAsFixed(0),
//               icon: Icons.account_balance_wallet,
//               color: Colors.purple,
//               isCurrency: true,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'System Health',
//               value:
//                   '${((cardStats?.activeCards ?? 0) / (cardStats?.totalCards ?? 1) * 100).toStringAsFixed(0)}%',
//               icon: Icons.health_and_safety,
//               color: Colors.teal,
//               onTap: () {},
//             ),
//           ],
//         ),

//         _buildQuickActionsSection(context, [
//           QuickActionButton(
//             icon: Icons.add_card,
//             label: 'Issue Card',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.block,
//             label: 'Block Card',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.lock_reset,
//             label: 'Reset PIN',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.assignment,
//             label: 'Requests',
//             onTap: () {},
//           ),
//         ]),

//         AlertsWidget(alerts: _getMockCardAlerts(), isLoading: _isRefreshing),
//       ],
//     );
//   }

//   // ── Admin dashboard ───────────────────────────────────────────────────────

//   Widget _buildAdminDashboard(BuildContext context) {
//     final theme = Theme.of(context);
//     final stats = _bankStats;

//     // ✅ transaction volume = totalDeposits (proxy for now; extend with a
//     //    dedicated /api/transactions/statistics endpoint when available)
//     final txVolume = stats?.totalDeposits ?? 0.0;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             'System Overview',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),

//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Customers',
//               value: (stats?.totalCustomers ?? 0).toString(),
//               icon: Icons.people,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Active Branches',
//               value: (stats?.activeBranches ?? 0).toString(),
//               icon: Icons.location_on,
//               color: Colors.blue,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Accounts',
//               value: (stats?.totalAccounts ?? 0).toString(),
//               icon: Icons.account_balance_wallet,
//               color: Colors.green,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Total Deposits',
//               value: (stats?.totalDeposits ?? 0).toStringAsFixed(0),
//               icon: Icons.trending_up,
//               color: Colors.purple,
//               isCurrency: true,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Active Loans',
//               value: (stats?.totalLoans ?? 0).toString(),
//               icon: Icons.account_balance,
//               color: Colors.teal,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Active Cards',
//               value: (stats?.totalCards ?? 0).toString(),
//               icon: Icons.credit_card,
//               color: Colors.orange,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Branches',
//               value: (stats?.totalBranches ?? 0).toString(),
//               icon: Icons.location_city,
//               color: Colors.indigo,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Loan Portfolio',
//               value: (stats?.totalLoanAmount ?? 0).toStringAsFixed(0),
//               icon: Icons.pie_chart,
//               color: Colors.deepOrange,
//               isCurrency: true,
//               onTap: () {},
//             ),
//           ],
//         ),
//         // ✅ Added: Transaction Volume row
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Transaction Volume',
//               value: txVolume.toStringAsFixed(0),
//               icon: Icons.swap_horiz,
//               color: Colors.cyan,
//               isCurrency: true,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Total Users',
//               // Total customers serves as a proxy; total registered users
//               // (staff + customers) would require GET /api/users count.
//               value: (stats?.totalCustomers ?? 0).toString(),
//               icon: Icons.manage_accounts,
//               color: Colors.brown,
//               onTap: () {},
//             ),
//           ],
//         ),

//         _buildQuickActionsSection(context, [
//           QuickActionButton(
//             icon: Icons.person_add,
//             label: 'Add User',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.location_city,
//             label: 'Branches',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.analytics,
//             label: 'Analytics',
//             onTap: () {},
//           ),
//           QuickActionButton(
//             icon: Icons.settings,
//             label: 'Settings',
//             onTap: () {},
//           ),
//         ]),

//         AlertsWidget(alerts: _getMockAdminAlerts(), isLoading: _isRefreshing),
//       ],
//     );
//   }

//   // ── Default dashboard (unknown role) ──────────────────────────────────────

//   Widget _buildDefaultDashboard(BuildContext context) {
//     return Column(
//       children: const [
//         SizedBox(height: 40),
//         Icon(Icons.dashboard, size: 80, color: Colors.grey),
//         SizedBox(height: 16),
//         Text(
//           'Dashboard',
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 8),
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 32),
//           child: Text(
//             'Your personalized dashboard will appear here',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Shared widgets ────────────────────────────────────────────────────────

//   Widget _buildQuickActionsSection(
//     BuildContext context,
//     List<QuickActionButton> actions,
//   ) {
//     final theme = Theme.of(context);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//           child: Text(
//             'Quick Actions',
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 4,
//             mainAxisSpacing: 12,
//             crossAxisSpacing: 12,
//             children: actions,
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Mock alerts ───────────────────────────────────────────────────────────

//   List<AlertItem> _getMockAlerts() => [
//     AlertItem(
//       title: 'Payment Due',
//       message: 'Your credit card payment is due in 3 days',
//       type: AlertType.warning,
//       timestamp: DateTime.now(),
//     ),
//     AlertItem(
//       title: 'Low Balance',
//       message: 'Your savings account balance is below minimum',
//       type: AlertType.warning,
//       timestamp: DateTime.now().subtract(const Duration(hours: 2)),
//     ),
//   ];

//   List<AlertItem> _getMockManagerAlerts() => [
//     AlertItem(
//       title: 'Branch Accounts',
//       message:
//           '${_branchStats?.totalAccounts ?? 0} total accounts in your branch',
//       type: AlertType.info,
//       timestamp: DateTime.now(),
//     ),
//     AlertItem(
//       title: 'Active Status',
//       message:
//           '${_branchStats?.activeAccounts ?? 0} accounts are currently active',
//       type: AlertType.success,
//       timestamp: DateTime.now(),
//     ),
//   ];

//   List<AlertItem> _getMockLoanAlerts() => [
//     AlertItem(
//       title: 'New Applications',
//       message:
//           '${_loanStats?.pendingLoans ?? 0} loan applications awaiting review',
//       type: AlertType.warning,
//       timestamp: DateTime.now(),
//     ),
//     AlertItem(
//       title: 'Ready for Disbursement',
//       message: '${_loanStats?.approvedLoans ?? 0} loans approved and ready',
//       type: AlertType.success,
//       timestamp: DateTime.now(),
//     ),
//   ];

//   List<AlertItem> _getMockCardAlerts() => [
//     AlertItem(
//       title: 'Card Requests',
//       message: '${_cardStats?.pendingCards ?? 0} pending card requests',
//       type: AlertType.warning,
//       timestamp: DateTime.now(),
//     ),
//     AlertItem(
//       title: 'Blocked Cards',
//       message: '${_cardStats?.blockedCards ?? 0} cards currently blocked',
//       type: AlertType.error,
//       timestamp: DateTime.now(),
//     ),
//   ];

//   List<AlertItem> _getMockAdminAlerts() => [
//     AlertItem(
//       title: 'System Overview',
//       message:
//           '${_bankStats?.totalCustomers ?? 0} total customers across all branches',
//       type: AlertType.info,
//       timestamp: DateTime.now(),
//     ),
//     AlertItem(
//       title: 'Active Operations',
//       message: '${_bankStats?.activeBranches ?? 0} branches actively operating',
//       type: AlertType.success,
//       timestamp: DateTime.now(),
//     ),
//   ];
// }


// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:vantedge/core/api/interceptors/dio_client.dart';
// import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
// import 'package:vantedge/features/auth/domain/entities/user_role.dart';
// import 'package:vantedge/features/dashboard/data/models/dashboard_models.dart';
// import 'package:vantedge/features/dashboard/data/services/dashboard_service.dart';
// // import 'package:vantedge/core/network/dio_client.dart';
// // import '../data/services/dashboard_service.dart';
// // import '../data/models/dashboard_models.dart';
// import '../widgets/account_summary_card.dart';
// import '../widgets/quick_action_button.dart';
// import '../widgets/recent_transactions_widget.dart';
// import '../widgets/alerts_widget.dart';
// import '../widgets/statistics_card.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   // Create service on demand
//   late final DashboardService _dashboardService = DashboardService(
//     dioClient: context.read<DioClient>(),
//   );

//   bool _isRefreshing = false;
//   bool _isLoading = true;

//   // Customer data
//   Map<String, dynamic>? _accountsSummary;
//   List<CardListItem> _customerCards = [];
//   List<LoanListItem> _customerLoans = [];

//   // Branch Manager data
//   DashboardStatistics? _branchStats;

//   // Admin data
//   DashboardStatistics? _bankStats;

//   // Loan Officer data
//   DashboardStatistics? _loanStats;

//   // Card Officer data
//   DashboardStatistics? _cardStats;

//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadDashboardData();
//     });
//   }

//   Future<void> _loadDashboardData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final userRole = authProvider.user?.role;

//       switch (userRole) {
//         case UserRole.customer:
//           await _loadCustomerData();
//           break;
//         case UserRole.branchManager:
//           await _loadBranchManagerData();
//           break;
//         case UserRole.loanOfficer:
//           await _loadLoanOfficerData();
//           break;
//         case UserRole.cardOfficer:
//           await _loadCardOfficerData();
//           break;
//         case UserRole.admin:
//         case UserRole.superAdmin:
//           await _loadAdminData();
//           break;
//         default:
//           break;
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _loadCustomerData() async {
//     try {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final customerId = authProvider.user?.customerId;

//       if (customerId == null) {
//         throw Exception('Customer ID not found');
//       }

//       // Fetch customer's accounts, cards, and loans in parallel
//       final results = await Future.wait([
//         _dashboardService.getCustomerAccountsSummary(customerId),
//         _dashboardService.getCustomerCards(customerId),
//         _dashboardService.getCustomerLoans(customerId),
//       ]);

//       setState(() {
//         _accountsSummary = results[0] as Map<String, dynamic>;
//         _customerCards = (results[1] as List)
//             .map((json) => CardListItem.fromJson(json))
//             .toList();
//         _customerLoans = (results[2] as List)
//             .map((json) => LoanListItem.fromJson(json))
//             .toList();
//       });
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> _loadBranchManagerData() async {
//     try {
//       // TODO: Get actual branch ID from user data
//       final branchId = 1; // Placeholder

//       final stats = await _dashboardService.calculateBranchStatistics(branchId);

//       setState(() {
//         _branchStats = DashboardStatistics.fromBranchData(stats);
//       });
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> _loadLoanOfficerData() async {
//     try {
//       final stats = await _dashboardService.calculateLoanStatistics();

//       setState(() {
//         _loanStats = DashboardStatistics.fromLoanData(stats);
//       });
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> _loadCardOfficerData() async {
//     try {
//       final stats = await _dashboardService.calculateCardStatistics();

//       setState(() {
//         _cardStats = DashboardStatistics.fromCardData(stats);
//       });
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> _loadAdminData() async {
//     try {
//       final stats = await _dashboardService.calculateBankStatistics();

//       setState(() {
//         _bankStats = DashboardStatistics.fromBankData(stats);
//       });
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> _handleRefresh() async {
//     setState(() => _isRefreshing = true);
//     await _loadDashboardData();
//     setState(() => _isRefreshing = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthProvider>(
//       builder: (context, authProvider, child) {
//         final user = authProvider.user;
//         final userRole = user?.role;

//         return Scaffold(
//           appBar: AppBar(
//             title: const Text('Dashboard'),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.notifications_outlined),
//                 onPressed: () {
//                   // TODO: Navigate to notifications
//                 },
//               ),
//             ],
//           ),
//           body: RefreshIndicator(
//             onRefresh: _handleRefresh,
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _errorMessage != null
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(Icons.error_outline, size: 64, color: Colors.red),
//                             const SizedBox(height: 16),
//                             Text(
//                               _errorMessage!,
//                               textAlign: TextAlign.center,
//                               style: const TextStyle(color: Colors.red),
//                             ),
//                             const SizedBox(height: 16),
//                             ElevatedButton(
//                               onPressed: _loadDashboardData,
//                               child: const Text('Retry'),
//                             ),
//                           ],
//                         ),
//                       )
//                     : SingleChildScrollView(
//                         physics: const AlwaysScrollableScrollPhysics(),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _buildGreetingSection(context, authProvider),
//                             const SizedBox(height: 8),
//                             // Role-specific content
//                             if (userRole == UserRole.customer)
//                               _buildCustomerDashboard(context)
//                             else if (userRole == UserRole.branchManager)
//                               _buildBranchManagerDashboard(context)
//                             else if (userRole == UserRole.loanOfficer)
//                               _buildLoanOfficerDashboard(context)
//                             else if (userRole == UserRole.cardOfficer)
//                               _buildCardOfficerDashboard(context)
//                             else if (userRole == UserRole.admin ||
//                                 userRole == UserRole.superAdmin)
//                               _buildAdminDashboard(context)
//                             else
//                               _buildDefaultDashboard(context),
//                             const SizedBox(height: 16),
//                           ],
//                         ),
//                       ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildGreetingSection(BuildContext context, AuthProvider authProvider) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final hour = DateTime.now().hour;
//     final greeting = hour < 12
//         ? 'Good Morning'
//         : hour < 17
//             ? 'Good Afternoon'
//             : 'Good Evening';

//     final user = authProvider.user;
//     final displayName = user?.fullName ?? user?.username ?? 'User';
//     final userRole = user?.role;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   greeting,
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   displayName,
//                   style: theme.textTheme.headlineSmall?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 if (userRole != null) ...[
//                   const SizedBox(height: 4),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: colorScheme.primaryContainer,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       userRole.displayName,
//                       style: theme.textTheme.labelSmall?.copyWith(
//                         color: colorScheme.onPrimaryContainer,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: colorScheme.primary,
//             child: Text(
//               displayName[0].toUpperCase(),
//               style: theme.textTheme.headlineMedium?.copyWith(
//                 color: colorScheme.onPrimary,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Customer Dashboard
//   Widget _buildCustomerDashboard(BuildContext context) {
//     final totalBalance = _accountsSummary?['totalBalance'] as double? ?? 0.0;
//     final accountCount = _accountsSummary?['accountCount'] as int? ?? 0;

//     return Column(
//       children: [
//         // Account Summary
//         AccountSummaryCard(
//           totalBalance: totalBalance,
//           accountCount: accountCount,
//           isLoading: _isRefreshing,
//           onTap: () {
//             // TODO: Navigate to accounts
//           },
//         ),
        
//         // Quick Actions
//         _buildQuickActionsSection(
//           context,
//           [
//             QuickActionButton(
//               icon: Icons.send,
//               label: 'Transfer',
//               onTap: () {
//                 // TODO: Navigate to transfer
//               },
//             ),
//             QuickActionButton(
//               icon: Icons.payment,
//               label: 'Deposit',
//               onTap: () {
//                 // TODO: Navigate to deposit
//               },
//             ),
//             QuickActionButton(
//               icon: Icons.credit_card,
//               label: 'Cards',
//               onTap: () {
//                 // TODO: Navigate to cards
//               },
//             ),
//             QuickActionButton(
//               icon: Icons.account_balance,
//               label: 'Loans',
//               onTap: () {
//                 // TODO: Navigate to loans
//               },
//             ),
//           ],
//         ),
        
//         // Cards Summary
//         if (_customerCards.isNotEmpty)
//           _buildCustomerCardsSection(context),
        
//         // Loans Summary
//         if (_customerLoans.isNotEmpty)
//           _buildCustomerLoansSection(context),
        
//         // Alerts
//         AlertsWidget(
//           alerts: _getMockAlerts(),
//           isLoading: _isRefreshing,
//           onViewAll: () {
//             // TODO: Navigate to all alerts
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildCustomerCardsSection(BuildContext context) {
//     final theme = Theme.of(context);
//     final activeCards = _customerCards.where((c) => c.isActive).length;
    
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'My Cards',
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _buildInfoTile(
//                     'Total Cards',
//                     _customerCards.length.toString(),
//                     Icons.credit_card,
//                   ),
//                   _buildInfoTile(
//                     'Active',
//                     activeCards.toString(),
//                     Icons.check_circle,
//                     color: Colors.green,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCustomerLoansSection(BuildContext context) {
//     final theme = Theme.of(context);
//     final activeLoans = _customerLoans.where((l) => l.isDisbursed).length;
//     final totalOutstanding = _customerLoans
//         .where((l) => l.isDisbursed)
//         .fold(0.0, (sum, loan) => sum + loan.outstandingBalance);
    
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'My Loans',
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _buildInfoTile(
//                     'Active Loans',
//                     activeLoans.toString(),
//                     Icons.account_balance,
//                   ),
//                   _buildInfoTile(
//                     'Outstanding',
//                     '৳${totalOutstanding.toStringAsFixed(0)}',
//                     Icons.trending_up,
//                     color: Colors.orange,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoTile(String label, String value, IconData icon, {Color? color}) {
//     final theme = Theme.of(context);
//     final tileColor = color ?? theme.colorScheme.primary;
    
//     return Column(
//       children: [
//         Icon(icon, color: tileColor, size: 32),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: theme.textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: tileColor,
//           ),
//         ),
//         Text(
//           label,
//           style: theme.textTheme.bodySmall?.copyWith(
//             color: theme.colorScheme.onSurfaceVariant,
//           ),
//         ),
//       ],
//     );
//   }

//   // Branch Manager Dashboard
//   Widget _buildBranchManagerDashboard(BuildContext context) {
//     final theme = Theme.of(context);
//     final stats = _branchStats;
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             'Branch Overview',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
        
//         // Statistics Grid
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Accounts',
//               value: (stats?.totalAccounts ?? 0).toString(),
//               icon: Icons.account_balance_wallet,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Active Accounts',
//               value: (stats?.activeAccounts ?? 0).toString(),
//               icon: Icons.check_circle,
//               color: Colors.green,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Deposits',
//               value: (stats?.totalDeposits ?? 0).toStringAsFixed(0),
//               icon: Icons.trending_up,
//               color: Colors.teal,
//               isCurrency: true,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Pending Actions',
//               value: '0', // TODO: Get from actual data
//               icon: Icons.pending_actions,
//               color: Colors.orange,
//               onTap: () {},
//             ),
//           ],
//         ),
        
//         // Quick Actions
//         _buildQuickActionsSection(
//           context,
//           [
//             QuickActionButton(
//               icon: Icons.person_add,
//               label: 'New Customer',
//               onTap: () {},
//             ),
//             QuickActionButton(
//               icon: Icons.check_circle,
//               label: 'Approvals',
//               onTap: () {},
//             ),
//             QuickActionButton(
//               icon: Icons.assessment,
//               label: 'Reports',
//               onTap: () {},
//             ),
//             QuickActionButton(
//               icon: Icons.people,
//               label: 'Staff',
//               onTap: () {},
//             ),
//           ],
//         ),
        
//         // Alerts
//         AlertsWidget(
//           alerts: _getMockManagerAlerts(),
//           isLoading: _isRefreshing,
//         ),
//       ],
//     );
//   }

//   // Loan Officer Dashboard
//   Widget _buildLoanOfficerDashboard(BuildContext context) {
//     final theme = Theme.of(context);
//     final loanStats = _loanStats;
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             'Loan Management',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
        
//         // Statistics
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Pending Applications',
//               value: (loanStats?.pendingLoans ?? 0).toString(),
//               icon: Icons.pending,
//               color: Colors.orange,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Approved Loans',
//               value: (loanStats?.approvedLoans ?? 0).toString(),
//               icon: Icons.check_circle,
//               color: Colors.green,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Disbursed',
//               value: (loanStats?.disbursedLoans ?? 0).toString(),
//               icon: Icons.account_balance,
//               color: Colors.blue,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Total Disbursed',
//               value: (loanStats?.totalLoanAmount ?? 0).toStringAsFixed(0),
//               icon: Icons.payments,
//               color: Colors.purple,
//               isCurrency: true,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Loans',
//               value: (loanStats?.totalLoans ?? 0).toString(),
//               icon: Icons.assignment,
//               color: Colors.teal,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Outstanding',
//               value: (loanStats?.totalOutstanding ?? 0).toStringAsFixed(0),
//               icon: Icons.trending_up,
//               color: Colors.red,
//               isCurrency: true,
//               onTap: () {},
//             ),
//           ],
//         ),
        
//         // Quick Actions
//         _buildQuickActionsSection(
//           context,
//           [
//             QuickActionButton(
//               icon: Icons.add_circle,
//               label: 'New Loan',
//               onTap: () {},
//             ),
//             QuickActionButton(
//               icon: Icons.pending_actions,
//               label: 'Review',
//               onTap: () {},
//             ),
//             QuickActionButton(
//               icon: Icons.payment,
//               label: 'Disburse',
//               onTap: () {},
//             ),
//             QuickActionButton(
//               icon: Icons.history,
//               label: 'History',
//               onTap: () {},
//             ),
//           ],
//         ),
        
//         AlertsWidget(
//           alerts: _getMockLoanAlerts(),
//           isLoading: _isRefreshing,
//         ),
//       ],
//     );
//   }

//   // Card Officer Dashboard
//   Widget _buildCardOfficerDashboard(BuildContext context) {
//     final theme = Theme.of(context);
//     final cardStats = _cardStats;
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             'Card Management',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
        
//         // Statistics
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Pending Requests',
//               value: (cardStats?.pendingCards ?? 0).toString(),
//               icon: Icons.pending,
//               color: Colors.orange,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Active Cards',
//               value: (cardStats?.activeCards ?? 0).toString(),
//               icon: Icons.credit_card,
//               color: Colors.green,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Blocked Cards',
//               value: (cardStats?.blockedCards ?? 0).toString(),
//               icon: Icons.block,
//               color: Colors.red,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Total Cards',
//               value: (cardStats?.totalCards ?? 0).toString(),
//               icon: Icons.add_card,
//               color: Colors.blue,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Credit Limit',
//               value: (cardStats?.totalCreditLimit ?? 0).toStringAsFixed(0),
//               icon: Icons.account_balance_wallet,
//               color: Colors.purple,
//               isCurrency: true,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'System Health',
//               value: '${((cardStats?.activeCards ?? 0) / (cardStats?.totalCards ?? 1) * 100).toStringAsFixed(0)}%',
//               icon: Icons.health_and_safety,
//               color: Colors.teal,
//               onTap: () {},
//             ),
//           ],
//         ),
        
//         // Quick Actions
//         _buildQuickActionsSection(
//           context,
//           [
//             QuickActionButton(
//               icon: Icons.add_card,
//               label: 'Issue Card',
//               onTap: () {},
//             ),
//             QuickActionButton(
//               icon: Icons.block,
//               label: 'Block Card',
//               onTap: () {},
//             ),
//             QuickActionButton(
//               icon: Icons.lock_reset,
//               label: 'Reset PIN',
//               onTap: () {},
//             ),
//             QuickActionButton(
//               icon: Icons.assignment,
//               label: 'Requests',
//               onTap: () {},
//             ),
//           ],
//         ),
        
//         AlertsWidget(
//           alerts: _getMockCardAlerts(),
//           isLoading: _isRefreshing,
//         ),
//       ],
//     );
//   }

//   // Admin Dashboard
//   Widget _buildAdminDashboard(BuildContext context) {
//     final theme = Theme.of(context);
//     final stats = _bankStats;
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Text(
//             'System Overview',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
        
//         // Statistics
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Customers',
//               value: (stats?.totalCustomers ?? 0).toString(),
//               icon: Icons.people,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Active Branches',
//               value: (stats?.activeBranches ?? 0).toString(),
//               icon: Icons.location_on,
//               color: Colors.blue,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Accounts',
//               value: (stats?.totalAccounts ?? 0).toString(),
//               icon: Icons.account_balance_wallet,
//               color: Colors.green,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Total Deposits',
//               value: (stats?.totalDeposits ?? 0).toStringAsFixed(0),
//               icon: Icons.trending_up,
//               color: Colors.purple,
//               isCurrency: true,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Active Loans',
//               value: (stats?.totalLoans ?? 0).toString(),
//               icon: Icons.account_balance,
//               color: Colors.teal,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Active Cards',
//               value: (stats?.totalCards ?? 0).toString(),
//               icon: Icons.credit_card,
//               color: Colors.orange,
//               onTap: () {},
//             ),
//           ],
//         ),
//         StatisticsRow(
//           cards: [
//             StatisticsCard(
//               title: 'Total Branches',
//               value: (stats?.totalBranches ?? 0).toString(),
//               icon: Icons.location_city,
//               color: Colors.indigo,
//               onTap: () {},
//             ),
//             StatisticsCard(
//               title: 'Loan Portfolio',
//               value: (stats?.totalLoanAmount ?? 0).toStringAsFixed(0),
//               icon: Icons.pie_chart,
//               color: Colors.deepOrange,
//               isCurrency: true,
//               onTap: () {},
//             ),
//           ],
//         ),
        
//         // Quick Actions
//         _buildQuickActionsSection(
//           context,
//           [
//             QuickActionButton(
//               icon: Icons.person_add,
//               label: 'Add User',
//               onTap: () {},
//             ),
//             QuickActionButton(
//               icon: Icons.location_city,
//               label: 'Branches',
//               onTap: () {},
//             ),
//             QuickActionButton(
//               icon: Icons.analytics,
//               label: 'Analytics',
//               onTap: () {},
//             ),
//             QuickActionButton(
//               icon: Icons.settings,
//               label: 'Settings',
//               onTap: () {},
//             ),
//           ],
//         ),
        
//         AlertsWidget(
//           alerts: _getMockAdminAlerts(),
//           isLoading: _isRefreshing,
//         ),
//       ],
//     );
//   }

//   // Default Dashboard
//   Widget _buildDefaultDashboard(BuildContext context) {
//     return Column(
//       children: [
//         const SizedBox(height: 40),
//         const Icon(
//           Icons.dashboard,
//           size: 80,
//           color: Colors.grey,
//         ),
//         const SizedBox(height: 16),
//         const Text(
//           'Dashboard',
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 8),
//         const Padding(
//           padding: EdgeInsets.symmetric(horizontal: 32),
//           child: Text(
//             'Your personalized dashboard will appear here',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildQuickActionsSection(
//     BuildContext context,
//     List<QuickActionButton> actions,
//   ) {
//     final theme = Theme.of(context);
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//           child: Text(
//             'Quick Actions',
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 4,
//             mainAxisSpacing: 12,
//             crossAxisSpacing: 12,
//             children: actions,
//           ),
//         ),
//       ],
//     );
//   }

//   // Mock data methods (for alerts - replace with API calls when available)
//   List<AlertItem> _getMockAlerts() {
//     return [
//       AlertItem(
//         title: 'Payment Due',
//         message: 'Your credit card payment is due in 3 days',
//         type: AlertType.warning,
//         timestamp: DateTime.now(),
//       ),
//       AlertItem(
//         title: 'Low Balance',
//         message: 'Your savings account balance is below minimum',
//         type: AlertType.warning,
//         timestamp: DateTime.now().subtract(const Duration(hours: 2)),
//       ),
//     ];
//   }

//   List<AlertItem> _getMockManagerAlerts() {
//     return [
//       AlertItem(
//         title: 'Branch Accounts',
//         message: '${_branchStats?.totalAccounts ?? 0} total accounts in your branch',
//         type: AlertType.info,
//         timestamp: DateTime.now(),
//       ),
//       AlertItem(
//         title: 'Active Status',
//         message: '${_branchStats?.activeAccounts ?? 0} accounts are currently active',
//         type: AlertType.success,
//         timestamp: DateTime.now(),
//       ),
//     ];
//   }

//   List<AlertItem> _getMockLoanAlerts() {
//     return [
//       AlertItem(
//         title: 'New Applications',
//         message: '${_loanStats?.pendingLoans ?? 0} loan applications awaiting review',
//         type: AlertType.warning,
//         timestamp: DateTime.now(),
//       ),
//       AlertItem(
//         title: 'Ready for Disbursement',
//         message: '${_loanStats?.approvedLoans ?? 0} loans approved and ready',
//         type: AlertType.success,
//         timestamp: DateTime.now(),
//       ),
//     ];
//   }

//   List<AlertItem> _getMockCardAlerts() {
//     return [
//       AlertItem(
//         title: 'Card Requests',
//         message: '${_cardStats?.pendingCards ?? 0} pending card requests',
//         type: AlertType.warning,
//         timestamp: DateTime.now(),
//       ),
//       AlertItem(
//         title: 'Blocked Cards',
//         message: '${_cardStats?.blockedCards ?? 0} cards currently blocked',
//         type: AlertType.error,
//         timestamp: DateTime.now(),
//       ),
//     ];
//   }

//   List<AlertItem> _getMockAdminAlerts() {
//     return [
//       AlertItem(
//         title: 'System Overview',
//         message: '${_bankStats?.totalCustomers ?? 0} total customers across all branches',
//         type: AlertType.info,
//         timestamp: DateTime.now(),
//       ),
//       AlertItem(
//         title: 'Active Operations',
//         message: '${_bankStats?.activeBranches ?? 0} branches actively operating',
//         type: AlertType.success,
//         timestamp: DateTime.now(),
//       ),
//     ];
//   }
// }