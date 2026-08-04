import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:bms_mobile_apps/features/settings/bms_settings.dart';

void main() {
  test('default BMS settings match the supplied mockup', () {
    final settings = BmsSettings.defaults();

    expect(settings.valueFor(BmsSettingKey.overVoltageProtection), 4200);
    expect(settings.valueFor(BmsSettingKey.underVoltageProtection), 2800);
    expect(settings.valueFor(BmsSettingKey.overCurrentDischarge), 120);
    expect(settings.valueFor(BmsSettingKey.resistorShunt), 1.5);
    expect(settings.valueFor(BmsSettingKey.dayToSleep), 7);
  });

  test('BMS settings survive a JSON round-trip', () {
    final settings = BmsSettings.defaults();
    final restored = BmsSettings.fromJson(settings.toJson());

    for (final definition in bmsSettingDefinitions) {
      expect(
        restored.valueFor(definition.key),
        settings.valueFor(definition.key),
      );
    }
  });

  test('BMS settings map to the Bluetooth parameter JSON format', () {
    final payload = BmsSettings.defaults().toBluetoothPayload();
    final json = jsonDecode(payload) as Map<String, dynamic>;

    expect(json, {
      'ovp': 4200,
      'ovr': 4100,
      'uvp': 2800,
      'uvr': 3000,
      'occ': 50,
      'docc': 1000,
      'ocd': 120,
      'docd': 2000,
      'otb': 60,
      'otbr': 50,
      'otm': 85,
      'otmr': 70,
      'cap': 100,
      'shunt': 1.5,
      'bal_min': 3500,
      'bal_dif': 50,
      'sleep': 7,
    });
    expect(payload, isNot(contains('\n')));
  });

  test('over-current delays display seconds but retain BLE milliseconds', () {
    final chargeDelay = bmsSettingDefinitions.firstWhere(
      (definition) => definition.key == BmsSettingKey.delayOverCurrentCharge,
    );
    final dischargeDelay = bmsSettingDefinitions.firstWhere(
      (definition) => definition.key == BmsSettingKey.delayOverCurrentDischarge,
    );

    expect(chargeDelay.unit, 's');
    expect(chargeDelay.toDisplayValue(1000), 1);
    expect(chargeDelay.toProtocolValue(1), 1000);
    expect(dischargeDelay.unit, 's');
    expect(dischargeDelay.toDisplayValue(2000), 2);
    expect(dischargeDelay.toProtocolValue(2), 2000);
  });

  test('battery chemistry presets apply supplied values only', () {
    final original = BmsSettings.defaults();
    final lfp = original.applyBatteryTypePreset(BmsBatteryType.lfp);
    final nmc = original.applyBatteryTypePreset(BmsBatteryType.nmc);
    final lto = original.applyBatteryTypePreset(BmsBatteryType.lto);

    expect(lfp.valueFor(BmsSettingKey.overVoltageProtection), 3650);
    expect(lfp.valueFor(BmsSettingKey.underVoltageProtection), 2500);
    expect(lfp.valueFor(BmsSettingKey.overTemperatureBattery), 55);
    expect(lfp.valueFor(BmsSettingKey.balancingMinimum), 3400);
    expect(lfp.matchingBatteryType, BmsBatteryType.lfp);

    expect(nmc.valueFor(BmsSettingKey.overVoltageProtection), 4200);
    expect(nmc.valueFor(BmsSettingKey.balancingMinimum), 4000);
    expect(nmc.matchingBatteryType, BmsBatteryType.nmc);

    expect(lto.valueFor(BmsSettingKey.overVoltageProtection), 2750);
    expect(lto.valueFor(BmsSettingKey.underVoltageProtection), 1800);
    expect(lto.valueFor(BmsSettingKey.balancingMinimum), 2500);
    expect(lto.matchingBatteryType, BmsBatteryType.lto);

    for (final settings in [lfp, nmc, lto]) {
      expect(settings.valueFor(BmsSettingKey.overCurrentCharge), 50);
      expect(settings.valueFor(BmsSettingKey.overCurrentDischarge), 120);
      expect(settings.valueFor(BmsSettingKey.batteryCapacity), 100);
      expect(settings.valueFor(BmsSettingKey.resistorShunt), 1.5);
    }
  });

  test('BMS settings map from the Bluetooth telemetry JSON format', () {
    final settings = BmsSettings.fromBluetoothJson({
      'ovp': 3600,
      'ovr': 3550,
      'uvp': 2800,
      'uvr': 2850,
      'occ': 50,
      'docc': 1000,
      'ocd': 100,
      'docd': 1000,
      'otb': 40,
      'otbr': 38,
      'otm': 50,
      'otmr': 45,
      'cap': 100,
      'shunt': 1.5,
      'bal_min': 3500,
      'bal_dif': 50,
      'sleep': 7,
    });

    expect(settings.valueFor(BmsSettingKey.overVoltageProtection), 3600);
    expect(settings.valueFor(BmsSettingKey.overVoltageRelease), 3550);
    expect(settings.valueFor(BmsSettingKey.underVoltageProtection), 2800);
    expect(settings.valueFor(BmsSettingKey.underVoltageRelease), 2850);
    expect(settings.valueFor(BmsSettingKey.overCurrentCharge), 50);
    expect(settings.valueFor(BmsSettingKey.delayOverCurrentCharge), 1000);
    expect(settings.valueFor(BmsSettingKey.overCurrentDischarge), 100);
    expect(settings.valueFor(BmsSettingKey.delayOverCurrentDischarge), 1000);
    expect(settings.valueFor(BmsSettingKey.overTemperatureBattery), 40);
    expect(settings.valueFor(BmsSettingKey.overTemperatureBatteryRelease), 38);
    expect(settings.valueFor(BmsSettingKey.overTemperatureMosfet), 50);
    expect(settings.valueFor(BmsSettingKey.overTemperatureMosfetRelease), 45);
    expect(settings.valueFor(BmsSettingKey.batteryCapacity), 100);
    expect(settings.valueFor(BmsSettingKey.resistorShunt), 1.5);
    expect(settings.valueFor(BmsSettingKey.balancingMinimum), 3500);
    expect(settings.valueFor(BmsSettingKey.balancingDifferent), 50);
    expect(settings.valueFor(BmsSettingKey.dayToSleep), 7);
  });
}
