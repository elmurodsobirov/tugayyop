import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScadaTheme {
  // Use "const" for better performance
  static const Color quietDark = Color(0xFF0F172A); // Slate 900
  static const Color neonCyan = Color(0xFF06B6D4); // Cyan 500
  static const Color neonPurple = Color(0xFFA855F7); // Purple 500
  static const Color neonGreen = Color(0xFF10B981); // Emerald 500
  static const Color neonRed = Color(0xFFF43F5E); // Rose 500
  static const Color glassBorder = Color(0xFF334155); // Slate 700

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: quietDark,
      primaryColor: neonCyan,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPurple,
        surface: Color(0xFF1E293B), // Slate 800
        error: neonRed,
      ),
      textTheme: TextTheme(
        // "Orbitron" for futuristic headers
        displayLarge: GoogleFonts.orbitron(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.orbitron(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.orbitron(
          color: neonCyan,
          fontWeight: FontWeight.bold,
        ),
        // "JetBrains Mono" for data/numbers
        bodyLarge: GoogleFonts.jetbrainsMono(color: Colors.white),
        bodyMedium: GoogleFonts.jetbrainsMono(color: Colors.white70),
        titleMedium: GoogleFonts.orbitron(
          color: neonCyan,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Glass-like buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: neonCyan.withOpacity(0.5),
          foregroundColor: neonCyan,
          side: const BorderSide(color: neonCyan),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: neonCyan),
        ),
        labelStyle: GoogleFonts.jetbrainsMono(color: Colors.white60),
      ),
    );
  }
}
