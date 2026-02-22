import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'app_exceptions.dart';

/// Global error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  /// Initialize error handling
  void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Handle errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug mode, use the default Flutter error handling
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In release mode, log the error
      _logger.e(
        'Flutter Error',
        error: details.exception,
        stackTrace: details.stack,
      );
      
      // Send to error reporting service (e.g., Sentry, Firebase Crashlytics)
      _reportError(details.exception, details.stack);
    }
  }

  /// Handle platform errors
  void _handlePlatformError(Object error, StackTrace stack) {
    if (kDebugMode) {
      _logger.e('Platform Error', error: error, stackTrace: stack);
    } else {
      _logger.e('Platform Error', error: error, stackTrace: stack);
      _reportError(error, stack);
    }
  }

  /// Handle API/business logic errors
  AppException handleError(dynamic error, [StackTrace? stackTrace]) {
    final exception = ExceptionFactory.fromError(error, stackTrace);
    
    _logger.e(
      'App Error: ${exception.code}',
      error: exception.getTechnicalMessage(),
      stackTrace: stackTrace,
    );

    // Report to error tracking service in production
    if (kReleaseMode) {
      _reportError(exception, stackTrace);
    }

    return exception;
  }

  /// Show error to user with appropriate UI
  void showError(BuildContext context, AppException exception) {
    final userMessage = exception.getUserMessage();
    
    // For auth errors, might want to navigate to login
    if (exception is AuthException && exception.code == 'session_expired') {
      _showSessionExpiredDialog(context);
      return;
    }

    // For network errors, show snackbar with retry option
    if (exception is NetworkException) {
      _showNetworkErrorSnackbar(context, userMessage);
      return;
    }

    // For validation errors, might be shown inline in forms
    if (exception is ValidationException) {
      _showValidationSnackbar(context, userMessage);
      return;
    }

    // Default: show error dialog
    _showErrorDialog(context, userMessage);
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSessionExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_clock, color: Colors.orange, size: 48),
        title: const Text('Session Expired'),
        content: const Text(
          'Your session has expired. Please login again to continue.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showNetworkErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // Implement retry logic
          },
        ),
      ),
    );
  }

  void _showValidationSnackbar(BuildContext context, String message) {
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Report error to external service
  void _reportError(dynamic error, StackTrace? stackTrace) {
    // TODO: Integrate with error reporting service
    // Examples:
    // - Firebase Crashlytics
    // - Sentry
    // - Custom logging service
    
    // For now, just log it
    _logger.e('Error reported', error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void logInfo(String message, {dynamic data}) {
    _logger.i(message, error: data);
  }

  /// Log warning message
  void logWarning(String message, {dynamic data}) {
    _logger.w(message, error: data);
  }

  /// Log debug message
  void logDebug(String message, {dynamic data}) {
    _logger.d(message, error: data);
  }
}

/// Extension for easy error handling in BuildContext
extension ErrorHandlingExtension on BuildContext {
  void showError(AppException exception) {
    ErrorHandler().showError(this, exception);
  }

  void showErrorMessage(String message) {
    showError(UnknownException(message: message));
  }
}

/// Mixin for error handling in providers
mixin ErrorHandlerMixin {
  final ErrorHandler _errorHandler = ErrorHandler();

  /// Handle error and optionally show to user
  AppException handleError(
    dynamic error, [
    StackTrace? stackTrace,
    BuildContext? context,
  ]) {
    final exception = _errorHandler.handleError(error, stackTrace);
    
    if (context != null && context.mounted) {
      _errorHandler.showError(context, exception);
    }
    
    return exception;
  }

  /// Log info
  void logInfo(String message, {dynamic data}) {
    _errorHandler.logInfo(message, data: data);
  }

  /// Log warning
  void logWarning(String message, {dynamic data}) {
    _errorHandler.logWarning(message, data: data);
  }

  /// Log debug
  void logDebug(String message, {dynamic data}) {
    _errorHandler.logDebug(message, data: data);
  }
}