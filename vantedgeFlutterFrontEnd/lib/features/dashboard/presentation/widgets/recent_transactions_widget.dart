import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionItem {
  final String type;
  final double amount;
  final DateTime date;
  final String description;
  final bool isCredit;

  TransactionItem({
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    required this.isCredit,
  });
}

class RecentTransactionsWidget extends StatelessWidget {
  final List<TransactionItem> transactions;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const RecentTransactionsWidget({
    super.key,
    required this.transactions,
    this.isLoading = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent transactions',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              elevation: 1,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: colorScheme.outlineVariant,
                ),
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _TransactionTile(transaction: transaction);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionItem transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (transaction.isCredit ? Colors.green : Colors.red)
              .withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          transaction.isCredit
              ? Icons.arrow_downward
              : Icons.arrow_upward,
          color: transaction.isCredit ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
      title: Text(
        transaction.type,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${transaction.description} • ${dateFormat.format(transaction.date)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        '${transaction.isCredit ? '+' : '-'}৳${transaction.amount.toStringAsFixed(2)}',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: transaction.isCredit ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}