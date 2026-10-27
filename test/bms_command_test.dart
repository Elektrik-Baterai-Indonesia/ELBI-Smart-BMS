import 'package:bms_mobile_apps/features/commands/bms_command.dart';
import 'package:bms_mobile_apps/features/commands/bms_command_pin_dialog.dart';
import 'package:bms_mobile_apps/features/commands/bms_command_screen.dart';
import 'package:bms_mobile_apps/features/devices/saved_device.dart';
import 'package:bms_mobile_apps/features/monitoring/ble_debug_controller.dart';
import 'package:bms_mobile_apps/features/settings/bms_settings.dart';
import 'package:bms_mobile_apps/features/settings/bms_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _device = SavedDevice(
  id: 'AA:BB:CC:DD:EE:10',
  name: 'Command test BMS',
  savedAt: DateTime.utc(2026, 10, 27),
);

void main() {
  test('commands encode the BMS command payloads', () {
    expect(BmsCommand.resetSoc.toBluetoothPayload(), '{"cmd":1}');
    expect(BmsCommand.resetBms.toBluetoothPayload(), '{"cmd":2}');
  });

  group('BmsCommandScreen', () {
    Future<List<String>> pumpScreen(
      WidgetTester tester, {
      Future<void> Function(String payload)? onSend,
      bool connected = true,
    }) async {
      final sent = <String>[];
      await _pumpFromHost(
        tester,
        BmsCommandScreen(
          device: _device,
          onSendCommand: connected
              ? onSend ??
                    (payload) async {
                      sent.add(payload);
                    }
              : null,
        ),
      );
      return sent;
    }

    for (final (label, payload) in [
      ('Reset SoC', '{"cmd":1}'),
      ('Reset BMS', '{"cmd":2}'),
    ]) {
      testWidgets('$label sends $payload after confirmation', (tester) async {
        final sent = await pumpScreen(tester);

        await tester.tap(find.widgetWithText(FilledButton, label));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Send'));
        await tester.pumpAndSettle();

        expect(sent, [payload]);
        expect(find.text('$label sent to Command test BMS.'), findsOneWidget);
      });
    }

    testWidgets('cancelling confirmation sends nothing', (tester) async {
      final sent = await pumpScreen(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Reset BMS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(sent, isEmpty);
    });

    testWidgets('requires a connected BMS', (tester) async {
      await pumpScreen(tester, connected: false);

      await tester.tap(find.widgetWithText(FilledButton, 'Reset SoC'));
      await tester.pumpAndSettle();

      expect(
        find.text('Connect to the BMS before sending commands.'),
        findsOneWidget,
      );
      expect(find.text('Send'), findsNothing);
    });

    testWidgets('shows Bluetooth write failures', (tester) async {
      await pumpScreen(
        tester,
        onSend: (_) async =>
            throw const BleWriteException(BleWriteFailure.transmissionFailed),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Reset SoC'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Send'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bluetooth command transmission failed. Please try again.'),
        findsOneWidget,
      );
    });
  });

  group('showBmsCommandPinDialog', () {
    Future<ValueNotifier<bool?>> pumpDialog(
      WidgetTester tester,
      String expectedPin,
    ) async {
      final result = ValueNotifier<bool?>(null);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result.value = await showBmsCommandPinDialog(
                    context,
                    expectedPin: expectedPin,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('unlocks with the correct PIN', (tester) async {
      final result = await pumpDialog(tester, '2468');

      await tester.enterText(find.byType(TextField), '2468');
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(result.value, isTrue);
    });

    testWidgets('stays open and shows an error for a wrong PIN', (
      tester,
    ) async {
      final result = await pumpDialog(tester, '2468');

      await tester.enterText(find.byType(TextField), '1111');
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect PIN.'), findsOneWidget);
      expect(result.value, isNull);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result.value, isFalse);
    });

    testWidgets('stays locked when no PIN is configured', (tester) async {
      final result = await pumpDialog(tester, '');

      expect(find.byType(TextField), findsNothing);
      expect(
        find.text('BMS Commands PIN is not configured in this build.'),
        findsOneWidget,
      );
      expect(result.value, isFalse);
    });
  });

  group('BMS Setting page entry', () {
    Future<void> pumpSettings(
      WidgetTester tester, {
      Future<void> Function(String payload)? onSend,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BmsSettingsScreen(
            device: _device,
            initialSettings: BmsSettings.defaults(),
            initialBatteryType: BmsBatteryType.lfp,
            onSendParameters: onSend,
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('hides BMS commands when not connected', (tester) async {
      await pumpSettings(tester);

      expect(find.byTooltip('BMS commands'), findsNothing);
    });

    testWidgets('shows BMS commands when connected and asks for PIN', (
      tester,
    ) async {
      await pumpSettings(tester, onSend: (_) async {});

      await tester.tap(find.byTooltip('BMS commands'));
      await tester.pumpAndSettle();

      // Tests run without .env, so the page must stay locked.
      expect(
        find.text('BMS Commands PIN is not configured in this build.'),
        findsOneWidget,
      );
      expect(find.byType(BmsCommandScreen), findsNothing);
    });

    testWidgets('shows BMS commands in demo mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BmsSettingsScreen(
            device: _device,
            demoMode: true,
            initialSettings: BmsSettings.defaults(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byTooltip('BMS commands'), findsOneWidget);
    });
  });

  testWidgets('demo mode confirms commands without sending', (tester) async {
    await _pumpFromHost(
      tester,
      BmsCommandScreen(device: _device, demoMode: true),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Reset BMS'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();

    expect(find.text('Demo: Reset BMS not sent.'), findsOneWidget);
  });

  testWidgets('closes and returns the command after a successful send', (
    tester,
  ) async {
    final result = await _pumpFromHost(
      tester,
      BmsCommandScreen(device: _device, onSendCommand: (_) async {}),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Reset BMS'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();

    expect(result.value, BmsCommand.resetBms);
    expect(find.byType(BmsCommandScreen), findsNothing);
  });
}

/// Opens [screen] on top of a host page, like the BMS Setting page does, and
/// records the value it closes with.
Future<ValueNotifier<BmsCommand?>> _pumpFromHost(
  WidgetTester tester,
  Widget screen,
) async {
  final result = ValueNotifier<BmsCommand?>(null);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result.value = await Navigator.of(
                context,
              ).push<BmsCommand>(MaterialPageRoute(builder: (_) => screen));
            },
            child: const Text('Open host'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open host'));
  await tester.pumpAndSettle();
  return result;
}
