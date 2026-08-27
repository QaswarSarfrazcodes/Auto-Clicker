import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local data source for settings and preferences (SRP separation).
class PreferencesLocalDataSource {
  PreferencesLocalDataSource._();
  static final PreferencesLocalDataSource instance = PreferencesLocalDataSource._();
  factory PreferencesLocalDataSource() => instance;

  static const String _onboardingKey = 'onboarding_complete_flag';
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _collisionKey = 'collision_detection_enabled';
  static const String _launchOnStartupKey = 'launch_on_startup_enabled';
  static const String _appLanguageKey = 'app_language_code';
  static const String _globalHotkeyKey = 'global_hotkey_label';
  static const String _proUserKey = 'pro_user_status_secure'; // renamed to avoid collision

  // Obfuscation key
  static const int _xorMask = 0x5A;

  /// Obfuscate a string value using simple XOR and Base64.
  String _obfuscate(String val) {
    final bytes = utf8.encode(val);
    final obfuscated = bytes.map((b) => b ^ _xorMask).toList();
    return base64.encode(obfuscated);
  }

  /// De-obfuscate a string value.
  String _deobfuscate(String base64Str) {
    try {
      final decoded = base64.decode(base64Str);
      final deobfuscated = decoded.map((b) => b ^ _xorMask).toList();
      return utf8.decode(deobfuscated);
    } catch (_) {
      return '';
    }
  }

  /// Get onboarding status.
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Set onboarding status.
  Future<void> setOnboardingComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, complete);
  }

  /// Dark mode settings
  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  /// Collision detection settings
  Future<bool> getCollisionDetection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_collisionKey) ?? true;
  }

  Future<void> setCollisionDetection(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_collisionKey, value);
  }

  /// Launch on startup settings
  Future<bool> getLaunchOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_launchOnStartupKey) ?? true;
  }

  /// §18 — Dual-write: Flutter-prefixed key (for the app) + raw key (for
  /// BootReceiver which reads SharedPrefs before the Flutter engine starts).
  Future<void> setLaunchOnStartup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_launchOnStartupKey, value);
    // Raw key without 'flutter.' prefix — readable from Kotlin BootReceiver
    await prefs.setBool('launch_on_startup', value);
  }

  /// App language code (e.g. 'en', 'ur') — §4.
  Future<String> getAppLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appLanguageKey) ?? 'en';
  }

  Future<void> setAppLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appLanguageKey, languageCode);
  }

  /// Global hotkey label — §5.
  Future<String?> getGlobalHotkey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_globalHotkeyKey);
  }

  Future<void> setGlobalHotkey(String keyLabel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_globalHotkeyKey, keyLabel);
  }

  /// Pro User status with security obfuscation
  Future<bool> isProUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? obfuscated = prefs.getString(_proUserKey);
    if (obfuscated == null) {
      // Fallback: check legacy unsecure key in case of update
      final legacy = prefs.getBool('pro_user_status');
      if (legacy != null) {
        await setProUser(legacy);
        await prefs.remove('pro_user_status'); // clean up legacy key
        return legacy;
      }
      return false;
    }
    final decrypted = _deobfuscate(obfuscated);
    return decrypted == 'true';
  }

  Future<void> setProUser(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    final String obfuscated = _obfuscate(status.toString());
    await prefs.setString(_proUserKey, obfuscated);
  }
}
