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
    expect(find.text('3.600'), findsOneWidget);

    await tester.tap(find.text('LFP'));
    await tester.pump();

    expect(find.text('3.649'), findsOneWidget);
    expect(find.textContaining('UVP >2.800 and <3.650 V'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pump();

    expect(find.text('SYSTEM & BALANCING'), findsOneWidget);
    expect(find.text('1.500'), findsOneWidget);
    expect(find.text('Save Parameters'), findsOneWidget);
  });

  testWidgets('over-voltage release must be below protection', (tester) async {
    await _pumpLfpSettings(tester);

    await tester.enterText(find.byType(TextFormField).at(1), '3.649');
    tester.testTextInput.hide();
    await _tapSave(tester);

    expect(
      find.text(
        'Over Voltage Protection Release must be below Over Voltage Protection.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('under-voltage release must be above protection', (tester) async {
    await _pumpLfpSettings(tester);

    await tester.enterText(find.byType(TextFormField).at(3), '2.801');
    tester.testTextInput.hide();
    await _tapSave(tester);

    expect(
      find.text(
        'Under Voltage Protection Release must be above Under Voltage Protection.',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpLfpSettings(WidgetTester tester) async {
  final device = SavedDevice(
    id: 'AA:BB:CC:DD:EE:04',
    name: 'BMS validation test',
    savedAt: DateTime.utc(2026, 10, 5),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: BmsSettingsScreen(
        device: device,
        demoMode: true,
        initialSettings: BmsSettings.defaults().applyBatteryTypePreset(
          BmsBatteryType.lfp,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -1800));
  await tester.pump();
  final saveButton = find.text('Save Parameters');
  await tester.ensureVisible(saveButton);
  await tester.pump();
  await tester.tap(saveButton);
  await tester.pump();
}
