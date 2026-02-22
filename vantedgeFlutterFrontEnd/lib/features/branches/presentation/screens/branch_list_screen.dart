import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/features/branches/data/models/branch_response_dto.dart';
import 'package:vantedge/features/branches/presentation/providers/branch_provider.dart';
import 'package:vantedge/features/branches/presentation/widgets/branch_card.dart';
import 'branch_details_screen.dart';

class BranchListScreen extends StatefulWidget {
  const BranchListScreen({super.key});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCity;
  bool _sortByName = true;   // true → sort by name, false → sort by city
  bool _sortAscending = true; // direction toggle

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BranchProvider>();
      if (!provider.hasBranches) provider.fetchAllBranches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data helpers ─────────────────────────────────────────────────────────────

  List<BranchResponseDTO> _getFiltered(BranchProvider provider) {
    var branches = provider.branches.toList();

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      branches = branches.where((b) =>
        b.branchName.toLowerCase().contains(q) ||
        b.city.toLowerCase().contains(q) ||
        b.branchCode.toLowerCase().contains(q) ||
        b.ifscCode.toLowerCase().contains(q),
      ).toList();
    }

    // City chip filter
    if (_selectedCity != null) {
      branches = branches.where((b) => b.city == _selectedCity).toList();
    }

    // Sort
    branches.sort((a, b) {
      final cmp = _sortByName
          ? a.branchName.compareTo(b.branchName)
          : a.city.compareTo(b.city);
      return _sortAscending ? cmp : -cmp;
    });

    return branches;
  }

  // ── Pull-to-refresh ───────────────────────────────────────────────────────────

  Future<void> _handleRefresh() async {
    await context.read<BranchProvider>().fetchAllBranches();
  }

  // ── Clear helpers ─────────────────────────────────────────────────────────────

  void _clearCityFilter() {
    setState(() => _selectedCity = null);
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branches'),
        actions: [
          // Sort axis toggle (name ↔ city)
          IconButton(
            icon: Icon(_sortByName ? Icons.sort_by_alpha : Icons.location_city),
            tooltip: _sortByName ? 'Sort by city' : 'Sort by name',
            onPressed: () => setState(() => _sortByName = !_sortByName),
          ),
          // Sort direction toggle (asc ↔ desc)
          IconButton(
            icon: Icon(_sortAscending
                ? Icons.arrow_upward
                : Icons.arrow_downward),
            tooltip: _sortAscending ? 'Sort descending' : 'Sort ascending',
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, city, code or IFSC…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // ── City filter chips ───────────────────────────────────────────────
          Consumer<BranchProvider>(
            builder: (context, provider, _) {
              if (provider.cities.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCity == null,
                      onSelected: (_) =>
                          setState(() => _selectedCity = null),
                    ),
                    ...provider.cities.map((city) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(city),
                            selected: _selectedCity == city,
                            onSelected: (_) =>
                                setState(() => _selectedCity = city),
                          ),
                        )),
                  ],
                ),
              );
            },
          ),

          // ── Active filter summary chip ───────────────────────────────────────
          if (_selectedCity != null || _searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedCity != null)
                    Chip(
                      avatar: const Icon(Icons.location_on, size: 16),
                      label: Text(_selectedCity!),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: _clearCityFilter,
                      backgroundColor:
                          colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                          color: colorScheme.onSecondaryContainer),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (_searchQuery.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.search, size: 16),
                      label: Text('"$_searchQuery"'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: _clearSearch,
                      backgroundColor: colorScheme.tertiaryContainer,
                      labelStyle: TextStyle(
                          color: colorScheme.onTertiaryContainer),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),

          const SizedBox(height: 4),

          // ── Branch list ─────────────────────────────────────────────────────
          Expanded(
            child: Consumer<BranchProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && !provider.hasBranches) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          provider.errorMessage ?? 'An error occurred',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _handleRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!provider.hasBranches) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No branches found'),
                      ],
                    ),
                  );
                }

                final branches = _getFiltered(provider);

                if (branches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 56,
                            color: colorScheme.onSurfaceVariant
                                .withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No branches match your filters',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // ── Pull-to-refresh wraps the list ─────────────────────────
                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    // Extra item count for sort/filter info header
                    itemCount: branches.length + 1,
                    itemBuilder: (context, i) {
                      // Header row showing result count + current sort
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                '${branches.length} branch${branches.length == 1 ? '' : 'es'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Sorted by ${_sortByName ? 'name' : 'city'} '
                                '(${_sortAscending ? 'A–Z' : 'Z–A'})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final branch = branches[i - 1];
                      return BranchCard(
                        branch: branch,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BranchDetailsScreen(branchId: branch.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:vantedge/features/branches/data/models/branch_response_dto.dart';
// // import '../../../data/models/branch_response_dto.dart';
// import '../providers/branch_provider.dart';
// import 'branch_details_screen.dart';

// /// Screen for displaying and searching branches
// class BranchListScreen extends StatefulWidget {
//   const BranchListScreen({super.key});

//   @override
//   State<BranchListScreen> createState() => _BranchListScreenState();
// }

// class _BranchListScreenState extends State<BranchListScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _selectedCity;
//   bool _sortByName = true;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final provider = context.read<BranchProvider>();
//       if (!provider.hasBranches) provider.fetchAllBranches();
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   List<BranchResponseDTO> _getFiltered(BranchProvider provider) {
//     var branches = provider.branches;
//     if (_searchQuery.isNotEmpty) {
//       branches = branches.where((b) =>
//         b.branchName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//         b.city.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
//     }
//     if (_selectedCity != null) {
//       branches = branches.where((b) => b.city == _selectedCity).toList();
//     }
//     branches.sort((a, b) => _sortByName 
//       ? a.branchName.compareTo(b.branchName)
//       : a.city.compareTo(b.city));
//     return branches;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Branches'),
//         actions: [
//           IconButton(
//             icon: Icon(_sortByName ? Icons.sort_by_alpha : Icons.location_city),
//             onPressed: () => setState(() => _sortByName = !_sortByName),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search branches...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//               onChanged: (v) => setState(() => _searchQuery = v),
//             ),
//           ),
//           Consumer<BranchProvider>(
//             builder: (context, provider, _) {
//               if (provider.cities.isEmpty) return const SizedBox.shrink();
//               return SizedBox(
//                 height: 50,
//                 child: ListView(
//                   scrollDirection: Axis.horizontal,
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   children: [
//                     ChoiceChip(
//                       label: const Text('All'),
//                       selected: _selectedCity == null,
//                       onSelected: (_) => setState(() => _selectedCity = null),
//                     ),
//                     ...provider.cities.map((city) => Padding(
//                       padding: const EdgeInsets.only(left: 8),
//                       child: ChoiceChip(
//                         label: Text(city),
//                         selected: _selectedCity == city,
//                         onSelected: (_) => setState(() => _selectedCity = city),
//                       ),
//                     )),
//                   ],
//                 ),
//               );
//             },
//           ),
//           Expanded(
//             child: Consumer<BranchProvider>(
//               builder: (context, provider, _) {
//                 if (provider.isLoading) return const Center(child: CircularProgressIndicator());
//                 if (provider.hasError) return Center(child: Text(provider.errorMessage!));
//                 if (!provider.hasBranches) return const Center(child: Text('No branches'));
                
//                 final branches = _getFiltered(provider);
//                 return ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: branches.length,
//                   itemBuilder: (context, i) {
//                     final branch = branches[i];
//                     return Card(
//                       child: ListTile(
//                         leading: const Icon(Icons.business),
//                         title: Text(branch.branchName),
//                         subtitle: Text('${branch.city} • ${branch.branchCode}'),
//                         trailing: const Icon(Icons.chevron_right),
//                         onTap: () => Navigator.push(context, MaterialPageRoute(
//                           builder: (_) => BranchDetailsScreen(branchId: branch.id),
//                         )),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }