import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vantedge/features/accounts/data/models/account_list_item_dto.dart';
import 'package:vantedge/features/accounts/data/models/account_type.dart';

class AccountSelectorWidget extends StatelessWidget {
  final List<AccountListItemDTO> accounts;
  final AccountListItemDTO? selectedAccount;
  final void Function(AccountListItemDTO) onSelected;
  final String label;
  final String? hint;
  final bool enabled;
  final String? Function(AccountListItemDTO?)? validator;

  const AccountSelectorWidget({
    super.key,
    required this.accounts,
    required this.onSelected,
    this.selectedAccount,
    this.label = 'Select Account',
    this.hint,
    this.enabled = true,
    this.validator,
  });


  String _formatCurrency(double amount) =>
      '৳${NumberFormat('#,##0.00').format(amount)}';

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '•••• $lastFour';
  }

  IconData _accountIcon(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return Icons.savings_outlined;
      case AccountType.current:
        return Icons.account_balance_outlined;
      case AccountType.salary:
        return Icons.work_outline;
      case AccountType.fd:
        return Icons.trending_up_outlined;
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEmpty = accounts.isEmpty;

    return DropdownButtonFormField<AccountListItemDTO>(
      initialValue: selectedAccount,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: enabled && !isEmpty
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurface.withOpacity(0.38),
      ),
      validator: validator ??
          (value) {
            if (value == null) return 'Please select an account.';
            return null;
          },
      onChanged: (enabled && !isEmpty)
          ? (value) {
              if (value != null) onSelected(value);
            }
          : null,
      decoration: InputDecoration(
        labelText: isEmpty ? 'No accounts available' : label,
        hintText: isEmpty ? null : (hint ?? 'Choose an account'),
        prefixIcon: Icon(
          Icons.account_balance_wallet_outlined,
          color: enabled && !isEmpty
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.38),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        filled: true,
        fillColor: (enabled && !isEmpty)
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      selectedItemBuilder: isEmpty
          ? null
          : (context) => accounts
              .map(
                (account) => _SelectedItem(
                  account: account,
                  formatCurrency: _formatCurrency,
                  maskAccountNumber: _maskAccountNumber,
                  accountIcon: _accountIcon,
                ),
              )
              .toList(),
      items: isEmpty
          ? [
              DropdownMenuItem<AccountListItemDTO>(
                enabled: false,
                child: Text(
                  'No accounts available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ]
          : accounts
              .map(
                (account) => DropdownMenuItem<AccountListItemDTO>(
                  value: account,
                  child: _AccountTile(
                    account: account,
                    formatCurrency: _formatCurrency,
                    maskAccountNumber: _maskAccountNumber,
                    accountIcon: _accountIcon,
                  ),
                ),
              )
              .toList(),
    );
  }
}


class _SelectedItem extends StatelessWidget {
  final AccountListItemDTO account;
  final String Function(double) formatCurrency;
  final String Function(String) maskAccountNumber;
  final IconData Function(AccountType) accountIcon;

  const _SelectedItem({
    required this.account,
    required this.formatCurrency,
    required this.maskAccountNumber,
    required this.accountIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          accountIcon(account.accountType),
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${account.accountType.displayName}  •  '
            '${maskAccountNumber(account.accountNumber)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatCurrency(account.availableBalance),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}


class _AccountTile extends StatelessWidget {
  final AccountListItemDTO account;
  final String Function(double) formatCurrency;
  final String Function(String) maskAccountNumber;
  final IconData Function(AccountType) accountIcon;

  const _AccountTile({
    required this.account,
    required this.formatCurrency,
    required this.maskAccountNumber,
    required this.accountIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            accountIcon(account.accountType),
            size: 20,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                account.accountType.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                maskAccountNumber(account.accountNumber),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatCurrency(account.availableBalance),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Available',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}