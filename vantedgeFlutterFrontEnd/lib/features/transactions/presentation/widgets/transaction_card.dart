import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vantedge/features/transactions/data/models/transaction_history_model.dart';
import 'transaction_status_chip.dart';

class TransactionCard extends StatelessWidget {
  final TransactionHistoryModel transaction;
  final VoidCallback? onTap;

  final String currencySymbol;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.currencySymbol = '৳',
  });


  bool get _isCredit => transaction.isCredit;

  String get _formattedDate {
    final ts = transaction.timestamp;
    if (ts == null) return '—';
    return DateFormat('dd MMM yyyy HH:mm').format(ts);
  }

  String get _formattedAmount {
    final prefix = _isCredit ? '+' : '−';
    final formatted =
        NumberFormat('#,##0.00').format(transaction.amount.abs());
    return '$prefix$currencySymbol$formatted';
  }

  String get _subtitle {
    final other = transaction.otherAccountNumber;
    if (other != null && other.isNotEmpty) {
      final masked = other.length > 4
          ? '•••• ${other.substring(other.length - 4)}'
          : other;
      return '$masked  •  $_formattedDate';
    }
    final desc = transaction.description;
    if (desc != null && desc.isNotEmpty) {
      return '$desc  •  $_formattedDate';
    }
    return _formattedDate;
  }

  String _transactionTypeLabel(String raw) {
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
      case 'PAYMENT':
        return 'Payment';
      case 'REFUND':
        return 'Refund';
      default:
        if (raw.isEmpty) return raw;
        return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const creditColor = Color(0xFF2E7D32); // green[800]
    const debitColor = Color(0xFFC62828);  // red[800]
    final directionColor = _isCredit ? creditColor : debitColor;

    return Semantics(
      label: '${_transactionTypeLabel(transaction.transactionType)} of '
          '$_formattedAmount, status ${transaction.status.displayName}, '
          'on $_formattedDate',
      button: onTap != null,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
        color: colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: directionColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isCredit
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: directionColor,
                    size: 22,
                    semanticLabel: _isCredit ? 'Credit' : 'Debit',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _transactionTypeLabel(transaction.transactionType),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formattedAmount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: directionColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TransactionStatusChip(
                      status: transaction.status,
                      compact: true,
                    ),
                  ],
                ),

                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}