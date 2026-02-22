import 'package:flutter/material.dart';

/// App color palette following Material 3 design principles
/// Colors chosen for professional banking aesthetics with trust and security
class AppColors {
  AppColors._();

  // Primary Colors - Deep Blue (Trust, Security, Stability)
  static const Color primary = Color(0xFF1A237E); // Indigo 900
  static const Color primaryLight = Color(0xFF534BAE);
  static const Color primaryDark = Color(0xFF000051);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary Colors - Gold Accent (Premium, Value)
  static const Color secondary = Color(0xFFFFD700); // Gold
  static const Color secondaryLight = Color(0xFFFFFF52);
  static const Color secondaryDark = Color(0xFFC7A600);
  static const Color onSecondary = Color(0xFF000000);

  // Tertiary Colors - Teal (Growth, Balance)
  static const Color tertiary = Color(0xFF00897B); // Teal 600
  static const Color tertiaryLight = Color(0xFF4EBAAA);
  static const Color tertiaryDark = Color(0xFF005B4F);
  static const Color onTertiary = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50); // Green 500
  static const Color successLight = Color(0xFF80E27E);
  static const Color successDark = Color(0xFF087F23);
  static const Color onSuccess = Color(0xFFFFFFFF);

  static const Color error = Color(0xFFD32F2F); // Red 700
  static const Color errorLight = Color(0xFFFF6659);
  static const Color errorDark = Color(0xFF9A0007);
  static const Color onError = Color(0xFFFFFFFF);

  static const Color warning = Color(0xFFF57C00); // Orange 700
  static const Color warningLight = Color(0xFFFFAD42);
  static const Color warningDark = Color(0xFFBB4D00);
  static const Color onWarning = Color(0xFFFFFFFF);

  static const Color info = Color(0xFF1976D2); // Blue 700
  static const Color infoLight = Color(0xFF63A4FF);
  static const Color infoDark = Color(0xFF004BA0);
  static const Color onInfo = Color(0xFFFFFFFF);

  // Neutral Colors - Light Theme
  static const Color background = Color(0xFFFAFAFA); // Grey 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5); // Grey 100
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // Outline Colors
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);

  // Shadow & Scrim
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);

  // Inverse Colors
  static const Color inverseSurface = Color(0xFF313033);
  static const Color inverseOnSurface = Color(0xFFF4EFF4);
  static const Color inversePrimary = Color(0xFFBAC3FF);

  // Text Colors - Light Theme
  static const Color textPrimary = Color(0xFF212121); // Grey 900
  static const Color textSecondary = Color(0xFF757575); // Grey 600
  static const Color textTertiary = Color(0xFF9E9E9E); // Grey 500
  static const Color textDisabled = Color(0xFFBDBDBD); // Grey 400
  static const Color textHint = Color(0xFF9E9E9E);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);
  static const Color onBackgroundDark = Color(0xFFE6E1E5);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);
  static const Color onSurfaceVariantDark = Color(0xFFCAC4D0);

  // Text Colors - Dark Theme
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  static const Color textTertiaryDark = Color(0xFF808080);
  static const Color textDisabledDark = Color(0xFF666666);

  // Divider Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);

  // Special Banking Colors
  static const Color income = Color(0xFF4CAF50); // Green for deposits
  static const Color expense = Color(0xFFF44336); // Red for withdrawals
  static const Color pending = Color(0xFFFF9800); // Orange for pending
  static const Color completed = Color(0xFF4CAF50); // Green for completed
  static const Color cancelled = Color(0xFF757575); // Grey for cancelled

  // Card Type Colors
  static const Color creditCard = Color(0xFF1976D2); // Blue
  static const Color debitCard = Color(0xFF7B1FA2); // Purple
  static const Color goldCard = Color(0xFFFFD700); // Gold
  static const Color platinumCard = Color(0xFFE5E4E2); // Platinum Silver

  // Account Type Colors
  static const Color savingsAccount = Color(0xFF388E3C); // Green
  static const Color checkingAccount = Color(0xFF1976D2); // Blue
  static const Color loanAccount = Color(0xFFF57C00); // Orange
  static const Color investmentAccount = Color(0xFF7B1FA2); // Purple

  // Chart Colors (for financial charts)
  static const List<Color> chartColors = [
    Color(0xFF1976D2), // Blue
    Color(0xFF388E3C), // Green
    Color(0xFFF57C00), // Orange
    Color(0xFF7B1FA2), // Purple
    Color(0xFFD32F2F), // Red
    Color(0xFF00897B), // Teal
    Color(0xFFFBC02D), // Yellow
    Color(0xFF5E35B1), // Deep Purple
  ];

  // Gradient Colors for Cards
  static const List<Color> gradientBlue = [
    Color(0xFF1976D2),
    Color(0xFF1565C0),
    Color(0xFF0D47A1),
  ];

  static const List<Color> gradientGold = [
    Color(0xFFFFD700),
    Color(0xFFFFC107),
    Color(0xFFFF8F00),
  ];

  static const List<Color> gradientGreen = [
    Color(0xFF43A047),
    Color(0xFF388E3C),
    Color(0xFF2E7D32),
  ];

  static const List<Color> gradientPurple = [
    Color(0xFF8E24AA),
    Color(0xFF7B1FA2),
    Color(0xFF6A1B9A),
  ];

  // Opacity Levels
  static const double opacityHigh = 0.87;
  static const double opacityMedium = 0.60;
  static const double opacityDisabled = 0.38;
  static const double opacityFaint = 0.12;

  // Helper Methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get color for transaction type
  static Color getTransactionColor(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
      case 'credit':
        return income;
      case 'withdrawal':
      case 'debit':
        return expense;
      case 'pending':
        return pending;
      case 'completed':
      case 'success':
        return completed;
      case 'cancelled':
      case 'failed':
        return cancelled;
      default:
        return textSecondary;
    }
  }

  /// Get color for account type
  static Color getAccountColor(String type) {
    switch (type.toLowerCase()) {
      case 'savings':
        return savingsAccount;
      case 'checking':
        return checkingAccount;
      case 'loan':
        return loanAccount;
      case 'investment':
        return investmentAccount;
      default:
        return primary;
    }
  }

  /// Get gradient for card type
  static List<Color> getCardGradient(String type) {
    switch (type.toLowerCase()) {
      case 'gold':
      case 'premium':
        return gradientGold;
      case 'platinum':
      case 'business':
        return gradientPurple;
      case 'debit':
        return gradientGreen;
      default:
        return gradientBlue;
    }
  }
}