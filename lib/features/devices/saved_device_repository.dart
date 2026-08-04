import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'saved_device.dart';

class SavedDeviceRepository {
  SavedDeviceRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'bms.saved_devices.v1';

  final SharedPreferencesAsync _preferences;

  Future<List<SavedDevice>> load() async {
    final records = await _preferences.getStringList(_storageKey) ?? const [];
    final devices = <SavedDevice>[];

    for (final record in records) {
      try {
        final json = jsonDecode(record) as Map<String, Object?>;
        devices.add(SavedDevice.fromJson(json));
      } on FormatException {
        // Ignore a damaged record while keeping the remaining saved devices.
      } on TypeError {
        // Ignore records written with an incompatible schema.
      }
    }

    devices.sort((first, second) => second.savedAt.compareTo(first.savedAt));
    return devices;
  }

  Future<void> save(SavedDevice device) async {
    final devices = await load();
    devices.removeWhere(
      (saved) => saved.id.toUpperCase() == device.id.toUpperCase(),
    );
    devices.insert(0, device);
    await _write(devices);
  }

  Future<void> remove(String deviceId) async {
    final devices = await load();
    devices.removeWhere(
      (device) => device.id.toUpperCase() == deviceId.toUpperCase(),
    );
    await _write(devices);
  }

  Future<void> clear() {
    return _preferences.remove(_storageKey);
  }

  Future<void> _write(List<SavedDevice> devices) {
    return _preferences.setStringList(
      _storageKey,
      devices.map((device) => jsonEncode(device.toJson())).toList(),
    );
  }
}
