import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bms_mobile_apps/app.dart';
import 'package:bms_mobile_apps/features/settings/app_settings.dart';
import 'package:bms_mobile_apps/features/splash/splash_screen.dart';

void main() {
  testWidgets('branded splash screen opens before the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BmsApp());

    expect(find.text('ELBI Smart BMS'), findsOneWidget);
    expect(find.text('by Elektrik Baterai Indonesia'), findsOneWidget);
    expect(find.text('Add Device'), findsNothing);

    await tester.pump(SplashScreen.duration);
    await tester.pump();

    expect(find.text('Add Device'), findsOneWidget);
  });

  testWidgets('BMS home screen shows all primary menu items', (
    WidgetTester tester,
  ) async {
    await _pumpAppPastSplash(tester);

    expect(find.text('ELBI Smart BMS'), findsOneWidget);
    expect(
      find.text('Monitor battery status in real-time via Bluetooth.'),
      findsOneWidget,
    );
    expect(find.text('Add Device'), findsOneWidget);
    expect(find.text('Monitoring Device'), findsOneWidget);
    expect(find.text('User Manual'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Powered by Elektrik Baterai Indonesia'), findsOneWidget);
  });

  testWidgets('User Manual opens from the home screen', (
    WidgetTester tester,
  ) async {
    await _pumpAppPastSplash(tester);

    await tester.tap(find.text('User Manual'));
    await tester.pumpAndSettle();

    expect(find.text('User Manual'), findsOneWidget);
    expect(find.text('Add a BMS Device'), findsOneWidget);
    expect(find.text('Enable access'), findsOneWidget);
    expect(find.text('Open Add Device'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1600));
    await tester.pumpAndSettle();

    expect(find.text('Choose the battery type'), findsOneWidget);
    expect(find.text('Review and save parameters'), findsOneWidget);
    expect(find.text('Record monitoring data'), findsOneWidget);
  });

  testWidgets('App Settings opens from the home screen', (
    WidgetTester tester,
  ) async {
    await _pumpAppPastSplash(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Temperature unit'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Show Raw JSON'), findsOneWidget);
    expect(find.text('Record data'), findsOneWidget);
    expect(find.text('Clear saved devices'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Version 1.0.4 (4)'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Temperature unit'))).brightness,
      Brightness.dark,
    );

    final languageDropdown = find.byWidgetPredicate(
      (widget) => widget is DropdownButton<AppLanguage>,
    );
    await tester.tap(languageDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bahasa Indonesia').last);
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Satuan suhu'), findsOneWidget);
    expect(find.text('Tampilkan JSON Mentah'), findsOneWidget);
    expect(find.text('Rekam data'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Tambah Perangkat'), findsOneWidget);

    await tester.tap(find.text('Panduan Pengguna'));
    await tester.pumpAndSettle();
    expect(find.text('Panduan Pengguna'), findsOneWidget);
    expect(find.text('Tambah Perangkat BMS'), findsOneWidget);
    expect(find.text('Aktifkan akses'), findsOneWidget);
  });
}

Future<void> _pumpAppPastSplash(WidgetTester tester) async {
  await tester.pumpWidget(const BmsApp());
  await tester.pump(SplashScreen.duration);
  await tester.pump();
}
