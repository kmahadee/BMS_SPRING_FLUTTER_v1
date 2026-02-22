import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/accounts/data/models/account_list_item_dto.dart';
import 'package:vantedge/features/accounts/data/models/account_status.dart';
import 'package:vantedge/features/accounts/data/models/account_type.dart';
import 'package:vantedge/features/accounts/presentation/providers/account_provider.dart';
import 'package:vantedge/features/auth/presentation/widgets/signup_step_indicator.dart';
import 'package:vantedge/features/transactions/data/models/transaction_enums.dart';
import 'package:vantedge/features/transactions/data/models/transaction_model.dart';
import 'package:vantedge/features/transactions/data/models/transfer_request.dart';
import 'package:vantedge/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:vantedge/features/transactions/presentation/widgets/amount_input.dart';
import 'package:vantedge/features/transactions/presentation/widgets/account_selector.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';
import 'package:vantedge/shared/widgets/custom_button.dart';



const double _kNormalFee       = 2.00;
const double _kHighFee         = 7.00;
const double _kServiceTaxRate  = 0.18;
const double _kRtgsMinimum     = 2000.00;


class TransferScreen extends StatefulWidget {
  final String? preselectedAccountNumber;

  const TransferScreen({super.key, this.preselectedAccountNumber});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _kTotalSteps = 2;

  final GlobalKey<FormState> _step0Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _step1Key = GlobalKey<FormState>();

  AccountListItemDTO? _sourceAccount;
  AccountListItemDTO? _destinationAccount;          // OWN type only
  final TextEditingController _destNumberCtrl = TextEditingController();
  TransferType  _transferType  = TransferType.other;
  TransferMode  _transferMode  = TransferMode.neft;

  final TextEditingController _amountCtrl      = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _remarksCtrl     = TextEditingController();
  double _amount   = 0.0;
  String _priority = 'normal';

  bool   get _isFreeTransfer => _transferType == TransferType.own;
  double get _baseFee        => _isFreeTransfer ? 0.0 : (_priority == 'high' ? _kHighFee : _kNormalFee);
  double get _tax            => _baseFee * _kServiceTaxRate;
  double get _totalFee       => _baseFee + _tax;
  double get _totalDebit     => _amount + _totalFee;

  bool             _isSuccess          = false;
  TransactionModel? _completedTxn;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final ap = context.read<AccountProvider>();
    if (ap.accounts.isEmpty) ap.fetchMyAccounts();

    if (widget.preselectedAccountNumber != null) {
      final match = ap.accounts.where(
        (a) => a.accountNumber == widget.preselectedAccountNumber,
      );
      if (match.isNotEmpty) setState(() => _sourceAccount = match.first);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _destNumberCtrl.dispose();
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }


  void _advance() {
    final formKey = _currentStep == 0 ? _step0Key : _step1Key;
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (_currentStep == 0) {
      if (_sourceAccount == null) {
        _showWarning('Please select a source account.');
        return;
      }
      if (!_sourceAccount!.status.canTransact) {
        _showWarning(
          'Source account is ${_sourceAccount!.status.displayName}. '
          'Only ACTIVE accounts can initiate transfers.',
        );
        return;
      }
      if (_transferType == TransferType.own && _destinationAccount == null) {
        _showWarning('Please select a destination account.');
        return;
      }
    }

    if (_currentStep == 1) {
      if (_amount <= 0) {
        _showWarning('Please enter a valid amount greater than zero.');
        return;
      }
      if (_transferMode == TransferMode.rtgs && _amount < _kRtgsMinimum) {
        _showWarning(
          'RTGS transfers require a minimum of ${_fmt(_kRtgsMinimum)}.',
        );
        return;
      }
      if (_amount > (_sourceAccount?.availableBalance ?? 0)) {
        _showWarning(
          'Insufficient balance. Available: '
          '${_fmt(_sourceAccount?.availableBalance ?? 0)}.',
        );
        return;
      }
      _showConfirmation();
      return;
    }

    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _retreat() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }


  void _showConfirmation() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConfirmationDialog(
        sourceAccount: _sourceAccount!,
        destinationDisplay: _transferType == TransferType.own
            ? _destinationAccount!.accountNumber
            : _destNumberCtrl.text.trim(),
        amount:      _amount,
        baseFee:     _baseFee,
        tax:         _tax,
        totalDebit:  _totalDebit,
        transferMode: _transferMode,
        transferType: _transferType,
        priority:    _priority,
        description: _descriptionCtrl.text.trim(),
        fmt:         _fmt,
        onConfirm: () {
          Navigator.of(ctx).pop();
          _submit();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }


  Future<void> _submit() async {
    final txnProvider = context.read<TransactionProvider>();

    final request = TransferRequest(
      fromAccountNumber: _sourceAccount!.accountNumber,
      toAccountNumber: _transferType == TransferType.own
          ? _destinationAccount!.accountNumber
          : _destNumberCtrl.text.trim(),
      amount:       _amount,
      transferMode: _transferMode,
      description:  _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      remarks:      _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
      priority:     _priority,
      transferType: _transferType,
    );

    final success = await txnProvider.transfer(request);
    if (!mounted) return;

    if (success) {
      setState(() {
        _isSuccess   = true;
        _completedTxn = txnProvider.lastTransaction;
      });
    } else {
      final msg = txnProvider.errorMessage ?? 'Transfer failed. Please try again.';
      _showError(msg);
      txnProvider.clearError();
    }
  }


  void _startOver() {
    setState(() {
      _isSuccess        = false;
      _completedTxn     = null;
      _currentStep      = 0;
      _sourceAccount    = null;
      _destinationAccount = null;
      _destNumberCtrl.clear();
      _transferType  = TransferType.other;
      _transferMode  = TransferMode.neft;
      _amountCtrl.clear();
      _amount   = 0.0;
      _descriptionCtrl.clear();
      _remarksCtrl.clear();
      _priority = 'normal';
    });
    _pageController.jumpToPage(0);
  }


  String _fmt(double v) => '৳${NumberFormat('#,##0.00').format(v)}';

  void _showWarning(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.orange[800],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.red[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 5),
    ));
  }


  @override
  Widget build(BuildContext context) {
    final txnProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Fund Transfer',
        showNotifications: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: _isSuccess ? 'Done' : (_currentStep == 0 ? 'Cancel' : 'Back'),
          onPressed: _isSuccess
              ? () => Navigator.of(context).pop()
              : _retreat,
        ),
      ),
      body: Stack(
        children: [
          _isSuccess
              ? _SuccessView(
                  txn:          _completedTxn,
                  baseFee:      _baseFee,
                  tax:          _tax,
                  totalDebit:   _totalDebit,
                  fmt:          _fmt,
                  onNewTransfer: _startOver,
                  onHome: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.customerHome, (_) => false,
                  ),
                )
              : Column(
                  children: [
                    SignupStepIndicator(
                      currentStep: _currentStep,
                      totalSteps:  _kTotalSteps,
                      stepLabels:  const ['Source & Destination', 'Amount & Details'],
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _Step0(
                            formKey:          _step0Key,
                            sourceAccount:    _sourceAccount,
                            destAccount:      _destinationAccount,
                            destNumberCtrl:   _destNumberCtrl,
                            transferType:     _transferType,
                            transferMode:     _transferMode,
                            onSourceSelected: (a) => setState(() => _sourceAccount = a),
                            onDestSelected:   (a) => setState(() => _destinationAccount = a),
                            onTypeChanged:    (t) => setState(() {
                              _transferType = t;
                              if (t == TransferType.own) _transferMode = TransferMode.imps;
                            }),
                            onModeChanged: (m) => setState(() => _transferMode = m),
                          ),
                          _Step1(
                            formKey:         _step1Key,
                            amountCtrl:      _amountCtrl,
                            descriptionCtrl: _descriptionCtrl,
                            remarksCtrl:     _remarksCtrl,
                            maxAmount:       _sourceAccount?.availableBalance,
                            transferType:    _transferType,
                            transferMode:    _transferMode,
                            priority:        _priority,
                            amount:          _amount,
                            baseFee:         _baseFee,
                            tax:             _tax,
                            totalDebit:      _totalDebit,
                            fmt:             _fmt,
                            onAmountChanged: (v) => setState(() => _amount = v),
                            onPriorityChanged: (p) => setState(() => _priority = p),
                          ),
                        ],
                      ),
                    ),
                    _BottomBar(
                      currentStep: _currentStep,
                      isLoading:   txnProvider.isLoading,
                      nextLabel: _currentStep == _kTotalSteps - 1
                          ? 'Review Transfer'
                          : 'Continue',
                      onNext: _advance,
                      onBack: _retreat,
                    ),
                  ],
                ),

          if (txnProvider.isLoading)
            Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: const Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing transfer…'),
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


class _Step0 extends StatelessWidget {
  final GlobalKey<FormState>         formKey;
  final AccountListItemDTO?          sourceAccount;
  final AccountListItemDTO?          destAccount;
  final TextEditingController        destNumberCtrl;
  final TransferType                 transferType;
  final TransferMode                 transferMode;
  final ValueChanged<AccountListItemDTO> onSourceSelected;
  final ValueChanged<AccountListItemDTO> onDestSelected;
  final ValueChanged<TransferType>   onTypeChanged;
  final ValueChanged<TransferMode>   onModeChanged;

  const _Step0({
    required this.formKey,
    required this.sourceAccount,
    required this.destAccount,
    required this.destNumberCtrl,
    required this.transferType,
    required this.transferMode,
    required this.onSourceSelected,
    required this.onDestSelected,
    required this.onTypeChanged,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final cs          = theme.colorScheme;
    final ap          = context.watch<AccountProvider>();
    final allAccounts = ap.accounts;

    final destAccounts = allAccounts
        .where((a) => a.accountNumber != (sourceAccount?.accountNumber ?? ''))
        .where((a) => a.status.canTransact)
        .toList();

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          _SectionHeader(icon: Icons.account_balance_wallet_outlined, label: 'From Account'),
          const SizedBox(height: 8),
          AccountSelectorWidget(
            label: 'Source Account',
            accounts: allAccounts,
            selectedAccount: sourceAccount,
            onSelected: onSourceSelected,
            validator: (v) => v == null ? 'Please select a source account.' : null,
          ),
          if (sourceAccount != null && !sourceAccount!.status.canTransact) ...[
            const SizedBox(height: 8),
            _InlineAlert(
              message: 'This account is ${sourceAccount!.status.displayName} '
                  'and cannot send transfers.',
              isError: true,
            ),
          ],

          const SizedBox(height: 22),

          _SectionHeader(icon: Icons.swap_horiz_rounded, label: 'Transfer Type'),
          const SizedBox(height: 8),
          SegmentedButton<TransferType>(
            segments: const [
              ButtonSegment(
                value: TransferType.own,
                icon: Icon(Icons.person_outline_rounded),
                label: Text('Own Account'),
              ),
              ButtonSegment(
                value: TransferType.other,
                icon: Icon(Icons.people_alt_outlined),
                label: Text('Other Account'),
              ),
            ],
            selected: {transferType},
            onSelectionChanged: (s) => onTypeChanged(s.first),
            style: ButtonStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            transferType == TransferType.own
                ? 'Free — instant between your own accounts.'
                : 'Transfer fees apply (Normal: ৳2 + tax, High: ৳7 + tax).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 22),

          _SectionHeader(
            icon: Icons.send_rounded,
            label: transferType == TransferType.own
                ? 'To Account (Your Account)'
                : 'To Account (External)',
          ),
          const SizedBox(height: 8),

          if (transferType == TransferType.own)
            AccountSelectorWidget(
              label: 'Destination Account',
              accounts: destAccounts,
              selectedAccount: destAccount,
              onSelected: onDestSelected,
              validator: (v) => v == null ? 'Please select a destination account.' : null,
            )
          else
            TextFormField(
              controller: destNumberCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 16,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                cs,
                label: 'Destination Account Number',
                hint: 'Enter 10–16 digit account number',
                prefixIcon: const Icon(Icons.account_balance_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter the destination account number.';
                }
                if (v.trim().length < 10) return 'Account number must be at least 10 digits.';
                if (v.trim() == sourceAccount?.accountNumber) {
                  return 'Destination cannot be the same as the source account.';
                }
                return null;
              },
            ),

          const SizedBox(height: 22),

          if (transferType == TransferType.other) ...[
            _SectionHeader(icon: Icons.account_tree_outlined, label: 'Transfer Mode'),
            const SizedBox(height: 8),
            DropdownButtonFormField<TransferMode>(
              initialValue: transferMode,
              isExpanded: true,
              decoration: _inputDecoration(cs, label: 'Mode'),
              onChanged: (v) { if (v != null) onModeChanged(v); },
              items: const [
                DropdownMenuItem(
                  value: TransferMode.neft,
                  child: _ModeOption(label: 'NEFT', sub: 'National Electronic Funds Transfer'),
                ),
                DropdownMenuItem(
                  value: TransferMode.rtgs,
                  child: _ModeOption(label: 'RTGS', sub: 'Real-Time Gross Settlement · min ৳2,000'),
                ),
                DropdownMenuItem(
                  value: TransferMode.imps,
                  child: _ModeOption(label: 'IMPS', sub: 'Immediate Payment Service · 24/7'),
                ),
                DropdownMenuItem(
                  value: TransferMode.upi,
                  child: _ModeOption(label: 'UPI', sub: 'Unified Payments Interface'),
                ),
              ],
            ),
            if (transferMode == TransferMode.rtgs) ...[
              const SizedBox(height: 6),
              _InlineAlert(message: 'RTGS minimum: ৳2,000.00.'),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: cs.onSecondaryContainer, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Internal transfer · Instant & Free',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
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

  InputDecoration _inputDecoration(
    ColorScheme cs, {
    String? label,
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
      filled: true,
      fillColor: cs.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      counterText: '',
    );
  }
}


class _Step1 extends StatelessWidget {
  final GlobalKey<FormState>   formKey;
  final TextEditingController  amountCtrl;
  final TextEditingController  descriptionCtrl;
  final TextEditingController  remarksCtrl;
  final double?                maxAmount;
  final TransferType           transferType;
  final TransferMode           transferMode;
  final String                 priority;
  final double                 amount;
  final double                 baseFee;
  final double                 tax;
  final double                 totalDebit;
  final String Function(double) fmt;
  final ValueChanged<double>   onAmountChanged;
  final ValueChanged<String>   onPriorityChanged;

  const _Step1({
    required this.formKey,
    required this.amountCtrl,
    required this.descriptionCtrl,
    required this.remarksCtrl,
    required this.maxAmount,
    required this.transferType,
    required this.transferMode,
    required this.priority,
    required this.amount,
    required this.baseFee,
    required this.tax,
    required this.totalDebit,
    required this.fmt,
    required this.onAmountChanged,
    required this.onPriorityChanged,
  });

  bool get _isFree => transferType == TransferType.own;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final bool rtgsError =
        transferMode == TransferMode.rtgs && amount > 0 && amount < _kRtgsMinimum;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          _SectionHeader(icon: Icons.payments_outlined, label: 'Transfer Amount'),
          const SizedBox(height: 8),
          AmountInputWidget(
            controller:     amountCtrl,
            currencySymbol: '৳',
            maxAmount:      maxAmount,
            label:          'Amount',
            onChanged:      onAmountChanged,
          ),
          if (rtgsError) ...[
            const SizedBox(height: 6),
            _InlineAlert(
              message: 'RTGS requires a minimum of ${fmt(_kRtgsMinimum)}.',
              isError: true,
            ),
          ],

          const SizedBox(height: 22),

          if (!_isFree) ...[
            _SectionHeader(icon: Icons.flash_on_outlined, label: 'Transfer Priority'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'normal',
                  icon: Icon(Icons.speed_outlined),
                  label: Text('Normal (৳2 + tax)'),
                ),
                ButtonSegment(
                  value: 'high',
                  icon: Icon(Icons.electric_bolt_outlined),
                  label: Text('High (৳7 + tax)'),
                ),
              ],
              selected: {priority},
              onSelectionChanged: (s) => onPriorityChanged(s.first),
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                Row(children: [
                  Icon(Icons.receipt_outlined, size: 15, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Transfer Summary',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                _SummaryLine(label: 'Transfer Amount', value: amount > 0 ? fmt(amount) : '—', theme: theme),
                const SizedBox(height: 5),
                _SummaryLine(
                  label: 'Transfer Fee',
                  value: _isFree ? 'Free' : (baseFee > 0 ? fmt(baseFee) : '—'),
                  theme: theme,
                  highlight: _isFree,
                ),
                if (!_isFree && tax > 0) ...[
                  const SizedBox(height: 5),
                  _SummaryLine(label: 'Service Tax (18%)', value: tax > 0 ? fmt(tax) : '—', theme: theme),
                ],
                const Divider(height: 16),
                _SummaryLine(
                  label: 'Total Debit',
                  value: amount > 0 ? fmt(totalDebit) : '—',
                  theme: theme,
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          _SectionHeader(icon: Icons.notes_rounded, label: 'Details (Optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: descriptionCtrl,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'e.g. Monthly rent payment',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
              filled: true,
              fillColor: cs.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: remarksCtrl,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Remarks',
              hintText: 'Internal notes (optional)',
              prefixIcon: const Icon(Icons.comment_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
              filled: true,
              fillColor: cs.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}


class _ConfirmationDialog extends StatelessWidget {
  final AccountListItemDTO       sourceAccount;
  final String                   destinationDisplay;
  final double                   amount;
  final double                   baseFee;
  final double                   tax;
  final double                   totalDebit;
  final TransferMode             transferMode;
  final TransferType             transferType;
  final String                   priority;
  final String                   description;
  final String Function(double)  fmt;
  final VoidCallback             onConfirm;
  final VoidCallback             onCancel;

  const _ConfirmationDialog({
    required this.sourceAccount,
    required this.destinationDisplay,
    required this.amount,
    required this.baseFee,
    required this.tax,
    required this.totalDebit,
    required this.transferMode,
    required this.transferType,
    required this.priority,
    required this.description,
    required this.fmt,
    required this.onConfirm,
    required this.onCancel,
  });

  String _mask(String n) =>
      n.length > 4 ? '•••• ${n.substring(n.length - 4)}' : n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.send_rounded, color: cs.onPrimaryContainer, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirm Transfer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Please review carefully. This action cannot be undone.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onTertiaryContainer),
              ),
            ),
            const SizedBox(height: 16),
            _ConfirmRow(label: 'From', value: _mask(sourceAccount.accountNumber)),
            _ConfirmRow(label: 'To',   value: _mask(destinationDisplay)),
            _ConfirmRow(
              label: 'Mode',
              value: transferType == TransferType.own
                  ? 'Internal (${transferMode.displayName})'
                  : transferMode.displayName,
            ),
            if (priority == 'high')
              const _ConfirmRow(label: 'Priority', value: 'High Priority ⚡'),
            const Divider(height: 20),
            _ConfirmRow(label: 'Transfer Amount', value: fmt(amount)),
            _ConfirmRow(
              label: 'Transfer Fee',
              value: baseFee == 0 ? 'Free ✓' : fmt(baseFee),
            ),
            if (tax > 0) _ConfirmRow(label: 'Tax (18%)', value: fmt(tax)),
            const Divider(height: 12),
            _ConfirmRow(label: 'Total Debit', value: fmt(totalDebit), isTotal: true),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              _ConfirmRow(label: 'Description', value: description),
            ],
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Edit'),
        ),
        FilledButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Confirm'),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}


class _SuccessView extends StatelessWidget {
  final TransactionModel?      txn;
  final double                 baseFee;
  final double                 tax;
  final double                 totalDebit;
  final String Function(double) fmt;
  final VoidCallback           onNewTransfer;
  final VoidCallback           onHome;

  const _SuccessView({
    required this.txn,
    required this.baseFee,
    required this.tax,
    required this.totalDebit,
    required this.fmt,
    required this.onNewTransfer,
    required this.onHome,
  });

  String _mask(String n) =>
      n.length > 4 ? '•••• ${n.substring(n.length - 4)}' : n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2E7D32),
              size: 50,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Transfer Successful!',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Your funds have been transferred successfully.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),

          const SizedBox(height: 28),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Transaction Receipt',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  if (txn != null) ...[
                    _ReceiptLine(label: 'Transaction ID', value: txn!.transactionId, mono: true),
                    _ReceiptLine(label: 'Reference',     value: txn!.referenceNumber, mono: true),
                    if (txn!.fromAccountNumber != null)
                      _ReceiptLine(label: 'From', value: _mask(txn!.fromAccountNumber!)),
                    if (txn!.toAccountNumber != null)
                      _ReceiptLine(label: 'To',   value: _mask(txn!.toAccountNumber!)),
                    _ReceiptLine(label: 'Mode', value: txn!.transferMode.displayName),
                    const Divider(height: 20),
                    _ReceiptLine(label: 'Amount', value: fmt(txn!.amount)),
                    _ReceiptLine(
                      label: 'Fee',
                      value: baseFee == 0 ? 'Free' : fmt(baseFee),
                    ),
                    if (tax > 0)
                      _ReceiptLine(label: 'Tax (18%)', value: fmt(tax)),
                    _ReceiptLine(label: 'Total Debited', value: fmt(totalDebit), isTotal: true),
                    const Divider(height: 20),
                    _ReceiptLine(
                      label: 'Status',
                      value: txn!.status.displayName.toUpperCase(),
                      valueColor: const Color(0xFF2E7D32),
                    ),
                    if (txn!.timestamp != null)
                      _ReceiptLine(
                        label: 'Date & Time',
                        value: DateFormat('dd MMM yyyy, hh:mm a').format(txn!.timestamp!),
                      ),
                    if (txn!.receiptNumber != null)
                      _ReceiptLine(label: 'Receipt #', value: txn!.receiptNumber!, mono: true),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Transfer completed successfully.'),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'New Transfer',
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              onPressed: onNewTransfer,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Back to Home',
              variant: ButtonVariant.outlined,
              onPressed: onHome,
            ),
          ),
        ],
      ),
    );
  }
}


class _BottomBar extends StatelessWidget {
  final int          currentStep;
  final bool         isLoading;
  final String       nextLabel;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _BottomBar({
    required this.currentStep,
    required this.isLoading,
    required this.nextLabel,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: isLoading ? null : onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(currentStep == 0 ? 'Cancel' : 'Back'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: isLoading ? null : onNext,
              icon: isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(nextLabel),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    return Row(children: [
      Icon(icon, size: 15, color: cs.primary),
      const SizedBox(width: 6),
      Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ]);
  }
}

class _InlineAlert extends StatelessWidget {
  final String message;
  final bool   isError;
  const _InlineAlert({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = isError ? cs.error : Colors.orange[800]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final String sub;
  const _ModeOption({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        Text(sub,   style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String    label;
  final String    value;
  final ThemeData theme;
  final bool      isTotal;
  final bool      highlight;
  const _SummaryLine({
    required this.label,
    required this.value,
    required this.theme,
    this.isTotal   = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize:   isTotal ? 14 : null,
            color: highlight ? const Color(0xFF2E7D32) : cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String  label;
  final String  value;
  final bool    isTotal;
  final Color?  valueColor;
  const _ConfirmRow({
    required this.label,
    required this.value,
    this.isTotal    = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                fontSize:   isTotal ? 14 : null,
                color: valueColor ?? cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final String  label;
  final String  value;
  final bool    isTotal;
  final bool    mono;
  final Color?  valueColor;
  const _ReceiptLine({
    required this.label,
    required this.value,
    this.isTotal    = false,
    this.mono       = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                fontSize:   isTotal ? 14 : null,
                fontFamily: mono ? 'monospace' : null,
                color: valueColor ?? cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}