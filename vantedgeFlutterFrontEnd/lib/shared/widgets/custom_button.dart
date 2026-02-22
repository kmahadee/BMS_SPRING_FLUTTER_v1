import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ButtonVariant { primary, secondary, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final double? width;
  final double height;
  final Widget? icon;
  final bool hapticFeedback;
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.width,
    this.height = 48,
    this.icon,
    this.hapticFeedback = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDisabled = onPressed == null || isLoading;

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTextColor(context, variant),
              ),
            ),
          )
        else if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        if (!isLoading)
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: _getTextColor(context, variant),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );

    void handlePress() {
      if (hapticFeedback) {
        HapticFeedback.lightImpact();
      }
      onPressed?.call();
    }

    Widget button;

    switch (variant) {
      case ButtonVariant.primary:
        if (gradient != null) {
          button = Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              gradient: isDisabled ? null : gradient,
              color: isDisabled ? colorScheme.surfaceContainerHighest : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled ? null : handlePress,
                borderRadius: BorderRadius.circular(12),
                child: Center(child: buttonChild),
              ),
            ),
          );
        } else {
          button = FilledButton(
            onPressed: isDisabled ? null : handlePress,
            style: FilledButton.styleFrom(
              minimumSize: Size(width ?? 0, height),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: buttonChild,
          );
        }
        break;

      case ButtonVariant.secondary:
        button = FilledButton.tonal(
          onPressed: isDisabled ? null : handlePress,
          style: FilledButton.styleFrom(
            minimumSize: Size(width ?? 0, height),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
        break;

      case ButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isDisabled ? null : handlePress,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(width ?? 0, height),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            side: BorderSide(
              color: isDisabled
                  ? colorScheme.outline.withOpacity(0.3)
                  : colorScheme.outline,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
        break;

      case ButtonVariant.text:
        button = TextButton(
          onPressed: isDisabled ? null : handlePress,
          style: TextButton.styleFrom(
            minimumSize: Size(width ?? 0, height),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }

  Color _getTextColor(BuildContext context, ButtonVariant variant) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading || onPressed == null) {
      return colorScheme.onSurface.withOpacity(0.38);
    }

    switch (variant) {
      case ButtonVariant.primary:
        return gradient != null
            ? colorScheme.onPrimary
            : colorScheme.onPrimary;
      case ButtonVariant.secondary:
        return colorScheme.onSecondaryContainer;
      case ButtonVariant.outlined:
      case ButtonVariant.text:
        return colorScheme.primary;
    }
  }
}