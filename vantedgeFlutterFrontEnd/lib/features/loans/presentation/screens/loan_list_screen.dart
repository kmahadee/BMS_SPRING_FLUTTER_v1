import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/core/widgets/empty_state.dart';
import 'package:vantedge/features/loans/data/models/loan_enums.dart';
import 'package:vantedge/features/loans/data/models/loan_model.dart';
import 'package:vantedge/features/loans/presentation/providers/loan_provider.dart';
import 'package:vantedge/features/loans/presentation/widgets/loan_card.dart';
import 'package:vantedge/features/loans/presentation/widgets/loan_enum_display_helpers.dart';
// import 'package:vantedge/shared/widgets/empty_state.dart';
import 'package:vantedge/shared/widgets/main_scaffold.dart';

import 'loan_details_screen.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class LoanListScreen extends StatefulWidget {
  const LoanListScreen({super.key});

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen> {
  // null means "All"
  LoanStatus? _filterStatus;

  // Sort options
  _SortOption _sort = _SortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LoanProvider>();
      if (!provider.hasLoans && !provider.isLoading) {
        provider.fetchMyLoans();
      }
    });
  }

  // ── Refresh ────────────────────────────────────────────────────────────────

  Future<void> _handleRefresh() => context.read<LoanProvider>().fetchMyLoans();

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _openDetails(LoanListItemModel loan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanDetailsScreen(loanId: loan.loanId),
      ),
    );
  }

  void _openApplication() {
    Navigator.pushNamed(context, AppRoutes.loanApplication);
  }

  // ── Filter / sort helpers ──────────────────────────────────────────────────

  List<LoanListItemModel> _apply(List<LoanListItemModel> src) {
    var list = _filterStatus == null
        ? List<LoanListItemModel>.from(src)
        : src.where((l) => l.loanStatus == _filterStatus).toList();

    switch (_sort) {
      case _SortOption.dateDesc:
        list.sort((a, b) =>
            (b.applicationDate ?? DateTime(0))
                .compareTo(a.applicationDate ?? DateTime(0)));
        break;
      case _SortOption.dateAsc:
        list.sort((a, b) =>
            (a.applicationDate ?? DateTime(0))
                .compareTo(b.applicationDate ?? DateTime(0)));
        break;
      case _SortOption.amountHigh:
        list.sort((a, b) => b.principal.compareTo(a.principal));
        break;
      case _SortOption.amountLow:
        list.sort((a, b) => a.principal.compareTo(b.principal));
        break;
    }
    return list;
  }

  void _clearFilter() => setState(() => _filterStatus = null);

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SortSheet(
        current: _sort,
        onSelected: (s) {
          setState(() => _sort = s);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: (context, provider, _) {
        // ── Shimmer while first load ────────────────────────────────────────
        if (provider.isLoading && !provider.hasLoans) {
          return MainScaffold(
            currentRoute: AppRoutes.loans,
            title: 'My Loans',
            showDrawer: true,
            showBottomNav: true,
            child: const _LoanShimmerList(),
          );
        }

        // ── Error (no cached data) ──────────────────────────────────────────
        if (provider.hasError && !provider.hasLoans) {
          return MainScaffold(
            currentRoute: AppRoutes.loans,
            title: 'My Loans',
            showDrawer: true,
            showBottomNav: true,
            child: _ErrorBody(
              message: provider.errorMessage!,
              onRetry: () {
                provider.clearError();
                provider.fetchMyLoans();
              },
            ),
          );
        }

        // ── True empty (no loans at all) ────────────────────────────────────
        if (!provider.hasLoans) {
          return MainScaffold(
            currentRoute: AppRoutes.loans,
            title: 'My Loans',
            showDrawer: true,
            showBottomNav: true,
            child: EmptyState.noLoans(onApplyLoan: _openApplication),
          );
        }

        // ── Filtered list ───────────────────────────────────────────────────
        final filtered = _apply(provider.myLoans);

        return MainScaffold(
          currentRoute: AppRoutes.loans,
          title: 'My Loans',
          showDrawer: true,
          showBottomNav: true,
          appBarActions: [
            IconButton(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Sort',
              onPressed: _showSortSheet,
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openApplication,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Apply for Loan'),
          ),
          child: Column(
            children: [
              // ── Summary strip ─────────────────────────────────────────────
              _SummaryStrip(provider: provider),

              // ── Filter chips ──────────────────────────────────────────────
              _FilterChipRow(
                selected: _filterStatus,
                onSelected: (s) => setState(() => _filterStatus = s),
                onClear: _clearFilter,
              ),

              // ── List ──────────────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: filtered.isEmpty
                      ? EmptyState.noFilterResults(onClearFilters: _clearFilter)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => LoanCard(
                            loan: filtered[i],
                            onTap: () => _openDetails(filtered[i]),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Summary Strip ────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final LoanProvider provider;

  const _SummaryStrip({required this.provider});

  static final _fmt = NumberFormat.compactCurrency(
    symbol: '৳',
    decimalDigits: 0,
    locale: 'en_IN',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _StripCell(
            label: 'Active',
            value: '${provider.activeLoanCount}',
            color: const Color(0xFF00695C),
            theme: theme,
          ),
          _VertDivider(),
          _StripCell(
            label: 'Outstanding',
            value: _fmt.format(provider.totalOutstanding),
            color: cs.error,
            theme: theme,
          ),
          _VertDivider(),
          _StripCell(
            label: 'Monthly EMI',
            value: _fmt.format(provider.totalMonthlyEMI),
            color: cs.primary,
            theme: theme,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _StripCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;
  final bool bold;

  const _StripCell({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip Row ──────────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  final LoanStatus? selected;
  final ValueChanged<LoanStatus?> onSelected;
  final VoidCallback onClear;

  const _FilterChipRow({
    required this.selected,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      color: cs.surfaceContainerHighest.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // "All" chip
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: selected == null,
                onSelected: (_) => onSelected(null),
              ),
            ),
            // Status chips
            ...LoanStatus.values.map((status) {
              final isSelected = selected == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: isSelected
                      ? null
                      : Icon(status.icon, size: 14,
                          color: status.badgeBackgroundColor),
                  label: Text(status.displayName),
                  selected: isSelected,
                  selectedColor: status.badgeBackgroundColor,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? status.badgeTextColor
                        : cs.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  onSelected: (v) => onSelected(v ? status : null),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Sort Bottom Sheet ────────────────────────────────────────────────────────

enum _SortOption {
  dateDesc,
  dateAsc,
  amountHigh,
  amountLow,
}

extension _SortLabel on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.dateDesc: return 'Newest First';
      case _SortOption.dateAsc:  return 'Oldest First';
      case _SortOption.amountHigh: return 'Amount (High → Low)';
      case _SortOption.amountLow:  return 'Amount (Low → High)';
    }
  }

  IconData get icon {
    switch (this) {
      case _SortOption.dateDesc:   return Icons.arrow_downward_rounded;
      case _SortOption.dateAsc:    return Icons.arrow_upward_rounded;
      case _SortOption.amountHigh: return Icons.payments_rounded;
      case _SortOption.amountLow:  return Icons.money_off_rounded;
    }
  }
}

class _SortSheet extends StatelessWidget {
  final _SortOption current;
  final ValueChanged<_SortOption> onSelected;

  const _SortSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sort By', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          ..._SortOption.values.map((opt) => RadioListTile<_SortOption>(
                value: opt,
                groupValue: current,
                onChanged: (v) => onSelected(v!),
                title: Text(opt.label),
                secondary: Icon(opt.icon),
                contentPadding: EdgeInsets.zero,
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Shimmer Loader ───────────────────────────────────────────────────────────

class _LoanShimmerList extends StatelessWidget {
  const _LoanShimmerList();

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor:      isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: _ShimmerLoanCard(),
      ),
    );
  }
}

class _ShimmerLoanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                _Box(46, 46, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Box(16, 140),
                      const SizedBox(height: 6),
                      _Box(12, 100),
                    ],
                  ),
                ),
                _Box(22, 70, radius: 11),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Box(12, 80),
                _Box(12, 80),
                _Box(12, 80),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final double h;
  final double w;
  final double radius;

  const _Box(this.h, this.w, {this.radius = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Error body ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: cs.error),
            const SizedBox(height: 20),
            Text(
              'Failed to load loans',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
