import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:vantedge/features/accounts/data/models/account_list_item_dto.dart';
// import '../../../data/models/account_list_item_dto.dart';
import 'account_status_badge.dart';

/// A compact list item for displaying accounts with swipe actions
/// 
/// Features:
/// - Compact design for lists
/// - Swipe left for actions (view details, refresh)
/// - Account icon and name
/// - Balance display
/// - Status badge
/// - Smooth animations
/// - Accessibility support
class AccountListItem extends StatelessWidget {
  final AccountListItemDTO account;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onViewDetails;
  final bool showBalance;

  const AccountListItem({
    super.key,
    required this.account,
    this.onTap,
    this.onRefresh,
    this.onViewDetails,
    this.showBalance = true,
  });

  IconData _getAccountIcon() {
    switch (account.accountType.value) {
      case 'SAVINGS':
        return Icons.savings;
      case 'CURRENT':
        return Icons.account_balance;
      case 'SALARY':
        return Icons.work;
      case 'FD':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getIconColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (account.accountType.value) {
      case 'SAVINGS':
        return colorScheme.primary;
      case 'CURRENT':
        return colorScheme.secondary;
      case 'SALARY':
        return colorScheme.tertiary;
      case 'FD':
        return Colors.green;
      default:
        return colorScheme.primary;
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: 'BDT',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '•••• $lastFour';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label:
          '${account.accountType.displayName}, ${account.accountName}, ending in ${account.accountNumber.substring(account.accountNumber.length - 4)}, '
          'balance ${_formatCurrency(account.currentBalance)}',
      button: true,
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Refresh'): () {
          onRefresh?.call();
        },
        const CustomSemanticsAction(label: 'View Details'): () {
          onViewDetails?.call();
        },
      },
      child: Slidable(
        key: ValueKey(account.accountNumber),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            if (onRefresh != null)
              SlidableAction(
                onPressed: (_) => onRefresh?.call(),
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                icon: Icons.refresh,
                label: 'Refresh',
              ),
            if (onViewDetails != null)
              SlidableAction(
                onPressed: (_) => onViewDetails?.call(),
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                icon: Icons.info_outline,
                label: 'Details',
              ),
          ],
        ),
        child: Material(
          color: colorScheme.surface,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getIconColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getAccountIcon(),
                      color: _getIconColor(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Account Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                account.accountName.isNotEmpty
                                    ? account.accountName
                                    : account.accountType.displayName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AccountStatusBadge(
                              status: account.status,
                              showIcon: false,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _maskAccountNumber(account.accountNumber),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Balance
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showBalance)
                        Text(
                          _formatCurrency(account.currentBalance),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        )
                      else
                        Text(
                          '••••••',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        account.branchCode,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  // Chevron
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Divider for account list items
class AccountListDivider extends StatelessWidget {
  const AccountListDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}