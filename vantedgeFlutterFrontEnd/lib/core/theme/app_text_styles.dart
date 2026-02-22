import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App text styles following Material 3 typography scale
/// Uses Google Fonts (Poppins) for professional banking aesthetic
class AppTextStyles {
  AppTextStyles._();

  // Base Font Family
  static String get fontFamily => GoogleFonts.poppins().fontFamily!;
  static String get numberFontFamily => GoogleFonts.robotoMono().fontFamily!;

  // Display Styles - Largest text (Hero sections, Landing pages)
  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
    color: AppColors.textPrimary,
  );

  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
    color: AppColors.textPrimary,
  );

  static TextStyle displaySmall = GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
    color: AppColors.textPrimary,
  );

  // Headline Styles - High-emphasis text (Page titles, Section headers)
  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineSmall = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
    color: AppColors.textPrimary,
  );

  // Title Styles - Medium-emphasis text (Card titles, List titles)
  static TextStyle titleLarge = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
    color: AppColors.textPrimary,
  );

  static TextStyle titleMedium = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.50,
    color: AppColors.textPrimary,
  );

  static TextStyle titleSmall = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  // Body Styles - Regular text (Paragraphs, Descriptions)
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.textSecondary,
  );

  // Label Styles - Low-emphasis text (Buttons, Captions, Labels)
  static TextStyle labelLarge = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  static TextStyle labelMedium = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
    color: AppColors.textPrimary,
  );

  static TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // Custom Banking Styles

  /// Bank logo text style
  static TextStyle bankLogo = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.primary,
  );

  /// Currency amount styles - Large
  static TextStyle currencyLarge = GoogleFonts.robotoMono(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// Currency amount styles - Medium
  static TextStyle currencyMedium = GoogleFonts.robotoMono(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
    color: AppColors.textPrimary,
  );

  /// Currency amount styles - Small
  static TextStyle currencySmall = GoogleFonts.robotoMono(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.44,
    color: AppColors.textPrimary,
  );

  /// Account number / Card number style (monospace)
  static TextStyle accountNumber = GoogleFonts.robotoMono(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.0,
    color: AppColors.textSecondary,
  );

  /// Error text style
  static TextStyle errorText = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.error,
  );

  /// Success text style
  static TextStyle successText = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.success,
  );

  /// Warning text style
  static TextStyle warningText = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.warning,
  );

  /// Info text style
  static TextStyle infoText = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.info,
  );

  /// Button text style
  static TextStyle button = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.43,
    color: AppColors.onPrimary,
  );

  /// Chip/Badge text style
  static TextStyle chip = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  /// Overline text style (Small uppercase labels)
  static TextStyle overline = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.6,
    color: AppColors.textSecondary,
  ).copyWith(
    fontFeatures: [const FontFeature.enable('smcp')], // Small caps
  );

  /// Caption text style
  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.textSecondary,
  );

  /// Hint text style
  static TextStyle hint = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.textHint,
  );

  // Dark Theme Text Styles
  static TextStyle displayLargeDark = displayLarge.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle displayMediumDark = displayMedium.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle displaySmallDark = displaySmall.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle headlineLargeDark = headlineLarge.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle headlineMediumDark = headlineMedium.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle headlineSmallDark = headlineSmall.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle titleLargeDark = titleLarge.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle titleMediumDark = titleMedium.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle titleSmallDark = titleSmall.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle bodyLargeDark = bodyLarge.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle bodyMediumDark = bodyMedium.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle bodySmallDark = bodySmall.copyWith(
    color: AppColors.textSecondaryDark,
  );

  static TextStyle labelLargeDark = labelLarge.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle labelMediumDark = labelMedium.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle labelSmallDark = labelSmall.copyWith(
    color: AppColors.textSecondaryDark,
  );

  /// Get TextTheme for light theme
  static TextTheme get lightTextTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );

  /// Get TextTheme for dark theme
  static TextTheme get darkTextTheme => TextTheme(
        displayLarge: displayLargeDark,
        displayMedium: displayMediumDark,
        displaySmall: displaySmallDark,
        headlineLarge: headlineLargeDark,
        headlineMedium: headlineMediumDark,
        headlineSmall: headlineSmallDark,
        titleLarge: titleLargeDark,
        titleMedium: titleMediumDark,
        titleSmall: titleSmallDark,
        bodyLarge: bodyLargeDark,
        bodyMedium: bodyMediumDark,
        bodySmall: bodySmallDark,
        labelLarge: labelLargeDark,
        labelMedium: labelMediumDark,
        labelSmall: labelSmallDark,
      );
}