import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF111827); // Charcoal
  static const Color secondary = Color(0xFF84CC16); // Lime Green
  static const Color accent = Color(0xFFF97316); // Burnt Orange

  // Semantic Colors
  static const Color success = Color(0xFF15803D); // Forest Green
  static const Color error = Color(0xFFDC2626); // Crimson Red
  static const Color info = Color(0xFF64748B); // Slate Grey

  // Surface Colors
  static const Color background = Color(0xFF090A0F);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFF1F2937);
  static const Color onSurface = Color(0xFFF8FAFC);
  static const Color onSurfaceVariant = Color(0xFF94A3B8);

  // Spacing
  static const double space50 = 4.0;
  static const double space100 = 8.0;
  static const double space150 = 12.0;
  static const double space200 = 16.0;
  static const double space300 = 24.0;
  static const double space400 = 32.0;
  static const double space500 = 40.0;
  static const double space600 = 48.0;

  // Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: secondary,
      onPrimary: primary,
      secondary: accent,
      onSecondary: primary,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: onSurface),
        titleTextStyle: const TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: secondary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600, color: onSurface),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: secondary);
          }
          return const IconThemeData(color: Colors.white70);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceVariant,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: secondary, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white54),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(color: onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w400),
      ),
    );
  }
}
