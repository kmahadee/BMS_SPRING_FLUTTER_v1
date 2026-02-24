import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/dps/data/models/dps_model.dart';
import 'package:vantedge/features/dps/presentation/providers/dps_provider.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';

// ── Payment mode enum ────────────────────────────────────────────────────────

enum _PayMode {
  cash('CASH', 'Cash', Icons.money_rounded),
  card('CARD', 'Card', Icons.credit_card_rounded),
  autoDebit('AUTO_DEBIT', 'Auto Debit', Icons.autorenew_rounded);

  const _PayMode(this.apiValue, this.label, this.icon);
  final String apiValue;
  final String label;
  final IconData icon;
}

// ── Screen ───────────────────────────────────────────────────────────────────

class PayInstallmentScreen extends StatefulWidget {
  final String dpsNumber;

  const PayInstallmentScreen({super.key, required this.dpsNumber});

  @override
  State<PayInstallmentScreen> createState() => _PayInstallmentScreenState();
}

class _PayInstallmentScreenState extends State<PayInstallmentScreen> {
  // ── State ──────────────────────────────────────────────────────────────────

  final _formKey      = GlobalKey<FormState>();
  final _amountCtrl   = TextEditingController();
  final _remarksCtrl  = TextEditingController();
  _PayMode? _payMode;

  // ── Formatters ─────────────────────────────────────────────────────────────

  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dtFmt   = DateFormat('dd MMM yyyy, hh:mm a');
  static final _currFmt = NumberFormat.currency(
    symbol: '৳ ',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  String _fmtAmt(double? v) => v != null ? _currFmt.format(v) : '—';
  String _fmtDate(DateTime? d) => d != null ? _dateFmt.format(d) : '—';

  String _currencySymbol(String? currency) {
    switch ((currency ?? 'BDT').toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'BDT':
      default:    return '৳';
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dps = context.read<DpsProvider>().selectedDps;
      if (dps?.monthlyInstallment != null && _amountCtrl.text.isEmpty) {
        _amountCtrl.text = dps!.monthlyInstallment!.toStringAsFixed(2);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  // ── Parsed amount ──────────────────────────────────────────────────────────

  double get _enteredAmount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0.0;

  // ── Submit flow ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final modeLabel  = _payMode!.label;
    final amountStr  = _fmtAmt(_enteredAmount);
    final dpsNum     = widget.dpsNumber;

    // Step 1: Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.payment_rounded),
            SizedBox(width: 8),
            Text('Confirm Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfirmRow('DPS Account', dpsNum),
            const SizedBox(height: 8),
            _ConfirmRow('Amount', amountStr),
            const SizedBox(height: 8),
            _ConfirmRow('Payment Mode', modeLabel),
            if (_remarksCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _ConfirmRow('Remarks', _remarksCtrl.text.trim()),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Pay Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Step 2: Call provider
    final provider = context.read<DpsProvider>();
    final success  = await provider.payInstallment({
      'dpsNumber':   widget.dpsNumber,
      'amount':      _enteredAmount,
      'paymentMode': _payMode!.apiValue,
      if (_remarksCtrl.text.trim().isNotEmpty)
        'remarks': _remarksCtrl.text.trim(),
    });

    if (!mounted) return;

    if (success) {
      // Step 3: Show receipt bottom sheet
      await _showReceiptSheet(
        amount:    _enteredAmount,
        mode:      _payMode!.label,
        timestamp: DateTime.now(),
      );
      provider.clearMessages();
    } else {
      _snack(
        provider.errorMessage ?? 'Payment failed. Please try again.',
        isError: true,
      );
      provider.clearMessages();
    }
  }

  // ── Success receipt bottom sheet ───────────────────────────────────────────

  Future<void> _showReceiptSheet({
    required double amount,
    required String mode,
    required DateTime timestamp,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ReceiptSheet(
        dpsNumber: widget.dpsNumber,
        amount:    amount,
        mode:      mode,
        timestamp: timestamp,
        fmtAmt:    _fmtAmt,
        fmtDt:     (d) => _dtFmt.format(d),
        onViewHistory: () {
          Navigator.of(ctx).pop();
          Navigator.pushNamed(
            context,
            '${AppRoutes.dps}/installment-history',
            arguments: widget.dpsNumber,
          );
        },
        onDone: () {
          Navigator.of(ctx).pop(); // close sheet
          Navigator.of(context).pop(true); // pop back to DPS details
        },
      ),
    );
  }

  // ── Snackbar helper ────────────────────────────────────────────────────────

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<DpsProvider>(
      builder: (context, provider, _) {
        final dps    = provider.selectedDps;
        final theme  = Theme.of(context);
        final cs     = theme.colorScheme;
        final symbol = _currencySymbol(dps?.currency);

        return Scaffold(
          backgroundColor: cs.surfaceContainerLowest,
          appBar: const CustomAppBar(
            title: 'Pay Installment',
            showNotifications: false,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── DPS Summary card ───────────────────────────────────
                    if (dps != null) _DpsSummaryCard(dps: dps, fmtDate: _fmtDate, fmtAmt: _fmtAmt),
                    if (dps == null)
                      _DpsNumberChip(dpsNumber: widget.dpsNumber, cs: cs, theme: theme),

                    const SizedBox(height: 24),

                    // ── Payment form ───────────────────────────────────────
                    _SectionLabel('Payment Details', cs.primary, theme),
                    const SizedBox(height: 12),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Amount
                          _FieldLabel('Amount', theme, cs),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              prefixText: '$symbol ',
                              hintText: '0.00',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: cs.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: cs.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              suffixIcon: dps?.monthlyInstallment != null
                                  ? Tooltip(
                                      message: 'Reset to monthly installment',
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.refresh_rounded,
                                            size: 18),
                                        onPressed: () => setState(() {
                                          _amountCtrl.text = dps!
                                              .monthlyInstallment!
                                              .toStringAsFixed(2);
                                        }),
                                      ),
                                    )
                                  : null,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter the payment amount';
                              }
                              final parsed = double.tryParse(
                                  v.replaceAll(',', ''));
                              if (parsed == null || parsed <= 0) {
                                return 'Amount must be greater than zero';
                              }
                              return null;
                            },
                          ),

                          // Quick-fill chips
                          if (dps != null) ...[
                            const SizedBox(height: 10),
                            _QuickFillChips(
                              monthlyInstallment:
                                  dps.monthlyInstallment,
                              penaltyAmount: dps.penaltyAmount,
                              onFill: (v) => setState(() {
                                _amountCtrl.text = v.toStringAsFixed(2);
                              }),
                              fmtAmt: _fmtAmt,
                              cs: cs,
                              theme: theme,
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Payment mode
                          _FieldLabel('Payment Mode', theme, cs),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<_PayMode>(
                            initialValue: _payMode,
                            hint: const Text('Select payment mode'),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: cs.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: cs.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            items: _PayMode.values
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Row(
                                        children: [
                                          Icon(m.icon,
                                              size: 18, color: cs.primary),
                                          const SizedBox(width: 10),
                                          Text(m.label),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (m) =>
                                setState(() => _payMode = m),
                            validator: (v) =>
                                v == null ? 'Select a payment mode' : null,
                          ),

                          const SizedBox(height: 20),

                          // Remarks
                          _FieldLabel('Remarks (optional)', theme, cs),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _remarksCtrl,
                            maxLines: 2,
                            maxLength: 200,
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. Monthly installment for April…',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: cs.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: cs.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Loading overlay
              if (provider.isLoading) const _LoadingOverlay(),
            ],
          ),

          // ── Sticky confirm button ────────────────────────────────────────
          bottomNavigationBar: _ConfirmBar(
            isLoading: provider.isLoading,
            onConfirm: _submit,
          ),
        );
      },
    );
  }
}

// ── DPS summary card ─────────────────────────────────────────────────────────

class _DpsSummaryCard extends StatelessWidget {
  final DpsModel dps;
  final String Function(DateTime?) fmtDate;
  final String Function(double?) fmtAmt;

  const _DpsSummaryCard({
    required this.dps,
    required this.fmtDate,
    required this.fmtAmt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Icon(Icons.savings_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dps.dpsNumber ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabel(dps.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stats row
          Row(
            children: [
              _BStat(
                'Monthly Installment',
                fmtAmt(dps.monthlyInstallment),
              ),
              _BStat(
                'Next Due',
                fmtDate(dps.nextPaymentDate),
              ),
              _BStat(
                'Installments Paid',
                '${dps.totalInstallmentsPaid ?? 0} / ${dps.tenureMonths ?? 0}',
              ),
            ],
          ),
          if ((dps.penaltyAmount ?? 0) > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Pending penalty: ${fmtAmt(dps.penaltyAmount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String? s) {
    if (s == null) return 'Unknown';
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
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
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Fallback chip when selectedDps is null ───────────────────────────────────

class _DpsNumberChip extends StatelessWidget {
  final String dpsNumber;
  final ColorScheme cs;
  final ThemeData theme;

  const _DpsNumberChip({
    required this.dpsNumber,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_outlined, color: cs.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            dpsNumber,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick-fill chips ─────────────────────────────────────────────────────────

class _QuickFillChips extends StatelessWidget {
  final double? monthlyInstallment;
  final double? penaltyAmount;
  final ValueChanged<double> onFill;
  final String Function(double?) fmtAmt;
  final ColorScheme cs;
  final ThemeData theme;

  const _QuickFillChips({
    required this.monthlyInstallment,
    required this.penaltyAmount,
    required this.onFill,
    required this.fmtAmt,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasPenalty = (penaltyAmount ?? 0) > 0;
    final total = (monthlyInstallment ?? 0) + (penaltyAmount ?? 0);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (monthlyInstallment != null)
          ActionChip(
            avatar: Icon(Icons.calendar_month_rounded,
                size: 14, color: cs.primary),
            label: Text(
              'Monthly ${fmtAmt(monthlyInstallment)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => onFill(monthlyInstallment!),
            backgroundColor: cs.primaryContainer.withOpacity(0.4),
            side: BorderSide(color: cs.primary.withOpacity(0.3)),
          ),
        if (hasPenalty)
          ActionChip(
            avatar: Icon(Icons.warning_amber_rounded,
                size: 14, color: cs.error),
            label: Text(
              'With penalty ${fmtAmt(total)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => onFill(total),
            backgroundColor: cs.errorContainer.withOpacity(0.3),
            side: BorderSide(color: cs.error.withOpacity(0.3)),
          ),
      ],
    );
  }
}

// ── Confirm dialog row ────────────────────────────────────────────────────────

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            ),
          ),
        ),
      ],
    );
  }
}

// ── Form helpers ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  final ThemeData theme;

  const _SectionLabel(this.label, this.color, this.theme);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;
  final ColorScheme cs;

  const _FieldLabel(this.label, this.theme, this.cs);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
    );
  }
}

// ── Sticky confirm button bar ────────────────────────────────────────────────

class _ConfirmBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onConfirm;

  const _ConfirmBar({required this.isLoading, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: isLoading ? null : onConfirm,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.payment_rounded),
          label: Text(isLoading ? 'Processing…' : 'Confirm Payment'),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Loading overlay ───────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.18),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

// ── Receipt bottom sheet ──────────────────────────────────────────────────────

class _ReceiptSheet extends StatefulWidget {
  final String dpsNumber;
  final double amount;
  final String mode;
  final DateTime timestamp;
  final String Function(double?) fmtAmt;
  final String Function(DateTime) fmtDt;
  final VoidCallback onViewHistory;
  final VoidCallback onDone;

  const _ReceiptSheet({
    required this.dpsNumber,
    required this.amount,
    required this.mode,
    required this.timestamp,
    required this.fmtAmt,
    required this.fmtDt,
    required this.onViewHistory,
    required this.onDone,
  });

  @override
  State<_ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends State<_ReceiptSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Animated checkmark
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.shade300,
                  width: 2.5,
                ),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 52,
                color: Colors.green.shade600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Success title
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                Text(
                  'Payment Successful!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your installment has been recorded.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Receipt details card
          FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.6)),
              ),
              child: Column(
                children: [
                  _ReceiptRow('DPS Account', widget.dpsNumber,
                      theme, cs, mono: true),
                  const Divider(height: 16),
                  _ReceiptRow(
                    'Amount Paid',
                    widget.fmtAmt(widget.amount),
                    theme, cs,
                    valueColor: Colors.green.shade700,
                    bold: true,
                  ),
                  const SizedBox(height: 8),
                  _ReceiptRow(
                      'Payment Mode', widget.mode, theme, cs),
                  const SizedBox(height: 8),
                  _ReceiptRow(
                    'Date & Time',
                    widget.fmtDt(widget.timestamp),
                    theme, cs,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onViewHistory,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('View Installment History'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: widget.onDone,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;
  final Color? valueColor;
  final bool bold;
  final bool mono;

  const _ReceiptRow(
    this.label,
    this.value,
    this.theme,
    this.cs, {
    this.valueColor,
    this.bold = false,
    this.mono  = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? cs.onSurface,
              fontFamily: mono ? 'monospace' : null,
              fontSize: mono ? 12 : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
