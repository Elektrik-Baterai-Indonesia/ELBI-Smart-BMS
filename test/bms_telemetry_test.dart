import 'package:flutter_test/flutter_test.dart';

import 'package:bms_mobile_apps/features/monitoring/bms_telemetry.dart';
import 'package:bms_mobile_apps/features/settings/bms_settings.dart';

void main() {
  const payload = '''
  {
    "serial_number": "00BB1000",
    "soc": 16,
    "voltage": 50.89,
    "current": -18.34,
    "temperature": 25.0,
    "error_code": 0,
    "cell_voltage": [
      3153, 3185, 3189, 3188, 3184, 3188, 3187, 3174,
      3178, 3178, 3185, 3186, 3186, 3185, 3183, 3163,
      0, 0, 0, 0, 0, 0, 0, 0
    ],
    "settings": {
      "ovp": 3600,
      "ovr": 3550,
      "uvp": 2800,
      "uvr": 2850,
      "occ": 50,
      "docc": 1000,
      "ocd": 100,
      "docd": 1000,
      "otb": 40,
      "otbr": 38,
      "otm": 50,
      "otmr": 45,
      "cap": 100,
      "shunt": 1.5,
      "bal_min": 3500,
      "bal_dif": 50,
      "sleep": 7
    }
  }
  ''';

  test('maps the BMS Bluetooth JSON payload', () {
    final telemetry = BmsTelemetry.tryParse(payload);

    expect(telemetry, isNotNull);
    expect(telemetry!.serialNumber, '00BB1000');
    expect(telemetry.soc, 16);
    expect(telemetry.voltage, 50.89);
    expect(telemetry.current, -18.34);
    expect(telemetry.temperature, 25);
    expect(telemetry.errorCode, 0);
    expect(telemetry.cellVoltageMillivolts, hasLength(24));
    expect(telemetry.monitoringCellVoltageMillivolts, hasLength(16));
    expect(telemetry.monitoringCellCount, 16);
    expect(telemetry.activeCellCount, 16);
    expect(telemetry.averageCellVoltage, closeTo(3.18075, 0.00001));
    expect(telemetry.cellVoltageDelta, closeTo(0.036, 0.0001));
    expect(
      telemetry.settings!.valueFor(BmsSettingKey.overVoltageProtection),
      3600,
    );
    expect(
      telemetry.settings!.valueFor(BmsSettingKey.underVoltageRelease),
      2850,
    );
    expect(telemetry.settings!.valueFor(BmsSettingKey.resistorShunt), 1.5);
  });

  test('cell monitoring excludes voltages below 500 mV', () {
    const variableCellPayload = '''
    {
      "serial_number": "00BB1000",
      "soc": 50,
      "voltage": 13.2,
      "current": 2.5,
      "temperature": 25.0,
      "error_code": 0,
      "cell_voltage": [3300, 499, 500, 3290, 3280, 0]
    }
    ''';

    final telemetry = BmsTelemetry.tryParse(variableCellPayload)!;

    expect(telemetry.cellVoltageMillivolts, hasLength(6));
    expect(telemetry.monitoringCellVoltageMillivolts, [3300, 500, 3290, 3280]);
    expect(telemetry.monitoringCellCount, 4);
    expect(telemetry.activeCellCount, 4);
  });

  test('continues to accept telemetry without device settings', () {
    const legacyPayload = '''
    {
      "serial_number": "00BB1000",
      "soc": 16,
      "voltage": 50.89,
      "current": -18.34,
      "temperature": 25.0,
      "error_code": 0,
      "cell_voltage": [3153, 3185]
    }
    ''';

    final telemetry = BmsTelemetry.tryParse(legacyPayload);

    expect(telemetry, isNotNull);
    expect(telemetry!.settings, isNull);
  });

  test('rejects incomplete or malformed telemetry', () {
    expect(BmsTelemetry.tryParse('{"soc": 16}'), isNull);
    expect(BmsTelemetry.tryParse('not-json'), isNull);
  });
}
