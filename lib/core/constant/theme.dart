import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgeTheme {
  // Light Aesthetic Color Palette from Screenshot
  static const Color background = Color(0xFFF2F1ED); // Soft off-white
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color brandBlue = Color(0xFF1D4ED8);   // Vibrant royal blue
  static const Color textDark = Color(0xFF0F172A);    // Rich slate dark text
  static const Color textMuted = Color(0xFF64748B);   // Soft gray for body text
  static const Color dotInactive = Color(0xFFCBD5E1); // Inactive slide dot

  // Typography
  static TextStyle displayHeader = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textDark,
    height: 1.1,
  );

  static TextStyle bodyText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.4,
  );

  static TextStyle actionButtonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: surfaceWhite,
  );
}