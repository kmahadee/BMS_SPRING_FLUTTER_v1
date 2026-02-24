import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import '../../data/models/loan_enums.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_search.dart';
import '../../presentation/providers/loan_officer_provider.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

final _currency = NumberFormat.currency(
  symbol: '৳',
  decimalDigits: 2,
  locale: 'en_IN',
);
final _dateFormat = DateFormat('dd MMM yyyy');

Color _typeColor(LoanType t) {
  switch (t) {
    case LoanType.homeLoan:           return const Color(0xFF1565C0);
    case LoanType.carLoan:            return const Color(0xFF00838F);
    case LoanType.personalLoan:       return const Color(0xFF6A1B9A);
    case LoanType.educationLoan:      return const Color(0xFF2E7D32);
    case LoanType.businessLoan:       return const Color(0xFFE65100);
    case LoanType.goldLoan:           return const Color(0xFFF9A825);
    case LoanType.industrialLoan:     return const Color(0xFF37474F);
    case LoanType.importLcLoan:       return const Color(0xFF880E4F);
    case LoanType.workingCapitalLoan: return const Color(0xFF004D40);
  }
}

IconData _typeIcon(LoanType t) {
  switch (t) {
    case LoanType.homeLoan:           return Icons.home_rounded;
    case LoanType.carLoan:            return Icons.directions_car_rounded;
    case LoanType.personalLoan:       return Icons.person_rounded;
    case LoanType.educationLoan:      return Icons.school_rounded;
    case LoanType.businessLoan:       return Icons.business_rounded;
    case LoanType.goldLoan:           return Icons.diamond_rounded;
    case LoanType.industrialLoan:     return Icons.factory_rounded;
    case LoanType.importLcLoan:       return Icons.local_shipping_rounded;
    case LoanType.workingCapitalLoan: return Icons.account_balance_wallet_rounded;
  }
}

Color _statusColor(LoanStatus s, ColorScheme cs) {
  switch (s) {
    case LoanStatus.active:    return const Color(0xFF2E7D32);
    case LoanStatus.approved:  return const Color(0xFF1565C0);
    case LoanStatus.defaulted: return cs.error;
    case LoanStatus.closed:    return cs.onSurfaceVariant;
    case LoanStatus.processing:
    case LoanStatus.application:
      return const Color(0xFFF57F17);
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class LoanSearchScreen extends StatefulWidget {
  const LoanSearchScreen({super.key});

  @override
  State<LoanSearchScreen> createState() => _LoanSearchScreenState();
}

class _LoanSearchScreenState extends State<LoanSearchScreen> {
  final _customerIdCtrl = TextEditingController();

  LoanType? _selectedType;
  LoanStatus? _selectedStatus;

  bool _hasSearched = false;
  bool _filtersExpanded = true;

  @override
  void dispose() {
    _customerIdCtrl.dispose();
    super.dispose();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<void> _search({int page = 0}) async {
    final request = LoanSearchRequestModel(
      customerId: _customerIdCtrl.text.trim().isEmpty
          ? null
          : _customerIdCtrl.text.trim(),
      loanType: _selectedType,
      loanStatus: _selectedStatus,
      pageNumber: page,
      pageSize: 20,
    );

    await context.read<LoanOfficerProvider>().searchLoans(request);
    if (mounted) {
      setState(() {
        _hasSearched = true;
        if (page == 0) _filtersExpanded = false; // collapse filters on new search
      });
    }
  }

  Future<void> _loadMore() =>
      context.read<LoanOfficerProvider>().loadNextPage();

  void _clearFilters() {
    setState(() {
      _customerIdCtrl.clear();
      _selectedType = null;
      _selectedStatus = null;
      _hasSearched = false;
    });
    context.read<LoanOfficerProvider>().clearSearchResults();
  }

  // ── Navigate to detail/approval ───────────────────────────────────────────

  void _openLoan(LoanListItemModel loan) {
    final isPendingApproval = loan.approvalStatus == ApprovalStatus.pending &&
        (loan.loanStatus == LoanStatus.application ||
            loan.loanStatus == LoanStatus.processing);

    if (isPendingApproval) {
      Navigator.pushNamed(
        context,
        AppRoutes.loanApproval,
        arguments: loan.loanId,
      );
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.loanDetails,
        arguments: loan.loanId,
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Search'),
        centerTitle: false,
        actions: [
          if (_hasSearched)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Clear'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1,
              thickness: 0.5,
              color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      body: Consumer<LoanOfficerProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // ── Filter panel ──────────────────────────────────────────
              _FilterPanel(
                expanded: _filtersExpanded,
                onToggle: () =>
                    setState(() => _filtersExpanded = !_filtersExpanded),
                customerIdCtrl: _customerIdCtrl,
                selectedType: _selectedType,
                selectedStatus: _selectedStatus,
                onTypeChanged: (t) => setState(() => _selectedType = t),
                onStatusChanged: (s) => setState(() => _selectedStatus = s),
                onSearch: () => _search(page: 0),
                isLoading: provider.isLoading,
              ),

              // ── Results area ──────────────────────────────────────────
              Expanded(
                child: _buildResults(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResults(LoanOfficerProvider provider) {
    // Initial (no search yet)
    if (!_hasSearched && !provider.isLoading) {
      return _InitialBody();
    }

    // Loading first page
    if (provider.isLoading && provider.searchResults.isEmpty) {
      return _LoadingList();
    }

    // Error
    if (provider.hasError && provider.searchResults.isEmpty) {
      return _ErrorBody(
        message: provider.errorMessage ?? 'Search failed.',
        onRetry: () => _search(page: 0),
      );
    }

    // Empty results
    if (provider.searchResults.isEmpty && _hasSearched) {
      return _EmptyBody(onClear: _clearFilters);
    }

    final results = provider.searchResults;
    final total = provider.totalSearchCount;
    final hasMore = provider.hasNextPage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Result count strip ──────────────────────────────────────
        _ResultCountBar(
          total: total,
          showing: results.length,
          isLoading: provider.isLoading,
        ),

        // ── Result list ─────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: results.length + (hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == results.length) {
                // Load More button
                return _LoadMoreButton(
                  isLoading: provider.isLoading,
                  onPressed: _loadMore,
                );
              }
              return _SearchResultCard(
                loan: results[i],
                onTap: () => _openLoan(results[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Filter Panel ─────────────────────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController customerIdCtrl;
  final LoanType? selectedType;
  final LoanStatus? selectedStatus;
  final ValueChanged<LoanType?> onTypeChanged;
  final ValueChanged<LoanStatus?> onStatusChanged;
  final VoidCallback onSearch;
  final bool isLoading;

  const _FilterPanel({
    required this.expanded,
    required this.onToggle,
    required this.customerIdCtrl,
    required this.selectedType,
    required this.selectedStatus,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onSearch,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
              color: cs.outlineVariant.withOpacity(0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Toggle header ───────────────────────────────────────────
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded,
                      size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Search Filters',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  if (selectedType != null || selectedStatus != null ||
                      customerIdCtrl.text.isNotEmpty)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded fields ─────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Customer ID
                  TextField(
                    controller: customerIdCtrl,
                    decoration: InputDecoration(
                      labelText: 'Customer ID',
                      hintText: 'e.g. CUST-00123',
                      prefixIcon: const Icon(Icons.person_search_rounded),
                      suffixIcon: customerIdCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: customerIdCtrl.clear,
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    onChanged: (_) {},
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSearch(),
                  ),
                  const SizedBox(height: 12),

                  // Type + Status dropdowns in a row
                  Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown<LoanType>(
                          label: 'Loan Type',
                          value: selectedType,
                          items: LoanType.values,
                          displayName: (t) => t.displayName,
                          onChanged: onTypeChanged,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FilterDropdown<LoanStatus>(
                          label: 'Status',
                          value: selectedStatus,
                          items: LoanStatus.values,
                          displayName: (s) => s.displayName,
                          onChanged: onStatusChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isLoading ? null : onSearch,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Icon(Icons.search_rounded),
                      label: Text(
                        isLoading ? 'Searching…' : 'Search Loans',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Dropdown ──────────────────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) displayName;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.displayName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 12),
      ),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text(
            'All',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
        ...items.map((t) => DropdownMenuItem<T>(
              value: t,
              child: Text(
                displayName(t),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            )),
      ],
      onChanged: onChanged,
    );
  }
}

// ─── Result Count Bar ─────────────────────────────────────────────────────────

class _ResultCountBar extends StatelessWidget {
  final int? total;
  final int showing;
  final bool isLoading;

  const _ResultCountBar({
    required this.total,
    required this.showing,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLowest,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.format_list_bulleted_rounded,
              size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              total != null
                  ? 'Showing $showing of $total loan${total == 1 ? '' : 's'}'
                  : '$showing result${showing == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

// ─── Search Result Card (LoanCard) ───────────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  final LoanListItemModel loan;
  final VoidCallback onTap;

  const _SearchResultCard({required this.loan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _typeColor(loan.loanType);
    final statusColor = _statusColor(loan.loanStatus, cs);

    // Determine CTA label
    final isPendingApproval =
        loan.approvalStatus == ApprovalStatus.pending &&
            (loan.loanStatus == LoanStatus.application ||
                loan.loanStatus == LoanStatus.processing);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: cs.outlineVariant.withOpacity(0.55)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Coloured header ───────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: typeColor.withOpacity(isDark ? 0.18 : 0.07),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color:
                          typeColor.withOpacity(isDark ? 0.3 : 0.13),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(_typeIcon(loan.loanType),
                        color: typeColor, size: 18),
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
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          loan.loanId,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  _StatusBadge(
                      label: loan.loanStatus.displayName,
                      color: statusColor),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer name
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 15, color: cs.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          loan.customerName ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Approval status pill
                      _ApprovalPill(status: loan.approvalStatus),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Amount row
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.account_balance_outlined,
                          label: 'Principal',
                          value: _currency.format(loan.principal),
                          valueColor: cs.primary,
                        ),
                      ),
                      if (loan.monthlyEMI != null)
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.repeat_rounded,
                            label: 'EMI',
                            value: _currency.format(loan.monthlyEMI!),
                          ),
                        ),
                      if (loan.applicationDate != null)
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.calendar_today_outlined,
                            label: 'Applied',
                            value: _dateFormat
                                .format(loan.applicationDate!),
                          ),
                        ),
                    ],
                  ),

                  if (isPendingApproval) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.rate_review_rounded,
                            size: 16),
                        label: const Text('Review Application'),
                        style: FilledButton.styleFrom(
                          backgroundColor: typeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10, color: cs.onSurfaceVariant)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ApprovalPill extends StatelessWidget {
  final ApprovalStatus status;
  const _ApprovalPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color color;
    IconData icon;
    switch (status) {
      case ApprovalStatus.approved:
        color = const Color(0xFF2E7D32);
        icon = Icons.check_circle_rounded;
        break;
      case ApprovalStatus.rejected:
        color = cs.error;
        icon = Icons.cancel_rounded;
        break;
      case ApprovalStatus.pending:
        color = const Color(0xFFF57F17);
        icon = Icons.pending_rounded;
        break;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          status.displayName,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ─── Load More button ─────────────────────────────────────────────────────────

class _LoadMoreButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoadMoreButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(
                    Icons.keyboard_arrow_down_rounded),
                label: const Text('Load More'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
      ),
    );
  }
}

// ─── State widgets ────────────────────────────────────────────────────────────

class _InitialBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search_rounded,
                size: 80,
                color: cs.onSurfaceVariant.withOpacity(0.35)),
            const SizedBox(height: 16),
            Text(
              'Search Loans',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the filters above to search by customer, '
              'loan type, or status.\nLeave all filters blank '
              'to retrieve all loans.',
              style:
                  TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyBody({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 72,
                color: cs.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'No Loans Found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'No loans match your search criteria.',
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade600 : Colors.grey.shade100;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      itemBuilder: (_, __) => _ShimmerCard(
          baseColor: base, highlightColor: highlight),
    );
  }
}

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
            Text('Search Failed',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(
                    color: cs.onSurfaceVariant, fontSize: 13),
                textAlign: TextAlign.center),
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

// ─── Shimmer card ─────────────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerCard({
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
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
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Box(width: 34, height: 34, radius: 9),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Box(width: 110, height: 13),
                      const SizedBox(height: 4),
                      _Box(width: 80, height: 11),
                    ],
                  ),
                  const Spacer(),
                  _Box(width: 70, height: 22, radius: 20),
                ],
              ),
              const SizedBox(height: 12),
              _Box(width: 150, height: 14),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  3,
                  (_) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Box(height: 30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _Box({this.width, this.height = 16, this.radius = 6});

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
