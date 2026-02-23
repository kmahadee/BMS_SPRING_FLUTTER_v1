import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import '../../data/models/loan_enums.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_application.dart';
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
    case LoanType.homeLoan:        return const Color(0xFF1565C0);
    case LoanType.carLoan:         return const Color(0xFF00838F);
    case LoanType.personalLoan:    return const Color(0xFF6A1B9A);
    case LoanType.educationLoan:   return const Color(0xFF2E7D32);
    case LoanType.businessLoan:    return const Color(0xFFE65100);
    case LoanType.goldLoan:        return const Color(0xFFF9A825);
    case LoanType.industrialLoan:  return const Color(0xFF37474F);
    case LoanType.importLcLoan:    return const Color(0xFF880E4F);
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

// ─── Screen ───────────────────────────────────────────────────────────────────

class LoanDisbursementScreen extends StatefulWidget {
  final String loanId;

  const LoanDisbursementScreen({super.key, required this.loanId});

  @override
  State<LoanDisbursementScreen> createState() => _LoanDisbursementScreenState();
}

class _LoanDisbursementScreenState extends State<LoanDisbursementScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _amountCtrl;
  late final TextEditingController _accountCtrl;
  final TextEditingController _bankDetailsCtrl = TextEditingController();
  DateTime? _scheduledDate;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _accountCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLoan());
  }

  Future<void> _loadLoan() async {
    final provider = context.read<LoanOfficerProvider>();
    if (provider.selectedLoan?.loanId != widget.loanId) {
      await provider.fetchLoanById(widget.loanId);
    }
    final loan = context.read<LoanOfficerProvider>().selectedLoan;
    if (loan != null && mounted) {
      // Pre-fill amount with approvedAmount (or principal if not yet approved)
      final fillAmount = loan.approvedAmount ?? loan.principal;
      _amountCtrl.text = fillAmount.toStringAsFixed(2);
      _accountCtrl.text = loan.accountNumber ?? '';
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    _bankDetailsCtrl.dispose();
    super.dispose();
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: now, // no past dates
      lastDate: DateTime(now.year + 1),
      helpText: 'Scheduled Disbursement Date',
    );
    if (picked != null && mounted) {
      setState(() => _scheduledDate = picked);
    }
  }

  void _clearDate() => setState(() => _scheduledDate = null);

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit(LoanResponseModel loan) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text.trim());
    final confirmed = await _showConfirmDialog(loan, amount);
    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final request = LoanDisbursementRequestModel(
        loanId: widget.loanId,
        disbursementAmount: amount,
        accountNumber: _accountCtrl.text.trim(),
        bankDetails: _bankDetailsCtrl.text.trim().isEmpty
            ? null
            : _bankDetailsCtrl.text.trim(),
        scheduledDate: _scheduledDate,
      );

      final success =
          await context.read<LoanOfficerProvider>().disburseLoan(request);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                    child: Text('Disbursement processed successfully.')),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final err = context.read<LoanOfficerProvider>().errorMessage ??
            'Disbursement failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _showConfirmDialog(
      LoanResponseModel loan, double amount) async {
    final cs = Theme.of(context).colorScheme;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            icon: Icon(Icons.send_rounded,
                color: _typeColor(loan.loanType), size: 40),
            title: const Text('Confirm Disbursement',
                textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogRow(
                    label: 'Loan ID', value: loan.loanId),
                const SizedBox(height: 8),
                _DialogRow(
                    label: 'Customer',
                    value: loan.customerName ?? '—'),
                const SizedBox(height: 8),
                _DialogRow(
                    label: 'Account',
                    value: _accountCtrl.text.trim()),
                const SizedBox(height: 8),
                _DialogRow(
                    label: 'Amount',
                    value: _currency.format(amount),
                    valueColor: const Color(0xFF2E7D32),
                    bold: true),
                if (_scheduledDate != null) ...[
                  const SizedBox(height: 8),
                  _DialogRow(
                      label: 'Scheduled',
                      value: _dateFormat.format(_scheduledDate!)),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'This action will transfer funds to the customer\'s account.',
                    style: TextStyle(
                        fontSize: 12, color: cs.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                    backgroundColor: _typeColor(loan.loanType)),
                child: const Text('Disburse'),
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
        title: const Text('Disburse Loan'),
        centerTitle: false,
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
          if (provider.isLoading && provider.selectedLoan == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.hasError && provider.selectedLoan == null) {
            return _ErrorBody(
              message: provider.errorMessage ?? 'Failed to load loan.',
              onRetry: _loadLoan,
            );
          }
          final loan = provider.selectedLoan;
          if (loan == null) {
            return const Center(child: Text('No loan data available.'));
          }

          // Guard: only APPROVED loans can be disbursed
          final isApproved = loan.approvalStatus == ApprovalStatus.approved;
          if (!isApproved) {
            return _NotApprovedBody(loan: loan);
          }

          return Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  children: [
                    // ── Read-only loan summary card ─────────────────────
                    _LoanSummaryCard(loan: loan),
                    const SizedBox(height: 20),

                    // ── Form section header ──────────────────────────────
                    _SectionHeader(
                      icon: Icons.send_rounded,
                      title: 'Disbursement Details',
                      color: _typeColor(loan.loanType),
                    ),
                    const SizedBox(height: 16),

                    // ── Disbursement amount ──────────────────────────────
                    _FormLabel('Disbursement Amount *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        prefixText: '৳ ',
                        hintText: '0.00',
                        helperText:
                            'Max: ${_currency.format(loan.approvedAmount ?? loan.principal)}',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Reset to approved amount',
                          onPressed: () {
                            final max =
                                loan.approvedAmount ?? loan.principal;
                            _amountCtrl.text =
                                max.toStringAsFixed(2);
                          },
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Disbursement amount is required';
                        }
                        final d = double.tryParse(v.trim());
                        if (d == null || d < 1) {
                          return 'Minimum disbursement is ৳1.00';
                        }
                        final max =
                            loan.approvedAmount ?? loan.principal;
                        if (d > max) {
                          return 'Cannot exceed approved amount (${_currency.format(max)})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Account number ────────────────────────────────────
                    _FormLabel('Account Number *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _accountCtrl,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Disbursement account number',
                        prefixIcon: const Icon(
                            Icons.account_balance_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Account number is required';
                        }
                        if (v.trim().length < 6) {
                          return 'Enter a valid account number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Bank details (optional) ───────────────────────────
                    _FormLabel('Bank Details (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _bankDetailsCtrl,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. SWIFT code, branch, IFSC code…',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Scheduled date (optional) ─────────────────────────
                    _FormLabel('Scheduled Date (optional)'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: 'Tap to pick a date',
                          prefixIcon: const Icon(
                              Icons.calendar_today_outlined),
                          suffixIcon: _scheduledDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: _clearDate,
                                )
                              : const Icon(
                                  Icons.arrow_drop_down_rounded),
                          helperText:
                              'Leave blank for immediate disbursement',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          _scheduledDate != null
                              ? _dateFormat.format(_scheduledDate!)
                              : 'Immediate (no scheduled date)',
                          style: TextStyle(
                            color: _scheduledDate != null
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Info notice ───────────────────────────────────────
                    _InfoBanner(
                      icon: Icons.info_outline_rounded,
                      message:
                          'Disbursing will transfer funds from the bank '
                          'to the customer\'s linked account. '
                          'This action cannot be undone once processed.',
                    ),
                  ],
                ),
              ),

              if (_isSubmitting) const _LoadingOverlay(message: 'Processing disbursement…'),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<LoanOfficerProvider>(
        builder: (_, provider, __) {
          final loan = provider.selectedLoan;
          if (loan == null || loan.approvalStatus != ApprovalStatus.approved) {
            return const SizedBox.shrink();
          }
          return _BottomBar(
            typeColor: _typeColor(loan.loanType),
            isSubmitting: _isSubmitting,
            onSubmit: () => _submit(loan),
          );
        },
      ),
    );
  }
}

// ─── Loan Summary Card (read-only) ────────────────────────────────────────────

class _LoanSummaryCard extends StatelessWidget {
  final LoanResponseModel loan;
  const _LoanSummaryCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(loan.loanType);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type header
          Row(
            children: [
              Icon(_typeIcon(loan.loanType),
                  color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loan.loanType.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _WhiteBadge(text: loan.approvalStatus.displayName.toUpperCase()),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${loan.loanId}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Approved Amount',
                  value: _currency.format(
                      loan.approvedAmount ?? loan.principal),
                  bold: true,
                ),
              ),
              Expanded(
                child: _HeroStat(
                  label: 'Customer',
                  value: loan.customerName ?? '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Account',
                  value: loan.accountNumber ?? '—',
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
          if (loan.actualDisbursementDate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Already disbursed on: ${_dateFormat.format(loan.actualDisbursementDate!)}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
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

class _WhiteBadge extends StatelessWidget {
  final String text;
  const _WhiteBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ─── Bottom action bar ────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final Color typeColor;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _BottomBar({
    required this.typeColor,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
              top: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSubmitting
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
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  isSubmitting ? 'Processing…' : 'Disburse Loan',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: typeColor,
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

// ─── Misc shared widgets ──────────────────────────────────────────────────────

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

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoBanner({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _DialogRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

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
                Text(message,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotApprovedBody extends StatelessWidget {
  final LoanResponseModel loan;
  const _NotApprovedBody({required this.loan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_clock_rounded,
                size: 72, color: cs.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'Loan Not Yet Approved',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Only APPROVED loans can be disbursed. '
              'This loan is currently in '
              '${loan.approvalStatus.displayName} status.',
              style:
                  TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
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
            Text('Failed to load loan',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
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
