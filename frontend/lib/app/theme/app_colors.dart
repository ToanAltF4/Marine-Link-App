import 'package:flutter/material.dart';

/// MarineLink color tokens.
///
/// Bảng màu tập trung của design system (dựa trên
/// `stitch_marinelink_b2b_seafood_ui_kit`). Tách riêng khỏi [AppTheme] để
/// dùng làm nguồn màu duy nhất cho toàn app.
abstract class AppColors {
  static const primary = Color(0xFF0B4F8F);
  static const primaryDark = Color(0xFF052449);
  static const secondary = Color(0xFF00A6B4);
  static const accent = Color(0xFF1E84C6);
  static const background = Color(0xFFF4FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSky = Color(0xFFEAF6FF);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFD8E7EF);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);

  static const orderPending = Color(0xFFF59E0B);
  static const orderConfirmed = Color(0xFF1E84C6);
  static const orderShipping = Color(0xFF0284C7);
  static const orderCompleted = Color(0xFF16A34A);
  static const orderCancelled = Color(0xFFDC2626);
  static const stockAvailable = Color(0xFF16A34A);
  static const stockLow = Color(0xFFF59E0B);
  static const stockOut = Color(0xFFDC2626);
  static const priceHighlight = Color(0xFF0B4F8F);

  static const oceanGradient = LinearGradient(
    colors: [primaryDark, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
