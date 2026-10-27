import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:bms_mobile_apps/features/settings/bms_settings.dart';
import 'package:bms_mobile_apps/features/settings/bms_settings_repository.dart';

void main() {
  const deviceId = 'AA:BB:CC:DD:EE:05';

  test('loads legacy v1 settings without guessing battery chemistry', () async {
    final settings = BmsSettings.fromBluetoothJson({'ovp': 3600, 'uvp': 2900});
    final store = _MemoryBmsSettingsStore({
      _key(deviceId, 1): jsonEncode(settings.toJson()),
    });
    final repository = BmsSettingsRepository(store: store);

    final configuration = await repository.loadConfiguration(deviceId);

    expect(configuration.batteryType, isNull);
    expect(
      configuration.settings.valueFor(BmsSettingKey.overVoltageProtection),
      3600,
    );
    expect(
      configuration.settings.valueFor(BmsSettingKey.underVoltageProtection),
      2900,
    );
  });

  test(
    'saves and restores chemistry separately from custom settings',
    () async {
      final store = _MemoryBmsSettingsStore();
      final repository = BmsSettingsRepository(store: store);
      final settings = BmsSettings.fromBluetoothJson({
        'ovp': 3600,
        'uvp': 2900,
      });

      await repository.saveConfiguration(
        deviceId,
        BmsDeviceConfiguration(
          settings: settings,
          batteryType: BmsBatteryType.lfp,
        ),
      );
      final restored = await repository.loadConfiguration(deviceId);

      expect(restored.batteryType, BmsBatteryType.lfp);
      expect(
        restored.settings.valueFor(BmsSettingKey.overVoltageProtection),
        3600,
      );
      expect(
        restored.settings.valueFor(BmsSettingKey.underVoltageProtection),
        2900,
      );
    },
  );

  test(
    'falls back to valid v1 settings when the v2 record is damaged',
    () async {
      final legacySettings = BmsSettings.fromBluetoothJson({'ovp': 3550});
      final store = _MemoryBmsSettingsStore({
        _key(deviceId, 1): jsonEncode(legacySettings.toJson()),
        _key(deviceId, 2): 'not-json',
      });
      final repository = BmsSettingsRepository(store: store);

      final configuration = await repository.loadConfiguration(deviceId);

      expect(configuration.batteryType, isNull);
      expect(
        configuration.settings.valueFor(BmsSettingKey.overVoltageProtection),
        3550,
      );
    },
  );
}

String _key(String deviceId, int version) {
  final encodedId = base64Url.encode(utf8.encode(deviceId)).replaceAll('=', '');
  return 'bms.settings.$encodedId.v$version';
}

class _MemoryBmsSettingsStore implements BmsSettingsStore {
  _MemoryBmsSettingsStore([Map<String, String>? values])
    : _values = {...?values};

  final Map<String, String> _values;

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}
