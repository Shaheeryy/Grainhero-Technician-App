import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ============================================
  // PRIMARY COLORS - Gold Accent Identity
  // ============================================
  static const primaryColor = Color(0xFFD4A843);
  static const primaryLight = Color(0xFFF5C842);
  static const primaryDark = Color(0xFFB8922E);
  
  // ============================================
  // ACCENT COLORS - Sensor Data
  // ============================================
  static const temperatureOrange = Color(0xFFE8A838);
  static const temperatureLight = Color(0xFFFFCC66);
  static const humidityBlue = Color(0xFF4ECDC4);
  static const humidityLight = Color(0xFF7EDDD6);
  static const co2Purple = Color(0xFFBB86FC);
  static const moistureBlue = Color(0xFF64B5F6);
  
  // ============================================
  // STATUS COLORS
  // ============================================
  static const errorColor = Color(0xFFFF4444);
  static const warningColor = Color(0xFFFFAA33);
  static const successColor = Color(0xFF4CAF50);
  static const infoColor = Color(0xFF29B6F6);
  
  // ============================================
  // DARK NEUTRAL COLORS
  // ============================================
  static const backgroundColor = Color(0xFF0D0D0D);
  static const surfaceColor = Color(0xFF1A1A1A);
  static const cardColor = Color(0xFF1E1E1E);
  static const cardColorLight = Color(0xFF252525);
  static const dividerColor = Color(0xFF2A2A2A);
  static const borderColor = Color(0xFF333333);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textHint = Color(0xFF555555);
  static const textGold = Color(0xFFD4A843);

  // ============================================
  // GRADIENTS
  // ============================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryColor],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5C842), Color(0xFFD4A843)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E1E), Color(0xFF161616)],
  );

  static const LinearGradient temperatureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [temperatureLight, temperatureOrange],
  );

  static const LinearGradient humidityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [humidityLight, humidityBlue],
  );

  static const LinearGradient riskGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [successColor, warningColor, errorColor],
  );

  // ============================================
  // SHADOWS (subtle glow for dark mode)
  // ============================================
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  // ============================================
  // BORDER RADIUS
  // ============================================
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusRound = 24.0;
  static const double radiusFull = 50.0;

  // ============================================
  // SPACING
  // ============================================
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;

  // ============================================
  // CARD DECORATION
  // ============================================
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: borderColor, width: 0.5),
    boxShadow: cardShadow,
  );

  static BoxDecoration cardWithAccent(Color accentColor) => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: borderColor, width: 0.5),
    boxShadow: cardShadow,
  );

  static BoxDecoration get pillDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusFull),
    border: Border.all(color: borderColor, width: 0.5),
  );

  static BoxDecoration get goldPillDecoration => BoxDecoration(
    color: primaryColor.withOpacity(0.15),
    borderRadius: BorderRadius.circular(radiusFull),
    border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
  );

  // ============================================
  // THEME DATA
  // ============================================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryLight,
      error: errorColor,
      surface: surfaceColor,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: textPrimary,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: backgroundColor,
      foregroundColor: textPrimary,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: BorderSide(color: borderColor, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      hintStyle: GoogleFonts.inter(
        color: textHint,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.inter(
        color: textSecondary,
        fontSize: 14,
      ),
      prefixIconColor: textSecondary,
      suffixIconColor: textSecondary,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
      elevation: 4,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceColor,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        side: BorderSide(color: borderColor),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: textPrimary,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: textSecondary,
      indicatorColor: primaryColor,
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
    ),
  );

  // Keep lightTheme reference for auth screens
  static ThemeData lightTheme = darkTheme;

  // ============================================
  // HELPER METHODS
  // ============================================
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'stored':
      case 'running':
      case 'healthy':
      case 'on':
        return successColor;
      case 'pending':
      case 'warning':
        return warningColor;
      case 'offline':
      case 'error':
      case 'critical':
      case 'off':
        return errorColor;
      default:
        return textSecondary;
    }
  }

  static Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return errorColor;
      case 'medium':
      case 'moderate':
        return warningColor;
      default:
        return successColor;
    }
  }

  static Color getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return errorColor;
      case 'medium':
        return warningColor;
      case 'low':
      default:
        return successColor;
    }
  }
}
