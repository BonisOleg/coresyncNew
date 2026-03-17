import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CoreSyncColors {
  CoreSyncColors._();

  static const Color bg = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color glass = Color(0xFF1A1A1A);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color textPrimary = Color(0xEBFFFFFF);
  static const Color textSecondary = Color(0x8CFFFFFF);
  static const Color textMuted = Color(0x59FFFFFF);
  static const Color accent = Color(0xCCFFFFFF);
}

class CoreSyncTheme {
  CoreSyncTheme._();

  static ThemeData get dark {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CoreSyncColors.bg,
      textTheme: textTheme.apply(
        bodyColor: CoreSyncColors.textPrimary,
        displayColor: CoreSyncColors.textPrimary,
      ),
      colorScheme: const ColorScheme.dark(
        surface: CoreSyncColors.surface,
        primary: CoreSyncColors.accent,
        onPrimary: CoreSyncColors.bg,
        onSurface: CoreSyncColors.textPrimary,
        onSurfaceVariant: CoreSyncColors.textSecondary,
        outline: CoreSyncColors.glassBorder,
      ),
      cardTheme: CardThemeData(
        color: CoreSyncColors.glass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CoreSyncColors.glassBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: CoreSyncColors.bg,
        foregroundColor: CoreSyncColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: CoreSyncColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CoreSyncColors.surface,
        selectedItemColor: CoreSyncColors.accent,
        unselectedItemColor: CoreSyncColors.textMuted,
      ),
      dividerTheme: const DividerThemeData(
        color: CoreSyncColors.glassBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CoreSyncColors.glass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CoreSyncColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CoreSyncColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CoreSyncColors.accent),
        ),
        labelStyle: const TextStyle(color: CoreSyncColors.textSecondary),
        hintStyle: const TextStyle(color: CoreSyncColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CoreSyncColors.accent,
          foregroundColor: CoreSyncColors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CoreSyncColors.accent,
        ),
      ),
    );
  }
}
