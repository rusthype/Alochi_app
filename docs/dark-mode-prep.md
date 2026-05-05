# A'lochi V1.2 Dark Mode Preparation

This document outlines the strategy for implementing Dark Mode in V1.2 of the A'lochi mobile app.

## Current Progress (V1.1 Build)
- Added color tokens for dark mode in `lib/theme/colors.dart`.
- Preserved all existing color constants to ensure zero impact on current light-only screens.
- Naming convention: `[tokenName]Light` and `[tokenName]Dark`.

## V1.2 Migration Plan

### 1. Theme Data Switch
In V1.2, `AlochiTheme` in `lib/theme/theme.dart` should be expanded to include a `dark` getter:

```dart
static ThemeData get dark {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.brand,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.inkDark,
      // ... other mappings
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    // ...
  );
}
```

### 2. Manual Color Detection
For custom widgets that don't rely purely on `ThemeData` mappings, use the following pattern:

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final cardColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
```

### 3. Guidelines
- **Brand Identity:** The primary `AppColors.brand` (#1F6F65) remains the same in both modes to maintain brand recognition.
- **Surface Elevation:** In dark mode, use slightly lighter shades of `surfaceDark` for elevated cards (Material 3 elevation overlays).
- **Contrast:** Ensure all text colors (Ink) meet WCAG AA standards against their respective backgrounds in dark mode.

## Color Mapping Table

| Token | Light Mode | Dark Mode | Usage |
|---|---|---|---|
| Brand Soft | `AppColors.brandSoftLight` | `AppColors.brandSoftDark` | Subtle backgrounds |
| Surface | `AppColors.surfaceLight` | `AppColors.surfaceDark` | Cards, Sheets |
| Background | `AppColors.backgroundLight` | `AppColors.backgroundDark` | Scaffold background |
| Ink | `AppColors.inkLight` | `AppColors.inkDark` | Primary text |
| Ink Muted | `AppColors.inkMutedLight` | `AppColors.inkMutedDark` | Secondary/Hint text |
