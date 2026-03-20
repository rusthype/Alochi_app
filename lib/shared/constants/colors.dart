import 'package:flutter/material.dart';

const kBgMain    = Color(0xFF0D0F1A);
const kBgCard    = Color(0xFF13162A);
const kBgBorder  = Color(0xFF1E2240);
const kOrange    = Color(0xFFF97316);
const kGreen     = Color(0xFF22C55E);
const kYellow    = Color(0xFFEAB308);
const kRed       = Color(0xFFEF4444);
const kBlue      = Color(0xFF3B82F6);
const kPurple    = Color(0xFFA855F7);
const kTextPrimary   = Color(0xFFFFFFFF);
const kTextSecondary = Color(0xFF8B92B3);
const kTextMuted     = Color(0xFF4A5080);

Color scoreColor(num score) {
  if (score >= 90) return kGreen;
  if (score >= 75) return kTextPrimary;
  if (score >= 60) return kYellow;
  return kRed;
}

Color avatarColor(String name) {
  const colors = [kOrange, kBlue, kGreen, kPurple, Color(0xFF06B6D4), Color(0xFFEC4899)];
  int hash = 0;
  for (final c in name.codeUnits) {
    hash = (hash * 31 + c) & 0xFFFFFFFF;
  }
  return colors[hash % colors.length];
}
