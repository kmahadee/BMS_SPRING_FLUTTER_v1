import 'package:flutter/material.dart';
import 'package:vantedge/features/loans/data/models/loan_enums.dart';
import 'loan_enum_display_helpers.dart';

/// Color-coded status badge for a [LoanStatus].
///
/// Mirrors the pattern of `AccountStatusBadge` from the accounts feature:
/// - Animated container with tooltip + Semantics
/// - Compact mode for use inside list cards
/// - Optional icon display
class LoanStatusBadge extends StatelessWidget {
  final LoanStatus status;
  final bool compact;
  final bool showIcon;

  const LoanStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = status.badgeBackgroundColor;
    final fg = status.badgeTextColor;

    return Tooltip(
      message: status.semanticDescription,
      child: Semantics(
        label: '${status.displayName}: ${status.semanticDescription}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  status.icon,
                  size: compact ? 13 : 15,
                  color: fg,
                ),
                SizedBox(width: compact ? 4 : 6),
              ],
              Text(
                status.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11 : 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
