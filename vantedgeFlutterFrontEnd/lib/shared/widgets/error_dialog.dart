import 'package:flutter/material.dart';

class ErrorDialog {
  static Future<void> show(
    BuildContext context, {
    String? title,
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool barrierDismissible = true,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _ErrorDialogContent(
        title: title,
        message: message,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }
}

class _ErrorDialogContent extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const _ErrorDialogContent({
    this.title,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      icon: Icon(
        Icons.error_outline,
        color: colorScheme.error,
        size: 48,
      ),
      title: Text(
        title ?? 'Error',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('Retry'),
          ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text('OK'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}

class SuccessDialog {
  static Future<void> show(
    BuildContext context, {
    String? title,
    required String message,
    VoidCallback? onDismiss,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => _SuccessDialogContent(
        title: title,
        message: message,
        onDismiss: onDismiss,
      ),
    );
  }
}

class _SuccessDialogContent extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onDismiss;

  const _SuccessDialogContent({
    this.title,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      icon: Icon(
        Icons.check_circle_outline,
        color: colorScheme.primary,
        size: 48,
      ),
      title: Text(
        title ?? 'Success',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text('OK'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}

class ConfirmDialog {
  static Future<bool?> show(
    BuildContext context, {
    String? title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialogContent(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDangerous: isDangerous,
      ),
    );
  }
}

class _ConfirmDialogContent extends StatelessWidget {
  final String? title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDangerous;

  const _ConfirmDialogContent({
    this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.isDangerous,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      icon: Icon(
        isDangerous ? Icons.warning_amber_rounded : Icons.help_outline,
        color: isDangerous ? colorScheme.error : colorScheme.primary,
        size: 48,
      ),
      title: title != null
          ? Text(
              title!,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            )
          : null,
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDangerous
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}