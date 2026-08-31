import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/session_fatigue_presets.dart';

/// Extension of PreferencesLocalDataSource to add Session Fatigue settings.
/// Stored in SharedPreferences under well-known keys.
class FatiguePreferencesDataSource {
  FatiguePreferencesDataSource._();
  static final FatiguePreferencesDataSource instance =
      FatiguePreferencesDataSource._();

  static const String _presetIndexKey = 'session_fatigue_preset_index';
  static const String _customMinutesKey = 'session_fatigue_custom_minutes';
  static const String _graceWindowMinutesKey = 'session_fatigue_grace_window_minutes';

  /// Saves the selected preset index. Defaults to [kDefaultFatiguePreset].
  Future<void> setFatiguePresetIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_presetIndexKey, index);
  }

  /// Gets the saved preset index. Defaults to [kDefaultFatiguePreset].
  Future<int> getFatiguePresetIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_presetIndexKey) ?? kDefaultFatiguePreset.index;
  }

  /// Saves custom duration in minutes (for [SessionFatiguePreset.custom]).
  Future<void> setCustomFatigueLimitMinutes(int? minutes) async {
    final prefs = await SharedPreferences.getInstance();
    if (minutes == null) {
      await prefs.remove(_customMinutesKey);
    } else {
      await prefs.setInt(_customMinutesKey, minutes.clamp(5, 480));
    }
  }

  /// Gets custom duration in minutes. Returns null if not set.
  Future<int?> getCustomFatigueLimitMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_customMinutesKey);
  }

  /// Saves grace window in minutes.
  Future<void> setGraceWindowMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_graceWindowMinutesKey, minutes.clamp(1, 30));
  }

  /// Gets grace window in minutes. Defaults to 5.
  Future<int> getGraceWindowMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_graceWindowMinutesKey) ??
        kDefaultFatigueGraceWindow.inMinutes;
  }
}
