// lib/core/theme.dart
// IntegraTax Design System - Emerald Green Edition
// Defines the full color palette, typography, and component themes.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._(); // Prevent instantiation

  // Brand (Emerald Green)
  static const Color primary = Color(0xFF00C689);
  static const Color primaryLight = Color(0xFF00E6A0);
  static const Color primaryDark = Color(0xFF009B74);

  // Backgrounds - Layered dark system
  static const Color bgBase = Color(0xFF070B14); // Deepest layer
  static const Color bgSurface = Color(0xFF111620); // Cards & panels
  static const Color bgElevated = Color(0xFF161D2B); // Elevated cards
  static const Color bgInput = Color(0xFF1A2236); // Input fields, chips

  // Borders
  static const Color borderSubtle = Color(0xFF1E2638);
  static const Color borderNormal = Color(0xFF2A344A);
  static const Color borderBright = Color(0xFF00C689);

  // Status Colors (Solid)
  static const Color statusOk = Color(0xFF00C689);
  static const Color statusWarning = Color(0xFFFFC107);
  static const Color statusError = Color(0xFFFF4D4D);
  static const Color statusOffline = Color(0xFF6B7FA3);

  // Status Glow (30% Opacity - Hex 4D)
  static const Color statusOkGlow = Color(0x4D00C689);
  static const Color statusWarningGlow = Color(0x4DFFC107);
  static const Color statusErrorGlow = Color(0x4DFF4D4D);

  // Status Subtle (10% Opacity - Hex 1A)
  static const Color statusOkSubtle = Color(0x1A00C689);
  static const Color statusWarningSubtle = Color(0x1AFFC107);
  static const Color statusErrorSubtle = Color(0x1AFF4D4D);
  static const Color statusOfflineSubtle = Color(0x1A6B7FA3);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0ABC0);
  static const Color textMuted = Color(0xFF6B7A99);
  static const Color textAccent = Color(0xFF5CC2E6);

  // Chart (Disesuaikan dengan tema Emerald)
  static const Color chartLine = Color(0xFF00C689);
  static const Color chartGradientTop = Color(0x6600C689); // 40% Emerald
  static const Color chartGradientBottom = Color(0x0000C689); // 0% Emerald
  static const Color chartGrid = Color(0xFF1A2440);
}

// ─── Typography ───────────────────────────────────────────────────────────────
class AppTypography {
  AppTypography._();

  // Display font for headings (geometric, authoritative)
  static TextStyle displayLarge(BuildContext context) => GoogleFonts.barlow(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium(BuildContext context) => GoogleFonts.barlow(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  // Monospace for data values
  static TextStyle dataLarge(BuildContext context) => GoogleFonts.jetBrainsMono(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle dataMedium(BuildContext context) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      );

  static TextStyle dataSmall(BuildContext context) => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 0.4,
  );

  // Body font (clean and readable)
  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 0.2,
  );

  static TextStyle labelCaps(BuildContext context) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 1.5,
  );
}

// ─── Theme Data ───────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgBase,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.bgSurface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.barlow(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 0,
      ),
    );
  }
}

// ─── Shared Decorations ───────────────────────────────────────────────────────
class AppDecorations {
  AppDecorations._();

  /// Standard surface card with subtle border
  static BoxDecoration card({Color? borderColor, double borderWidth = 1}) =>
      BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? AppColors.borderSubtle,
          width: borderWidth,
        ),
      );

  /// Elevated card (e.g., highlighted or selected)
  static BoxDecoration cardElevated({Color? accentColor}) => BoxDecoration(
    color: AppColors.bgElevated,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.borderNormal, width: 1),
    boxShadow: accentColor != null
        ? [
            BoxShadow(
              color: accentColor.withValues(
                alpha: 0.12,
              ), // Menggunakan format baru
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ]
        : [],
  );

  /// Section label style small uppercase tracking
  static BoxDecoration sectionBadge(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.12), // Menggunakan format baru
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
  );
}
