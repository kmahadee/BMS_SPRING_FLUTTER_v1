import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/accounts/presentation/providers/account_provider.dart';
import 'package:vantedge/features/branches/presentation/widgets/account_card.dart';
import 'package:vantedge/features/branches/presentation/widgets/account_list_item.dart';
import 'package:vantedge/features/branches/presentation/widgets/account_shimmer_loader.dart';
import 'package:vantedge/shared/providers/badge_count_provider.dart';
import 'package:vantedge/shared/widgets/main_scaffold.dart';
import '../../../data/models/account_type.dart';
import '../../../data/models/account_status.dart';
import 'account_details_screen.dart';

/// Main screen for displaying user's accounts list
/// 
/// Features:
/// - Pull-to-refresh
/// - Search functionality
/// - Sort and filter options
/// - Empty and error states
/// - Loading skeleton
/// - FAB for quick actions
class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  
  // Sort and filter states
  _SortOption _currentSort = _SortOption.name;
  AccountType? _filterType;
  AccountStatus? _filterStatus;
  bool _showFilters = false;
  bool _useListView = false; // Toggle between card and list view

  @override
  void initState() {
    super.initState();
    print('💰 [AccountListScreen] initState');
    // Load accounts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AccountProvider>();
      if (!provider.hasAccounts && !provider.isLoading) {
        print('💰 [AccountListScreen] Fetching accounts');
        provider.fetchMyAccounts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    print('💰 [AccountListScreen] Refreshing accounts');
    await context.read<AccountProvider>().fetchMyAccounts();
  }

  void _navigateToDetails(String accountNumber) {
    print('💰 [AccountListScreen] Navigating to account details: $accountNumber');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountDetailsScreen(
          accountNumber: accountNumber,
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SortBottomSheet(
        currentSort: _currentSort,
        onSortChanged: (sort) {
          setState(() => _currentSort = sort);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showFilterOptions() {
    setState(() => _showFilters = !_showFilters);
  }

  void _clearFilters() {
    setState(() {
      _filterType = null;
      _filterStatus = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  List<dynamic> _getFilteredAndSortedAccounts(AccountProvider provider) {
    var accounts = provider.accounts;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      accounts = accounts.where((account) {
        return account.accountName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            account.accountNumber.contains(_searchQuery) ||
            account.branchName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply type filter
    if (_filterType != null) {
      accounts = accounts.where((a) => a.accountType == _filterType).toList();
    }

    // Apply status filter
    if (_filterStatus != null) {
      accounts = accounts.where((a) => a.status == _filterStatus).toList();
    }

    // Sort
    switch (_currentSort) {
      case _SortOption.name:
        accounts.sort((a, b) => a.accountName.compareTo(b.accountName));
        break;
      case _SortOption.balanceHigh:
        accounts.sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
        break;
      case _SortOption.balanceLow:
        accounts.sort((a, b) => a.currentBalance.compareTo(b.currentBalance));
        break;
      case _SortOption.type:
        accounts.sort((a, b) => a.accountType.value.compareTo(b.accountType.value));
        break;
    }

    return accounts;
  }

  @override
  Widget build(BuildContext context) {
    print('💰 [AccountListScreen] 🔨 BUILD METHOD CALLED');
    
    return Consumer2<AccountProvider, BadgeCountProvider>(
      builder: (context, provider, badgeProvider, child) {
        print('💰 [AccountListScreen] Consumer builder called');
        print('  - isLoading: ${provider.isLoading}');
        print('  - hasAccounts: ${provider.hasAccounts}');
        print('  - hasError: ${provider.hasError}');
        print('  - accounts count: ${provider.accounts.length}');

        // Loading state
        if (provider.isLoading && !provider.hasAccounts) {
          return MainScaffold(
            currentRoute: AppRoutes.accounts,
            title: 'My Accounts',
            showAppBar: true,
            showDrawer: true,
            showBottomNav: true,
            showNotifications: true,
            // notificationCount: badgeProvider.totalNotificationCount,
            child: const AccountShimmerLoader(),
          );
        }

        // Error state
        if (provider.hasError && !provider.hasAccounts) {
          return MainScaffold(
            currentRoute: AppRoutes.accounts,
            title: 'My Accounts',
            showAppBar: true,
            showDrawer: true,
            showBottomNav: true,
            showNotifications: true,
            // notificationCount: badgeProvider.totalNotificationCount,
            child: _ErrorState(
              message: provider.errorMessage!,
              onRetry: () {
                provider.clearError();
                provider.fetchMyAccounts();
              },
            ),
          );
        }

        // Empty state
        if (!provider.hasAccounts) {
          return MainScaffold(
            currentRoute: AppRoutes.accounts,
            title: 'My Accounts',
            showAppBar: true,
            showDrawer: true,
            showBottomNav: true,
            showNotifications: true,
            // notificationCount: badgeProvider.totalNotificationCount,
            child: const _EmptyState(),
          );
        }

        // Get filtered and sorted accounts
        final accounts = _getFilteredAndSortedAccounts(provider);

        // No results from filter
        if (accounts.isEmpty) {
          return MainScaffold(
            currentRoute: AppRoutes.accounts,
            title: 'My Accounts',
            showAppBar: true,
            showDrawer: true,
            showBottomNav: true,
            showNotifications: true,
            // notificationCount: badgeProvider.totalNotificationCount,
            child: _NoResultsState(onClear: _clearFilters),
          );
        }

        // Success - Show accounts
        return MainScaffold(
          currentRoute: AppRoutes.accounts,
          title: 'My Accounts',
          showAppBar: true,
          showDrawer: true,
          showBottomNav: true,
          showNotifications: true,
          // notificationCount: badgeProvider.totalNotificationCount,
          onNotificationTap: () {
            print('💰 [AccountListScreen] Navigating to notifications');
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
          child: Column(
            children: [
              // Filter chips
              if (_showFilters)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filters',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Type filter
                          ChoiceChip(
                            label: const Text('Savings'),
                            selected: _filterType == AccountType.savings,
                            onSelected: (selected) {
                              setState(() {
                                _filterType = selected ? AccountType.savings : null;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Current'),
                            selected: _filterType == AccountType.current,
                            onSelected: (selected) {
                              setState(() {
                                _filterType = selected ? AccountType.current : null;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Active'),
                            selected: _filterStatus == AccountStatus.active,
                            onSelected: (selected) {
                              setState(() {
                                _filterStatus = selected ? AccountStatus.active : null;
                              });
                            },
                          ),
                          // Clear filters
                          if (_filterType != null || _filterStatus != null)
                            ActionChip(
                              label: const Text('Clear All'),
                              onPressed: _clearFilters,
                              avatar: const Icon(Icons.close, size: 16),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Accounts list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: _useListView
                      ? _AccountsListView(
                          accounts: accounts,
                          onTap: (account) => _navigateToDetails(account.accountNumber),
                          onRefresh: (account) async {
                            await provider.refreshBalance(account.accountNumber);
                          },
                        )
                      : _AccountsGridView(
                          accounts: accounts,
                          onTap: (account) => _navigateToDetails(account.accountNumber),
                        ),
                ),
              ),
            ],
          ),
          floatingActionButton: provider.hasAccounts
              ? FloatingActionButton.extended(
                  onPressed: () {
                    // TODO: Navigate to transfer screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transfer feature coming soon')),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Transfer'),
                )
              : null,
        );
      },
    );
  }
}

// Sort options enum
enum _SortOption {
  name,
  balanceHigh,
  balanceLow,
  type,
}

// Sort bottom sheet
class _SortBottomSheet extends StatelessWidget {
  final _SortOption currentSort;
  final Function(_SortOption) onSortChanged;

  const _SortBottomSheet({
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort By',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ..._SortOption.values.map((option) {
            String label;
            IconData icon;
            switch (option) {
              case _SortOption.name:
                label = 'Account Name (A-Z)';
                icon = Icons.sort_by_alpha;
                break;
              case _SortOption.balanceHigh:
                label = 'Balance (High to Low)';
                icon = Icons.arrow_downward;
                break;
              case _SortOption.balanceLow:
                label = 'Balance (Low to High)';
                icon = Icons.arrow_upward;
                break;
              case _SortOption.type:
                label = 'Account Type';
                icon = Icons.category;
                break;
            }

            return RadioListTile<_SortOption>(
              title: Text(label),
              secondary: Icon(icon),
              value: option,
              groupValue: currentSort,
              onChanged: (value) => onSortChanged(value!),
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
    );
  }
}

// Grid view for cards
class _AccountsGridView extends StatelessWidget {
  final List accounts;
  final Function(dynamic) onTap;

  const _AccountsGridView({
    required this.accounts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: accounts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final account = accounts[index];
        return AccountCard(
          account: account,
          onTap: () => onTap(account),
        );
      },
    );
  }
}

// List view for compact items
class _AccountsListView extends StatelessWidget {
  final List accounts;
  final Function(dynamic) onTap;
  final Future<void> Function(dynamic)? onRefresh;

  const _AccountsListView({
    required this.accounts,
    required this.onTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: accounts.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final account = accounts[index];
        return AccountListItem(
          account: account,
          onTap: () => onTap(account),
          onRefresh: onRefresh != null ? () => onRefresh!(account) : null,
          onViewDetails: () => onTap(account),
        );
      },
    );
  }
}

// Empty state widget
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 120,
              color: colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Accounts Yet',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You don\'t have any accounts yet. Contact your branch to open a new account.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // TODO: Navigate to branch locator or account opening
              },
              icon: const Icon(Icons.add),
              label: const Text('Find Nearest Branch'),
            ),
          ],
        ),
      ),
    );
  }
}

// Error state widget
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// No results state
class _NoResultsState extends StatelessWidget {
  final VoidCallback onClear;

  const _NoResultsState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Results Found',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your filters or search query',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onClear,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:vantedge/features/accounts/presentation/providers/account_provider.dart';
// import 'package:vantedge/features/branches/presentation/widgets/account_card.dart';
// import 'package:vantedge/features/branches/presentation/widgets/account_list_item.dart';
// import 'package:vantedge/features/branches/presentation/widgets/account_shimmer_loader.dart';
// import '../../../data/models/account_type.dart';
// import '../../../data/models/account_status.dart';
// // import '../providers/account_provider.dart';
// // import '../widgets/account_card.dart';
// // import '../widgets/account_list_item.dart';
// // import '../widgets/account_shimmer_loader.dart';
// import 'account_details_screen.dart';

// /// Main screen for displaying user's accounts list
// /// 
// /// Features:
// /// - Pull-to-refresh
// /// - Search functionality
// /// - Sort and filter options
// /// - Empty and error states
// /// - Loading skeleton
// /// - FAB for quick actions
// class AccountListScreen extends StatefulWidget {
//   const AccountListScreen({super.key});

//   @override
//   State<AccountListScreen> createState() => _AccountListScreenState();
// }

// class _AccountListScreenState extends State<AccountListScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   bool _isSearching = false;
//   String _searchQuery = '';
  
//   // Sort and filter states
//   _SortOption _currentSort = _SortOption.name;
//   AccountType? _filterType;
//   AccountStatus? _filterStatus;
//   bool _showFilters = false;
//   bool _useListView = false; // Toggle between card and list view

//   @override
//   void initState() {
//     super.initState();
//     // Load accounts when screen initializes
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final provider = context.read<AccountProvider>();
//       if (!provider.hasAccounts && !provider.isLoading) {
//         provider.fetchMyAccounts();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleRefresh() async {
//     await context.read<AccountProvider>().fetchMyAccounts();
//   }

//   void _navigateToDetails(String accountNumber) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AccountDetailsScreen(
//           accountNumber: accountNumber,
//         ),
//       ),
//     );
//   }

//   void _showSortOptions() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => _SortBottomSheet(
//         currentSort: _currentSort,
//         onSortChanged: (sort) {
//           setState(() => _currentSort = sort);
//           Navigator.pop(context);
//         },
//       ),
//     );
//   }

//   void _showFilterOptions() {
//     setState(() => _showFilters = !_showFilters);
//   }

//   void _clearFilters() {
//     setState(() {
//       _filterType = null;
//       _filterStatus = null;
//       _searchQuery = '';
//       _searchController.clear();
//     });
//   }

//   List<dynamic> _getFilteredAndSortedAccounts(AccountProvider provider) {
//     var accounts = provider.accounts;

//     // Apply search filter
//     if (_searchQuery.isNotEmpty) {
//       accounts = accounts.where((account) {
//         return account.accountName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//             account.accountNumber.contains(_searchQuery) ||
//             account.branchName.toLowerCase().contains(_searchQuery.toLowerCase());
//       }).toList();
//     }

//     // Apply type filter
//     if (_filterType != null) {
//       accounts = accounts.where((a) => a.accountType == _filterType).toList();
//     }

//     // Apply status filter
//     if (_filterStatus != null) {
//       accounts = accounts.where((a) => a.status == _filterStatus).toList();
//     }

//     // Sort
//     switch (_currentSort) {
//       case _SortOption.name:
//         accounts.sort((a, b) => a.accountName.compareTo(b.accountName));
//         break;
//       case _SortOption.balanceHigh:
//         accounts.sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
//         break;
//       case _SortOption.balanceLow:
//         accounts.sort((a, b) => a.currentBalance.compareTo(b.currentBalance));
//         break;
//       case _SortOption.type:
//         accounts.sort((a, b) => a.accountType.value.compareTo(b.accountType.value));
//         break;
//     }

//     return accounts;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Scaffold(
//       appBar: AppBar(
//         title: _isSearching
//             ? TextField(
//                 controller: _searchController,
//                 autofocus: true,
//                 decoration: InputDecoration(
//                   hintText: 'Search accounts...',
//                   border: InputBorder.none,
//                   hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
//                 ),
//                 style: TextStyle(color: colorScheme.onSurface),
//                 onChanged: (value) {
//                   setState(() => _searchQuery = value);
//                 },
//               )
//             : const Text('My Accounts'),
//         actions: [
//           // Search toggle
//           IconButton(
//             icon: Icon(_isSearching ? Icons.close : Icons.search),
//             onPressed: () {
//               setState(() {
//                 _isSearching = !_isSearching;
//                 if (!_isSearching) {
//                   _searchController.clear();
//                   _searchQuery = '';
//                 }
//               });
//             },
//             tooltip: 'Search',
//           ),
//           // View toggle
//           IconButton(
//             icon: Icon(_useListView ? Icons.grid_view : Icons.view_list),
//             onPressed: () {
//               setState(() => _useListView = !_useListView);
//             },
//             tooltip: _useListView ? 'Card View' : 'List View',
//           ),
//           // Sort
//           IconButton(
//             icon: const Icon(Icons.sort),
//             onPressed: _showSortOptions,
//             tooltip: 'Sort',
//           ),
//           // Filter
//           IconButton(
//             icon: Icon(
//               Icons.filter_list,
//               color: (_filterType != null || _filterStatus != null)
//                   ? colorScheme.primary
//                   : null,
//             ),
//             onPressed: _showFilterOptions,
//             tooltip: 'Filter',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Filter chips
//           if (_showFilters)
//             Container(
//               padding: const EdgeInsets.all(12),
//               color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Filters',
//                     style: theme.textTheme.labelLarge,
//                   ),
//                   const SizedBox(height: 8),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: [
//                       // Type filter
//                       ChoiceChip(
//                         label: const Text('Savings'),
//                         selected: _filterType == AccountType.savings,
//                         onSelected: (selected) {
//                           setState(() {
//                             _filterType = selected ? AccountType.savings : null;
//                           });
//                         },
//                       ),
//                       ChoiceChip(
//                         label: const Text('Current'),
//                         selected: _filterType == AccountType.current,
//                         onSelected: (selected) {
//                           setState(() {
//                             _filterType = selected ? AccountType.current : null;
//                           });
//                         },
//                       ),
//                       ChoiceChip(
//                         label: const Text('Active'),
//                         selected: _filterStatus == AccountStatus.active,
//                         onSelected: (selected) {
//                           setState(() {
//                             _filterStatus = selected ? AccountStatus.active : null;
//                           });
//                         },
//                       ),
//                       // Clear filters
//                       if (_filterType != null || _filterStatus != null)
//                         ActionChip(
//                           label: const Text('Clear All'),
//                           onPressed: _clearFilters,
//                           avatar: const Icon(Icons.close, size: 16),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//           // Main content
//           Expanded(
//             child: Consumer<AccountProvider>(
//               builder: (context, provider, child) {
//                 // Loading state
//                 if (provider.isLoading && !provider.hasAccounts) {
//                   return const AccountShimmerLoader();
//                 }

//                 // Error state
//                 if (provider.hasError && !provider.hasAccounts) {
//                   return _ErrorState(
//                     message: provider.errorMessage!,
//                     onRetry: () {
//                       provider.clearError();
//                       provider.fetchMyAccounts();
//                     },
//                   );
//                 }

//                 // Empty state
//                 if (!provider.hasAccounts) {
//                   return _EmptyState();
//                 }

//                 // Get filtered and sorted accounts
//                 final accounts = _getFilteredAndSortedAccounts(provider);

//                 // No results from filter
//                 if (accounts.isEmpty) {
//                   return _NoResultsState(onClear: _clearFilters);
//                 }

//                 // Success - Show accounts
//                 return RefreshIndicator(
//                   onRefresh: _handleRefresh,
//                   child: _useListView
//                       ? _AccountsListView(
//                           accounts: accounts,
//                           onTap: (account) => _navigateToDetails(account.accountNumber),
//                           onRefresh: (account) async {
//                             await provider.refreshBalance(account.accountNumber);
//                           },
//                         )
//                       : _AccountsGridView(
//                           accounts: accounts,
//                           onTap: (account) => _navigateToDetails(account.accountNumber),
//                         ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: Consumer<AccountProvider>(
//         builder: (context, provider, child) {
//           if (!provider.hasAccounts) return const SizedBox.shrink();

//           return FloatingActionButton.extended(
//             onPressed: () {
//               // TODO: Navigate to transfer screen
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Transfer feature coming soon')),
//               );
//             },
//             icon: const Icon(Icons.send),
//             label: const Text('Transfer'),
//           );
//         },
//       ),
//     );
//   }
// }

// // Sort options enum
// enum _SortOption {
//   name,
//   balanceHigh,
//   balanceLow,
//   type,
// }

// // Sort bottom sheet
// class _SortBottomSheet extends StatelessWidget {
//   final _SortOption currentSort;
//   final Function(_SortOption) onSortChanged;

//   const _SortBottomSheet({
//     required this.currentSort,
//     required this.onSortChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Sort By',
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//           const SizedBox(height: 16),
//           _SortOption.values.map((option) {
//             String label;
//             IconData icon;
//             switch (option) {
//               case _SortOption.name:
//                 label = 'Account Name (A-Z)';
//                 icon = Icons.sort_by_alpha;
//                 break;
//               case _SortOption.balanceHigh:
//                 label = 'Balance (High to Low)';
//                 icon = Icons.arrow_downward;
//                 break;
//               case _SortOption.balanceLow:
//                 label = 'Balance (Low to High)';
//                 icon = Icons.arrow_upward;
//                 break;
//               case _SortOption.type:
//                 label = 'Account Type';
//                 icon = Icons.category;
//                 break;
//             }

//             return RadioListTile<_SortOption>(
//               title: Text(label),
//               secondary: Icon(icon),
//               value: option,
//               groupValue: currentSort,
//               onChanged: (value) => onSortChanged(value!),
//             );
//           }).toList()[0],
//           ..._SortOption.values.skip(1).map((option) {
//             String label;
//             IconData icon;
//             switch (option) {
//               case _SortOption.name:
//                 label = 'Account Name (A-Z)';
//                 icon = Icons.sort_by_alpha;
//                 break;
//               case _SortOption.balanceHigh:
//                 label = 'Balance (High to Low)';
//                 icon = Icons.arrow_downward;
//                 break;
//               case _SortOption.balanceLow:
//                 label = 'Balance (Low to High)';
//                 icon = Icons.arrow_upward;
//                 break;
//               case _SortOption.type:
//                 label = 'Account Type';
//                 icon = Icons.category;
//                 break;
//             }

//             return RadioListTile<_SortOption>(
//               title: Text(label),
//               secondary: Icon(icon),
//               value: option,
//               groupValue: currentSort,
//               onChanged: (value) => onSortChanged(value!),
//             );
//           }),
//         ],
//       ),
//     );
//   }
// }

// // Grid view for cards
// class _AccountsGridView extends StatelessWidget {
//   final List accounts;
//   final Function(dynamic) onTap;

//   const _AccountsGridView({
//     required this.accounts,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListView.separated(
//       padding: const EdgeInsets.all(16),
//       itemCount: accounts.length,
//       separatorBuilder: (context, index) => const SizedBox(height: 12),
//       itemBuilder: (context, index) {
//         final account = accounts[index];
//         return AccountCard(
//           account: account,
//           onTap: () => onTap(account),
//         );
//       },
//     );
//   }
// }

// // List view for compact items
// class _AccountsListView extends StatelessWidget {
//   final List accounts;
//   final Function(dynamic) onTap;
//   final Future<void> Function(dynamic)? onRefresh;

//   const _AccountsListView({
//     required this.accounts,
//     required this.onTap,
//     this.onRefresh,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListView.separated(
//       itemCount: accounts.length,
//       separatorBuilder: (context, index) => const Divider(height: 1),
//       itemBuilder: (context, index) {
//         final account = accounts[index];
//         return AccountListItem(
//           account: account,
//           onTap: () => onTap(account),
//           onRefresh: onRefresh != null ? () => onRefresh!(account) : null,
//           onViewDetails: () => onTap(account),
//         );
//       },
//     );
//   }
// }

// // Empty state widget
// class _EmptyState extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.account_balance_wallet_outlined,
//               size: 120,
//               color: colorScheme.primary.withOpacity(0.3),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               'No Accounts Yet',
//               style: theme.textTheme.headlineSmall,
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'You don\'t have any accounts yet. Contact your branch to open a new account.',
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: colorScheme.onSurface.withOpacity(0.7),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             FilledButton.icon(
//               onPressed: () {
//                 // TODO: Navigate to branch locator or account opening
//               },
//               icon: const Icon(Icons.add),
//               label: const Text('Find Nearest Branch'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Error state widget
// class _ErrorState extends StatelessWidget {
//   final String message;
//   final VoidCallback onRetry;

//   const _ErrorState({
//     required this.message,
//     required this.onRetry,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 80,
//               color: colorScheme.error,
//             ),
//             const SizedBox(height: 24),
//             Text(
//               'Oops!',
//               style: theme.textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               message,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: colorScheme.onSurface.withOpacity(0.7),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             FilledButton.icon(
//               onPressed: onRetry,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Try Again'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // No results state
// class _NoResultsState extends StatelessWidget {
//   final VoidCallback onClear;

//   const _NoResultsState({required this.onClear});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.search_off,
//               size: 80,
//               color: theme.colorScheme.primary.withOpacity(0.3),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               'No Results Found',
//               style: theme.textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Try adjusting your filters or search query',
//               style: theme.textTheme.bodyMedium,
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             OutlinedButton(
//               onPressed: onClear,
//               child: const Text('Clear Filters'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }