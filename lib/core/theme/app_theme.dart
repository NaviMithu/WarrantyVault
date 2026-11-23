import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand accents
  static const Color primaryLight = Color(0xFF0284C7); // Sky blue
  static const Color primaryDark = Color(0xFF38BDF8);

  // Light Mode Surfaces
  static const Color backgroundLight = Color(0xFFF1F5F9); // Soft grey-blue
  static const Color surfaceLight = Color(0xFFFFFFFF); // White cards
  static const Color textPrimaryLight = Color(0xFF0F172A); // Dark navy
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark Mode Surfaces
  static const Color backgroundDark = Color(0xFF0B1220); // Near-black navy
  static const Color surfaceDark = Color(0xFF162032); // Dark slate card
  static const Color textPrimaryDark = Color(0xFFE2E8F0); // Light slate
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Muted slate
  static const Color borderDark = Color(0xFF1E293B);

  // Warranty Status Colors (Reserved strictly for warranty)
  static const Color statusActive = Color(0xFF10B981); // Emerald green
  static const Color statusExpiring = Color(0xFFF59E0B); // Amber
  static const Color statusExpired = Color(0xFFEF4444); // Crimson red

  // Status Badge Backgrounds (tinted)
  static const Color statusActiveBgLight = Color(0xFFD1FAE5);
  static const Color statusActiveTextLight = Color(0xFF065F46);
  static const Color statusActiveBgDark = Color(0xFF064E3B);
  static const Color statusActiveTextDark = Color(0xFF6EE7B7);

  static const Color statusExpiringBgLight = Color(0xFFFEF3C7);
  static const Color statusExpiringTextLight = Color(0xFF92400E);
  static const Color statusExpiringBgDark = Color(0xFF78350F);
  static const Color statusExpiringTextDark = Color(0xFFFCD34D);

  static const Color statusExpiredBgLight = Color(0xFFFEE2E2);
  static const Color statusExpiredTextLight = Color(0xFF991B1B);
  static const Color statusExpiredBgDark = Color(0xFF7F1D1D);
  static const Color statusExpiredTextDark = Color(0xFFFCA5A5);
}

class AppTheme {
  static ThemeData light() {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
      displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
      displaySmall: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
      headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      titleSmall: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: AppColors.textPrimaryLight),
      bodyLarge: GoogleFonts.inter(color: AppColors.textPrimaryLight),
      bodyMedium: GoogleFonts.inter(color: AppColors.textSecondaryLight),
      bodySmall: GoogleFonts.inter(color: AppColors.textSecondaryLight),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryLight,
        brightness: Brightness.light,
        surface: AppColors.surfaceLight,
        primary: AppColors.primaryLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.statusExpired),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 24,
      ),
    );
  }

  static ThemeData dark() {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
      displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
      displaySmall: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
      headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
      headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
      titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
      titleSmall: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: AppColors.textPrimaryDark),
      bodyLarge: GoogleFonts.inter(color: AppColors.textPrimaryDark),
      bodyMedium: GoogleFonts.inter(color: AppColors.textSecondaryDark),
      bodySmall: GoogleFonts.inter(color: AppColors.textSecondaryDark),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryDark,
        brightness: Brightness.dark,
        surface: AppColors.surfaceDark,
        primary: AppColors.primaryDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: const Color(0xFF0F172A),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.statusExpired),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 24,
      ),
    );
  }
}
