import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.azulCeleste,
        primary: AppColors.azulCeleste,
        secondary: AppColors.amareloSol,
        tertiary: AppColors.verdePasto,
        background: AppColors.background,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.poppins(color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.poppins(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56), // Touch targets grandes
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      // cardTheme removed due to compilation error
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.azulCeleste,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
    );
  }

  static ThemeData highContrastTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.highContrastLight(),
      textTheme: GoogleFonts.poppinsTextTheme(),
    );
  }
}
