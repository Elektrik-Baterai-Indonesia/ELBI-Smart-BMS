import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../devices/saved_device.dart';
import '../monitoring/ble_debug_controller.dart';
import 'bms_command.dart';

class BmsCommandScreen extends StatefulWidget {
  const BmsCommandScreen({
    required this.device,
    this.demoMode = false,
    this.onSendCommand,
    super.key,
  });

  final SavedDevice device;
  final bool demoMode;

  /// Writes a payload to the connected BMS. Null when not connected.
  ///
  /// After a successful send the screen closes and returns the [BmsCommand].
  final Future<void> Function(String payload)? onSendCommand;

  @override
  State<BmsCommandScreen> createState() => _BmsCommandScreenState();
}

class _BmsCommandScreenState extends State<BmsCommandScreen> {
  BmsCommand? _sending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 46, 16, 14),
          children: [
            _CommandHeader(onBack: () => Navigator.of(context).pop()),
            const SizedBox(height: 50),
            for (final command in BmsCommand.values) ...[
              _CommandCard(
                command: command,
                sending: _sending == command,
                enabled: _sending == null,
                onPressed: () => _confirmAndSend(command),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            const Text(
              AppTheme.brandName,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.accent, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndSend(BmsCommand command) async {
    final sender = widget.onSendCommand;
    if (!widget.demoMode && sender == null) {
      _showMessage(
        context.translate(
          'Connect to the BMS before sending commands.',
          'Hubungkan ke BMS sebelum mengirim perintah.',
        ),
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_commandTitle(context, command)}?'),
        content: Text(_commandDescription(context, command)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.translate('Cancel', 'Batal')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.translate('Send', 'Kirim')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sending = command);
    try {
      if (!widget.demoMode) {
        await sender!(command.toBluetoothPayload());
      }
      if (!mounted) return;
      _showMessage(
        widget.demoMode
            ? context.translate(
                'Demo: ${_commandTitle(context, command)} not sent.',
                'Demo: ${_commandTitle(context, command)} tidak dikirim.',
              )
            : context.translate(
                '${_commandTitle(context, command)} sent to ${widget.device.name}.',
                '${_commandTitle(context, command)} dikirim ke ${widget.device.name}.',
              ),
      );
      Navigator.of(context).pop(command);
    } on BleWriteException catch (error) {
      if (!mounted) return;
      _showMessage(switch (error.failure) {
        BleWriteFailure.disconnected => context.translate(
          'The BMS disconnected before the command could be sent.',
          'BMS terputus sebelum perintah dapat dikirim.',
        ),
        BleWriteFailure.noWritableCharacteristic => context.translate(
          'No writable Bluetooth characteristic was found on this BMS.',
          'Karakteristik Bluetooth yang dapat ditulis tidak ditemukan pada BMS ini.',
        ),
        BleWriteFailure.transmissionFailed => context.translate(
          'Bluetooth command transmission failed. Please try again.',
          'Pengiriman perintah melalui Bluetooth gagal. Silakan coba lagi.',
        ),
      }, isError: true);
    } on Object {
      if (!mounted) return;
      _showMessage(
        context.translate(
          'The command could not be sent. Please try again.',
          'Perintah tidak dapat dikirim. Silakan coba lagi.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _sending = null);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

String _commandTitle(BuildContext context, BmsCommand command) {
  return switch (command) {
    BmsCommand.resetSoc => context.translate('Reset SoC', 'Reset SoC'),
    BmsCommand.resetBms => context.translate('Reset BMS', 'Reset BMS'),
  };
}

String _commandDescription(BuildContext context, BmsCommand command) {
  return switch (command) {
    BmsCommand.resetSoc => context.translate(
      'Resets the state of charge calculation on the BMS.',
      'Mengatur ulang perhitungan status pengisian pada BMS.',
    ),
    BmsCommand.resetBms => context.translate(
      'Restarts the BMS. The Bluetooth connection may drop briefly.',
      'Memulai ulang BMS. Koneksi Bluetooth dapat terputus sementara.',
    ),
  };
}

class _CommandHeader extends StatelessWidget {
  const _CommandHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(6),
            child: const SizedBox.square(
              dimension: 27,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 27),
            child: Text(
              context.translate('BMS Commands', 'Perintah BMS'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommandCard extends StatelessWidget {
  const _CommandCard({
    required this.command,
    required this.sending,
    required this.enabled,
    required this.onPressed,
  });

  final BmsCommand command;
  final bool sending;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final title = _commandTitle(context, command);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _commandDescription(context, command),
            style: const TextStyle(color: AppColors.text, fontSize: 14),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(49),
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            icon: sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(switch (command) {
                    BmsCommand.resetSoc => Icons.battery_charging_full,
                    BmsCommand.resetBms => Icons.restart_alt_rounded,
                  }),
            label: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
