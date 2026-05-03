import 'package:flutter/material.dart';

/// A'lochi Teacher v1.1 — Design system color tokens.
/// All values are final; no Color const allowed here (Color() is not const in older SDKs).
abstract final class AppColors {
  // Brand — teal
  static const Color brand = Color(0xFF1F6F65);
  static const Color brandSoft = Color(0xFFE8F2EF);
  static const Color brandLight = Color(0xFFD5E8E1);
  static const Color brandTint = Color(0xFFBCD9D1);
  static const Color brandInk = Color(0xFF0F4F49);
  static const Color brandDarkInk = Color(0xFF0A3A35);
  static const Color brandOnDark = Color(0xFFA8D5CD);
  static const Color brandMuted = Color(0xFF5A8B87);

  // Hero dark
  static const Color heroDark = Color(0xFF0E2E2A);

  // Accent — coral / orange
  static const Color accent = Color(0xFFE8954E);
  static const Color accentSoft = Color(0xFFFCEFE3);
  static const Color accentInk = Color(0xFF7A4218);

  // Semantic
  static const Color success = Color(0xFF0F9A6E);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // Neutrals
  static const Color surface = Color(0xFFFAFAFA);
  static const Color ink = Color(0xFF111827);
}
