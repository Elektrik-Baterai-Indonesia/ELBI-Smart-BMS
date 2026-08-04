import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bms_settings.dart';

class BmsSettingsRepository {
  BmsSettingsRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  Future<BmsSettings> load(String deviceId) async {
    final record = await _preferences.getString(_keyFor(deviceId));
    if (record == null) return BmsSettings.defaults();

    try {
      return BmsSettings.fromJson(jsonDecode(record) as Map<String, dynamic>);
    } on FormatException {
      return BmsSettings.defaults();
    } on TypeError {
      return BmsSettings.defaults();
    }
  }

  Future<void> save(String deviceId, BmsSettings settings) {
    return _preferences.setString(
      _keyFor(deviceId),
      jsonEncode(settings.toJson()),
    );
  }

  String _keyFor(String deviceId) {
    final encodedId = base64Url
        .encode(utf8.encode(deviceId))
        .replaceAll('=', '');
    return 'bms.settings.$encodedId.v1';
  }
}
