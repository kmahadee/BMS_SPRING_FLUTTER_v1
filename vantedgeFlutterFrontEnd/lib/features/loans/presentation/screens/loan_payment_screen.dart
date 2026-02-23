import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/loans/data/models/loan_enums.dart';
import 'package:vantedge/features/loans/data/models/loan_model.dart';
import 'package:vantedge/features/loans/presentation/providers/loan_provider.dart';
import 'package:vantedge/features/loans/presentation/widgets/loan_enum_display_helpers.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';
import 'package:vantedge/shared/widgets/custom_button.dart';
import 'package:vantedge/shared/widgets/custom_text_field.dart';

// ─── Payment Modes ────────────────────────────────────────────────────────────

enum _PaymentMode {
  online,
  cash,
  cheque,
  neft,
  rtgs;

  String get displayName {
    switch (this) {
      case _PaymentMode.online: return 'Online Banking';
      case _PaymentMode.cash:   return 'Cash';
      case _PaymentMode.cheque: return 'Cheque';
      case _PaymentMode.neft:   return 'NEFT';
      case _PaymentMode.rtgs:   return 'RTGS';
    }
  }

  LoanPaymentMode toLoanPaymentMode() {
    switch (this) {
      case _PaymentMode.online: return LoanPaymentMode.imps;
      case _PaymentMode.cash:   return LoanPaymentMode.cash;
      case _PaymentMode.cheque: return LoanPaymentMode.cheque;
      case _PaymentMode.neft:   return LoanPaymentMode.neft;
      case _PaymentMode.rtgs:   return LoanPaymentMode.neft;
    }
  }

  IconData get icon {
    switch (this) {
      case _PaymentMode.online: return Icons.phone_android_rounded;
      case _PaymentMode.cash:   return Icons.money_rounded;
      case _PaymentMode.cheque: return Icons.receipt_long_rounded;
      case _PaymentMode.neft:   return Icons.account_balance_rounded;
      case _PaymentMode.rtgs:   return Icons.bolt_rounded;
    }
  }
}

const double _kForeclosureChargeRate = 0.02; // 2% of outstanding

// ─── Screen ───────────────────────────────────────────────────────────────────

class LoanPaymentScreen extends StatefulWidget {
  final String loanId;
  const LoanPaymentScreen({super.key, required this.loanId});

  @override
  State<LoanPaymentScreen> createState() => _LoanPaymentScreenState();
}

class _LoanPaymentScreenState extends State<LoanPaymentScreen> {
  static final _currFmt = NumberFormat.currency(
      symbol: '৳', decimalDigits: 2, locale: 'en_IN');
  static final _dateFmt = DateFormat('dd MMM yyyy');

  // Repayment form
  final _repayKey   = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _refCtrl    = TextEditingController();
  _PaymentMode _mode = _PaymentMode.online;
  DateTime _date     = DateTime.now();

  // Foreclosure form
  final _fcKey         = GlobalKey<FormState>();
  final _fcAccountCtrl = TextEditingController();
  DateTime _fcDate     = DateTime.now();

  LoanResponseModel? _loan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final provider = context.read<LoanProvider>();
    final current  = provider.selectedLoan;
    if (current?.loanId == widget.loanId) {
      setState(() => _loan = current);
      _prefillAmount(current!);
    } else {
      await provider.fetchLoanById(widget.loanId);
      if (!mounted) return;
      final loaded = provider.selectedLoan;
      if (loaded != null) {
        setState(() => _loan = loaded);
        _prefillAmount(loaded);
      }
    }
  }

  void _prefillAmount(LoanResponseModel loan) {
    if (loan.monthlyEMI != null && _amountCtrl.text.isEmpty) {
      _amountCtrl.text = loan.monthlyEMI!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _fcAccountCtrl.dispose();
    super.dispose();
  }

  // ── Computed ───────────────────────────────────────────────────────────────

  String _fmt(double? v) => v != null ? _currFmt.format(v) : '—';

  double get _enteredAmount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0.0;

  bool get _isOverpayment =>
      _loan?.outstandingBalance != null &&
      _enteredAmount > (_loan!.outstandingBalance!);

  double get _foreclosureCharge =>
      (_loan?.outstandingBalance ?? 0) * _kForeclosureChargeRate;

  double get _totalForeclosureAmount =>
      (_loan?.outstandingBalance ?? 0) + _foreclosureCharge;

  // ── Date pickers ───────────────────────────────────────────────────────────

  Future<void> _pickPaymentDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select payment date',
    );
    if (p != null) setState(() => _date = p);
  }

  Future<void> _pickForeclosureDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _fcDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Select foreclosure date',
    );
    if (p != null) setState(() => _fcDate = p);
  }

  // ── Submit handlers ────────────────────────────────────────────────────────

  Future<void> _submitRepayment() async {
    if (!(_repayKey.currentState?.validate() ?? false)) return;
    if (_loan == null) return;

    final ok = await _confirm(
      title: 'Confirm Payment',
      body:  'Pay ${_fmt(_enteredAmount)} via ${_mode.displayName}\n'
             'on ${_dateFmt.format(_date)}?',
      label: 'Pay Now',
    );
    if (ok != true) return;

    final provider = context.read<LoanProvider>();
    final success  = await provider.repayLoan(
      loanId:               widget.loanId,
      amount:               _enteredAmount,
      paymentMode:          _mode.toLoanPaymentMode(),
      date:                 _date,
      transactionReference: _refCtrl.text.trim().isEmpty
                                ? null
                                : _refCtrl.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      _snack('Payment of ${_fmt(_enteredAmount)} processed!', success: true);
      await provider.fetchLoanById(widget.loanId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      _snack(provider.errorMessage ?? 'Payment failed.');
      provider.clearError();
    }
  }

  Future<void> _submitForeclosure() async {
    if (!(_fcKey.currentState?.validate() ?? false)) return;
    if (_loan == null) return;

    final ok = await _confirm(
      title: 'Confirm Foreclosure',
      body:  'Foreclose loan on ${_dateFmt.format(_fcDate)}?\n\n'
             'Total: ${_fmt(_totalForeclosureAmount)} '
             '(includes ${_fmt(_foreclosureCharge)} foreclosure charge).\n\n'
             'This action cannot be undone.',
      label: 'Foreclose',
      destructive: true,
    );
    if (ok != true) return;

    final provider = context.read<LoanProvider>();
    final success  = await provider.forecloseLoan(
      loanId:                  widget.loanId,
      foreclosureDate:         _fcDate,
      settlementAccountNumber: _fcAccountCtrl.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      _snack('Loan foreclosed successfully!', success: true);
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.loans,
        (r) => r.settings.name == AppRoutes.customerHome,
      );
    } else {
      _snack(provider.errorMessage ?? 'Foreclosure failed.');
      provider.clearError();
    }
  }

  // ── Dialogs / snackbars ────────────────────────────────────────────────────

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String label,
    bool destructive = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: cs.error)
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool success = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: Colors.white,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: success ? const Color(0xFF2E7D32) : cs.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: Duration(seconds: success ? 3 : 4),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: CustomAppBar(
            title: 'Loan Payment',
            showNotifications: false,
          ),
          body: Stack(
            children: [
              _buildContent(provider),
              if (provider.isLoading) const _LoadingOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(LoanProvider provider) {
    if (_loan == null && !provider.isLoading) {
      return const _NoDataBody();
    }

    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // ── Loan banner ────────────────────────────────────────────────
          if (_loan != null)
            _LoanBanner(loan: _loan!, fmt: _fmt),

          const SizedBox(height: 24),

          // ── Repayment section ──────────────────────────────────────────
          _SecLabel('Make a Payment', cs.primary, theme),
          const SizedBox(height: 12),

          Form(
            key: _repayKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amount field
                _FLabel('Payment Amount', theme, cs),
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: cs.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    suffixIcon: _loan?.monthlyEMI != null
                        ? Tooltip(
                            message: 'Reset to monthly EMI',
                            child: IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              onPressed: () => setState(() {
                                _amountCtrl.text =
                                    _loan!.monthlyEMI!.toStringAsFixed(2);
                              }),
                            ),
                          )
                        : null,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Enter payment amount';
                    }
                    final p = double.tryParse(v.replaceAll(',', ''));
                    if (p == null || p <= 0) {
                      return 'Amount must be greater than zero';
                    }
                    if (_loan?.outstandingBalance != null &&
                        p > _loan!.outstandingBalance!) {
                      return 'Exceeds outstanding balance '
                          '(${_fmt(_loan!.outstandingBalance)})';
                    }
                    return null;
                  },
                ),

                if (_isOverpayment) ...[
                  const SizedBox(height: 8),
                  _Warning(
                      'Amount exceeds outstanding balance of '
                      '${_fmt(_loan!.outstandingBalance)}.'),
                ],

                if (_loan != null) ...[
                  const SizedBox(height: 10),
                  _QuickFillRow(
                    emi: _loan!.monthlyEMI,
                    outstanding: _loan!.outstandingBalance,
                    onFill: (v) => setState(() =>
                        _amountCtrl.text = v.toStringAsFixed(2)),
                    fmt: _fmt,
                  ),
                ],

                const SizedBox(height: 18),

                // Payment mode
                _FLabel('Payment Mode', theme, cs),
                const SizedBox(height: 6),
                DropdownButtonFormField<_PaymentMode>(
                  value: _mode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: cs.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  items: _PaymentMode.values.map((m) => DropdownMenuItem(
                        value: m,
                        child: Row(
                          children: [
                            Icon(m.icon, size: 18, color: cs.primary),
                            const SizedBox(width: 10),
                            Text(m.displayName),
                          ],
                        ),
                      )).toList(),
                  onChanged: (m) => setState(() => _mode = m!),
                  validator: (v) =>
                      v == null ? 'Select payment mode' : null,
                ),

                const SizedBox(height: 18),

                // Payment date
                _FLabel('Payment Date', theme, cs),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickPaymentDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: cs.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      suffixIcon: const Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text(_dateFmt.format(_date),
                        style: theme.textTheme.bodyLarge),
                  ),
                ),

                const SizedBox(height: 18),

                // Transaction reference
                _FLabel('Transaction Reference (optional)', theme, cs),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _refCtrl,
                  hint: 'e.g. UTR number / Cheque number',
                  prefixIcon: const Icon(Icons.tag_rounded),
                  maxLength: 60,
                ),

                const SizedBox(height: 24),

                CustomButton(
                  text: 'Confirm Payment',
                  onPressed: _submitRepayment,
                  icon: const Icon(Icons.payment_rounded,
                      color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Foreclosure section ────────────────────────────────────────
          if (_loan?.loanStatus == LoanStatus.active) ...[
            const Divider(),
            const SizedBox(height: 8),
            _ForeclosureTile(
              loan: _loan!,
              fmt: _fmt,
              dateFmt: _dateFmt,
              formKey: _fcKey,
              accountCtrl: _fcAccountCtrl,
              fcDate: _fcDate,
              foreclosureCharge: _foreclosureCharge,
              totalAmount: _totalForeclosureAmount,
              onPickDate: _pickForeclosureDate,
              onSubmit: _submitForeclosure,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Loan Banner ──────────────────────────────────────────────────────────────

class _LoanBanner extends StatelessWidget {
  final LoanResponseModel loan;
  final String Function(double?) fmt;

  const _LoanBanner({required this.loan, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final color = loan.loanType.color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(loan.loanType.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(loan.loanType.displayName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(loan.loanStatus.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _BStat('Outstanding', fmt(loan.outstandingBalance)),
              _BStat('Monthly EMI', fmt(loan.monthlyEMI)),
              _BStat('Rate',
                  '${loan.annualInterestRate.toStringAsFixed(2)}% p.a.'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BStat extends StatelessWidget {
  final String label;
  final String value;
  const _BStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─── Quick Fill Row ───────────────────────────────────────────────────────────

class _QuickFillRow extends StatelessWidget {
  final double? emi;
  final double? outstanding;
  final ValueChanged<double> onFill;
  final String Function(double?) fmt;

  const _QuickFillRow({
    required this.emi,
    required this.outstanding,
    required this.onFill,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      children: [
        if (emi != null)
          ActionChip(
            label: Text('EMI ${fmt(emi)}',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w600)),
            onPressed: () => onFill(emi!),
            avatar: Icon(Icons.calendar_month_rounded,
                size: 14, color: cs.primary),
            backgroundColor: cs.primaryContainer.withOpacity(0.4),
            side: BorderSide(color: cs.primary.withOpacity(0.3)),
          ),
        if (outstanding != null)
          ActionChip(
            label: Text('Full Outstanding ${fmt(outstanding)}',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.error, fontWeight: FontWeight.w600)),
            onPressed: () => onFill(outstanding!),
            avatar: Icon(Icons.account_balance_rounded,
                size: 14, color: cs.error),
            backgroundColor: cs.errorContainer.withOpacity(0.3),
            side: BorderSide(color: cs.error.withOpacity(0.3)),
          ),
      ],
    );
  }
}

// ─── Foreclosure Tile ─────────────────────────────────────────────────────────

class _ForeclosureTile extends StatelessWidget {
  final LoanResponseModel loan;
  final String Function(double?) fmt;
  final DateFormat dateFmt;
  final GlobalKey<FormState> formKey;
  final TextEditingController accountCtrl;
  final DateTime fcDate;
  final double foreclosureCharge;
  final double totalAmount;
  final VoidCallback onPickDate;
  final VoidCallback onSubmit;

  const _ForeclosureTile({
    required this.loan,
    required this.fmt,
    required this.dateFmt,
    required this.formKey,
    required this.accountCtrl,
    required this.fcDate,
    required this.foreclosureCharge,
    required this.totalAmount,
    required this.onPickDate,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(Icons.lock_reset_rounded, color: cs.error),
        title: Text('Loan Foreclosure',
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: cs.error)),
        subtitle: Text(
            'Pay the full outstanding to close this loan early.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant)),
        initiallyExpanded: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.error.withOpacity(0.35)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
        ),
        backgroundColor: cs.errorContainer.withOpacity(0.08),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Breakdown card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: cs.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        _BRow('Outstanding Balance',
                            fmt(loan.outstandingBalance), theme, cs),
                        const SizedBox(height: 6),
                        _BRow('Foreclosure Charge (2%)',
                            fmt(foreclosureCharge), theme, cs,
                            valueColor: cs.error),
                        const Divider(height: 16),
                        _BRow('Total Payable', fmt(totalAmount), theme, cs,
                            bold: true, valueColor: cs.error),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Warning
                  _Warning(
                    'Foreclosing this loan is permanent and cannot be undone.',
                    isError: true,
                  ),
                  const SizedBox(height: 16),

                  // Foreclosure date
                  _FLabel('Foreclosure Date', theme, cs),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onPickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: cs.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        suffixIcon:
                            const Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(dateFmt.format(fcDate),
                          style: theme.textTheme.bodyLarge),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Settlement account
                  _FLabel('Settlement Account Number', theme, cs),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: accountCtrl,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'e.g. 10001234567',
                      prefixIcon: const Icon(
                          Icons.account_balance_wallet_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.error, width: 2),
                      ),
                      filled: true,
                      fillColor: cs.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Settlement account number is required';
                      }
                      if (v.trim().length < 6) {
                        return 'Enter a valid account number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  FilledButton.icon(
                    onPressed: onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: Text('Foreclose — Pay ${fmt(totalAmount)}'),
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

class _BRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;
  final bool bold;
  final Color? valueColor;

  const _BRow(this.label, this.value, this.theme, this.cs,
      {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant)),
        Text(value,
            style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? cs.onSurface)),
      ],
    );
  }
}

// ─── Small shared widgets ─────────────────────────────────────────────────────

class _Warning extends StatelessWidget {
  final String message;
  final bool isError;

  const _Warning(this.message, {this.isError = false});

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = isError ? cs.error : const Color(0xFFF57F17);
    final bg    = isError
        ? cs.errorContainer.withOpacity(0.4)
        : const Color(0xFFFFF3E0).withOpacity(0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _SecLabel extends StatelessWidget {
  final String text;
  final Color color;
  final ThemeData theme;

  const _SecLabel(this.text, this.color, this.theme);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700, color: color));
  }
}

class _FLabel extends StatelessWidget {
  final String text;
  final ThemeData theme;
  final ColorScheme cs;

  const _FLabel(this.text, this.theme, this.cs);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600, color: cs.onSurfaceVariant));
  }
}

// ─── Loading Overlay ──────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      alignment: Alignment.center,
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 36, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing…',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── No Data Body ─────────────────────────────────────────────────────────────

class _NoDataBody extends StatelessWidget {
  const _NoDataBody();

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
            Icon(Icons.cloud_off_rounded, size: 72, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text('Loan data unavailable',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Please go back and reopen this screen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
