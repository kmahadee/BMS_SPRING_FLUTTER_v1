import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vantedge/features/accounts/data/models/account_list_item_dto.dart';
import 'package:vantedge/features/accounts/data/models/account_type.dart';
// import '../../../data/models/account_list_item_dto.dart';
// import '../../../data/models/account_type.dart';
import 'account_status_badge.dart';

/// A polished card widget for displaying account information
/// 
/// Features:
/// - Color-coded background based on account type
/// - Account type icon
/// - Masked account number
/// - Balance display with tap-to-reveal
/// - Status badge
/// - Branch information
/// - Hero animation support
/// - Smooth tap feedback
/// - Accessibility support
class AccountCard extends StatefulWidget {
  final AccountListItemDTO account;
  final VoidCallback? onTap;
  final bool showBalance;
  final bool enableHeroAnimation;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.showBalance = true,
    this.enableHeroAnimation = true,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard>
    with SingleTickerProviderStateMixin {
  bool _isBalanceVisible = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (widget.account.accountType) {
      case AccountType.savings:
        return colorScheme.primaryContainer;
      case AccountType.current:
        return colorScheme.secondaryContainer;
      case AccountType.salary:
        return colorScheme.tertiaryContainer;
      case AccountType.fd:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _getOnBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (widget.account.accountType) {
      case AccountType.savings:
        return colorScheme.onPrimaryContainer;
      case AccountType.current:
        return colorScheme.onSecondaryContainer;
      case AccountType.salary:
        return colorScheme.onTertiaryContainer;
      case AccountType.fd:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData _getAccountIcon() {
    switch (widget.account.accountType) {
      case AccountType.savings:
        return Icons.savings;
      case AccountType.current:
        return Icons.account_balance;
      case AccountType.salary:
        return Icons.work;
      case AccountType.fd:
        return Icons.trending_up;
    }
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '•••• $lastFour';
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: 'BDT',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = _getBackgroundColor(context);
    final onBackgroundColor = _getOnBackgroundColor(context);

    final cardContent = Card(
      elevation: 2,
      shadowColor: backgroundColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Account Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: onBackgroundColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getAccountIcon(),
                          color: onBackgroundColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Account Name and Number
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.account.accountName.isNotEmpty
                                  ? widget.account.accountName
                                  : widget.account.accountType.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: onBackgroundColor,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _maskAccountNumber(widget.account.accountNumber),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: onBackgroundColor.withOpacity(0.7),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status Badge
                      AccountStatusBadge(
                        status: widget.account.status,
                        compact: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(
                    color: onBackgroundColor.withOpacity(0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 16),

                  // Balance Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Current Balance
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Balance',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: onBackgroundColor.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (widget.showBalance)
                                  GestureDetector(
                                    onTap: _toggleBalanceVisibility,
                                    child: Icon(
                                      _isBalanceVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 14,
                                      color: onBackgroundColor.withOpacity(0.5),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                widget.showBalance && !_isBalanceVisible
                                    ? _formatCurrency(
                                        widget.account.currentBalance)
                                    : '••••••',
                                key: ValueKey(_isBalanceVisible),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: onBackgroundColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Branch Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.business,
                                size: 14,
                                color: onBackgroundColor.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.account.branchCode,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: onBackgroundColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.account.branchName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onBackgroundColor.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Wrap with Hero animation if enabled
    if (widget.enableHeroAnimation) {
      return Hero(
        tag: 'account_${widget.account.accountNumber}',
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Semantics(
            label:
                '${widget.account.accountType.displayName} account, ${widget.account.accountName}, '
                'ending in ${widget.account.accountNumber.substring(widget.account.accountNumber.length - 4)}, '
                'balance ${_formatCurrency(widget.account.currentBalance)}, '
                '${widget.account.status.displayName} status',
            button: true,
            child: cardContent,
          ),
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Semantics(
        label:
            '${widget.account.accountType.displayName} account, ${widget.account.accountName}, '
            'ending in ${widget.account.accountNumber.substring(widget.account.accountNumber.length - 4)}, '
            'balance ${_formatCurrency(widget.account.currentBalance)}, '
            '${widget.account.status.displayName} status',
        button: true,
        child: cardContent,
      ),
    );
  }
}