import 'package:flutter/material.dart';
import 'package:vantedge/features/accounts/data/models/account_status.dart';
// import '../../../data/models/account_status.dart';

/// A color-coded badge that displays account status
/// 
/// Features:
/// - Color-coded backgrounds based on status
/// - Status-specific icons
/// - Tooltip with status description
/// - Animated state transitions
/// - Accessibility support
class AccountStatusBadge extends StatelessWidget {
  final AccountStatus status;
  final bool showIcon;
  final bool compact;

  const AccountStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine colors based on status
    final Color backgroundColor;
    final Color textColor;
    final IconData icon;
    final String description;

    switch (status) {
      case AccountStatus.active:
        backgroundColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        icon = Icons.check_circle;
        description = 'Account is active and operational';
        break;
      case AccountStatus.inactive:
        backgroundColor = colorScheme.tertiaryContainer;
        textColor = colorScheme.onTertiaryContainer;
        icon = Icons.pause_circle;
        description = 'Account is temporarily inactive';
        break;
      case AccountStatus.dormant:
        backgroundColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        icon = Icons.schedule;
        description = 'Account has been inactive for an extended period';
        break;
      case AccountStatus.blocked:
        backgroundColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        icon = Icons.block;
        description = 'Account is blocked';
        break;
    }

    return Tooltip(
      message: description,
      child: Semantics(
        label: '${status.displayName} status: $description',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  icon,
                  size: compact ? 14 : 16,
                  color: textColor,
                ),
                SizedBox(width: compact ? 4 : 6),
              ],
              Text(
                status.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 11 : 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}