import 'package:flutter/material.dart';
import 'colors.dart';
import 'radii.dart';
import 'typography.dart';

/// A'lochi Teacher v1.1 — Material 3 light theme.
abstract final class AlochiTheme {
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
          fontSize: 20,
          height: 28 / 20,
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
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.brandSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
          borderSide: BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
          borderSide: BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
          borderSide: BorderSide(color: AppColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w500,
          color: AppColors.brandMuted,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          height: 22 / 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFF9CA3AF),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.m)),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brand,
        onPrimary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkInk,
        error: AppColors.danger,
        outline: AppColors.darkBorder,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          height: 28 / 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkInk,
        ),
        iconTheme: IconThemeData(color: AppColors.darkInk),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.l)),
          side: BorderSide(color: AppColors.darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
          borderSide: BorderSide(color: AppColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.s)),
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w500,
          color: AppColors.darkMuted,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          height: 22 / 15,
          fontWeight: FontWeight.w400,
          color: AppColors.darkMuted,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.m)),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
    );
  }
}
