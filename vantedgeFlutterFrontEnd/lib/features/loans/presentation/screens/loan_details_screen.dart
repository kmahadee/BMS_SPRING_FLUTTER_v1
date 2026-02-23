import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:vantedge/features/loans/data/models/loan_enums.dart';
import 'package:vantedge/features/loans/data/models/loan_model.dart';
import 'package:vantedge/features/loans/presentation/providers/loan_provider.dart';
import 'package:vantedge/features/loans/presentation/widgets/loan_enum_display_helpers.dart';
import 'package:vantedge/features/loans/presentation/widgets/loan_status_badge.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';

// ─── Placeholder route names (wire up in AppRouter when those screens exist) ──
// AppRoutes.repaymentSchedule  → passes loanId as argument
// AppRoutes.loanPayment        → passes loanId as argument

class LoanDetailsScreen extends StatefulWidget {
  final String loanId;

  const LoanDetailsScreen({super.key, required this.loanId});

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  static final _currFmt = NumberFormat.currency(
    symbol: '৳',
    decimalDigits: 2,
    locale: 'en_IN',
  );
  static final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoanProvider>().fetchLoanById(widget.loanId);
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(double? v) => v != null ? _currFmt.format(v) : '—';
  String _date(DateTime? d) => d != null ? _dateFmt.format(d) : '—';

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navRepaymentSchedule() {
    // Navigate to RepaymentScheduleScreen — passes loanId as argument
    Navigator.pushNamed(context, '/loans/schedule', arguments: widget.loanId);
  }

  void _navLoanPayment() {
    Navigator.pushNamed(context, '/loans/payment', arguments: widget.loanId);
  }

  void _downloadStatement() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Statement download coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: (context, provider, _) {
        // ── Loading state ─────────────────────────────────────────────────
        if (provider.isLoading && provider.selectedLoan == null) {
          return _LoadingScaffold(loanId: widget.loanId);
        }

        // ── Error state ───────────────────────────────────────────────────
        if (provider.hasError && provider.selectedLoan == null) {
          return _ErrorScaffold(
            message: provider.errorMessage ?? 'Could not load loan details.',
            onRetry: () {
              provider.clearError();
              provider.fetchLoanById(widget.loanId);
            },
          );
        }

        final loan = provider.selectedLoan;

        if (loan == null) {
          return _ErrorScaffold(
            message: 'Loan not found.',
            onRetry: () => provider.fetchLoanById(widget.loanId),
          );
        }

        return _buildContent(context, loan);
      },
    );
  }

  Widget _buildContent(BuildContext context, LoanResponseModel loan) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final hasCollateral = loan.collateralType != null;
    final hasBizLc =
        loan.industryType != null || loan.lcNumber != null;
    final hasPurpose =
        loan.purpose != null && loan.purpose!.isNotEmpty;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing hero AppBar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: loan.loanType.color,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: () =>
                    context.read<LoanProvider>().fetchLoanById(loan.loanId),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HeroBackground(loan: loan, fmt: _fmt),
            ),
            // Status badge in app bar title (visible when collapsed)
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    loan.loanType.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                LoanStatusBadge(
                  status: loan.loanStatus,
                  compact: true,
                  showIcon: false,
                ),
              ],
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Loan ID + copy ──────────────────────────────────────
                  _LoanIdChip(
                    loanId: loan.loanId,
                    onCopy: () => _copy(loan.loanId, 'Loan ID'),
                  ),
                  const SizedBox(height: 20),

                  // ── Financial Summary ───────────────────────────────────
                  _SectionLabel(label: 'Financial Summary'),
                  const SizedBox(height: 10),
                  _FinancialSummaryCard(loan: loan, fmt: _fmt),
                  const SizedBox(height: 20),

                  // ── Progress bar (active loans only) ─────────────────────
                  if (loan.loanStatus.isActive &&
                      loan.outstandingBalance != null) ...[
                    _RepaymentProgressCard(loan: loan, fmt: _fmt),
                    const SizedBox(height: 20),
                  ],

                  // ── Dates ───────────────────────────────────────────────
                  _SectionLabel(label: 'Important Dates'),
                  const SizedBox(height: 10),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.assignment_rounded,
                        label: 'Application Date',
                        value: _date(loan.applicationDate),
                      ),
                      _divider(),
                      _InfoRow(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Approval Date',
                        value: _date(loan.approvedDate),
                        valueColor: loan.approvedDate != null
                            ? const Color(0xFF2E7D32)
                            : null,
                      ),
                      _divider(),
                      _InfoRow(
                        icon: Icons.account_balance_rounded,
                        label: 'Disbursement Date',
                        value: _date(loan.actualDisbursementDate),
                      ),
                      if (loan.disbursementStatus != null) ...[
                        _divider(),
                        _InfoRow(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Disbursement Status',
                          value: loan.disbursementStatus!.displayName,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Account & Eligibility ────────────────────────────────
                  _SectionLabel(label: 'Account Details'),
                  const SizedBox(height: 10),
                  _InfoCard(
                    children: [
                      if (loan.accountNumber != null) ...[
                        _InfoRow(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Linked Account',
                          value: '•••• ${loan.accountNumber!.length > 4 ? loan.accountNumber!.substring(loan.accountNumber!.length - 4) : loan.accountNumber!}',
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            tooltip: 'Copy account number',
                            onPressed: () =>
                                _copy(loan.accountNumber!, 'Account number'),
                          ),
                        ),
                        _divider(),
                      ],
                      if (loan.creditScore != null) ...[
                        _InfoRow(
                          icon: Icons.stars_rounded,
                          label: 'Credit Score',
                          value: '${loan.creditScore}',
                          valueColor: _creditScoreColor(loan.creditScore!),
                        ),
                        _divider(),
                      ],
                      if (loan.eligibilityStatus != null) ...[
                        _InfoRow(
                          icon: Icons.verified_rounded,
                          label: 'Eligibility',
                          value: loan.eligibilityStatus!,
                        ),
                        _divider(),
                      ],
                      _InfoRow(
                        icon: Icons.gavel_rounded,
                        label: 'Approval Status',
                        value: loan.approvalStatus.displayName,
                      ),
                      if (loan.approvalConditions != null &&
                          loan.approvalConditions!.isNotEmpty) ...[
                        _divider(),
                        _InfoRow(
                          icon: Icons.info_outline_rounded,
                          label: 'Conditions',
                          value: loan.approvalConditions!,
                          multiline: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Purpose ─────────────────────────────────────────────
                  if (hasPurpose) ...[
                    _SectionLabel(label: 'Purpose'),
                    const SizedBox(height: 10),
                    _InfoCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes_rounded,
                                  size: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  loan.purpose!,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Collateral ──────────────────────────────────────────
                  if (hasCollateral) ...[
                    _SectionLabel(label: 'Collateral'),
                    const SizedBox(height: 10),
                    _InfoCard(
                      children: [
                        _InfoRow(
                          icon: Icons.security_rounded,
                          label: 'Collateral Type',
                          value: loan.collateralType!,
                        ),
                        if (loan.collateralValue != null) ...[
                          _divider(),
                          _InfoRow(
                            icon: Icons.price_check_rounded,
                            label: 'Estimated Value',
                            value: _fmt(loan.collateralValue),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Business / LC ──────────────────────────────────────
                  if (hasBizLc) ...[
                    _SectionLabel(label: 'Business & LC Details'),
                    const SizedBox(height: 10),
                    _InfoCard(
                      children: [
                        if (loan.industryType != null) ...[
                          _InfoRow(
                            icon: Icons.factory_rounded,
                            label: 'Industry',
                            value: loan.industryType!,
                          ),
                          if (loan.businessTurnover != null) ...[
                            _divider(),
                            _InfoRow(
                              icon: Icons.trending_up_rounded,
                              label: 'Annual Turnover',
                              value: _fmt(loan.businessTurnover),
                            ),
                          ],
                        ],
                        if (loan.lcNumber != null) ...[
                          if (loan.industryType != null) _divider(),
                          _InfoRow(
                            icon: Icons.receipt_rounded,
                            label: 'LC Number',
                            value: loan.lcNumber!,
                            trailing: IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              tooltip: 'Copy LC number',
                              onPressed: () =>
                                  _copy(loan.lcNumber!, 'LC number'),
                            ),
                          ),
                          if (loan.beneficiaryName != null) ...[
                            _divider(),
                            _InfoRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Beneficiary',
                              value: loan.beneficiaryName!,
                            ),
                          ],
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Bottom padding so action bar doesn't cover content ──
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Context-sensitive Action Bar ──────────────────────────────────────
      bottomNavigationBar: _ActionBar(
        loan: loan,
        onViewSchedule: _navRepaymentSchedule,
        onMakePayment: _navLoanPayment,
        onDownloadStatement: _downloadStatement,
      ),
    );
  }

  Color _creditScoreColor(int score) {
    if (score >= 750) return const Color(0xFF2E7D32);
    if (score >= 650) return const Color(0xFFF57F17);
    return const Color(0xFFC62828);
  }

  Divider _divider() => const Divider(height: 1, indent: 16, endIndent: 16);
}

// ─── Hero Background ─────────────────────────────────────────────────────────

class _HeroBackground extends StatelessWidget {
  final LoanResponseModel loan;
  final String Function(double?) fmt;

  const _HeroBackground({required this.loan, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final color = loan.loanType.color;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.75)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Row(
            children: [
              // Type icon container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(loan.loanType.icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    LoanStatusBadge(
                      status: loan.loanStatus,
                      compact: false,
                      showIcon: true,
                    ),
                    const SizedBox(height: 6),
                    // Principal
                    Text(
                      fmt(loan.principal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Principal Amount',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Loan ID Chip ─────────────────────────────────────────────────────────────

class _LoanIdChip extends StatelessWidget {
  final String loanId;
  final VoidCallback onCopy;

  const _LoanIdChip({required this.loanId, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tag_rounded, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            'Loan ID: $loanId',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onCopy,
            child: Icon(Icons.copy_rounded, size: 15, color: cs.primary),
          ),
        ],
      ),
    );
  }
}

// ─── Financial Summary Card ───────────────────────────────────────────────────

class _FinancialSummaryCard extends StatelessWidget {
  final LoanResponseModel loan;
  final String Function(double?) fmt;

  const _FinancialSummaryCard({required this.loan, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final color = loan.loanType.color;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      color: color.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Highlighted EMI row ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Monthly EMI',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    loan.monthlyEMI != null ? fmt(loan.monthlyEMI) : '—',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Grid of financial stats ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _FinStat(
                    label: 'Principal',
                    value: fmt(loan.principal),
                    icon: Icons.payments_rounded,
                    cs: cs,
                    theme: theme,
                  ),
                ),
                Expanded(
                  child: _FinStat(
                    label: 'Outstanding',
                    value: fmt(loan.outstandingBalance),
                    icon: Icons.account_balance_rounded,
                    cs: cs,
                    theme: theme,
                    valueColor: (loan.outstandingBalance ?? 0) > 0
                        ? const Color(0xFFC62828)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _FinStat(
                    label: 'Total Payable',
                    value: fmt(loan.totalAmount),
                    icon: Icons.account_balance_wallet_rounded,
                    cs: cs,
                    theme: theme,
                  ),
                ),
                Expanded(
                  child: _FinStat(
                    label: 'Total Interest',
                    value: fmt(loan.totalInterest),
                    icon: Icons.trending_up_rounded,
                    cs: cs,
                    theme: theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _FinStat(
                    label: 'Interest Rate',
                    value: '${loan.annualInterestRate.toStringAsFixed(2)}% p.a.',
                    icon: Icons.percent_rounded,
                    cs: cs,
                    theme: theme,
                  ),
                ),
                Expanded(
                  child: _FinStat(
                    label: 'Tenure',
                    value: '${loan.tenureMonths} months',
                    icon: Icons.timer_rounded,
                    cs: cs,
                    theme: theme,
                  ),
                ),
              ],
            ),
            if (loan.approvedAmount != null || loan.disbursedAmount != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (loan.approvedAmount != null)
                    Expanded(
                      child: _FinStat(
                        label: 'Approved Amount',
                        value: fmt(loan.approvedAmount),
                        icon: Icons.check_circle_outline_rounded,
                        cs: cs,
                        theme: theme,
                        valueColor: const Color(0xFF2E7D32),
                      ),
                    ),
                  if (loan.disbursedAmount != null)
                    Expanded(
                      child: _FinStat(
                        label: 'Disbursed',
                        value: fmt(loan.disbursedAmount),
                        icon: Icons.send_rounded,
                        cs: cs,
                        theme: theme,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme cs;
  final ThemeData theme;
  final Color? valueColor;

  const _FinStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.cs,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Repayment Progress Card ──────────────────────────────────────────────────

class _RepaymentProgressCard extends StatelessWidget {
  final LoanResponseModel loan;
  final String Function(double?) fmt;

  const _RepaymentProgressCard({required this.loan, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
    final principal = loan.principal;
    final outstanding = loan.outstandingBalance ?? 0;
    final repaid = principal - outstanding;
    final progress = principal > 0 ? (repaid / principal).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Repayment Progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repaid',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      fmt(repaid),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      fmt(outstanding),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Context-sensitive Action Bar ─────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final LoanResponseModel loan;
  final VoidCallback onViewSchedule;
  final VoidCallback onMakePayment;
  final VoidCallback onDownloadStatement;

  const _ActionBar({
    required this.loan,
    required this.onViewSchedule,
    required this.onMakePayment,
    required this.onDownloadStatement,
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
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: _buildButtons(context, theme, cs),
    );
  }

  Widget _buildButtons(
      BuildContext context, ThemeData theme, ColorScheme cs) {
    switch (loan.loanStatus) {
      // ── ACTIVE: View Schedule + Make Payment ──────────────────────────────
      case LoanStatus.active:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onViewSchedule,
                icon: const Icon(Icons.calendar_view_month_rounded),
                label: const Text('View Schedule'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onMakePayment,
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Make Payment'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      // ── APPROVED: View Schedule only ──────────────────────────────────────
      case LoanStatus.approved:
        return FilledButton.tonalIcon(
          onPressed: onViewSchedule,
          icon: const Icon(Icons.calendar_view_month_rounded),
          label: const Text('View Repayment Schedule'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

      // ── CLOSED / DEFAULTED: Download Statement ────────────────────────────
      case LoanStatus.closed:
      case LoanStatus.defaulted:
        return OutlinedButton.icon(
          onPressed: onDownloadStatement,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Download Statement'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

      // ── APPLICATION / PROCESSING: Status tracker ──────────────────────────
      case LoanStatus.application:
      case LoanStatus.processing:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                loan.loanStatus == LoanStatus.application
                    ? 'Application under review'
                    : 'Processing your loan…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
    }
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;
  final bool multiline;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? cs.onSurface,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ─── Loading Scaffold ─────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  final String loanId;

  const _LoadingScaffold({required this.loanId});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            title: Text('Loan Details'),
          ),
          SliverToBoxAdapter(
            child: Shimmer.fromColors(
              baseColor:      isDark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
              child: _DetailsShimmerBody(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsShimmerBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID chip
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          // Section label
          Container(width: 140, height: 16, color: Colors.white),
          const SizedBox(height: 12),
          // Financial card
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 20),
          Container(width: 100, height: 16, color: Colors.white),
          const SizedBox(height: 12),
          // Dates card
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 20),
          Container(width: 120, height: 16, color: Colors.white),
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error Scaffold ───────────────────────────────────────────────────────────

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            title: Text('Loan Details'),
          ),
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 80, color: cs.error),
                    const SizedBox(height: 20),
                    Text(
                      'Could not load loan',
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
            ),
          ),
        ],
      ),
    );
  }
}
