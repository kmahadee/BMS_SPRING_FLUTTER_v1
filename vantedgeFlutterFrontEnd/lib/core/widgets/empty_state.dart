import 'package:flutter/material.dart';

/// Empty state widget with customizable illustration and message
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Empty accounts list
  factory EmptyState.noAccounts({VoidCallback? onCreateAccount}) {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'No Accounts Yet',
      message: 'Open your first account to get started with banking.',
      actionLabel: 'Open Account',
      onAction: onCreateAccount,
    );
  }

  /// Empty transactions list
  factory EmptyState.noTransactions() {
    return const EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No Transactions',
      message: 'Your transaction history will appear here.',
    );
  }

  /// Empty search results
  factory EmptyState.noSearchResults({String? query}) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: query != null
          ? 'No results found for "$query"'
          : 'Try adjusting your search criteria',
    );
  }

  /// Empty notifications
  factory EmptyState.noNotifications() {
    return const EmptyState(
      icon: Icons.notifications_off_outlined,
      title: 'No Notifications',
      message: 'You\'re all caught up! Check back later for updates.',
    );
  }

  /// Empty branches
  factory EmptyState.noBranches() {
    return const EmptyState(
      icon: Icons.location_off,
      title: 'No Branches Found',
      message: 'No branches match your search criteria.',
    );
  }

  /// Empty cards
  factory EmptyState.noCards({VoidCallback? onApplyCard}) {
    return EmptyState(
      icon: Icons.credit_card_outlined,
      title: 'No Cards',
      message: 'Apply for a card to start enjoying the benefits.',
      actionLabel: 'Apply for Card',
      onAction: onApplyCard,
    );
  }

  /// Empty loans
  factory EmptyState.noLoans({VoidCallback? onApplyLoan}) {
    return EmptyState(
      icon: Icons.account_balance_outlined,
      title: 'No Active Loans',
      message: 'Apply for a loan when you need financial assistance.',
      actionLabel: 'Apply for Loan',
      onAction: onApplyLoan,
    );
  }

  /// Empty DPS
  factory EmptyState.noDPS({VoidCallback? onOpenDPS}) {
    return EmptyState(
      icon: Icons.savings_outlined,
      title: 'No DPS Accounts',
      message: 'Open a DPS account to start saving systematically.',
      actionLabel: 'Open DPS',
      onAction: onOpenDPS,
    );
  }

  /// Empty pending approvals
  factory EmptyState.noApprovals() {
    return const EmptyState(
      icon: Icons.check_circle_outline,
      title: 'No Pending Approvals',
      message: 'All items have been reviewed.',
      iconColor: Colors.green,
    );
  }

  /// Empty customers
  factory EmptyState.noCustomers({VoidCallback? onAddCustomer}) {
    return EmptyState(
      icon: Icons.people_outline,
      title: 'No Customers',
      message: 'Add customers to start managing their accounts.',
      actionLabel: 'Add Customer',
      onAction: onAddCustomer,
    );
  }

  /// Empty staff
  factory EmptyState.noStaff({VoidCallback? onAddStaff}) {
    return EmptyState(
      icon: Icons.groups_outlined,
      title: 'No Staff Members',
      message: 'Add staff members to your branch.',
      actionLabel: 'Add Staff',
      onAction: onAddStaff,
    );
  }

  /// Filter results empty
  factory EmptyState.noFilterResults({VoidCallback? onClearFilters}) {
    return EmptyState(
      icon: Icons.filter_list_off,
      title: 'No Matches Found',
      message: 'Try adjusting your filters to see more results.',
      actionLabel: 'Clear Filters',
      onAction: onClearFilters,
    );
  }
}

/// Animated empty state with illustration
class AnimatedEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: EmptyState(
          icon: widget.icon,
          title: widget.title,
          message: widget.message,
          actionLabel: widget.actionLabel,
          onAction: widget.onAction,
        ),
      ),
    );
  }
}

/// Empty state with custom illustration widget
class CustomEmptyState extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CustomEmptyState({
    super.key,
    required this.illustration,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 120,
              child: illustration,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline empty message for smaller sections
class InlineEmptyMessage extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const InlineEmptyMessage({
    super.key,
    required this.message,
    this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}