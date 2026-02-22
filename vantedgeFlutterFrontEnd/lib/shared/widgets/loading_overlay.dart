import 'dart:ui';
import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isLoading;
  final Widget child;
  final Color? backgroundColor;
  final double blurAmount;

  const LoadingOverlay({
    super.key,
    required this.child,
    this.message,
    this.isLoading = false,
    this.backgroundColor,
    this.blurAmount = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: _LoadingOverlayContent(
              message: message,
              backgroundColor: backgroundColor,
              blurAmount: blurAmount,
            ),
          ),
      ],
    );
  }

  static void show(
    BuildContext context, {
    String? message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: _LoadingOverlayContent(
            message: message,
            blurAmount: 0,
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class _LoadingOverlayContent extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;
  final double blurAmount;

  const _LoadingOverlayContent({
    this.message,
    this.backgroundColor,
    required this.blurAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: blurAmount,
        sigmaY: blurAmount,
      ),
      child: Container(
        color: backgroundColor ??
            colorScheme.surface.withOpacity(0.8),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}