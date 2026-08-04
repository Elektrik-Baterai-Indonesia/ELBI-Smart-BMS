import 'package:flutter_test/flutter_test.dart';

import 'package:bms_mobile_apps/features/scanner/bluetooth_mac_address.dart';

void main() {
  group('BluetoothMacAddress.tryParse', () {
    test('reads and normalizes a plain colon-separated address', () {
      final result = BluetoothMacAddress.tryParse('aa:bb:cc:dd:ee:01');

      expect(result?.value, 'AA:BB:CC:DD:EE:01');
    });

    test('extracts an address from a QR payload string', () {
      final result = BluetoothMacAddress.tryParse(
        '{"device":"BMS","mac":"A1-B2-C3-D4-E5-F6"}',
      );

      expect(result?.value, 'A1:B2:C3:D4:E5:F6');
    });

    test('reads a compact address', () {
      final result = BluetoothMacAddress.tryParse('mac=AABBCCDDEE01');

      expect(result?.value, 'AA:BB:CC:DD:EE:01');
    });

    test('rejects missing, malformed, and sentinel addresses', () {
      expect(BluetoothMacAddress.tryParse('not a mac'), isNull);
      expect(BluetoothMacAddress.tryParse('AA:BB:CC:DD:EE'), isNull);
      expect(BluetoothMacAddress.tryParse('00:00:00:00:00:00'), isNull);
      expect(BluetoothMacAddress.tryParse('FF:FF:FF:FF:FF:FF'), isNull);
    });
  });
}
