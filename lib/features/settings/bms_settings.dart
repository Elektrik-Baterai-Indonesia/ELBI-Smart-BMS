import 'dart:convert';

enum BmsSettingsSection {
  voltageProtection,
  currentAndDelay,
  temperature,
  systemAndBalancing,
}

enum BmsSettingKey {
  overVoltageProtection,
  overVoltageRelease,
  underVoltageProtection,
  underVoltageRelease,
  overCurrentCharge,
  delayOverCurrentCharge,
  overCurrentDischarge,
  delayOverCurrentDischarge,
  overTemperatureBattery,
  overTemperatureBatteryRelease,
  overTemperatureMosfet,
  overTemperatureMosfetRelease,
  batteryCapacity,
  resistorShunt,
  balancingMinimum,
  balancingDifferent,
  dayToSleep,
}

enum BmsBatteryType {
  lfp,
  nmc,
  lto;

  String get label => name.toUpperCase();

  Map<BmsSettingKey, double> get presetValues => switch (this) {
    BmsBatteryType.lfp => const {
      BmsSettingKey.overVoltageProtection: 3650,
      BmsSettingKey.overVoltageRelease: 3450,
      BmsSettingKey.underVoltageProtection: 2500,
      BmsSettingKey.underVoltageRelease: 2800,
      BmsSettingKey.delayOverCurrentCharge: 1000,
      BmsSettingKey.delayOverCurrentDischarge: 2000,
      BmsSettingKey.overTemperatureBattery: 55,
      BmsSettingKey.overTemperatureBatteryRelease: 45,
      BmsSettingKey.overTemperatureMosfet: 85,
      BmsSettingKey.overTemperatureMosfetRelease: 70,
      BmsSettingKey.balancingMinimum: 3400,
      BmsSettingKey.balancingDifferent: 20,
      BmsSettingKey.dayToSleep: 7,
    },
    BmsBatteryType.nmc => const {
      BmsSettingKey.overVoltageProtection: 4200,
      BmsSettingKey.overVoltageRelease: 4100,
      BmsSettingKey.underVoltageProtection: 2800,
      BmsSettingKey.underVoltageRelease: 3000,
      BmsSettingKey.delayOverCurrentCharge: 1000,
      BmsSettingKey.delayOverCurrentDischarge: 2000,
      BmsSettingKey.overTemperatureBattery: 50,
      BmsSettingKey.overTemperatureBatteryRelease: 45,
      BmsSettingKey.overTemperatureMosfet: 85,
      BmsSettingKey.overTemperatureMosfetRelease: 70,
      BmsSettingKey.balancingMinimum: 4000,
      BmsSettingKey.balancingDifferent: 20,
      BmsSettingKey.dayToSleep: 7,
    },
    BmsBatteryType.lto => const {
      BmsSettingKey.overVoltageProtection: 2750,
      BmsSettingKey.overVoltageRelease: 2650,
      BmsSettingKey.underVoltageProtection: 1800,
      BmsSettingKey.underVoltageRelease: 2000,
      BmsSettingKey.delayOverCurrentCharge: 1000,
      BmsSettingKey.delayOverCurrentDischarge: 2000,
      BmsSettingKey.overTemperatureBattery: 50,
      BmsSettingKey.overTemperatureBatteryRelease: 45,
      BmsSettingKey.overTemperatureMosfet: 85,
      BmsSettingKey.overTemperatureMosfetRelease: 70,
      BmsSettingKey.balancingMinimum: 2500,
      BmsSettingKey.balancingDifferent: 20,
      BmsSettingKey.dayToSleep: 7,
    },
  };
}

class BmsSettingDefinition {
  const BmsSettingDefinition({
    required this.key,
    required this.section,
    required this.label,
    required this.unit,
    required this.defaultValue,
    this.decimalPlaces = 0,
    this.protocolUnitsPerDisplayUnit = 1,
  });

  final BmsSettingKey key;
  final BmsSettingsSection section;
  final String label;
  final String unit;
  final double defaultValue;
  final int decimalPlaces;
  final double protocolUnitsPerDisplayUnit;

  double toDisplayValue(double protocolValue) {
    return protocolValue / protocolUnitsPerDisplayUnit;
  }

  double toProtocolValue(double displayValue) {
    return displayValue * protocolUnitsPerDisplayUnit;
  }
}

const bmsSettingDefinitions = [
  BmsSettingDefinition(
    key: BmsSettingKey.overVoltageProtection,
    section: BmsSettingsSection.voltageProtection,
    label: 'Over Voltage Protection',
    unit: 'mV',
    defaultValue: 4200,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.overVoltageRelease,
    section: BmsSettingsSection.voltageProtection,
    label: 'Over Voltage Protection\nRelease',
    unit: 'mV',
    defaultValue: 4100,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.underVoltageProtection,
    section: BmsSettingsSection.voltageProtection,
    label: 'Under Voltage Protection',
    unit: 'mV',
    defaultValue: 2800,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.underVoltageRelease,
    section: BmsSettingsSection.voltageProtection,
    label: 'Under Voltage Protection\nRelease',
    unit: 'mV',
    defaultValue: 3000,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.overCurrentCharge,
    section: BmsSettingsSection.currentAndDelay,
    label: 'Over Current Charge',
    unit: 'A',
    defaultValue: 50,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.delayOverCurrentCharge,
    section: BmsSettingsSection.currentAndDelay,
    label: 'Delay Over Current Charge',
    unit: 's',
    defaultValue: 1000,
    protocolUnitsPerDisplayUnit: 1000,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.overCurrentDischarge,
    section: BmsSettingsSection.currentAndDelay,
    label: 'Over Current Discharge',
    unit: 'A',
    defaultValue: 120,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.delayOverCurrentDischarge,
    section: BmsSettingsSection.currentAndDelay,
    label: 'Delay Over Current\nDischarge',
    unit: 's',
    defaultValue: 2000,
    protocolUnitsPerDisplayUnit: 1000,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.overTemperatureBattery,
    section: BmsSettingsSection.temperature,
    label: 'Over Temperature Battery',
    unit: '°C',
    defaultValue: 60,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.overTemperatureBatteryRelease,
    section: BmsSettingsSection.temperature,
    label: 'Over Temp Battery Release',
    unit: '°C',
    defaultValue: 50,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.overTemperatureMosfet,
    section: BmsSettingsSection.temperature,
    label: 'Over Temperature Mosfet',
    unit: '°C',
    defaultValue: 85,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.overTemperatureMosfetRelease,
    section: BmsSettingsSection.temperature,
    label: 'Over Temp Mosfet Release',
    unit: '°C',
    defaultValue: 70,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.batteryCapacity,
    section: BmsSettingsSection.systemAndBalancing,
    label: 'Battery Capacity',
    unit: 'Ah',
    defaultValue: 100,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.resistorShunt,
    section: BmsSettingsSection.systemAndBalancing,
    label: 'Resistor Shunt',
    unit: 'mΩ',
    defaultValue: 1.5,
    decimalPlaces: 1,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.balancingMinimum,
    section: BmsSettingsSection.systemAndBalancing,
    label: 'Balancing Minimum',
    unit: 'mV',
    defaultValue: 3500,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.balancingDifferent,
    section: BmsSettingsSection.systemAndBalancing,
    label: 'Balancing Different',
    unit: 'mV',
    defaultValue: 50,
  ),
  BmsSettingDefinition(
    key: BmsSettingKey.dayToSleep,
    section: BmsSettingsSection.systemAndBalancing,
    label: 'Day to Sleep',
    unit: 'days',
    defaultValue: 7,
  ),
];

class BmsSettings {
  BmsSettings(Map<BmsSettingKey, double> values)
    : values = Map.unmodifiable(values);

  factory BmsSettings.defaults() {
    return BmsSettings({
      for (final definition in bmsSettingDefinitions)
        definition.key: definition.defaultValue,
    });
  }

  factory BmsSettings.fromJson(Map<String, dynamic> json) {
    final defaults = BmsSettings.defaults();
    return BmsSettings({
      for (final definition in bmsSettingDefinitions)
        definition.key:
            (json[definition.key.name] as num?)?.toDouble() ??
            defaults.valueFor(definition.key),
    });
  }

  factory BmsSettings.fromBluetoothJson(Map<String, dynamic> json) {
    final defaults = BmsSettings.defaults();

    double read(String bluetoothKey, BmsSettingKey settingKey) {
      final value = json[bluetoothKey];
      return value is num ? value.toDouble() : defaults.valueFor(settingKey);
    }

    return BmsSettings({
      BmsSettingKey.overVoltageProtection: read(
        'ovp',
        BmsSettingKey.overVoltageProtection,
      ),
      BmsSettingKey.overVoltageRelease: read(
        'ovr',
        BmsSettingKey.overVoltageRelease,
      ),
      BmsSettingKey.underVoltageProtection: read(
        'uvp',
        BmsSettingKey.underVoltageProtection,
      ),
      BmsSettingKey.underVoltageRelease: read(
        'uvr',
        BmsSettingKey.underVoltageRelease,
      ),
      BmsSettingKey.overCurrentCharge: read(
        'occ',
        BmsSettingKey.overCurrentCharge,
      ),
      BmsSettingKey.delayOverCurrentCharge: read(
        'docc',
        BmsSettingKey.delayOverCurrentCharge,
      ),
      BmsSettingKey.overCurrentDischarge: read(
        'ocd',
        BmsSettingKey.overCurrentDischarge,
      ),
      BmsSettingKey.delayOverCurrentDischarge: read(
        'docd',
        BmsSettingKey.delayOverCurrentDischarge,
      ),
      BmsSettingKey.overTemperatureBattery: read(
        'otb',
        BmsSettingKey.overTemperatureBattery,
      ),
      BmsSettingKey.overTemperatureBatteryRelease: read(
        'otbr',
        BmsSettingKey.overTemperatureBatteryRelease,
      ),
      BmsSettingKey.overTemperatureMosfet: read(
        'otm',
        BmsSettingKey.overTemperatureMosfet,
      ),
      BmsSettingKey.overTemperatureMosfetRelease: read(
        'otmr',
        BmsSettingKey.overTemperatureMosfetRelease,
      ),
      BmsSettingKey.batteryCapacity: read('cap', BmsSettingKey.batteryCapacity),
      BmsSettingKey.resistorShunt: read('shunt', BmsSettingKey.resistorShunt),
      BmsSettingKey.balancingMinimum: read(
        'bal_min',
        BmsSettingKey.balancingMinimum,
      ),
      BmsSettingKey.balancingDifferent: read(
        'bal_dif',
        BmsSettingKey.balancingDifferent,
      ),
      BmsSettingKey.dayToSleep: read('sleep', BmsSettingKey.dayToSleep),
    });
  }

  final Map<BmsSettingKey, double> values;

  double valueFor(BmsSettingKey key) => values[key]!;

  BmsSettings applyBatteryTypePreset(BmsBatteryType batteryType) {
    return BmsSettings({...values, ...batteryType.presetValues});
  }

  BmsBatteryType? get matchingBatteryType {
    for (final batteryType in BmsBatteryType.values) {
      final matches = batteryType.presetValues.entries.every(
        (entry) => valueFor(entry.key) == entry.value,
      );
      if (matches) return batteryType;
    }
    return null;
  }

  Map<String, double> toJson() {
    return {for (final entry in values.entries) entry.key.name: entry.value};
  }

  Map<String, num> toBluetoothJson() {
    num value(BmsSettingKey key) {
      final settingValue = valueFor(key);
      return settingValue == settingValue.roundToDouble()
          ? settingValue.toInt()
          : settingValue;
    }

    return {
      'ovp': value(BmsSettingKey.overVoltageProtection),
      'ovr': value(BmsSettingKey.overVoltageRelease),
      'uvp': value(BmsSettingKey.underVoltageProtection),
      'uvr': value(BmsSettingKey.underVoltageRelease),
      'occ': value(BmsSettingKey.overCurrentCharge),
      'docc': value(BmsSettingKey.delayOverCurrentCharge),
      'ocd': value(BmsSettingKey.overCurrentDischarge),
      'docd': value(BmsSettingKey.delayOverCurrentDischarge),
      'otb': value(BmsSettingKey.overTemperatureBattery),
      'otbr': value(BmsSettingKey.overTemperatureBatteryRelease),
      'otm': value(BmsSettingKey.overTemperatureMosfet),
      'otmr': value(BmsSettingKey.overTemperatureMosfetRelease),
      'cap': value(BmsSettingKey.batteryCapacity),
      'shunt': value(BmsSettingKey.resistorShunt),
      'bal_min': value(BmsSettingKey.balancingMinimum),
      'bal_dif': value(BmsSettingKey.balancingDifferent),
      'sleep': value(BmsSettingKey.dayToSleep),
    };
  }

  String toBluetoothPayload() => jsonEncode(toBluetoothJson());
}
