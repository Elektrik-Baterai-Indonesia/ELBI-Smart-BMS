import 'package:flutter_test/flutter_test.dart';

import 'package:bms_mobile_apps/features/devices/saved_device.dart';

void main() {
  test('SavedDevice JSON round-trip preserves its fields', () {
    final savedAt = DateTime.utc(2026, 7, 29, 12, 30);
    final device = SavedDevice(
      id: 'AA:BB:CC:DD:EE:01',
      name: 'Battery 1',
      savedAt: savedAt,
    );

    final restored = SavedDevice.fromJson(device.toJson());

    expect(restored.id, device.id);
    expect(restored.name, device.name);
    expect(restored.savedAt, savedAt);
  });

  test('SavedDevice generates a readable name for a QR identifier', () {
    final device = SavedDevice.fromIdentifier('AA:BB:CC:DD:EE:01');

    expect(device.name, 'BMS EE:01');
  });
}
