import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bms_mobile_apps/features/devices/saved_device.dart';
import 'package:bms_mobile_apps/features/settings/bms_settings.dart';
import 'package:bms_mobile_apps/features/settings/bms_settings_screen.dart';

void main() {
  testWidgets('BMS settings page renders editable parameter sections', (
    tester,
  ) async {
    final device = SavedDevice(
      id: 'AA:BB:CC:DD:EE:03',
      name: 'BMS-003',
      savedAt: DateTime.utc(2026, 7, 30),
    );

    final deviceSettings = BmsSettings.fromBluetoothJson({
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

    await tester.pumpWidget(
      MaterialApp(
        home: BmsSettingsScreen(
          device: device,
          demoMode: true,
          initialSettings: deviceSettings,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('BMS Setting'), findsOneWidget);
    expect(find.text('BATTERY TYPE'), findsOneWidget);
    expect(find.text('LFP'), findsOneWidget);
    expect(find.text('NMC'), findsOneWidget);
    expect(find.text('LTO'), findsOneWidget);
    expect(find.text('VOLTAGE PROTECTION'), findsOneWidget);
    expect(find.text('3600'), findsOneWidget);

    await tester.tap(find.text('LFP'));
    await tester.pump();

    expect(find.text('3650'), findsOneWidget);
    expect(find.text('2500'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pump();

    expect(find.text('SYSTEM & BALANCING'), findsOneWidget);
    expect(find.text('Save Parameters'), findsOneWidget);
  });
}
