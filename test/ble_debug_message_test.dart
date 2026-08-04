import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:bms_mobile_apps/features/monitoring/ble_debug_controller.dart';

void main() {
  test('BLE debug message pretty-prints a valid JSON packet', () {
    final message = BleDebugMessage.fromBytes(
      serviceId: 'service',
      characteristicId: 'characteristic',
      source: 'NOTIFY',
      bytes: utf8.encode('{"voltage":54.6,"status":"OK"}'),
      timestamp: DateTime.utc(2026, 7, 30),
    );

    expect(message.containsJson, isTrue);
    expect(message.prettyJson, contains('"voltage": 54.6'));
    expect(message.hex, startsWith('7B 22'));
  });

  test('BLE debug message preserves non-JSON text and bytes', () {
    final message = BleDebugMessage.fromBytes(
      serviceId: 'service',
      characteristicId: 'characteristic',
      source: 'READ',
      bytes: [0x42, 0x4D, 0x53],
    );

    expect(message.containsJson, isFalse);
    expect(message.text, 'BMS');
    expect(message.hex, '42 4D 53');
  });
}
