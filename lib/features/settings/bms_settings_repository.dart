import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bms_settings.dart';

abstract interface class BmsSettingsStore {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);
}

class SharedPreferencesBmsSettingsStore implements BmsSettingsStore {
  SharedPreferencesBmsSettingsStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }
}

class BmsSettingsRepository {
  BmsSettingsRepository({
    SharedPreferencesAsync? preferences,
    BmsSettingsStore? store,
  }) : assert(preferences == null || store == null),
       _store = store ?? SharedPreferencesBmsSettingsStore(preferences);

  final BmsSettingsStore _store;

  Future<BmsSettings> load(String deviceId) async {
    return (await loadConfiguration(deviceId)).settings;
  }

  Future<BmsDeviceConfiguration> loadConfiguration(String deviceId) async {
    final configurationRecord = await _store.getString(
      _configurationKeyFor(deviceId),
    );
    if (configurationRecord != null) {
      try {
        return BmsDeviceConfiguration.fromJson(
          jsonDecode(configurationRecord) as Map<String, dynamic>,
        );
      } on FormatException {
        // Fall back to the legacy record without discarding valid v1 settings.
      } on TypeError {
        // Fall back to the legacy record without discarding valid v1 settings.
      }
    }

    final legacyRecord = await _store.getString(_legacyKeyFor(deviceId));
    if (legacyRecord == null) {
      return BmsDeviceConfiguration(settings: BmsSettings.defaults());
    }

    try {
      return BmsDeviceConfiguration(
        settings: BmsSettings.fromJson(
          jsonDecode(legacyRecord) as Map<String, dynamic>,
        ),
      );
    } on FormatException {
      return BmsDeviceConfiguration(settings: BmsSettings.defaults());
    } on TypeError {
      return BmsDeviceConfiguration(settings: BmsSettings.defaults());
    }
  }

  Future<void> save(String deviceId, BmsSettings settings) async {
    final current = await loadConfiguration(deviceId);
    return saveConfiguration(
      deviceId,
      BmsDeviceConfiguration(
        settings: settings,
        batteryType: current.batteryType,
      ),
    );
  }

  Future<void> saveConfiguration(
    String deviceId,
    BmsDeviceConfiguration configuration,
  ) {
    return _store.setString(
      _configurationKeyFor(deviceId),
      jsonEncode(configuration.toJson()),
    );
  }

  String _encodedDeviceId(String deviceId) {
    return base64Url.encode(utf8.encode(deviceId)).replaceAll('=', '');
  }

  String _legacyKeyFor(String deviceId) {
    return 'bms.settings.${_encodedDeviceId(deviceId)}.v1';
  }

  String _configurationKeyFor(String deviceId) {
    return 'bms.settings.${_encodedDeviceId(deviceId)}.v2';
  }
}
