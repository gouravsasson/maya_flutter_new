import 'package:flutter/material.dart';

class AppTheme {
  // Single dark theme with splash page colors
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2A57E8),      // Brand blue for primary elements
        background: Color(0xFF111827),   // Dark base background
        onBackground: Colors.white,      // White text on dark bg
        surface: Color(0xFF111827),      // For cards/surfaces (same as bg)
        onSurface: Colors.white,         // Text on surfaces
        onSurfaceVariant: Color(0xFF111827), // Subtle variants
        surfaceVariant: Color.fromRGBO(189, 189, 189, 1), // Subtle grey for hints
        outlineVariant: Color.fromRGBO(189, 189, 189, 1), // Borders/subtle
      ),
      scaffoldBackgroundColor: Color(0xFF111827), // Dark base from splash
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,    // White icons/text on app bar
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A57E8), // Primary blue button bg
          foregroundColor: Colors.white,             // White text on button
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827).withOpacity(0.8), // Dark input bg
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromRGBO(189, 189, 189, 1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A57E8), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(  // For splash title (32px bold white)
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        bodyMedium: TextStyle(      // For splash subtitle (16px white)
          fontSize: 16,
          color: Colors.white,
          height: 1.4,
        ),
        bodySmall: TextStyle(       // For splash loading text (14px subtle grey)
          fontSize: 14,
          color: Color.fromRGBO(189, 189, 189, 1),
        ),
      ),
    );
  }
}