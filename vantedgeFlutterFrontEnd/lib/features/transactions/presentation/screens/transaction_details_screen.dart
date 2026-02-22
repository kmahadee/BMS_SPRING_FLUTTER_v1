import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:vantedge/features/transactions/data/models/transaction_enums.dart';
import 'package:vantedge/features/transactions/data/models/transaction_history_model.dart';
import 'package:vantedge/features/transactions/data/models/transaction_model.dart';
import 'package:vantedge/features/transactions/presentation/widgets/transaction_receipt.dart';
import 'package:vantedge/features/transactions/presentation/widgets/transaction_status_chip.dart';
import 'package:vantedge/shared/widgets/custom_app_bar.dart';


class TransactionDetailsScreen extends StatelessWidget {
  final TransactionHistoryModel transaction;

  final TransactionModel? fullTransaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
    this.fullTransaction,
  });

  static const _currencySymbol = '৳';
  static final _amountFmt = NumberFormat('#,##0.00');
  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  String _fmt(double? v) =>
      v == null ? '—' : '$_currencySymbol${_amountFmt.format(v)}';

  String _fmtDate(DateTime? dt) => dt == null ? '—' : _dateFmt.format(dt);

  bool get _isCredit => transaction.isCredit;

  Color get _directionColor =>
      _isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

  String _buildShareText() {
    final buf = StringBuffer();
    buf.writeln('VantEdge Bank – Transaction Receipt');
    buf.writeln('─' * 40);
    buf.writeln('Transaction ID : ${transaction.transactionId}');
    buf.writeln('Reference No.  : ${transaction.referenceNumber}');
    buf.writeln('Date & Time    : ${_fmtDate(transaction.timestamp)}');
    buf.writeln('Type           : ${transaction.transactionType}');
    buf.writeln('Mode           : ${transaction.transferMode.displayName}');
    buf.writeln('Status         : ${transaction.status.displayName}');
    buf.writeln('Amount         : ${_fmt(transaction.amount)}');
    if (fullTransaction?.transferFee != null) {
      buf.writeln('Transfer Fee   : ${_fmt(fullTransaction!.transferFee)}');
    }
    if (fullTransaction?.serviceTax != null) {
      buf.writeln('Service Tax    : ${_fmt(fullTransaction!.serviceTax)}');
    }
    if (fullTransaction?.totalAmount != null) {
      buf.writeln('Total Amount   : ${_fmt(fullTransaction!.totalAmount)}');
    }
    buf.writeln('Balance After  : ${_fmt(transaction.balanceAfter)}');
    if (transaction.description?.isNotEmpty == true) {
      buf.writeln('Description    : ${transaction.description}');
    }
    buf.writeln('─' * 40);
    buf.writeln('Thank you for banking with VantEdge Bank.');
    return buf.toString();
  }

  void _showReceipt(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => TransactionReceiptWidget(
          transaction: transaction,
          fullTransaction: fullTransaction,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: const CustomAppBar(
        title: 'Transaction Details',
        showNotifications: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroHeader(
                    amount: transaction.amount,
                    isCredit: _isCredit,
                    directionColor: _directionColor,
                    transactionType: transaction.transactionType,
                    status: transaction.status,
                    currencySymbol: _currencySymbol,
                    amountFmt: _amountFmt,
                  ),

                  const SizedBox(height: 16),

                  _DetailCard(
                    title: 'Transaction Info',
                    icon: Icons.receipt_long_outlined,
                    children: [
                      _DetailRow(
                        label: 'Transaction ID',
                        value: transaction.transactionId,
                        copyable: true,
                      ),
                      _DetailRow(
                        label: 'Reference No.',
                        value: transaction.referenceNumber,
                        copyable: true,
                      ),
                      if (fullTransaction?.receiptNumber != null)
                        _DetailRow(
                          label: 'Receipt No.',
                          value: fullTransaction!.receiptNumber!,
                          copyable: true,
                        ),
                      _DetailRow(
                        label: 'Date & Time',
                        value: _fmtDate(transaction.timestamp),
                      ),
                      if (fullTransaction?.completedAt != null)
                        _DetailRow(
                          label: 'Completed At',
                          value: _fmtDate(fullTransaction!.completedAt),
                        ),
                      _DetailRow(
                        label: 'Transfer Mode',
                        value: transaction.transferMode.displayName,
                      ),
                      _DetailRow(
                        label: 'Transaction Type',
                        value: _typeLabel(transaction.transactionType),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _AccountDetailsCard(
                    transaction: transaction,
                    fullTransaction: fullTransaction,
                  ),

                  const SizedBox(height: 12),

                  if (fullTransaction != null &&
                      (fullTransaction!.transferFee != null ||
                          fullTransaction!.serviceTax != null ||
                          fullTransaction!.totalAmount != null)) ...[
                    _DetailCard(
                      title: 'Amount Breakdown',
                      icon: Icons.calculate_outlined,
                      children: [
                        _DetailRow(
                          label: 'Amount',
                          value: _fmt(transaction.amount),
                          valueStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface),
                        ),
                        if (fullTransaction!.transferFee != null)
                          _DetailRow(
                            label: 'Transfer Fee',
                            value: _fmt(fullTransaction!.transferFee),
                          ),
                        if (fullTransaction!.serviceTax != null)
                          _DetailRow(
                            label: 'Service Tax (18%)',
                            value: _fmt(fullTransaction!.serviceTax),
                          ),
                        _DashedDivider(),
                        _DetailRow(
                          label: 'Total Amount',
                          value: _fmt(fullTransaction!.totalAmount ??
                              fullTransaction!.effectiveTotal),
                          valueStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _directionColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  _DetailCard(
                    title: 'Balance Information',
                    icon: Icons.account_balance_wallet_outlined,
                    children: [
                      if (fullTransaction?.balanceBefore != null)
                        _DetailRow(
                          label: 'Balance Before',
                          value: _fmt(fullTransaction!.balanceBefore),
                        ),
                      _DetailRow(
                        label: 'Balance After',
                        value: _fmt(transaction.balanceAfter),
                        valueStyle: TextStyle(
                            fontWeight: FontWeight.w600, color: cs.primary),
                      ),
                    ],
                  ),

                  if (_hasRemarks) ...[
                    const SizedBox(height: 12),
                    _RemarksCard(
                      description: transaction.description,
                      remarks: fullTransaction?.remarks,
                    ),
                  ],

                  if (fullTransaction?.beneficiaryName != null ||
                      fullTransaction?.beneficiaryBank != null) ...[
                    const SizedBox(height: 12),
                    _DetailCard(
                      title: 'Beneficiary',
                      icon: Icons.person_outline_rounded,
                      children: [
                        if (fullTransaction?.beneficiaryName != null)
                          _DetailRow(
                            label: 'Name',
                            value: fullTransaction!.beneficiaryName!,
                          ),
                        if (fullTransaction?.beneficiaryBank != null)
                          _DetailRow(
                            label: 'Bank',
                            value: fullTransaction!.beneficiaryBank!,
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          _ActionBar(
            onShare: () => Share.share(_buildShareText(),
                subject: 'VantEdge Transaction Receipt'),
            onDownload: () => _showReceipt(context),
          ),
        ],
      ),
    );
  }

  bool get _hasRemarks =>
      (transaction.description?.isNotEmpty == true) ||
      (fullTransaction?.remarks?.isNotEmpty == true);

  String _typeLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'CREDIT':
        return 'Credit';
      case 'DEBIT':
        return 'Debit';
      case 'TRANSFER':
        return 'Transfer';
      case 'DEPOSIT':
        return 'Deposit';
      case 'WITHDRAWAL':
        return 'Withdrawal';
      default:
        if (raw.isEmpty) return raw;
        return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    }
  }
}


class _HeroHeader extends StatelessWidget {
  final double amount;
  final bool isCredit;
  final Color directionColor;
  final String transactionType;
  final TransactionStatus status;
  final String currencySymbol;
  final NumberFormat amountFmt;

  const _HeroHeader({
    required this.amount,
    required this.isCredit,
    required this.directionColor,
    required this.transactionType,
    required this.status,
    required this.currencySymbol,
    required this.amountFmt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prefix = isCredit ? '+' : '−';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: directionColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: directionColor.withOpacity(0.20), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: directionColor.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: directionColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),

          Text(
            '$prefix$currencySymbol${amountFmt.format(amount)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: directionColor,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _readableType(transactionType),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          TransactionStatusChip(status: status, compact: false),
        ],
      ),
    );
  }

  String _readableType(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }
}


class _AccountDetailsCard extends StatelessWidget {
  final TransactionHistoryModel transaction;
  final TransactionModel? fullTransaction;

  const _AccountDetailsCard({
    required this.transaction,
    required this.fullTransaction,
  });

  String _maskAccount(String? acct) {
    if (acct == null || acct.isEmpty) return '—';
    if (acct.length <= 4) return acct;
    return '•••• ${acct.substring(acct.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final fromAcct = fullTransaction?.fromAccountNumber ??
        (transaction.isDebit ? transaction.accountNumber : null);
    final toAcct = fullTransaction?.toAccountNumber ??
        (transaction.isCredit ? transaction.accountNumber : transaction.otherAccountNumber);
    final fromBranch = fullTransaction?.fromBranchName ?? transaction.branchName;
    final toBranch = fullTransaction?.toBranchName ?? transaction.otherBranchName;
    final fromBranchCode = fullTransaction?.fromBranchCode ?? transaction.branchCode;
    final toBranchCode = fullTransaction?.toBranchCode ?? transaction.otherBranchCode;

    return _DetailCard(
      title: 'Account Details',
      icon: Icons.swap_horiz_rounded,
      children: [
        _AccountRow(
          label: 'From',
          accountNumber: fromAcct ?? 'CASH / EXTERNAL',
          branchName: fromBranch,
          branchCode: fromBranchCode,
          maskAccount: _maskAccount,
        ),
        const SizedBox(height: 4),
        Center(
          child: Icon(Icons.arrow_downward_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
        ),
        const SizedBox(height: 4),
        _AccountRow(
          label: 'To',
          accountNumber: toAcct ?? '—',
          branchName: toBranch,
          branchCode: toBranchCode,
          maskAccount: _maskAccount,
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String label;
  final String accountNumber;
  final String? branchName;
  final String? branchCode;
  final String Function(String?) maskAccount;

  const _AccountRow({
    required this.label,
    required this.accountNumber,
    required this.maskAccount,
    this.branchName,
    this.branchCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isCash = accountNumber == 'CASH / EXTERNAL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCash
                  ? Icons.payments_outlined
                  : Icons.account_balance_outlined,
              size: 18,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  isCash ? accountNumber : maskAccount(accountNumber),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (branchName != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    [branchName, if (branchCode != null) '($branchCode)']
                        .join(' '),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _RemarksCard extends StatelessWidget {
  final String? description;
  final String? remarks;

  const _RemarksCard({this.description, this.remarks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _DetailCard(
      title: 'Remarks & Description',
      icon: Icons.notes_rounded,
      children: [
        if (description?.isNotEmpty == true) ...[
          Text('Description',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(description!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurface)),
        ],
        if (remarks?.isNotEmpty == true) ...[
          if (description?.isNotEmpty == true) const SizedBox(height: 10),
          Text('Remarks',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(remarks!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurface)),
        ],
      ],
    );
  }
}


class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withOpacity(0.4)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}


class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final valueWidget = Text(
      value,
      textAlign: TextAlign.end,
      style: valueStyle ??
          theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w500,
          ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 5,
            child: copyable
                ? GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$label copied'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(child: valueWidget),
                        const SizedBox(width: 4),
                        Icon(Icons.copy_rounded,
                            size: 13,
                            color: cs.onSurfaceVariant.withOpacity(0.5)),
                      ],
                    ),
                  )
                : Align(alignment: Alignment.centerRight, child: valueWidget),
          ),
        ],
      ),
    );
  }
}


class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (_, constraints) {
          const dashW = 4.0;
          const gap = 4.0;
          final count = (constraints.maxWidth / (dashW + gap)).floor();
          return Row(
            children: List.generate(count, (_) {
              return Padding(
                padding: const EdgeInsets.only(right: gap),
                child: Container(
                  width: dashW,
                  height: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.6),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}


class _ActionBar extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onDownload;

  const _ActionBar({required this.onShare, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share Receipt'),
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
            child: FilledButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('View Receipt'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}