import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:vantedge/features/dps/data/models/dps_installment_model.dart';
import 'package:vantedge/features/dps/presentation/providers/dps_provider.dart';
import 'package:vantedge/features/dps/presentation/widgets/installment_card.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';

// ── Filter enum ─────────────────────────────────────────────────────────────

enum _InstallmentFilter {
  all('All'),
  paid('Paid'),
  pending('Pending'),
  overdue('Overdue'),
  waived('Waived');

  const _InstallmentFilter(this.label);
  final String label;
}

// ── Screen ──────────────────────────────────────────────────────────────────

class InstallmentHistoryScreen extends StatefulWidget {
  final String dpsNumber;

  const InstallmentHistoryScreen({super.key, required this.dpsNumber});

  @override
  State<InstallmentHistoryScreen> createState() =>
      _InstallmentHistoryScreenState();
}

class _InstallmentHistoryScreenState extends State<InstallmentHistoryScreen> {
  _InstallmentFilter _filter = _InstallmentFilter.all;

  // ── Formatters ─────────────────────────────────────────────────────────────

  static final _currFmt = NumberFormat.currency(
    symbol: '৳ ',
    decimalDigits: 2,
    locale: 'en_IN',
  );
  static final _compactFmt = NumberFormat.compactCurrency(
    symbol: '৳',
    decimalDigits: 1,
    locale: 'en_IN',
  );

  String _compact(double v) => _compactFmt.format(v);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DpsProvider>();
      if (provider.installments.isEmpty && !provider.isLoading) {
        provider.fetchInstallments(widget.dpsNumber);
      }
    });
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<DpsInstallmentModel> _filtered(List<DpsInstallmentModel> src) {
    if (_filter == _InstallmentFilter.all) return src;
    return src
        .where((i) =>
            i.status?.toUpperCase() == _filter.label.toUpperCase())
        .toList();
  }

  // ── Counts for filter chips ────────────────────────────────────────────────

  Map<_InstallmentFilter, int> _counts(List<DpsInstallmentModel> all) {
    final m = <_InstallmentFilter, int>{
      _InstallmentFilter.all: all.length,
    };
    for (final f in _InstallmentFilter.values) {
      if (f == _InstallmentFilter.all) continue;
      m[f] = all
          .where((i) => i.status?.toUpperCase() == f.label.toUpperCase())
          .length;
    }
    return m;
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _handleRefresh() =>
      context.read<DpsProvider>().fetchInstallments(widget.dpsNumber);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<DpsProvider>(
      builder: (context, provider, _) {
        // Loading
        if (provider.isLoading && provider.installments.isEmpty) {
          return _LoadingScaffold(dpsNumber: widget.dpsNumber);
        }

        // Error
        if (provider.hasError && provider.installments.isEmpty) {
          return _ErrorScaffold(
            dpsNumber: widget.dpsNumber,
            message: provider.errorMessage ?? 'Could not load installments.',
            onRetry: () {
              provider.clearMessages();
              _handleRefresh();
            },
          );
        }

        final all      = provider.installments;
        final counts   = _counts(all);
        final filtered = _filtered(all);

        // Total deposited = sum of PAID installment amounts
        final totalDeposited = all
            .where((i) => i.status?.toUpperCase() == 'PAID')
            .fold<double>(0.0, (sum, i) => sum + (i.amount ?? 0));

        final paidCount = counts[_InstallmentFilter.paid] ?? 0;
        // tenure = total installments from statement (use all.length as proxy)
        final tenureCount = all.length;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: CustomAppBar(
            title: 'Installment History',
            showNotifications: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: _handleRefresh,
              ),
            ],
          ),
          body: Column(
            children: [
              // ── DPS number subtitle banner ──────────────────────────────
              _DpsSubtitleBanner(dpsNumber: widget.dpsNumber),

              // ── Summary header ─────────────────────────────────────────
              _SummaryHeader(
                all: all,
                counts: counts,
                compact: _compact,
              ),

              // ── Filter chips ────────────────────────────────────────────
              _FilterBar(
                selected: _filter,
                counts: counts,
                onSelected: (f) => setState(() => _filter = f),
              ),

              // ── List ────────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyFiltered(
                        filter: _filter,
                        onClear: () =>
                            setState(() => _filter = _InstallmentFilter.all),
                      )
                    : RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              16, 12, 16, 120),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              InstallmentCard(installment: filtered[i]),
                        ),
                      ),
              ),
            ],
          ),

          // ── Sticky summary bottom bar ────────────────────────────────────
          bottomNavigationBar: _StickyBottomBar(
            paidCount:      paidCount,
            tenureCount:    tenureCount,
            totalDeposited: totalDeposited,
            compact:        _compact,
          ),
        );
      },
    );
  }
}

// ── DPS subtitle banner ─────────────────────────────────────────────────────

class _DpsSubtitleBanner extends StatelessWidget {
  final String dpsNumber;

  const _DpsSubtitleBanner({required this.dpsNumber});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      width: double.infinity,
      color: cs.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        dpsNumber,
        style: theme.textTheme.labelMedium?.copyWith(
          color: cs.onPrimary.withOpacity(0.8),
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Summary header ──────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final List<DpsInstallmentModel> all;
  final Map<_InstallmentFilter, int> counts;
  final String Function(double) compact;

  const _SummaryHeader({
    required this.all,
    required this.counts,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
    final total    = all.length;
    final paid     = counts[_InstallmentFilter.paid]    ?? 0;
    final pending  = counts[_InstallmentFilter.pending] ?? 0;
    final overdue  = counts[_InstallmentFilter.overdue] ?? 0;
    final progress = total > 0 ? paid / total : 0.0;
    final hasOverdue = overdue > 0;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cells
          IntrinsicHeight(
            child: Row(
              children: [
                _StatCell('$total',   'Total',   cs.primary,              theme),
                _VSep(cs),
                _StatCell('$paid',    'Paid',    const Color(0xFF2E7D32), theme),
                _VSep(cs),
                _StatCell('$pending', 'Pending', const Color(0xFFF57F17), theme),
                _VSep(cs),
                _StatCell('$overdue', 'Overdue', cs.error,               theme),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      hasOverdue ? cs.error : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final ThemeData theme;

  const _StatCell(this.value, this.label, this.color, this.theme);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VSep extends StatelessWidget {
  final ColorScheme cs;
  const _VSep(this.cs);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: cs.outlineVariant.withOpacity(0.6),
    );
  }
}

// ── Filter bar ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _InstallmentFilter selected;
  final Map<_InstallmentFilter, int> counts;
  final ValueChanged<_InstallmentFilter> onSelected;

  const _FilterBar({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  Color _chipColor(_InstallmentFilter f, ColorScheme cs) {
    switch (f) {
      case _InstallmentFilter.all:     return cs.primary;
      case _InstallmentFilter.paid:    return const Color(0xFF2E7D32);
      case _InstallmentFilter.pending: return const Color(0xFFF57F17);
      case _InstallmentFilter.overdue: return cs.error;
      case _InstallmentFilter.waived:  return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surfaceContainerHighest.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: _InstallmentFilter.values.map((f) {
            final isSelected = selected == f;
            final color      = _chipColor(f, cs);
            final count      = counts[f] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelected(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.14)
                        : Colors.transparent,
                    border: Border.all(
                        color: isSelected ? color : cs.outlineVariant),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${f.label} ($count)',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isSelected ? color : cs.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Sticky bottom summary bar ────────────────────────────────────────────────

class _StickyBottomBar extends StatelessWidget {
  final int paidCount;
  final int tenureCount;
  final double totalDeposited;
  final String Function(double) compact;

  const _StickyBottomBar({
    required this.paidCount,
    required this.tenureCount,
    required this.totalDeposited,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Installments Paid',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$paidCount / $tenureCount',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: cs.outlineVariant.withOpacity(0.6),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Deposited',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    compact(totalDeposited),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty filtered state ─────────────────────────────────────────────────────

class _EmptyFiltered extends StatelessWidget {
  final _InstallmentFilter filter;
  final VoidCallback onClear;

  const _EmptyFiltered({required this.filter, required this.onClear});

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
            Icon(Icons.inbox_rounded, size: 72, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No ${filter.label} installments',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different filter to see more results.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Show All'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading scaffold ─────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  final String dpsNumber;
  const _LoadingScaffold({required this.dpsNumber});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Installment History',
        showNotifications: false,
      ),
      body: Shimmer.fromColors(
        baseColor:      isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const _ShimmerCard(),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ── Error scaffold ───────────────────────────────────────────────────────────

class _ErrorScaffold extends StatelessWidget {
  final String dpsNumber;
  final String message;
  final VoidCallback onRetry;

  const _ErrorScaffold({
    required this.dpsNumber,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Installment History',
        showNotifications: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 72, color: cs.error),
              const SizedBox(height: 20),
              Text(
                'Failed to load installments',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
