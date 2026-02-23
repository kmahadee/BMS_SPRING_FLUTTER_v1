import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/loans/presentation/providers/loan_officer_provider.dart';
import '../../data/models/loan_enums.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_application.dart';
// import '../../providers/loan_officer_provider.dart';

// ─── Formatting helpers ───────────────────────────────────────────────────────

final _currency = NumberFormat.currency(
  symbol: '৳',
  decimalDigits: 2,
  locale: 'en_IN',
);
final _dateFormat = DateFormat('dd MMM yyyy');

Color _typeColor(LoanType t) {
  switch (t) {
    case LoanType.homeLoan:
      return const Color(0xFF1565C0);
    case LoanType.carLoan:
      return const Color(0xFF00838F);
    case LoanType.personalLoan:
      return const Color(0xFF6A1B9A);
    case LoanType.educationLoan:
      return const Color(0xFF2E7D32);
    case LoanType.businessLoan:
      return const Color(0xFFE65100);
    case LoanType.goldLoan:
      return const Color(0xFFF9A825);
    case LoanType.industrialLoan:
      return const Color(0xFF37474F);
    case LoanType.importLcLoan:
      return const Color(0xFF880E4F);
    case LoanType.workingCapitalLoan:
      return const Color(0xFF004D40);
  }
}

IconData _typeIcon(LoanType t) {
  switch (t) {
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

// ─── Screen ───────────────────────────────────────────────────────────────────

class LoanApprovalScreen extends StatefulWidget {
  final String loanId;

  const LoanApprovalScreen({super.key, required this.loanId});

  @override
  State<LoanApprovalScreen> createState() => _LoanApprovalScreenState();
}

class _LoanApprovalScreenState extends State<LoanApprovalScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Form state
  ApprovalStatus _decision = ApprovalStatus.approved;
  late final TextEditingController _amountCtrl;
  final TextEditingController _conditionsCtrl = TextEditingController();
  final TextEditingController _rejectionCtrl = TextEditingController();
  final TextEditingController _rateModCtrl = TextEditingController();

  // Section expansion
  bool _applicantExpanded = true;
  bool _loanExpanded = true;
  bool _collateralExpanded = false;
  bool _businessExpanded = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLoan();
    });
  }

  Future<void> _loadLoan() async {
    final provider = context.read<LoanOfficerProvider>();
    // Use cached selectedLoan if it's the same loan
    if (provider.selectedLoan?.loanId != widget.loanId) {
      await provider.fetchLoanById(widget.loanId);
    }
    final loan = context.read<LoanOfficerProvider>().selectedLoan;
    if (loan != null && mounted) {
      _amountCtrl.text = loan.principal.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _conditionsCtrl.dispose();
    _rejectionCtrl.dispose();
    _rateModCtrl.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await _showConfirmDialog();
    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<LoanOfficerProvider>();

      final amount = double.tryParse(_amountCtrl.text.trim());
      final rateMod = _rateModCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_rateModCtrl.text.trim());

      final request = LoanApprovalRequestModel(
        loanId: widget.loanId,
        approvalStatus: _decision,
        approvalConditions: _conditionsCtrl.text.trim().isEmpty
            ? null
            : _conditionsCtrl.text.trim(),
        rejectionReason: _decision == ApprovalStatus.rejected &&
                _rejectionCtrl.text.trim().isNotEmpty
            ? _rejectionCtrl.text.trim()
            : null,
        interestRateModification: rateMod,
        comments: null,
      );

      bool success;
      if (_decision == ApprovalStatus.approved) {
        success = await provider.approveLoan(request);
      } else {
        success = await provider.rejectLoan(request);
      }

      if (!mounted) return;

      if (success) {
        final isApproved = _decision == ApprovalStatus.approved;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isApproved
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isApproved
                        ? 'Loan approved successfully.'
                        : 'Loan application rejected.',
                  ),
                ),
              ],
            ),
            backgroundColor:
                isApproved ? const Color(0xFF2E7D32) : Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        // Pop back to queue, signal refresh
        Navigator.of(context).pop(true);
      } else {
        final errMsg = provider.errorMessage ?? 'Action failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _showConfirmDialog() async {
    final isApproved = _decision == ApprovalStatus.approved;
    final amount = double.tryParse(_amountCtrl.text.trim());
    final cs = Theme.of(context).colorScheme;

    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Icon(
              isApproved
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: isApproved ? const Color(0xFF2E7D32) : cs.error,
              size: 40,
            ),
            title: Text(
              isApproved ? 'Confirm Approval' : 'Confirm Rejection',
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isApproved
                      ? 'You are about to APPROVE this loan application.'
                      : 'You are about to REJECT this loan application.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                if (isApproved && amount != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Approved Amount: ',
                          style: TextStyle(color: cs.onPrimaryContainer),
                        ),
                        Text(
                          _currency.format(amount),
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.error,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isApproved ? const Color(0xFF2E7D32) : cs.error,
                ),
                child: Text(isApproved ? 'Approve' : 'Reject'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Review'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1,
              thickness: 0.5,
              color:
                  Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      body: Consumer<LoanOfficerProvider>(
        builder: (context, provider, _) {
          // Loading
          if (provider.isLoading && provider.selectedLoan == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (provider.hasError && provider.selectedLoan == null) {
            return _LoadErrorBody(
              message: provider.errorMessage ?? 'Failed to load loan.',
              onRetry: _loadLoan,
            );
          }

          final loan = provider.selectedLoan;
          if (loan == null) {
            return const Center(child: Text('No loan data available.'));
          }

          return Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  children: [
                    const SizedBox(height: 12),

                    // ── Hero banner ──────────────────────────────────────
                    _LoanHeroBanner(loan: loan),
                    const SizedBox(height: 16),

                    // ── Collapsible detail sections ──────────────────────
                    _DetailSection(
                      icon: Icons.person_rounded,
                      title: 'Applicant Info',
                      expanded: _applicantExpanded,
                      onToggle: () => setState(
                          () => _applicantExpanded = !_applicantExpanded),
                      child: _ApplicantInfoContent(loan: loan),
                    ),
                    const SizedBox(height: 10),

                    _DetailSection(
                      icon: Icons.account_balance_rounded,
                      title: 'Loan Details',
                      expanded: _loanExpanded,
                      onToggle: () =>
                          setState(() => _loanExpanded = !_loanExpanded),
                      child: _LoanDetailsContent(loan: loan),
                    ),
                    const SizedBox(height: 10),

                    if (loan.collateralType != null ||
                        loan.collateralValue != null) ...[
                      _DetailSection(
                        icon: Icons.security_rounded,
                        title: 'Collateral',
                        expanded: _collateralExpanded,
                        onToggle: () => setState(
                            () => _collateralExpanded = !_collateralExpanded),
                        child: _CollateralContent(loan: loan),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (loan.loanType == LoanType.businessLoan ||
                        loan.loanType == LoanType.industrialLoan ||
                        loan.loanType == LoanType.workingCapitalLoan ||
                        loan.loanType == LoanType.importLcLoan) ...[
                      _DetailSection(
                        icon: Icons.business_rounded,
                        title: 'Business / Trade Info',
                        expanded: _businessExpanded,
                        onToggle: () => setState(
                            () => _businessExpanded = !_businessExpanded),
                        child: _BusinessContent(loan: loan),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ── Officer decision form ────────────────────────────
                    _OfficerDecisionForm(
                      loan: loan,
                      decision: _decision,
                      amountCtrl: _amountCtrl,
                      conditionsCtrl: _conditionsCtrl,
                      rejectionCtrl: _rejectionCtrl,
                      rateModCtrl: _rateModCtrl,
                      onDecisionChanged: (v) {
                        if (v != null) setState(() => _decision = v);
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ── Loading overlay while submitting ─────────────────────
              if (_isSubmitting)
                const _LoadingOverlay(message: 'Processing decision…'),
            ],
          );
        },
      ),

      // ── Bottom action buttons ────────────────────────────────────────
      bottomNavigationBar: _BottomActionBar(
        decision: _decision,
        onSubmit: _isSubmitting ? null : _submit,
      ),
    );
  }
}

// ─── Hero Banner ──────────────────────────────────────────────────────────────

class _LoanHeroBanner extends StatelessWidget {
  final LoanResponseModel loan;
  const _LoanHeroBanner({required this.loan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _typeColor(loan.loanType);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_typeIcon(loan.loanType), color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loan.loanType.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _WhitePill(
                text: loan.loanStatus.displayName.toUpperCase(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${loan.loanId}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Requested',
                  value: _currency.format(loan.principal),
                  bold: true,
                ),
              ),
              Expanded(
                child: _HeroStat(
                  label: 'Interest Rate',
                  value: '${loan.annualInterestRate.toStringAsFixed(2)}% p.a.',
                ),
              ),
              Expanded(
                child: _HeroStat(
                  label: 'Tenure',
                  value: '${loan.tenureMonths} months',
                ),
              ),
            ],
          ),
          if (loan.monthlyEMI != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _HeroStat(
                    label: 'Monthly EMI',
                    value: _currency.format(loan.monthlyEMI!),
                  ),
                ),
                if (loan.creditScore != null)
                  Expanded(
                    child: _HeroStat(
                      label: 'Credit Score',
                      value: '${loan.creditScore}',
                    ),
                  ),
                if (loan.eligibilityStatus != null)
                  Expanded(
                    child: _HeroStat(
                      label: 'Eligibility',
                      value: loan.eligibilityStatus!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _HeroStat({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _WhitePill extends StatelessWidget {
  final String text;
  const _WhitePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white38),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── Collapsible detail section ───────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: cs.primary),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
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
            // Body
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                      height: 1,
                      thickness: 0.5,
                      color: cs.outlineVariant.withOpacity(0.5)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: child,
                  ),
                ],
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Section Contents ──────────────────────────────────────────────────

class _ApplicantInfoContent extends StatelessWidget {
  final LoanResponseModel loan;
  const _ApplicantInfoContent({required this.loan});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 10,
      children: [
        _Row2(
          left: _DetailRow(
              label: 'Customer Name',
              value: loan.customerName ?? '—'),
          right: _DetailRow(
              label: 'Customer ID',
              value: loan.customerId ?? '—'),
        ),
        _Row2(
          left: _DetailRow(
              label: 'Account Number',
              value: loan.accountNumber ?? '—'),
          right: _DetailRow(
              label: 'Credit Score',
              value: loan.creditScore?.toString() ?? '—'),
        ),
        _Row2(
          left: _DetailRow(
              label: 'Eligibility',
              value: loan.eligibilityStatus ?? '—'),
          right: _DetailRow(
              label: 'Applied On',
              value: loan.applicationDate != null
                  ? _dateFormat.format(loan.applicationDate!)
                  : '—'),
        ),
        if (loan.purpose != null)
          _DetailRow(label: 'Purpose', value: loan.purpose!),
      ],
    );
  }
}

class _LoanDetailsContent extends StatelessWidget {
  final LoanResponseModel loan;
  const _LoanDetailsContent({required this.loan});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 10,
      children: [
        _Row2(
          left: _DetailRow(
              label: 'Principal Amount',
              value: _currency.format(loan.principal)),
          right: _DetailRow(
              label: 'Interest Rate',
              value:
                  '${loan.annualInterestRate.toStringAsFixed(2)}% p.a.'),
        ),
        _Row2(
          left: _DetailRow(
              label: 'Tenure',
              value: '${loan.tenureMonths} months'),
          right: _DetailRow(
              label: 'Monthly EMI',
              value: loan.monthlyEMI != null
                  ? _currency.format(loan.monthlyEMI!)
                  : '—'),
        ),
        if (loan.totalAmount != null || loan.totalInterest != null)
          _Row2(
            left: _DetailRow(
                label: 'Total Payable',
                value: loan.totalAmount != null
                    ? _currency.format(loan.totalAmount!)
                    : '—'),
            right: _DetailRow(
                label: 'Total Interest',
                value: loan.totalInterest != null
                    ? _currency.format(loan.totalInterest!)
                    : '—'),
          ),
        _Row2(
          left: _DetailRow(
              label: 'Loan Status',
              value: loan.loanStatus.displayName),
          right: _DetailRow(
              label: 'Approval Status',
              value: loan.approvalStatus.displayName),
        ),
        if (loan.approvalConditions != null)
          _DetailRow(
              label: 'Existing Conditions',
              value: loan.approvalConditions!),
      ],
    );
  }
}

class _CollateralContent extends StatelessWidget {
  final LoanResponseModel loan;
  const _CollateralContent({required this.loan});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 10,
      children: [
        _Row2(
          left: _DetailRow(
              label: 'Collateral Type',
              value: loan.collateralType ?? '—'),
          right: _DetailRow(
              label: 'Collateral Value',
              value: loan.collateralValue != null
                  ? _currency.format(loan.collateralValue!)
                  : '—'),
        ),
        if (loan.collateralValue != null)
          _DetailRow(
            label: 'Loan-to-Value',
            value: loan.collateralValue! > 0
                ? '${((loan.principal / loan.collateralValue!) * 100).toStringAsFixed(1)}%'
                : '—',
          ),
      ],
    );
  }
}

class _BusinessContent extends StatelessWidget {
  final LoanResponseModel loan;
  const _BusinessContent({required this.loan});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 10,
      children: [
        if (loan.industryType != null)
          _Row2(
            left: _DetailRow(
                label: 'Industry Type', value: loan.industryType!),
            right: _DetailRow(
                label: 'Business Turnover',
                value: loan.businessTurnover != null
                    ? _currency.format(loan.businessTurnover!)
                    : '—'),
          ),
        if (loan.lcNumber != null || loan.beneficiaryName != null)
          _Row2(
            left: _DetailRow(
                label: 'LC Number', value: loan.lcNumber ?? '—'),
            right: _DetailRow(
                label: 'Beneficiary', value: loan.beneficiaryName ?? '—'),
          ),
      ],
    );
  }
}

// ─── Officer Decision Form ────────────────────────────────────────────────────

class _OfficerDecisionForm extends StatelessWidget {
  final LoanResponseModel loan;
  final ApprovalStatus decision;
  final TextEditingController amountCtrl;
  final TextEditingController conditionsCtrl;
  final TextEditingController rejectionCtrl;
  final TextEditingController rateModCtrl;
  final ValueChanged<ApprovalStatus?> onDecisionChanged;

  const _OfficerDecisionForm({
    required this.loan,
    required this.decision,
    required this.amountCtrl,
    required this.conditionsCtrl,
    required this.rejectionCtrl,
    required this.rateModCtrl,
    required this.onDecisionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isApproved = decision == ApprovalStatus.approved;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: isApproved
              ? const Color(0xFF2E7D32).withOpacity(0.5)
              : cs.error.withOpacity(0.45),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
        color: (isApproved
                ? const Color(0xFF2E7D32)
                : cs.error)
            .withOpacity(0.04),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Row(
              children: [
                Icon(
                  Icons.gavel_rounded,
                  size: 20,
                  color: isApproved
                      ? const Color(0xFF2E7D32)
                      : cs.error,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Officer Decision',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Decision Radio ────────────────────────────────────────
            Text(
              'Decision *',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DecisionRadioTile(
                    value: ApprovalStatus.approved,
                    groupValue: decision,
                    label: 'Approve',
                    icon: Icons.check_circle_rounded,
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: onDecisionChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DecisionRadioTile(
                    value: ApprovalStatus.rejected,
                    groupValue: decision,
                    label: 'Reject',
                    icon: Icons.cancel_rounded,
                    activeColor: cs.error,
                    onChanged: onDecisionChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Approved Amount ───────────────────────────────────────
            if (isApproved) ...[
              _FormLabel('Approved Amount *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: '৳ ',
                  hintText: '0.00',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Reset to requested amount',
                    onPressed: () {
                      amountCtrl.text =
                          loan.principal.toStringAsFixed(2);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Approved amount is required';
                  }
                  final d = double.tryParse(v.trim());
                  if (d == null || d <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (d > loan.principal * 1.2) {
                    return 'Cannot exceed 120% of requested amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // ── Interest Rate Modification ────────────────────────────
            _FormLabel('Interest Rate Modification (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: rateModCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                suffixText: '% p.a.',
                hintText: 'e.g. 8.50',
                helperText:
                    'Leave blank to keep original rate (${loan.annualInterestRate.toStringAsFixed(2)}%)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final d = double.tryParse(v.trim());
                if (d == null || d <= 0) {
                  return 'Enter a valid interest rate';
                }
                if (d > 36) return 'Rate seems too high';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Approval Conditions ───────────────────────────────────
            if (isApproved) ...[
              _FormLabel('Approval Conditions (optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: conditionsCtrl,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText:
                      'e.g. Provide title deed within 30 days of disbursement…',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) {
                  if (v != null && v.length > 1000) {
                    return 'Cannot exceed 1000 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
            ],

            // ── Rejection Reason ──────────────────────────────────────
            if (!isApproved) ...[
              _FormLabel('Rejection Reason *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: rejectionCtrl,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText:
                      'Describe the reason(s) for rejection…',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.error),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: cs.error.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.error),
                  ),
                ),
                validator: (v) {
                  if (!isApproved &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Rejection reason is required';
                  }
                  if (v != null && v.length > 1000) {
                    return 'Cannot exceed 1000 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Warning banner for rejection
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: cs.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejection is permanent. The applicant will be notified.',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Decision Radio Tile ──────────────────────────────────────────────────────

class _DecisionRadioTile extends StatelessWidget {
  final ApprovalStatus value;
  final ApprovalStatus groupValue;
  final String label;
  final IconData icon;
  final Color activeColor;
  final ValueChanged<ApprovalStatus?> onChanged;

  const _DecisionRadioTile({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? activeColor.withOpacity(0.08) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.grey.shade500,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Action Bar ────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final ApprovalStatus decision;
  final VoidCallback? onSubmit;

  const _BottomActionBar({
    required this.decision,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isApproved = decision == ApprovalStatus.approved;
    final actionColor =
        isApproved ? const Color(0xFF2E7D32) : cs.error;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
                color: cs.outlineVariant.withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSubmit == null
                    ? null
                    : () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onSubmit,
                icon: Icon(
                  isApproved
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 20,
                ),
                label: Text(
                  isApproved ? 'Approve Loan' : 'Reject Application',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: actionColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _Row2 extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _Row2({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

// ─── Loading overlay ──────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  final String message;
  const _LoadingOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Load Error body ──────────────────────────────────────────────────────────

class _LoadErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: cs.error.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'Unable to load loan',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(message,
                style:
                    TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
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
