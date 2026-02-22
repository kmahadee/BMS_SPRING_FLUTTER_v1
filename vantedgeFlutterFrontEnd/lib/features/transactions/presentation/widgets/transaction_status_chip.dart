import 'package:flutter/material.dart';
import 'package:vantedge/features/transactions/data/models/transaction_enums.dart';

class TransactionStatusChip extends StatelessWidget {
  final TransactionStatus status;

  final bool compact;

  final bool showIcon;

  const TransactionStatusChip({
    super.key,
    required this.status,
    this.compact = false,
    this.showIcon = true,
  });


  _ChipStyle _resolveStyle(ColorScheme cs) {
    switch (status) {
      case TransactionStatus.completed:
        return _ChipStyle(
          background: const Color(0xFFE8F5E9), // green[50]
          foreground: const Color(0xFF1B5E20), // green[900]
          icon: Icons.check_circle_outline_rounded,
        );
      case TransactionStatus.pending:
        return _ChipStyle(
          background: const Color(0xFFFFF8E1), // amber[50]
          foreground: const Color(0xFFE65100), // deepOrange[900]
          icon: Icons.schedule_rounded,
        );
      case TransactionStatus.processing:
        return _ChipStyle(
          background: const Color(0xFFE3F2FD), // blue[50]
          foreground: const Color(0xFF0D47A1), // blue[900]
          icon: Icons.sync_rounded,
        );
      case TransactionStatus.failed:
        return _ChipStyle(
          background: cs.errorContainer,
          foreground: cs.onErrorContainer,
          icon: Icons.cancel_outlined,
        );
      case TransactionStatus.cancelled:
        return _ChipStyle(
          background: const Color(0xFFF5F5F5), // grey[100]
          foreground: const Color(0xFF424242), // grey[800]
          icon: Icons.do_not_disturb_on_outlined,
        );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _resolveStyle(theme.colorScheme);

    final double iconSize = compact ? 13.0 : 15.0;
    final double fontSize = compact ? 11.0 : 12.0;
    final double hPadding = compact ? 7.0 : 10.0;
    final double vPadding = compact ? 3.0 : 5.0;
    final double radius = compact ? 10.0 : 12.0;

    return Semantics(
      label: '${status.displayName} transaction',
      child: Tooltip(
        message: status.displayName,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: hPadding,
            vertical: vPadding,
          ),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  style.icon,
                  size: iconSize,
                  color: style.foreground,
                ),
                SizedBox(width: compact ? 4 : 5),
              ],
              Text(
                status.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ChipStyle {
  final Color background;
  final Color foreground;
  final IconData icon;

  const _ChipStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });
}