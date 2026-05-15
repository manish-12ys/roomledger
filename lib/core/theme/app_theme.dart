import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors (Premium Teal & Cyan Night Palette)
  static const Color primary = Color(0xFFF8FAFC);
  static const Color secondary = Color(0xFF2DD4BF); // Bright Aqua
  static const Color accent = Color(0xFF60A5FA); // Crisp Sky Blue

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // Surface Colors (Deep Night Surfaces)
  static const Color background = Color(0xFF02060E);
  static const Color surface = Color(0xFF08111F);
  static const Color surfaceVariant = Color(0xFF0E1728);
  static const Color surfaceContainer = Color(0xFF111D2E);
  static const Color surfaceElevated = Color(0xFF14213B);
  static const Color onSurface = Color(0xFFF8FAFC);
  static const Color onSurfaceVariant = Color(0xFF9BB3D1);
  static const Color muted = Color(0xFF6D84A1);
  static const Color disabled = Color(0xFF334559);

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
  static const double radiusSmall = 16.0;
  static const double radiusMedium = 24.0;
  static const double radiusLarge = 32.0;
  static const double radiusXLarge = 40.0;

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animSpring = Duration(milliseconds: 700);

  // Animation Curves
  static const Curve animCurve = Curves.easeOutCirc;
  static const Curve animSpringCurve = Curves.elasticOut;

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: secondary,
      onPrimary: background,
      secondary: accent,
      onSecondary: background,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: background,
      surfaceContainerHighest: surfaceVariant,
      outline: muted,
      shadow: Colors.black,
      scrim: Colors.black87,
    );

    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: onSurface),
        titleTextStyle: GoogleFonts.outfit(
          color: onSurface,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceElevated.withValues(alpha: 0.94),
        indicatorColor: secondary.withValues(alpha: 0.25),
        height: 76,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontWeight: FontWeight.w600, color: onSurface, fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: secondary, size: 28);
          }
          return IconThemeData(color: onSurfaceVariant, size: 26);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: background,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceVariant,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: space200, vertical: space200),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: secondary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: onSurfaceVariant),
        hintStyle: GoogleFonts.inter(color: muted),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(color: onSurface, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.0),
        displayMedium: GoogleFonts.outfit(color: onSurface, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        titleLarge: GoogleFonts.outfit(color: onSurface, fontSize: 24, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.inter(color: onSurface, fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.inter(color: onSurface, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: onSurface, fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.inter(color: onSurface, fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    );
  }
}
