import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/accounts/data/models/account_list_item_dto.dart';
import 'package:vantedge/features/accounts/presentation/providers/account_provider.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/features/auth/presentation/widgets/signup_step_indicator.dart';
import 'package:vantedge/features/transactions/data/models/transaction_enums.dart';
import 'package:vantedge/features/transactions/data/models/transaction_model.dart';
import 'package:vantedge/features/transactions/data/models/withdraw_request.dart';
import 'package:vantedge/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:vantedge/features/transactions/presentation/widgets/amount_input.dart';
import 'package:vantedge/features/transactions/presentation/widgets/account_selector.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';
import 'package:vantedge/shared/widgets/custom_button.dart';



class WithdrawScreen extends StatefulWidget {
  final String? preselectedAccountNumber;

  const WithdrawScreen({super.key, this.preselectedAccountNumber});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _kTotalSteps = 2;

  final GlobalKey<FormState> _step0Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _step1Key = GlobalKey<FormState>();

  AccountListItemDTO? _sourceAccount;

  _WithdrawMode _withdrawalMode = _WithdrawMode.cash;

  final TextEditingController _amountCtrl      = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _remarksCtrl     = TextEditingController();
  double _amount = 0.0;

  bool              _isSuccess    = false;
  TransactionModel? _completedTxn;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final ap = context.read<AccountProvider>();
    // if (ap.accounts.isEmpty) ap.fetchMyAccounts();



    if (ap.accounts.isEmpty) {
      final customerId = context.read<AuthProvider>().user?.customerId;
        if (customerId != null) {
          await ap.fetchMyAccounts(customerId);
        }
    }



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
          'Account is ${_sourceAccount!.status.displayName}. '
          'Only ACTIVE accounts can process withdrawals.',
        );
        return;
      }
    }

    if (_currentStep == 1) {
      if (_amount <= 0) {
        _showWarning('Please enter a valid amount greater than zero.');
        return;
      }
      final available = _sourceAccount?.availableBalance ?? 0;
      if (_amount > available) {
        _showError(
          'Insufficient balance. Available: ${_fmt(available)}, '
          'Requested: ${_fmt(_amount)}.',
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
      builder: (ctx) => _WithdrawConfirmDialog(
        sourceAccount:   _sourceAccount!,
        amount:          _amount,
        withdrawalMode:  _withdrawalMode,
        description:     _descriptionCtrl.text.trim(),
        fmt:             _fmt,
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

    final request = WithdrawRequest(
      accountNumber:  _sourceAccount!.accountNumber,
      amount:         _amount,
      withdrawalMode: _withdrawalMode.toTransferMode,
      description:    _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      remarks:        _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
    );

    final success = await txnProvider.withdraw(request);
    if (!mounted) return;

    if (success) {
      setState(() {
        _isSuccess    = true;
        _completedTxn = txnProvider.lastTransaction;
      });
    } else {
      final msg = txnProvider.errorMessage ?? 'Withdrawal failed. Please try again.';
      _showError(msg);
      txnProvider.clearError();
    }
  }


  void _startOver() {
    setState(() {
      _isSuccess       = false;
      _completedTxn    = null;
      _currentStep     = 0;
      _sourceAccount   = null;
      _withdrawalMode  = _WithdrawMode.cash;
      _amountCtrl.clear();
      _amount = 0.0;
      _descriptionCtrl.clear();
      _remarksCtrl.clear();
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
        title: 'Withdraw Money',
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
              ? _WithdrawSuccessView(
                  txn:            _completedTxn,
                  amount:         _amount,
                  withdrawalMode: _withdrawalMode,
                  fmt:            _fmt,
                  onNewWithdrawal: _startOver,
                  onHome: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.customerHome, (_) => false,
                  ),
                )
              : Column(
                  children: [
                    SignupStepIndicator(
                      currentStep: _currentStep,
                      totalSteps:  _kTotalSteps,
                      stepLabels:  const ['Account & Mode', 'Amount & Details'],
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _WithdrawStep0(
                            formKey:           _step0Key,
                            sourceAccount:     _sourceAccount,
                            withdrawalMode:    _withdrawalMode,
                            onAccountSelected: (a) => setState(() => _sourceAccount = a),
                            onModeChanged:     (m) => setState(() => _withdrawalMode = m),
                          ),
                          _WithdrawStep1(
                            formKey:           _step1Key,
                            amountCtrl:        _amountCtrl,
                            descriptionCtrl:   _descriptionCtrl,
                            remarksCtrl:       _remarksCtrl,
                            availableBalance:  _sourceAccount?.availableBalance,
                            amount:            _amount,
                            fmt:               _fmt,
                            onAmountChanged:   (v) => setState(() => _amount = v),
                          ),
                        ],
                      ),
                    ),
                    _WdwBottomBar(
                      currentStep: _currentStep,
                      isLoading:   txnProvider.isLoading,
                      nextLabel:   _currentStep == _kTotalSteps - 1
                          ? 'Review Withdrawal'
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
                      Text('Processing withdrawal…'),
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


enum _WithdrawMode {
  cash,
  cheque,
  card,
  atm;

  String get displayName {
    switch (this) {
      case _WithdrawMode.cash:   return 'Cash';
      case _WithdrawMode.cheque: return 'Cheque';
      case _WithdrawMode.card:   return 'Card';
      case _WithdrawMode.atm:    return 'ATM';
    }
  }

  TransferMode get toTransferMode {
    switch (this) {
      case _WithdrawMode.cash:   return TransferMode.cash;
      case _WithdrawMode.cheque: return TransferMode.cheque;
      case _WithdrawMode.card:   return TransferMode.card;
      case _WithdrawMode.atm:    return TransferMode.cash;
    }
  }

  String get apiValue {
    switch (this) {
      case _WithdrawMode.cash:   return 'CASH';
      case _WithdrawMode.cheque: return 'CHEQUE';
      case _WithdrawMode.card:   return 'CARD';
      case _WithdrawMode.atm:    return 'ATM';
    }
  }

  IconData get icon {
    switch (this) {
      case _WithdrawMode.cash:   return Icons.money_rounded;
      case _WithdrawMode.cheque: return Icons.receipt_outlined;
      case _WithdrawMode.card:   return Icons.credit_card_outlined;
      case _WithdrawMode.atm:    return Icons.local_atm_rounded;
    }
  }

  String get subtitle {
    switch (this) {
      case _WithdrawMode.cash:
        return 'Over-the-counter cash withdrawal';
      case _WithdrawMode.cheque:
        return 'Withdrawal via issued cheque';
      case _WithdrawMode.card:
        return 'Withdrawal via debit card';
      case _WithdrawMode.atm:
        return 'ATM cash withdrawal';
    }
  }
}


class _WithdrawStep0 extends StatelessWidget {
  final GlobalKey<FormState>             formKey;
  final AccountListItemDTO?              sourceAccount;
  final _WithdrawMode                    withdrawalMode;
  final ValueChanged<AccountListItemDTO> onAccountSelected;
  final ValueChanged<_WithdrawMode>      onModeChanged;

  const _WithdrawStep0({
    required this.formKey,
    required this.sourceAccount,
    required this.withdrawalMode,
    required this.onAccountSelected,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final ap    = context.watch<AccountProvider>();

    final eligibleAccounts = ap.accounts
        .where((a) => a.status.canTransact)
        .toList();

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_upward_rounded,
                    color: cs.onErrorContainer, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Withdrawals are immediately debited from your account.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:      cs.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          _WdwSectionHeader(icon: Icons.account_balance_wallet_outlined, label: 'From Account'),
          const SizedBox(height: 8),
          AccountSelectorWidget(
            label:           'Source Account',
            accounts:        ap.accounts,
            selectedAccount: sourceAccount,
            onSelected:      onAccountSelected,
            validator: (v) => v == null ? 'Please select a source account.' : null,
          ),

          if (sourceAccount != null && !sourceAccount!.status.canTransact) ...[
            const SizedBox(height: 8),
            _WdwInlineAlert(
              message: 'This account is ${sourceAccount!.status.displayName} '
                  'and cannot process withdrawals.',
              isError: true,
            ),
          ],

          if (sourceAccount != null && sourceAccount!.status.canTransact) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:        cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border:       Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_outlined, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Available Balance: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '৳${NumberFormat('#,##0.00').format(sourceAccount!.availableBalance)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:      cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),

          _WdwSectionHeader(icon: Icons.account_tree_outlined, label: 'Withdrawal Mode'),
          const SizedBox(height: 8),
          DropdownButtonFormField<_WithdrawMode>(
            initialValue:      withdrawalMode,
            isExpanded: true,
            decoration: _fieldDecoration(cs, label: 'Mode'),
            onChanged: (v) { if (v != null) onModeChanged(v); },
            items: _WithdrawMode.values
                .map((mode) => DropdownMenuItem(
                      value: mode,
                      child: _WdwModeOption(mode: mode),
                    ))
                .toList(),
          ),

          if (withdrawalMode == _WithdrawMode.atm) ...[
            const SizedBox(height: 8),
            _WdwInlineAlert(
              message: 'ATM withdrawals are subject to your daily limit. '
                  'Ensure your card is linked to this account.',
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(ColorScheme cs, {String? label}) {
    return InputDecoration(
      labelText:   label,
      border:      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: cs.error, width: 2),
      ),
      filled:         true,
      fillColor:      cs.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}


class _WithdrawStep1 extends StatelessWidget {
  final GlobalKey<FormState>    formKey;
  final TextEditingController   amountCtrl;
  final TextEditingController   descriptionCtrl;
  final TextEditingController   remarksCtrl;
  final double?                 availableBalance;
  final double                  amount;
  final String Function(double) fmt;
  final ValueChanged<double>    onAmountChanged;

  const _WithdrawStep1({
    required this.formKey,
    required this.amountCtrl,
    required this.descriptionCtrl,
    required this.remarksCtrl,
    required this.availableBalance,
    required this.amount,
    required this.fmt,
    required this.onAmountChanged,
  });

  bool get _insufficientBalance =>
      availableBalance != null && amount > 0 && amount > availableBalance!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          _WdwSectionHeader(icon: Icons.payments_outlined, label: 'Withdrawal Amount'),
          const SizedBox(height: 8),

          AmountInputWidget(
            controller:     amountCtrl,
            currencySymbol: '৳',
            maxAmount:      availableBalance,
            label:          'Amount',
            onChanged:      onAmountChanged,
          ),

          if (_insufficientBalance) ...[
            const SizedBox(height: 6),
            _WdwInlineAlert(
              message: 'Insufficient balance. '
                  'Available: ${fmt(availableBalance!)}, '
                  'Requested: ${fmt(amount)}.',
              isError: true,
            ),
          ],

          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                Row(children: [
                  Icon(Icons.receipt_outlined, size: 15, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Withdrawal Summary',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color:      cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                _WdwSummaryLine(
                  label: 'Withdrawal Amount',
                  value: amount > 0 ? fmt(amount) : '—',
                  theme: theme,
                ),
                const SizedBox(height: 5),
                _WdwSummaryLine(
                  label: 'Fee',
                  value: 'Free ✓',
                  theme: theme,
                  highlight: true,
                ),
                if (availableBalance != null) ...[
                  const SizedBox(height: 5),
                  _WdwSummaryLine(
                    label: 'Remaining Balance',
                    value: amount > 0 && !_insufficientBalance
                        ? fmt(availableBalance! - amount)
                        : '—',
                    theme: theme,
                  ),
                ],
                const Divider(height: 16),
                _WdwSummaryLine(
                  label:   'Total Debit',
                  value:   amount > 0 ? fmt(amount) : '—',
                  theme:   theme,
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          _WdwSectionHeader(icon: Icons.notes_rounded, label: 'Details (Optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller:         descriptionCtrl,
            maxLength:          200,
            textCapitalization: TextCapitalization.sentences,
            textInputAction:    TextInputAction.next,
            decoration: _fieldDecoration(
              cs,
              label:      'Description',
              hint:       'e.g. Utility bill payment',
              prefixIcon: const Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller:         remarksCtrl,
            maxLength:          200,
            textCapitalization: TextCapitalization.sentences,
            textInputAction:    TextInputAction.done,
            decoration: _fieldDecoration(
              cs,
              label:      'Remarks',
              hint:       'Internal notes (optional)',
              prefixIcon: const Icon(Icons.comment_outlined),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(
    ColorScheme cs, {
    String? label,
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText:   label,
      hintText:    hint,
      prefixIcon:  prefixIcon,
      border:      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: cs.error, width: 2),
      ),
      filled:         true,
      fillColor:      cs.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      counterText:    '',
    );
  }
}


class _WithdrawConfirmDialog extends StatelessWidget {
  final AccountListItemDTO      sourceAccount;
  final double                  amount;
  final _WithdrawMode           withdrawalMode;
  final String                  description;
  final String Function(double) fmt;
  final VoidCallback            onConfirm;
  final VoidCallback            onCancel;

  const _WithdrawConfirmDialog({
    required this.sourceAccount,
    required this.amount,
    required this.withdrawalMode,
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

    final double remaining =
        sourceAccount.availableBalance - amount;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: cs.onErrorContainer,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirm Withdrawal',
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
                color:        cs.errorContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Funds will be immediately debited. This cannot be undone.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onErrorContainer),
              ),
            ),
            const SizedBox(height: 16),
            _WdwConfirmRow(label: 'From Account',     value: _mask(sourceAccount.accountNumber)),
            _WdwConfirmRow(label: 'Account Type',     value: sourceAccount.accountType.displayName),
            _WdwConfirmRow(label: 'Withdrawal Mode',  value: withdrawalMode.displayName),
            const Divider(height: 20),
            _WdwConfirmRow(label: 'Withdrawal Amount', value: fmt(amount)),
            _WdwConfirmRow(label: 'Fee',               value: 'Free ✓'),
            const Divider(height: 12),
            _WdwConfirmRow(
              label:      'Total Debit',
              value:      fmt(amount),
              isTotal:    true,
              valueColor: cs.error,
            ),
            const SizedBox(height: 8),
            _WdwConfirmRow(
              label: 'Balance After',
              value: fmt(remaining),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              _WdwConfirmRow(label: 'Description', value: description),
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
          icon:  const Icon(Icons.check_rounded, size: 18),
          label: const Text('Confirm Withdrawal'),
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}


class _WithdrawSuccessView extends StatelessWidget {
  final TransactionModel?       txn;
  final double                  amount;
  final _WithdrawMode           withdrawalMode;
  final String Function(double) fmt;
  final VoidCallback            onNewWithdrawal;
  final VoidCallback            onHome;

  const _WithdrawSuccessView({
    required this.txn,
    required this.amount,
    required this.withdrawalMode,
    required this.fmt,
    required this.onNewWithdrawal,
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
            'Withdrawal Successful!',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Your withdrawal has been processed successfully.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
                        'Withdrawal Receipt',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  if (txn != null) ...[
                    _WdwReceiptLine(label: 'Transaction ID', value: txn!.transactionId, mono: true),
                    _WdwReceiptLine(label: 'Reference',     value: txn!.referenceNumber, mono: true),
                    if (txn!.fromAccountNumber != null)
                      _WdwReceiptLine(
                        label: 'Withdrawn From',
                        value: _mask(txn!.fromAccountNumber!),
                      ),
                    _WdwReceiptLine(label: 'Mode', value: withdrawalMode.displayName),
                    const Divider(height: 20),
                    _WdwReceiptLine(label: 'Amount',  value: fmt(txn!.amount)),
                    _WdwReceiptLine(label: 'Fee',     value: 'Free'),
                    _WdwReceiptLine(
                      label:      'Total Debited',
                      value:      fmt(txn!.amount),
                      isTotal:    true,
                      valueColor: cs.error,
                    ),
                    const Divider(height: 20),
                    _WdwReceiptLine(
                      label:      'Status',
                      value:      txn!.status.displayName.toUpperCase(),
                      valueColor: const Color(0xFF2E7D32),
                    ),
                    if (txn!.timestamp != null)
                      _WdwReceiptLine(
                        label: 'Date & Time',
                        value: DateFormat('dd MMM yyyy, hh:mm a').format(txn!.timestamp!),
                      ),
                    if (txn!.receiptNumber != null)
                      _WdwReceiptLine(label: 'Receipt #', value: txn!.receiptNumber!, mono: true),
                    if (txn!.balanceAfter != null)
                      _WdwReceiptLine(label: 'Balance After', value: fmt(txn!.balanceAfter!)),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Withdrawal completed successfully.'),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'New Withdrawal',
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              onPressed: onNewWithdrawal,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text:    'Back to Home',
              variant: ButtonVariant.outlined,
              onPressed: onHome,
            ),
          ),
        ],
      ),
    );
  }
}


class _WdwBottomBar extends StatelessWidget {
  final int          currentStep;
  final bool         isLoading;
  final String       nextLabel;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _WdwBottomBar({
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
        color:  cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: isLoading ? null : onBack,
            icon:  const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(currentStep == 0 ? 'Cancel' : 'Back'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WdwSectionHeader extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _WdwSectionHeader({required this.icon, required this.label});

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
          color:         cs.primary,
          fontWeight:    FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ]);
  }
}

class _WdwInlineAlert extends StatelessWidget {
  final String message;
  final bool   isError;
  const _WdwInlineAlert({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = isError ? cs.error : Colors.orange[800]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: color.withOpacity(0.3)),
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

class _WdwModeOption extends StatelessWidget {
  final _WithdrawMode mode;
  const _WdwModeOption({required this.mode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    return Row(
      children: [
        Icon(mode.icon, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:       MainAxisSize.min,
          children: [
            Text(mode.displayName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(mode.subtitle,    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

class _WdwSummaryLine extends StatelessWidget {
  final String    label;
  final String    value;
  final ThemeData theme;
  final bool      isTotal;
  final bool      highlight;
  const _WdwSummaryLine({
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
            color:      cs.onSurfaceVariant,
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

class _WdwConfirmRow extends StatelessWidget {
  final String  label;
  final String  value;
  final bool    isTotal;
  final Color?  valueColor;
  const _WdwConfirmRow({
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
            width: 120,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                fontSize:   isTotal ? 14 : null,
                color:      valueColor ?? cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WdwReceiptLine extends StatelessWidget {
  final String  label;
  final String  value;
  final bool    isTotal;
  final bool    mono;
  final Color?  valueColor;
  const _WdwReceiptLine({
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
            width: 120,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                fontSize:   isTotal ? 14 : null,
                fontFamily: mono ? 'monospace' : null,
                color:      valueColor ?? cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}