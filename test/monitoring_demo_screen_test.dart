import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bms_mobile_apps/features/monitoring/monitoring_demo_screen.dart';

void main() {
  testWidgets('monitoring demo opens with the BMS-003 sample', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MonitoringDemoScreen()));

    expect(find.text('Monitoring Device'), findsOneWidget);
    expect(find.text('BMS-003'), findsOneWidget);
    expect(find.text('52%'), findsOneWidget);
    expect(find.text('Live demo data'), findsOneWidget);

    await tester.tap(find.text('Simulate fault'));
    await tester.pump();

    expect(find.text('FAULT'), findsOneWidget);
    expect(find.text('Clear fault'), findsOneWidget);
  });

  testWidgets('monitoring demo can simulate a low battery', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MonitoringDemoScreen()));

    await tester.tap(find.text('Simulate low battery'));
    await tester.pump();

    expect(find.text('12%'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Charging'), findsNothing);
    expect(find.text('Clear low battery'), findsOneWidget);

    await tester.tap(find.text('Clear low battery'));
    await tester.pump();

    expect(find.text('52%'), findsOneWidget);
    expect(find.text('Charging'), findsOneWidget);
  });
}
