import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider delle impostazioni globali (auto-lock, clipboard, tema, lingua).
///
/// Note di sicurezza:
/// - Salviamo solo preferenze non-sensibili in `SharedPreferences`.
/// - I segreti (master password, key file) NON passano mai da qui.

const _kAutoLockSeconds = 'settings.autoLockSeconds';
const _kClipboardClearSeconds = 'settings.clipboardClearSeconds';
const _kThemeMode = 'settings.themeMode';
const _kLocale = 'settings.locale';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

final autoLockTimeoutSecondsProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  return prefs?.getInt(_kAutoLockSeconds) ?? 60;
});

final clipboardClearSecondsProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  return prefs?.getInt(_kClipboardClearSeconds) ?? 30;
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  final raw = prefs?.getString(_kThemeMode);
  return switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

final localeProvider = StateProvider<Locale?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  final raw = prefs?.getString(_kLocale);
  if (raw == null || raw.isEmpty) return null; // system
  return Locale(raw);
});

/// Persistenza one-shot dei settings (chiamata dalle schermate di Settings).
class SettingsRepo {
  SettingsRepo(this._prefs);
  final SharedPreferences _prefs;

  Future<void> setAutoLockSeconds(int v) =>
      _prefs.setInt(_kAutoLockSeconds, v);
  Future<void> setClipboardClearSeconds(int v) =>
      _prefs.setInt(_kClipboardClearSeconds, v);
  Future<void> setThemeMode(ThemeMode m) =>
      _prefs.setString(_kThemeMode, m.name);
  Future<void> setLocale(Locale? l) =>
      _prefs.setString(_kLocale, l?.languageCode ?? '');
}

final settingsRepoProvider = FutureProvider<SettingsRepo>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsRepo(prefs);
});
