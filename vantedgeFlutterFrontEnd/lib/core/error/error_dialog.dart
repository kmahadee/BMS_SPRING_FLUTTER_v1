import 'package:flutter/material.dart';
import 'app_exceptions.dart';

/// Reusable error dialog with retry functionality
class ErrorDialog extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String? customTitle;
  final String? customMessage;

  const ErrorDialog({
    super.key,
    required this.exception,
    this.onRetry,
    this.onDismiss,
    this.customTitle,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: _buildIcon(colorScheme),
      title: Text(customTitle ?? _getTitle()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(customMessage ?? exception.getUserMessage()),
          if (exception.code != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Error Code: ${exception.code}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
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
    );
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;

    if (exception is NetworkException) {
      iconData = Icons.wifi_off;
      iconColor = Colors.orange;
    } else if (exception is AuthException) {
      iconData = Icons.lock_outline;
      iconColor = Colors.red;
    } else if (exception is ValidationException) {
      iconData = Icons.warning_amber;
      iconColor = Colors.orange;
    } else if (exception is ServerException) {
      iconData = Icons.dns_outlined;
      iconColor = Colors.red;
    } else {
      iconData = Icons.error_outline;
      iconColor = colorScheme.error;
    }

    return Icon(iconData, color: iconColor, size: 48);
  }

  String _getTitle() {
    if (exception is NetworkException) {
      return 'Connection Error';
    } else if (exception is AuthException) {
      return 'Authentication Error';
    } else if (exception is ValidationException) {
      return 'Validation Error';
    } else if (exception is ServerException) {
      return 'Server Error';
    } else {
      return 'Error';
    }
  }

  /// Show error dialog
  static Future<void> show(
    BuildContext context,
    AppException exception, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    String? customTitle,
    String? customMessage,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        exception: exception,
        onRetry: onRetry,
        onDismiss: onDismiss,
        customTitle: customTitle,
        customMessage: customMessage,
      ),
    );
  }
}

/// Error snackbar for quick feedback
class ErrorSnackbar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static void showException(
    BuildContext context,
    AppException exception, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    show(
      context,
      exception.getUserMessage(),
      duration: duration,
      onRetry: onRetry,
    );
  }
}

/// Success snackbar
class SuccessSnackbar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: duration,
      ),
    );
  }
}

/// Warning snackbar
class WarningSnackbar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: duration,
      ),
    );
  }
}

/// Info snackbar
class InfoSnackbar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        duration: duration,
      ),
    );
  }
}

/// Confirmation dialog for destructive actions
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Show confirmation dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }
}