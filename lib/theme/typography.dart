import 'package:flutter/material.dart';

/// A'lochi Teacher v1.1 — Design system text styles.
/// Font family: Inter (system fallback on Day 0 — font asset added later).
abstract final class AppTextStyles {
  static const String _font = 'Inter';

  static const TextStyle displayL = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle displayM = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle titleL = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleM = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyS = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle monoCode = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );
}
