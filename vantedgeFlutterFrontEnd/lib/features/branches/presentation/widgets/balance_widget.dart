import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// An animated widget that displays account balance with tap-to-reveal functionality
/// 
/// Features:
/// - Tap to toggle visibility (show/hide balance)
/// - Smooth fade and scale animations
/// - Currency formatting with locale support
/// - Available vs current balance distinction
/// - Visual indicators for negative balance
/// - Accessibility support
class BalanceWidget extends StatefulWidget {
  final double currentBalance;
  final double? availableBalance;
  final String? currency;
  final bool initiallyVisible;
  final bool showAvailableBalance;
  final VoidCallback? onTap;

  const BalanceWidget({
    super.key,
    required this.currentBalance,
    this.availableBalance,
    this.currency = 'BDT',
    this.initiallyVisible = true,
    this.showAvailableBalance = true,
    this.onTap,
  });

  @override
  State<BalanceWidget> createState() => _BalanceWidgetState();
}

class _BalanceWidgetState extends State<BalanceWidget>
    with SingleTickerProviderStateMixin {
  late bool _isVisible;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isVisible = widget.initiallyVisible;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    if (_isVisible) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
      if (_isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    widget.onTap?.call();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: widget.currency ?? 'BDT',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isNegative = widget.currentBalance < 0;

    return Semantics(
      label: _isVisible
          ? 'Current balance: ${_formatCurrency(widget.currentBalance)}. Tap to hide.'
          : 'Balance hidden. Tap to reveal.',
      button: true,
      child: GestureDetector(
        onTap: _toggleVisibility,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isNegative
                ? colorScheme.errorContainer.withOpacity(0.3)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with label and toggle icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Balance',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: _isVisible ? 0 : 0.5,
                    child: Icon(
                      _isVisible ? Icons.visibility : Icons.visibility_off,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Balance amount
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: _isVisible
                    ? Text(
                        _formatCurrency(widget.currentBalance),
                        key: const ValueKey('visible'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isNegative
                              ? colorScheme.error
                              : colorScheme.onSurface,
                        ),
                      )
                    : Text(
                        '••••••',
                        key: const ValueKey('hidden'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),

              // Available balance (if different from current)
              if (widget.showAvailableBalance &&
                  widget.availableBalance != null &&
                  widget.availableBalance != widget.currentBalance) ...[
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: _isVisible ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Available: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _isVisible
                            ? _formatCurrency(widget.availableBalance!)
                            : '••••',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Negative balance indicator
              if (isNegative && _isVisible) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Overdrawn',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}