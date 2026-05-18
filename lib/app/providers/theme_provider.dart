import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'themeMode';

/// Persists and exposes the user's [ThemeMode] choice.
///
/// Reads the saved value from [SharedPreferences] on first access so the
/// correct theme is applied immediately on launch — no flash of wrong theme.
///
/// Usage anywhere in the app:
///   Read:   ref.watch(themeModeProvider)
///   Write:  ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark)
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _load(SharedPreferences prefs) {
    switch (prefs.getString(_kThemeModeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system; // Follow OS by default
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_kThemeModeKey, mode.name);
  }
}

/// Synchronous provider for [SharedPreferences]. Always overridden in
/// main.dart with the pre-loaded instance so there is never an async gap.
final prefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('prefsProvider must be overridden in main'),
);

/// The main provider to watch/read throughout the app.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final prefs = ref.watch(prefsProvider);
  return ThemeModeNotifier(prefs);
});
