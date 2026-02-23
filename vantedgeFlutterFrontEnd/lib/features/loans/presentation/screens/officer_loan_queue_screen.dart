import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import '../../data/models/loan_enums.dart';
import '../../data/models/loan_model.dart';
import '../../presentation/providers/loan_officer_provider.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

final _currency = NumberFormat.currency(
  symbol: '৳',
  decimalDigits: 2,
  locale: 'en_IN',
);

final _dateFormat = DateFormat('dd MMM yyyy');

Color _loanTypeColor(LoanType type) {
  switch (type) {
    case LoanType.homeLoan:
      return const Color(0xFF1565C0); // deep blue
    case LoanType.carLoan:
      return const Color(0xFF00838F); // teal
    case LoanType.personalLoan:
      return const Color(0xFF6A1B9A); // purple
    case LoanType.educationLoan:
      return const Color(0xFF2E7D32); // green
    case LoanType.businessLoan:
      return const Color(0xFFE65100); // deep orange
    case LoanType.goldLoan:
      return const Color(0xFFF9A825); // amber
    case LoanType.industrialLoan:
      return const Color(0xFF37474F); // blue-grey
    case LoanType.importLcLoan:
      return const Color(0xFF880E4F); // pink
    case LoanType.workingCapitalLoan:
      return const Color(0xFF004D40); // dark teal
  }
}

IconData _loanTypeIcon(LoanType type) {
  switch (type) {
    case LoanType.homeLoan:
      return Icons.home_rounded;
    case LoanType.carLoan:
      return Icons.directions_car_rounded;
    case LoanType.personalLoan:
      return Icons.person_rounded;
    case LoanType.educationLoan:
      return Icons.school_rounded;
    case LoanType.businessLoan:
      return Icons.business_rounded;
    case LoanType.goldLoan:
      return Icons.diamond_rounded;
    case LoanType.industrialLoan:
      return Icons.factory_rounded;
    case LoanType.importLcLoan:
      return Icons.local_shipping_rounded;
    case LoanType.workingCapitalLoan:
      return Icons.account_balance_wallet_rounded;
  }
}

String _daysAgo(DateTime? date) {
  if (date == null) return '—';
  final diff = DateTime.now().difference(date).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return '1 day ago';
  return '$diff days ago';
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class OfficerLoanQueueScreen extends StatefulWidget {
  const OfficerLoanQueueScreen({super.key});

  @override
  State<OfficerLoanQueueScreen> createState() => _OfficerLoanQueueScreenState();
}

class _OfficerLoanQueueScreenState extends State<OfficerLoanQueueScreen> {
  // Null means "All"
  LoanType? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          context.read<LoanOfficerProvider>();
      if (provider.pendingLoans.isEmpty && !provider.isLoading) {
        provider.fetchPendingLoans();
      }
    });
  }

  // ── Sorted + filtered list ────────────────────────────────────────────────

  List<LoanListItemModel> _filtered(List<LoanListItemModel> raw) {
    final filtered = _selectedType == null
        ? raw
        : raw.where((l) => l.loanType == _selectedType).toList();

    filtered.sort((a, b) {
      final da = a.applicationDate ?? DateTime(2000);
      final db = b.applicationDate ?? DateTime(2000);
      return da.compareTo(db); // oldest first
    });

    return filtered;
  }

  // ── Pull-to-refresh ───────────────────────────────────────────────────────

  Future<void> _refresh() =>
      context.read<LoanOfficerProvider>().fetchPendingLoans();

  // ── Navigate to approval screen ───────────────────────────────────────────

  Future<void> _openApproval(LoanListItemModel item) async {
    final refreshed = await Navigator.pushNamed(
      context,
      AppRoutes.loanApproval,
      arguments: item.loanId,
    );
    if (refreshed == true && mounted) {
      context.read<LoanOfficerProvider>().fetchPendingLoans();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        actions: [
          Consumer<LoanOfficerProvider>(
            builder: (_, p, __) {
              if (p.pendingLoanCount == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  label: Text(
                    '${p.pendingLoanCount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.errorContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<LoanOfficerProvider>(
        builder: (context, provider, _) {
          // ── Error state ──────────────────────────────────────────────────
          if (provider.hasError && !provider.isLoading) {
            return _ErrorBody(
              message: provider.errorMessage ?? 'Failed to load queue.',
              onRetry: _refresh,
            );
          }

          // ── Loading (initial) ────────────────────────────────────────────
          if (provider.isLoading && provider.pendingLoans.isEmpty) {
            return Column(
              children: [
                _FilterBarShimmer(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: 6,
                    itemBuilder: (_, __) => const _ShimmerQueueItem(),
                  ),
                ),
              ],
            );
          }

          final displayed = _filtered(provider.pendingLoans);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Stats banner ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _StatsBanner(provider: provider),
                ),

                // ── Filter bar ───────────────────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterHeaderDelegate(
                    child: _FilterBar(
                      selected: _selectedType,
                      counts: _countsByType(provider.pendingLoans),
                      onSelected: (t) =>
                          setState(() => _selectedType = t),
                    ),
                  ),
                ),

                // ── Empty state ──────────────────────────────────────────
                if (displayed.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyBody(
                      filtered: _selectedType != null,
                      onClear: () =>
                          setState(() => _selectedType = null),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _QueueItem(
                          loan: displayed[i],
                          onReview: () => _openApproval(displayed[i]),
                        ),
                        childCount: displayed.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<LoanType, int> _countsByType(List<LoanListItemModel> loans) {
    final map = <LoanType, int>{};
    for (final l in loans) {
      map[l.loanType] = (map[l.loanType] ?? 0) + 1;
    }
    return map;
  }
}

// ─── Stats Banner ─────────────────────────────────────────────────────────────

class _StatsBanner extends StatelessWidget {
  final LoanOfficerProvider provider;

  const _StatsBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = provider.pendingLoanCount;
    final outstanding = provider.totalOutstandingPending;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions_rounded,
              color: Colors.white70, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Approval Queue',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total application${total == 1 ? '' : 's'} pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total Exposure',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                _currency.format(outstanding),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final LoanType? selected;
  final Map<LoanType, int> counts;
  final ValueChanged<LoanType?> onSelected;

  const _FilterBar({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                // "All" chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      'All (${counts.values.fold(0, (a, b) => a + b)})',
                    ),
                    selected: selected == null,
                    onSelected: (_) => onSelected(null),
                    showCheckmark: false,
                    selectedColor: cs.primary,
                    labelStyle: TextStyle(
                      color: selected == null
                          ? Colors.white
                          : (isDark
                              ? cs.onSurfaceVariant
                              : cs.onSurfaceVariant),
                      fontWeight: selected == null
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: selected == null
                          ? cs.primary
                          : cs.outlineVariant,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                // Per-type chips — only show types that have loans
                ...LoanType.values
                    .where((t) => (counts[t] ?? 0) > 0)
                    .map((type) {
                  final isSelected = selected == type;
                  final typeColor = _loanTypeColor(type);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(
                        _loanTypeIcon(type),
                        size: 15,
                        color: isSelected ? Colors.white : typeColor,
                      ),
                      label: Text(
                        '${type.displayName} (${counts[type] ?? 0})',
                      ),
                      selected: isSelected,
                      onSelected: (_) =>
                          onSelected(isSelected ? null : type),
                      showCheckmark: false,
                      selectedColor: typeColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : cs.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected ? typeColor : cs.outlineVariant,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
        ],
      ),
    );
  }
}

// ─── Filter Header Delegate (pinned) ─────────────────────────────────────────

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _FilterHeaderDelegate({required this.child});

  @override
  double get minExtent => 49;
  @override
  double get maxExtent => 49;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(_FilterHeaderDelegate old) => old.child != child;
}

// ─── Queue Item (LoanCard replacement) ───────────────────────────────────────

class _QueueItem extends StatelessWidget {
  final LoanListItemModel loan;
  final VoidCallback onReview;

  const _QueueItem({required this.loan, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _loanTypeColor(loan.loanType);
    final daysWaiting = loan.applicationDate != null
        ? DateTime.now().difference(loan.applicationDate!).inDays
        : null;
    final isUrgent = daysWaiting != null && daysWaiting >= 5;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isUrgent
              ? cs.error.withOpacity(0.45)
              : cs.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: InkWell(
        onTap: onReview,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar with type colour ────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: typeColor.withOpacity(isDark ? 0.2 : 0.08),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(isDark ? 0.35 : 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_loanTypeIcon(loan.loanType),
                        color: typeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.loanType.displayName,
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'ID: ${loan.loanId}',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Urgency badge
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 12,
                              color: cs.onErrorContainer),
                          const SizedBox(width: 3),
                          Text(
                            'Urgent',
                            style: TextStyle(
                              color: cs.onErrorContainer,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _StatusPill(status: loan.loanStatus.displayName),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Applicant
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          loan.customerName ?? 'Unknown Applicant',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Amount + date row
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.account_balance_outlined,
                          label: 'Requested',
                          value: _currency.format(loan.principal),
                          valueColor: cs.primary,
                          bold: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Applied',
                          value: loan.applicationDate != null
                              ? _dateFormat.format(loan.applicationDate!)
                              : '—',
                        ),
                      ),
                    ],
                  ),

                  // Waiting duration
                  if (daysWaiting != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: isUrgent
                              ? cs.error
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Waiting: ${_daysAgo(loan.applicationDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isUrgent
                                ? cs.error
                                : cs.onSurfaceVariant,
                            fontWeight: isUrgent
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Review button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onReview,
                      icon: const Icon(Icons.rate_review_rounded, size: 18),
                      label: const Text('Review Application'),
                      style: FilledButton.styleFrom(
                        backgroundColor: typeColor,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small reusable tiles ─────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: valueColor,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  final bool filtered;
  final VoidCallback onClear;

  const _EmptyBody({required this.filtered, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtered
                  ? Icons.filter_list_off_rounded
                  : Icons.inbox_rounded,
              size: 72,
              color: cs.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              filtered
                  ? 'No applications match this filter'
                  : 'Queue is clear!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'Try selecting a different loan type.'
                  : 'No pending loan applications at this time.',
              style:
                  TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (filtered) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Clear Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 64, color: cs.error.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              'Failed to load queue',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style:
                  TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
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

// ─── Shimmer placeholders ─────────────────────────────────────────────────────

class _ShimmerQueueItem extends StatelessWidget {
  const _ShimmerQueueItem();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final highlight =
        isDark ? Colors.grey.shade600 : Colors.grey.shade100;

    return _Shimmer(
      baseColor: base,
      highlightColor: highlight,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ShimmerBox(width: 36, height: 36, radius: 10),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 120, height: 14),
                      const SizedBox(height: 4),
                      _ShimmerBox(width: 80, height: 11),
                    ],
                  ),
                  const Spacer(),
                  _ShimmerBox(width: 60, height: 22, radius: 20),
                ],
              ),
              const SizedBox(height: 14),
              _ShimmerBox(width: 160, height: 15),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _ShimmerBox(height: 36)),
                  const SizedBox(width: 12),
                  Expanded(child: _ShimmerBox(height: 36)),
                ],
              ),
              const SizedBox(height: 12),
              _ShimmerBox(width: double.infinity, height: 40, radius: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBarShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final highlight =
        isDark ? Colors.grey.shade600 : Colors.grey.shade100;

    return _Shimmer(
      baseColor: base,
      highlightColor: highlight,
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ShimmerBox(width: 90, height: 32, radius: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _ShimmerBox({
    this.width,
    this.height = 16,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Minimal inline shimmer (avoids package dependency issues in isolation)
class _Shimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const _Shimmer({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            widget.baseColor,
            widget.highlightColor,
            widget.baseColor
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(_anim.value - 1, 0),
          end: Alignment(_anim.value + 1, 0),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}
