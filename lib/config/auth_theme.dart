import 'package:flutter/material.dart';

class AuthTheme {
  // =========================
  // Brand Colors
  // =========================

  // Primary
  static const Color primaryGreen = Color(0xFF2FAC0C);
  static const Color primaryGreenDark = Color(0xFF2FAC0C);
  static const Color primaryGreenSoft = Color(0x1F2FAC0C); // 12% opacity

  // Backgrounds
  static const Color greenOverlay = Color(0xFF252D26);
  static const Color beigeBackground = Color(0xFFEDE9D4);
  static const Color cardBackground = Color(0xFFEDE9D4);

  // Text
  static const Color textPrimary = Color(0xFF404F44);
  static const Color textSecondary = Color(0xFF252D26);
  static const Color textHint = Color(0xFF7B847D);

  // Borders & Divider
  static const Color borderLight = Color(0xFFD5D0B9);
  static const Color dividerColor = Color(0xFFD5D0B9);

  // =========================
  // Input Decoration
  // =========================

  static InputDecoration getInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: textHint,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),

      prefixIcon: Icon(
        prefixIcon,
        color: textSecondary,
        size: 20,
      ),

      suffixIcon: suffixIcon,

      filled: true,
      fillColor: Colors.transparent,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: const BorderSide(
          color: borderLight,
          width: 1,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: const BorderSide(
          color: borderLight,
          width: 1,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: const BorderSide(
          color: primaryGreen,
          width: 1.8,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.2,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  // =========================
  // Primary Button
  // =========================

  static ButtonStyle get primaryButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      disabledBackgroundColor: primaryGreen.withValues(alpha: 0.6),
      disabledForegroundColor: Colors.white70,

      elevation: 0,

      padding: const EdgeInsets.symmetric(vertical: 16),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
    );
  }
}