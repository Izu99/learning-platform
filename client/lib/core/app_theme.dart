import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors (Green/Teal theme from S5.png design) ──
  static const Color primaryGreen = Color(0xFF1B6B5E);   // Deep teal-green (main brand)
  static const Color primaryTeal  = Color(0xFF009688);   // Medium teal (accents, verified badge)
  static const Color accentGreen  = Color(0xFF2ECC9A);   // Bright mint (highlights)
  static const Color accentRed    = Color(0xFFF43F5E);   // Error / reject
  static const Color primaryBlue  = Color(0xFF1B6B5E);   // Alias kept for backward compatibility

  // ── Background & Surface ──
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface    = Colors.white;

  // ── Text Colors ──
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted     = Color(0xFF94A3B8);

  // ── Semantic helpers ──
  static const Color tagBackground = Color(0xFFE0F7F4); // Mint tag bg (S5.png topic chips)
  static const Color tagText       = Color(0xFF00695C); // Dark teal tag text

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: primaryTeal,
        error: accentRed,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentRed),
        ),
        hintStyle: GoogleFonts.inter(
          color: textMuted,
          fontSize: 15,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          // AppBar title in teal-green, matching S5.png "Teacher Profile" label
          color: primaryGreen,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGreen;
          return null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
      ),
      extensions: const [
        AppDesignTokens.defaultTokens,
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Design Tokens Extension
// ─────────────────────────────────────────────
@immutable
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  final double cardRadius;
  final double buttonRadius;
  final BoxShadow softShadow;
  final BoxShadow deepShadow;

  const AppDesignTokens({
    required this.cardRadius,
    required this.buttonRadius,
    required this.softShadow,
    required this.deepShadow,
  });

  @override
  AppDesignTokens copyWith({
    double? cardRadius,
    double? buttonRadius,
    BoxShadow? softShadow,
    BoxShadow? deepShadow,
  }) {
    return AppDesignTokens(
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      softShadow: softShadow ?? this.softShadow,
      deepShadow: deepShadow ?? this.deepShadow,
    );
  }

  @override
  AppDesignTokens lerp(ThemeExtension<AppDesignTokens>? other, double t) {
    if (other is! AppDesignTokens) return this;
    return AppDesignTokens(
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t),
      buttonRadius: lerpDouble(buttonRadius, other.buttonRadius, t),
      softShadow: BoxShadow.lerp(softShadow, other.softShadow, t)!,
      deepShadow: BoxShadow.lerp(deepShadow, other.deepShadow, t)!,
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  static const defaultTokens = AppDesignTokens(
    cardRadius: 24,
    buttonRadius: 16,
    softShadow: BoxShadow(
      color: Color(0x0A1B6B5E),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
    deepShadow: BoxShadow(
      color: Color(0x121B6B5E),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  );
}
