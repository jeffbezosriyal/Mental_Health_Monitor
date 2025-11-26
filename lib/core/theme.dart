import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // -- Color Palette --
  static const Color primaryTeal = Color(0xFF006D77);
  static const Color secondarySage = Color(0xFF83C5BE);
  static const Color backgroundIce = Colors.white;
  static const Color alertCoral = Color(0xFFE29578);
  static const Color textDark = Color(0xFF2D3436);
  static const Color cardWhite = Colors.white;
  static const Color statuscodecalm = Colors.green;

  // -- Text Styles --
  static TextStyle get titleStyle => GoogleFonts.lato(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static TextStyle get headingStyle => GoogleFonts.lato(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static TextStyle get labelStyle => GoogleFonts.lato(
    fontSize: 14,
    color: Colors.grey[600],
  );

  // -- Decorations --
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: cardWhite,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: primaryTeal.withOpacity(0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );
}