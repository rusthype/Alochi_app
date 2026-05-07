import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/storage.dart';

const _kThemeModeKey = 'theme_mode';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  // Default: light mode always. User can switch to dark in Profile.
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final saved = await AppStorage.readKey(_kThemeModeKey);
    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else {
      // Default to light (includes null / 'light' / 'system')
      state = ThemeMode.light;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final val = mode == ThemeMode.dark ? 'dark' : 'light';
    await AppStorage.writeKey(_kThemeModeKey, val);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }

  /// Called on logout — resets to light mode
  Future<void> resetToLight() async {
    state = ThemeMode.light;
    await AppStorage.writeKey(_kThemeModeKey, 'light');
  }

  bool isDark(BuildContext context) => state == ThemeMode.dark;
}
