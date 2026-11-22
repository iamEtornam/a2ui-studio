import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'studio_colors.dart';

/// Builds the Obsidian Kinetic IDE (Dark) and Lumen Kinetic (Light) themes.
class AppTheme {
  static ThemeData dark() {
    const c = StudioColors.dark;
    final bodyFamily = GoogleFonts.inter().fontFamily;
    final headingFamily = GoogleFonts.plusJakartaSans().fontFamily;
    final baseText = ThemeData.dark().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: bodyFamily,
      scaffoldBackgroundColor: c.canvasBg,
      colorScheme: ColorScheme.dark(
        primary: c.primaryAccent,
        onPrimary: Colors.white,
        secondary: c.cyanAccent,
        onSecondary: const Color(0xFF00354A),
        surface: c.panelBg,
        onSurface: c.textPrimary,
        surfaceContainerHighest: c.elevatedBg,
        outline: c.borderStrong,
        outlineVariant: c.borderSubtle,
        error: c.danger,
      ),
      textTheme: baseText.copyWith(
        displaySmall: TextStyle(
          fontFamily: headingFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: c.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: headingFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: c.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: headingFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: c.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: headingFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          fontFamily: bodyFamily,
          fontSize: 13.5,
          color: c.textPrimary,
        ),
        bodySmall: baseText.bodySmall?.copyWith(
          fontFamily: bodyFamily,
          fontSize: 12,
          color: c.textSecondary,
        ),
      ),
      dividerColor: c.borderSubtle,
      cardTheme: CardThemeData(
        color: c.panelBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: c.borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.codeBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.primaryAccent, width: 1.5),
        ),
        hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primaryAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.borderSubtle),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.elevatedBg,
        selectedColor: c.primaryAccent.withValues(alpha: 0.28),
        disabledColor: c.elevatedBg.withValues(alpha: 0.5),
        checkmarkColor: c.cyanAccent,
        side: BorderSide(color: c.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return c.textSecondary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return c.primaryAccent;
            }
            return c.elevatedBg;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: c.borderSubtle)),
        ),
      ),
      extensions: const [StudioColors.dark],
    );
  }

  static ThemeData light() {
    const c = StudioColors.light;
    final bodyFamily = GoogleFonts.inter().fontFamily;
    final headingFamily = GoogleFonts.plusJakartaSans().fontFamily;
    final baseText = ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: bodyFamily,
      scaffoldBackgroundColor: c.canvasBg,
      colorScheme: ColorScheme.light(
        primary: c.primaryAccent,
        onPrimary: Colors.white,
        secondary: c.cyanAccent,
        onSecondary: Colors.white,
        surface: c.panelBg,
        onSurface: c.textPrimary,
        surfaceContainerHighest: c.elevatedBg,
        outline: c.borderStrong,
        outlineVariant: c.borderSubtle,
        error: c.danger,
      ),
      textTheme: baseText.copyWith(
        displaySmall: TextStyle(
          fontFamily: headingFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: c.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: headingFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: c.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: headingFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: c.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: headingFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          fontFamily: bodyFamily,
          fontSize: 13.5,
          color: c.textPrimary,
        ),
        bodySmall: baseText.bodySmall?.copyWith(
          fontFamily: bodyFamily,
          fontSize: 12,
          color: c.textSecondary,
        ),
      ),
      dividerColor: c.borderSubtle,
      cardTheme: CardThemeData(
        color: c.panelBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: c.borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.panelBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.primaryAccent, width: 1.5),
        ),
        hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primaryAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.borderSubtle),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.elevatedBg,
        selectedColor: c.primaryAccent.withValues(alpha: 0.14),
        disabledColor: c.elevatedBg.withValues(alpha: 0.5),
        checkmarkColor: c.primaryAccent,
        side: BorderSide(color: c.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: c.primaryAccent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return c.textSecondary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return c.primaryAccent;
            }
            return c.elevatedBg;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: c.borderSubtle)),
        ),
      ),
      extensions: const [StudioColors.light],
    );
  }
}
