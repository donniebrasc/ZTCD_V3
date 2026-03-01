import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Automotive dark-dashboard theme.
///
/// Palette:
///   background  #0A0A0F  (near-black, carbon fibre)
///   surface     #13131A  (dark panel)
///   container   #1E1E2A  (raised panel)
///   primary     #E53935  (racing red)
///   secondary   #FF8F00  (amber / warning)
///   tertiary    #00D4FF  (electric blue – connected)
///   onSurface   #E8E8E8  (off-white text)

class AppTheme {
  AppTheme._();

  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color background    = Color(0xFF0A0A0F);
  static const Color surface       = Color(0xFF13131A);
  static const Color surfaceVar    = Color(0xFF1E1E2A);
  static const Color racingRed     = Color(0xFFE53935);
  static const Color amber         = Color(0xFFFF8F00);
  static const Color electricBlue  = Color(0xFF00D4FF);
  static const Color successGreen  = Color(0xFF00C853);
  static const Color onSurface     = Color(0xFFE8E8E8);
  static const Color onSurfaceDim  = Color(0xFF9E9E9E);

  static ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: racingRed,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF7B1111),
      onPrimaryContainer: const Color(0xFFFFDAD6),
      secondary: amber,
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF6E3900),
      onSecondaryContainer: const Color(0xFFFFDDB4),
      tertiary: electricBlue,
      onTertiary: Colors.black,
      tertiaryContainer: const Color(0xFF003545),
      onTertiaryContainer: const Color(0xFFB8EAFF),
      error: const Color(0xFFFF5252),
      onError: Colors.black,
      errorContainer: const Color(0xFF930006),
      onErrorContainer: const Color(0xFFFFDAD4),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceVar,
      onSurfaceVariant: onSurfaceDim,
      outline: const Color(0xFF444455),
      outlineVariant: const Color(0xFF2A2A38),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: onSurface,
      onInverseSurface: surface,
      inversePrimary: const Color(0xFFB71C1C),
    );

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,

      // ── Typography ──────────────────────────────────────────────────────
      textTheme: GoogleFonts.rajdhaniTextTheme(base.textTheme).copyWith(
        // Large readout values use Orbitron (digital dashboard feel)
        headlineLarge: GoogleFonts.orbitron(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
        headlineMedium: GoogleFonts.orbitron(
          color: onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
        headlineSmall: GoogleFonts.orbitron(
          color: onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        // Labels & body use Rajdhani (clean, slightly technical)
        titleLarge: GoogleFonts.rajdhani(
          color: onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
        titleMedium: GoogleFonts.rajdhani(
          color: onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
        titleSmall: GoogleFonts.rajdhani(
          color: onSurfaceDim,
          fontWeight: FontWeight.w500,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
        bodyLarge: GoogleFonts.rajdhani(
          color: onSurface,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.rajdhani(
          color: onSurface,
          fontSize: 13,
        ),
        bodySmall: GoogleFonts.rajdhani(
          color: onSurfaceDim,
          fontSize: 11,
        ),
        labelLarge: GoogleFonts.rajdhani(
          color: onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 1,
        ),
        labelMedium: GoogleFonts.rajdhani(
          color: onSurfaceDim,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.rajdhani(
          color: onSurfaceDim,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.orbitron(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: onSurface),
        actionsIconTheme: const IconThemeData(color: onSurface),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF2A2A38), width: 1),
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2A2A38), width: 1),
        ),
      ),

      // ── NavigationBar ───────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: racingRed.withOpacity(0.25),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: racingRed, size: 22);
          }
          return IconThemeData(color: onSurfaceDim, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.rajdhani(
              color: racingRed,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.5,
            );
          }
          return GoogleFonts.rajdhani(
            color: onSurfaceDim,
            fontSize: 11,
          );
        }),
        elevation: 0,
        height: 64,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ── Buttons ─────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: racingRed,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(0, 44),
        ),
      ),

      // ── Input fields ────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVar,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF444455)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF444455)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: racingRed, width: 2),
        ),
        labelStyle: GoogleFonts.rajdhani(color: onSurfaceDim),
        hintStyle: GoogleFonts.rajdhani(
            color: onSurfaceDim.withOpacity(0.5)),
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVar,
        selectedColor: racingRed.withOpacity(0.25),
        labelStyle: GoogleFonts.rajdhani(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        side: const BorderSide(color: Color(0xFF444455)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),

      // ── Snack bar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVar,
        contentTextStyle: GoogleFonts.rajdhani(color: onSurface, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A38),
        thickness: 1,
        space: 1,
      ),

      // ── Floating action button ───────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: racingRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
