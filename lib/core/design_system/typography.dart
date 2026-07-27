import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class DsTypography {
  // Headings (Fredoka - Lúdico, Amigável, Arredondado)
  static TextStyle get heading1 => GoogleFonts.fredoka(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: DsColors.textHighEmphasis,
        letterSpacing: -0.5,
      );

  static TextStyle get heading2 => GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: DsColors.textHighEmphasis,
        letterSpacing: -0.2,
      );

  static TextStyle get heading3 => GoogleFonts.fredoka(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: DsColors.textHighEmphasis,
      );

  // Body (Nunito - Altíssima Legibilidade, limpo)
  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: DsColors.textMediumEmphasis,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: DsColors.textMediumEmphasis,
      );

  static TextStyle get bodySmall => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: DsColors.textMediumEmphasis,
      );

  // Componentes Específicos
  static TextStyle get buttonText => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );
      
  static TextStyle get badgeText => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.5,
      );
}
