import 'package:flutter/material.dart';

/// A'lochi Teacher v1.1 — Design system color tokens.
/// All values are final; no Color const allowed here (Color() is not const in older SDKs).
abstract final class AppColors {
  // Brand — teal (Shared)
  static const Color brand = Color(0xFF1F6F65);
  static const Color brandDeep = Color(0xFF155248);
  static const Color brandInk = Color(0xFF0F4F49);
  static const Color brandDarkInk = Color(0xFF0A3A35);
  static const Color brandMuted = Color(0xFF5A8B87);

  // Accent — coral / orange (Shared)
  static const Color accent = Color(0xFFE8954E);
  static const Color accentSoft = Color(0xFFFCEFE3);
  static const Color accentInk = Color(0xFF7A4218);

  // Semantic (Shared)
  static const Color success = Color(0xFF0F9A6E);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // --- Light mode (V1.1 Legacy & Default) ---
  static const Color brandSoft = Color(0xFFE8F2EF);
  static const Color brandLight = Color(0xFFD5E8E1);
  static const Color brandTint = Color(0xFFBCD9D1);
  static const Color brandOnDark = Color(0xFFA8D5CD);
  static const Color heroDark = Color(0xFF0E2E2A);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color ink = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color gray2 = Color(0xFF9CA3AF);
  static const Color gray3 = Color(0xFFD1D5DB);
  static const Color line = Color(0xFFE5E7EB);
  static const Color lineSoft = Color(0xFFF4F5F7);

  // --- V1.2 Dark Mode Tokens ---
  static const Color darkBg = Color(0xFF0E1514);
  static const Color darkSurface = Color(0xFF1A2422);
  static const Color darkCard = Color(0xFF1F2D2B);
  static const Color darkBorder = Color(0xFF2A3D3A);
  static const Color darkInk = Color(0xFFF0F4F3);
  static const Color darkMuted = Color(0xFF8BA8A3);

  // Dark mode brand variants
  static const Color brandSoftDark = Color(0xFF1A3D38);
}
