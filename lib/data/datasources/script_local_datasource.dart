import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/util/logger.dart';
import '../../domain/entities/script_entity.dart';

/// Local data source for saving and loading scripts using SharedPreferences.
class ScriptLocalDataSource {
  // Private constructor and singleton instance for DIP compliance
  ScriptLocalDataSource._();
  static final ScriptLocalDataSource instance = ScriptLocalDataSource._();
  factory ScriptLocalDataSource() => instance;

  static const String _legacyScriptsKey = 'auto_clicker_saved_scripts';
  static const String _scriptIndexKey = 'auto_clicker_script_index';
  static const String _scriptKeyPrefix = 'auto_clicker_script_';

  /// Save a new or updated script locally to disk (O(1) serialization/write).
  Future<bool> saveScript(ScriptEntity script) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save individual script under its own key
      final String encoded = jsonEncode(script.toJson());
      final bool scriptSaved = await prefs.setString('$_scriptKeyPrefix${script.id}', encoded);

      if (!scriptSaved) return false;

      // Update script index list
      final List<String> index = prefs.getStringList(_scriptIndexKey) ?? [];
      if (!index.contains(script.id)) {
        index.insert(0, script.id);
        await prefs.setStringList(_scriptIndexKey, index);
      }
      return true;
    } catch (e) {
      logDebug('ScriptLocalDataSource saveScript error: $e');
      return false;
    }
  }

  /// Retrieve all saved scripts from local disk storage (with legacy data migration).
  Future<List<ScriptEntity>> getSavedScripts() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check for legacy list-based data to migrate
      if (prefs.containsKey(_legacyScriptsKey)) {
        final String? jsonString = prefs.getString(_legacyScriptsKey);
        if (jsonString != null && jsonString.isNotEmpty) {
          logDebug('ScriptLocalDataSource: Migrating legacy scripts to O(1) storage');
          try {
            final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
            final List<String> newIndex = [];

            for (final item in decoded) {
              final script = ScriptEntity.fromJson(item as Map<String, dynamic>);
              final encodedScript = jsonEncode(script.toJson());
              
              await prefs.setString('$_scriptKeyPrefix${script.id}', encodedScript);
              newIndex.add(script.id);
            }

            await prefs.setStringList(_scriptIndexKey, newIndex);
            await prefs.remove(_legacyScriptsKey); // Delete old key
          } catch (migrationErr) {
            logDebug('ScriptLocalDataSource: Migration error: $migrationErr');
          }
        }
      }

      // Load index
      final List<String> index = prefs.getStringList(_scriptIndexKey) ?? [];
      if (index.isEmpty) {
        return [];
      }

      final List<ScriptEntity> scripts = [];
      for (final id in index) {
        final String? scriptJson = prefs.getString('$_scriptKeyPrefix$id');
        if (scriptJson != null && scriptJson.isNotEmpty) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(scriptJson) as Map<String, dynamic>;
            scripts.add(ScriptEntity.fromJson(decoded));
          } catch (e) {
            logDebug('ScriptLocalDataSource error parsing script $id: $e');
          }
        }
      }
      return scripts;
    } catch (e) {
      logDebug('ScriptLocalDataSource getSavedScripts error: $e');
      return [];
    }
  }

  /// Delete a script by ID (O(1) deletion).
  Future<bool> deleteScript(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Delete individual script
      await prefs.remove('$_scriptKeyPrefix$id');

      // Update script index list
      final List<String> index = prefs.getStringList(_scriptIndexKey) ?? [];
      if (index.contains(id)) {
        index.remove(id);
        await prefs.setStringList(_scriptIndexKey, index);
      }
      return true;
    } catch (e) {
      logDebug('ScriptLocalDataSource deleteScript error: $e');
      return false;
    }
  }

  /// Update an existing saved script (overwrite by ID, preserving order in index).
  Future<bool> updateScript(ScriptEntity updatedScript) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> index = prefs.getStringList(_scriptIndexKey) ?? [];

      // Only allow update if the script already exists in the index
      if (!index.contains(updatedScript.id)) {
        logDebug('ScriptLocalDataSource updateScript: script not found, saving as new');
        return saveScript(updatedScript);
      }

      final String encoded = jsonEncode(updatedScript.toJson());
      final bool saved = await prefs.setString('$_scriptKeyPrefix${updatedScript.id}', encoded);
      return saved;
    } catch (e) {
      logDebug('ScriptLocalDataSource updateScript error: $e');
      return false;
    }
  }

  /// Clear all saved scripts (for testing / reset flows).
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> index = prefs.getStringList(_scriptIndexKey) ?? [];
      for (final id in index) {
        await prefs.remove('$_scriptKeyPrefix$id');
      }
      await prefs.remove(_scriptIndexKey);
    } catch (e) {
      logDebug('ScriptLocalDataSource clearAll error: $e');
    }
  }
}
