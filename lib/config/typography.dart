import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextStyle headingStyle({
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
  }) {
    return GoogleFonts.lexend(
      color: color,
      fontSize: fontSize,
      height: height,
      fontWeight: fontWeight,
      letterSpacing: -0.25,
    );
  }

  static TextStyle bodyStyle({
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      color: color,
      fontSize: fontSize,
      height: height,
      fontWeight: fontWeight,
    );
  }
}