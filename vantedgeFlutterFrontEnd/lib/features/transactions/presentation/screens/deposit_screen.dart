import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/accounts/data/models/account_list_item_dto.dart';
import 'package:vantedge/features/accounts/presentation/providers/account_provider.dart';
import 'package:vantedge/features/auth/presentation/widgets/signup_step_indicator.dart';
import 'package:vantedge/features/transactions/data/models/deposit_request.dart';
import 'package:vantedge/features/transactions/data/models/transaction_enums.dart';
import 'package:vantedge/features/transactions/data/models/transaction_model.dart';
import 'package:vantedge/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:vantedge/features/transactions/presentation/widgets/amount_input.dart';
import 'package:vantedge/features/transactions/presentation/widgets/account_selector.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';
import 'package:vantedge/shared/widgets/custom_button.dart';



class DepositScreen extends StatefulWidget {
  final String? preselectedAccountNumber;

  const DepositScreen({super.key, this.preselectedAccountNumber});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _kTotalSteps = 2;

  final GlobalKey<FormState> _step0Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _step1Key = GlobalKey<FormState>();

  AccountListItemDTO? _targetAccount;
  TransferMode        _depositMode = TransferMode.cash;

  final TextEditingController _amountCtrl       = TextEditingController();
  final TextEditingController _descriptionCtrl  = TextEditingController();
  final TextEditingController _remarksCtrl      = TextEditingController();
  final TextEditingController _chequeNumberCtrl = TextEditingController();
  final TextEditingController _bankNameCtrl     = TextEditingController();
  double _amount = 0.0;

  bool              _isSuccess    = false;
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
      if (match.isNotEmpty) setState(() => _targetAccount = match.first);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _remarksCtrl.dispose();
    _chequeNumberCtrl.dispose();
    _bankNameCtrl.dispose();
    super.dispose();
  }


  void _advance() {
    final formKey = _currentStep == 0 ? _step0Key : _step1Key;
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (_currentStep == 0) {
      if (_targetAccount == null) {
        _showWarning('Please select a target account.');
        return;
      }
    }

    if (_currentStep == 1) {
      if (_amount <= 0) {
        _showWarning('Please enter a valid amount greater than zero.');
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
      builder: (ctx) => _DepositConfirmDialog(
        targetAccount:  _targetAccount!,
        amount:         _amount,
        depositMode:    _depositMode,
        description:    _descriptionCtrl.text.trim(),
        chequeNumber:   _depositMode == TransferMode.cheque
            ? _chequeNumberCtrl.text.trim()
            : null,
        bankName:       _depositMode == TransferMode.cheque
            ? _bankNameCtrl.text.trim()
            : null,
        fmt:            _fmt,
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

    final request = DepositRequest(
      accountNumber: _targetAccount!.accountNumber,
      amount:        _amount,
      depositMode:   _depositMode,
      description:   _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      remarks:       _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
      chequeNumber:  _depositMode == TransferMode.cheque && _chequeNumberCtrl.text.trim().isNotEmpty
          ? _chequeNumberCtrl.text.trim() : null,
      bankName:      _depositMode == TransferMode.cheque && _bankNameCtrl.text.trim().isNotEmpty
          ? _bankNameCtrl.text.trim() : null,
    );

    final success = await txnProvider.deposit(request);
    if (!mounted) return;

    if (success) {
      setState(() {
        _isSuccess    = true;
        _completedTxn = txnProvider.lastTransaction;
      });
    } else {
      final msg = txnProvider.errorMessage ?? 'Deposit failed. Please try again.';
      _showError(msg);
      txnProvider.clearError();
    }
  }


  void _startOver() {
    setState(() {
      _isSuccess     = false;
      _completedTxn  = null;
      _currentStep   = 0;
      _targetAccount = null;
      _depositMode   = TransferMode.cash;
      _amountCtrl.clear();
      _amount = 0.0;
      _descriptionCtrl.clear();
      _remarksCtrl.clear();
      _chequeNumberCtrl.clear();
      _bankNameCtrl.clear();
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
        title: 'Deposit Money',
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
              ? _DepositSuccessView(
                  txn:           _completedTxn,
                  amount:        _amount,
                  depositMode:   _depositMode,
                  fmt:           _fmt,
                  onNewDeposit:  _startOver,
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
                          _DepositStep0(
                            formKey:          _step0Key,
                            targetAccount:    _targetAccount,
                            depositMode:      _depositMode,
                            onAccountSelected: (a) => setState(() => _targetAccount = a),
                            onModeChanged:    (m) => setState(() => _depositMode = m),
                          ),
                          _DepositStep1(
                            formKey:           _step1Key,
                            amountCtrl:        _amountCtrl,
                            descriptionCtrl:   _descriptionCtrl,
                            remarksCtrl:       _remarksCtrl,
                            chequeNumberCtrl:  _chequeNumberCtrl,
                            bankNameCtrl:      _bankNameCtrl,
                            depositMode:       _depositMode,
                            amount:            _amount,
                            fmt:               _fmt,
                            onAmountChanged:   (v) => setState(() => _amount = v),
                          ),
                        ],
                      ),
                    ),
                    _TxnBottomBar(
                      currentStep: _currentStep,
                      isLoading:   txnProvider.isLoading,
                      nextLabel:   _currentStep == _kTotalSteps - 1
                          ? 'Review Deposit'
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
                      Text('Processing deposit…'),
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


class _DepositStep0 extends StatelessWidget {
  final GlobalKey<FormState>         formKey;
  final AccountListItemDTO?          targetAccount;
  final TransferMode                 depositMode;
  final ValueChanged<AccountListItemDTO> onAccountSelected;
  final ValueChanged<TransferMode>   onModeChanged;

  const _DepositStep0({
    required this.formKey,
    required this.targetAccount,
    required this.depositMode,
    required this.onAccountSelected,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final cs          = theme.colorScheme;
    final ap          = context.watch<AccountProvider>();
    final allAccounts = ap.accounts;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_downward_rounded,
                    color: cs.onPrimaryContainer, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Deposits are fee-free and credited instantly.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          _TxnSectionHeader(icon: Icons.account_balance_wallet_outlined, label: 'Deposit To'),
          const SizedBox(height: 8),
          AccountSelectorWidget(
            label:          'Target Account',
            accounts:       allAccounts,
            selectedAccount: targetAccount,
            onSelected:     onAccountSelected,
            validator: (v) => v == null ? 'Please select a target account.' : null,
          ),

          if (targetAccount != null && !targetAccount!.status.canTransact) ...[
            const SizedBox(height: 8),
            _TxnInlineAlert(
              message: 'This account is ${targetAccount!.status.displayName} '
                  'and cannot receive deposits.',
              isError: true,
            ),
          ],

          const SizedBox(height: 22),

          _TxnSectionHeader(icon: Icons.account_tree_outlined, label: 'Deposit Mode'),
          const SizedBox(height: 8),
          DropdownButtonFormField<TransferMode>(
            initialValue: depositMode,
            isExpanded: true,
            decoration: _fieldDecoration(cs, label: 'Mode'),
            onChanged: (v) { if (v != null) onModeChanged(v); },
            items: [
              DropdownMenuItem(
                value: TransferMode.cash,
                child: _TxnModeOption(
                  label: 'Cash',
                  sub:   'Over-the-counter cash deposit',
                  icon:  Icons.money_rounded,
                ),
              ),
              DropdownMenuItem(
                value: TransferMode.cheque,
                child: _TxnModeOption(
                  label: 'Cheque',
                  sub:   'Deposit via cheque (additional details required)',
                  icon:  Icons.receipt_outlined,
                ),
              ),
              DropdownMenuItem(
                value: TransferMode.card,
                child: _TxnModeOption(
                  label: 'Card',
                  sub:   'Deposit via debit / credit card',
                  icon:  Icons.credit_card_outlined,
                ),
              ),
            ],
          ),

          if (depositMode == TransferMode.cheque) ...[
            const SizedBox(height: 8),
            _TxnInlineAlert(
              message: 'Cheque deposits may take 1–3 business days to clear.',
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(ColorScheme cs, {String? label, String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      labelText:    label,
      hintText:     hint,
      prefixIcon:   prefixIcon,
      border:       OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      filled:          true,
      fillColor:       cs.surface,
      contentPadding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      counterText:     '',
    );
  }
}


class _DepositStep1 extends StatelessWidget {
  final GlobalKey<FormState>    formKey;
  final TextEditingController   amountCtrl;
  final TextEditingController   descriptionCtrl;
  final TextEditingController   remarksCtrl;
  final TextEditingController   chequeNumberCtrl;
  final TextEditingController   bankNameCtrl;
  final TransferMode            depositMode;
  final double                  amount;
  final String Function(double) fmt;
  final ValueChanged<double>    onAmountChanged;

  const _DepositStep1({
    required this.formKey,
    required this.amountCtrl,
    required this.descriptionCtrl,
    required this.remarksCtrl,
    required this.chequeNumberCtrl,
    required this.bankNameCtrl,
    required this.depositMode,
    required this.amount,
    required this.fmt,
    required this.onAmountChanged,
  });

  bool get _isCheque => depositMode == TransferMode.cheque;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          _TxnSectionHeader(icon: Icons.payments_outlined, label: 'Deposit Amount'),
          const SizedBox(height: 8),
          AmountInputWidget(
            controller:     amountCtrl,
            currencySymbol: '৳',
            label:          'Amount',
            onChanged:      onAmountChanged,
          ),

          const SizedBox(height: 22),

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
                    'Deposit Summary',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                _TxnSummaryLine(
                  label: 'Deposit Amount',
                  value: amount > 0 ? fmt(amount) : '—',
                  theme: theme,
                ),
                const SizedBox(height: 5),
                _TxnSummaryLine(
                  label: 'Fee',
                  value: 'Free ✓',
                  theme: theme,
                  highlight: true,
                ),
                const Divider(height: 16),
                _TxnSummaryLine(
                  label: 'Credit to Account',
                  value: amount > 0 ? fmt(amount) : '—',
                  theme: theme,
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          if (_isCheque) ...[
            _TxnSectionHeader(
              icon: Icons.receipt_long_outlined,
              label: 'Cheque Details',
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller:          chequeNumberCtrl,
              keyboardType:        TextInputType.text,
              textInputAction:     TextInputAction.next,
              textCapitalization:  TextCapitalization.characters,
              decoration: _fieldDecoration(
                cs,
                label:      'Cheque Number',
                hint:       'e.g. 123456',
                prefixIcon: const Icon(Icons.tag_rounded),
              ),
              validator: _isCheque
                  ? (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Cheque number is required for cheque deposits.';
                      }
                      return null;
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller:         bankNameCtrl,
              keyboardType:       TextInputType.text,
              textInputAction:    TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDecoration(
                cs,
                label:      'Issuing Bank',
                hint:       'e.g. Sonali Bank',
                prefixIcon: const Icon(Icons.account_balance_outlined),
              ),
              validator: _isCheque
                  ? (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Bank name is required for cheque deposits.';
                      }
                      return null;
                    }
                  : null,
            ),
            const SizedBox(height: 22),
          ],

          _TxnSectionHeader(icon: Icons.notes_rounded, label: 'Details (Optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller:          descriptionCtrl,
            maxLength:           200,
            textCapitalization:  TextCapitalization.sentences,
            textInputAction:     TextInputAction.next,
            decoration: _fieldDecoration(
              cs,
              label:      'Description',
              hint:       'e.g. Monthly savings deposit',
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


class _DepositConfirmDialog extends StatelessWidget {
  final AccountListItemDTO      targetAccount;
  final double                  amount;
  final TransferMode            depositMode;
  final String                  description;
  final String?                 chequeNumber;
  final String?                 bankName;
  final String Function(double) fmt;
  final VoidCallback            onConfirm;
  final VoidCallback            onCancel;

  const _DepositConfirmDialog({
    required this.targetAccount,
    required this.amount,
    required this.depositMode,
    required this.description,
    required this.fmt,
    required this.onConfirm,
    required this.onCancel,
    this.chequeNumber,
    this.bankName,
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
              color:  const Color(0xFFE8F5E9),
              shape:  BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_downward_rounded,
              color: Color(0xFF2E7D32),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirm Deposit',
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
            _TxnConfirmRow(label: 'To Account',    value: _mask(targetAccount.accountNumber)),
            _TxnConfirmRow(label: 'Account Type',  value: targetAccount.accountType.displayName),
            _TxnConfirmRow(label: 'Deposit Mode',  value: depositMode.displayName),
            if (chequeNumber != null && chequeNumber!.isNotEmpty)
              _TxnConfirmRow(label: 'Cheque No.',  value: chequeNumber!),
            if (bankName != null && bankName!.isNotEmpty)
              _TxnConfirmRow(label: 'Issuing Bank', value: bankName!),
            const Divider(height: 20),
            _TxnConfirmRow(label: 'Deposit Amount', value: fmt(amount)),
            _TxnConfirmRow(label: 'Fee',            value: 'Free ✓'),
            const Divider(height: 12),
            _TxnConfirmRow(
              label:   'Credit Amount',
              value:   fmt(amount),
              isTotal: true,
              valueColor: const Color(0xFF2E7D32),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              _TxnConfirmRow(label: 'Description', value: description),
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
          label: const Text('Confirm Deposit'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}


class _DepositSuccessView extends StatelessWidget {
  final TransactionModel?       txn;
  final double                  amount;
  final TransferMode            depositMode;
  final String Function(double) fmt;
  final VoidCallback            onNewDeposit;
  final VoidCallback            onHome;

  const _DepositSuccessView({
    required this.txn,
    required this.amount,
    required this.depositMode,
    required this.fmt,
    required this.onNewDeposit,
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
            'Deposit Successful!',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Your deposit has been processed successfully.',
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
                        'Deposit Receipt',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  if (txn != null) ...[
                    _TxnReceiptLine(label: 'Transaction ID', value: txn!.transactionId, mono: true),
                    _TxnReceiptLine(label: 'Reference',     value: txn!.referenceNumber, mono: true),
                    if (txn!.toAccountNumber != null)
                      _TxnReceiptLine(
                        label: 'Deposited To',
                        value: _mask(txn!.toAccountNumber!),
                      ),
                    _TxnReceiptLine(label: 'Mode', value: depositMode.displayName),
                    const Divider(height: 20),
                    _TxnReceiptLine(label: 'Deposit Amount', value: fmt(txn!.amount)),
                    _TxnReceiptLine(label: 'Fee',            value: 'Free'),
                    _TxnReceiptLine(
                      label:      'Credited',
                      value:      fmt(txn!.amount),
                      isTotal:    true,
                      valueColor: const Color(0xFF2E7D32),
                    ),
                    const Divider(height: 20),
                    _TxnReceiptLine(
                      label:      'Status',
                      value:      txn!.status.displayName.toUpperCase(),
                      valueColor: const Color(0xFF2E7D32),
                    ),
                    if (txn!.timestamp != null)
                      _TxnReceiptLine(
                        label: 'Date & Time',
                        value: DateFormat('dd MMM yyyy, hh:mm a').format(txn!.timestamp!),
                      ),
                    if (txn!.receiptNumber != null)
                      _TxnReceiptLine(label: 'Receipt #', value: txn!.receiptNumber!, mono: true),
                    if (txn!.balanceAfter != null)
                      _TxnReceiptLine(label: 'New Balance', value: fmt(txn!.balanceAfter!)),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Deposit completed successfully.'),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'New Deposit',
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              onPressed: onNewDeposit,
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


class _TxnBottomBar extends StatelessWidget {
  final int          currentStep;
  final bool         isLoading;
  final String       nextLabel;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _TxnBottomBar({
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
                shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxnSectionHeader extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _TxnSectionHeader({required this.icon, required this.label});

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
          color:        cs.primary,
          fontWeight:   FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ]);
  }
}

class _TxnInlineAlert extends StatelessWidget {
  final String message;
  final bool   isError;
  const _TxnInlineAlert({required this.message, this.isError = false});

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

class _TxnModeOption extends StatelessWidget {
  final String  label;
  final String  sub;
  final IconData icon;
  const _TxnModeOption({
    required this.label,
    required this.sub,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:       MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(sub,   style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

class _TxnSummaryLine extends StatelessWidget {
  final String    label;
  final String    value;
  final ThemeData theme;
  final bool      isTotal;
  final bool      highlight;
  const _TxnSummaryLine({
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
            color: highlight
                ? const Color(0xFF2E7D32)
                : isTotal ? cs.onSurface : cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _TxnConfirmRow extends StatelessWidget {
  final String  label;
  final String  value;
  final bool    isTotal;
  final Color?  valueColor;
  const _TxnConfirmRow({
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

class _TxnReceiptLine extends StatelessWidget {
  final String  label;
  final String  value;
  final bool    isTotal;
  final bool    mono;
  final Color?  valueColor;
  const _TxnReceiptLine({
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