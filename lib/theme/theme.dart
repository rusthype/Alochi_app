import 'package:flutter/material.dart';
import 'colors.dart';
import 'radii.dart';
import 'typography.dart';

abstract final class AlochiTheme {
  // Shared button style
  static ButtonStyle get _primaryButton => ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.m)),
        ),
        textStyle: AppTextStyles.button,
      );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: AppColors.brand,
        onPrimary: Colors.white,
        primaryContainer: AppColors.brandSoft,
        onPrimaryContainer: AppColors.brandInk,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      splashColor: AppColors.brandSoft,
      highlightColor: AppColors.brandSoft,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.l)),
          side: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.brandSoft,
        border: const Color(0xFFD1D5DB),
        label: AppColors.brandMuted,
        hint: const Color(0xFF9CA3AF),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _primaryButton),
      dividerColor: const Color(0xFFE5E7EB),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brand;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
    );
  }

  static ThemeData get dark {
    // Clean neutral dark — not greenish, easy on eyes
    const bg = Color(0xFF111318); // near-black neutral
    const surface = Color(0xFF1C1E26); // dark blue-grey surface
    const card = Color(0xFF232630); // slightly lighter card
    const border = Color(0xFF2E3240); // subtle border
    const ink = Color(0xFFF0F2FF); // near-white text
    const muted = Color(0xFF8B90A8); // muted grey-blue text

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brand,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1A3330),
        onPrimaryContainer: Color(0xFF9FD8D0),
        surface: surface,
        onSurface: ink,
        error: AppColors.danger,
        outline: border,
        surfaceContainerHighest: card,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: border,
      splashColor: AppColors.brand.withValues(alpha: 0.08),
      highlightColor: AppColors.brand.withValues(alpha: 0.05),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        iconTheme: IconThemeData(color: ink),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.l)),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: _inputTheme(
        fill: card,
        border: border,
        label: muted,
        hint: muted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _primaryButton),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: muted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brand;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: border, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brand;
          return muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brand.withValues(alpha: 0.3);
          }
          return border;
        }),
      ),
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color label,
    required Color hint,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.s)),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.s)),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
        borderSide: BorderSide(color: AppColors.brand, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
        borderSide: BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
        borderSide: BorderSide(color: AppColors.danger, width: 1.5),
      ),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: label,
      ),
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: hint,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
