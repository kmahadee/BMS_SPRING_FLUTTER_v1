import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String? imagePath;
  final String? lottieAsset;
  final Color? backgroundColor;
  final IconData? icon;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    this.imagePath,
    this.lottieAsset,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          _buildIllustration(context),
          const SizedBox(height: 60),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                  fontSize: 28,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                  fontSize: 16,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    if (lottieAsset != null) {
      return Lottie.asset(
        lottieAsset!,
        width: 300,
        height: 300,
        fit: BoxFit.contain,
      );
    }

    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        width: 300,
        height: 300,
        fit: BoxFit.contain,
      );
    }

    if (icon != null) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 100,
          color: const Color(0xFF1A237E),
        ),
      );
    }

    return const SizedBox(width: 300, height: 300);
  }
}