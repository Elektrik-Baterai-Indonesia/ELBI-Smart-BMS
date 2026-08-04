import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class AppSettingsRepository {
  AppSettingsRepository([this._preferences]);

  static const _temperatureUnitKey = 'app.temperature_unit.v1';
  static const _themeModeKey = 'app.theme_mode.v1';
  static const _showRawJsonKey = 'app.show_raw_json.v1';
  static const _recordDataKey = 'app.record_data.v1';
  static const _languageKey = 'app.language.v1';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _store {
    return _preferences ??= SharedPreferencesAsync();
  }

  Future<AppSettings> load() async {
    final temperatureName = await _store.getString(_temperatureUnitKey);
    final themeName = await _store.getString(_themeModeKey);
    final languageName = await _store.getString(_languageKey);

    return AppSettings(
      temperatureUnit:
          TemperatureUnit.values
              .where((unit) => unit.name == temperatureName)
              .firstOrNull ??
          TemperatureUnit.celsius,
      themeMode:
          ThemeMode.values
              .where((mode) => mode.name == themeName)
              .firstOrNull ??
          ThemeMode.light,
      showRawJson: await _store.getBool(_showRawJsonKey) ?? false,
      recordData: await _store.getBool(_recordDataKey) ?? false,
      language:
          AppLanguage.values
              .where((language) => language.name == languageName)
              .firstOrNull ??
          AppLanguage.english,
    );
  }

  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _store.setString(_temperatureUnitKey, settings.temperatureUnit.name),
      _store.setString(_themeModeKey, settings.themeMode.name),
      _store.setBool(_showRawJsonKey, settings.showRawJson),
      _store.setBool(_recordDataKey, settings.recordData),
      _store.setString(_languageKey, settings.language.name),
    ]);
  }
}
