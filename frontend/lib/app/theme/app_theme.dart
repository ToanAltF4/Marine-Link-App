import 'package:flutter/material.dart';

import 'app_colors.dart';

// Re-export color tokens để mọi file đang import `app_theme.dart` vẫn dùng
// được `AppColors` sau khi tách ra file riêng.
export 'app_colors.dart';

/// MarineLink design system based on `stitch_marinelink_b2b_seafood_ui_kit`.
abstract class AppTheme {
  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryDark,
          onPrimaryContainer: const Color(0xFFD4E3FF),
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.surfaceSky,
          onSecondaryContainer: AppColors.primaryDark,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.border,
          outlineVariant: const Color(0xFFE2E8F0),
          error: AppColors.error,
          onError: Colors.white,
          surfaceContainerLowest: AppColors.surface,
          surfaceContainerLow: const Color(0xFFF7FBFF),
          surfaceContainer: const Color(0xFFEAF6FF),
          surfaceContainerHigh: const Color(0xFFE3F0FB),
          surfaceContainerHighest: const Color(0xFFDCEBF9),
        );

    final baseTextTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
    ).textTheme;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: 30,
          height: 38 / 30,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: 24,
          height: 32 / 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 20,
          height: 28 / 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 17,
          height: 24 / 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 15,
          height: 22 / 15,
          color: AppColors.textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 13,
          height: 20 / 13,
          color: AppColors.textSecondary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 12,
          height: 18 / 12,
          color: AppColors.textSecondary,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 15,
          height: 20 / 15,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontSize: 12,
          height: 18 / 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primaryDark,
        secondarySelectedColor: AppColors.primaryDark,
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerColor: const Color(0xFFE2E8F0),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData dark() {
    final lightTheme = light();
    final darkScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return lightTheme.copyWith(
      colorScheme: darkScheme,
      scaffoldBackgroundColor: const Color(0xFF08121E),
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF08121E),
        foregroundColor: Colors.white,
      ),
    );
  }
}

