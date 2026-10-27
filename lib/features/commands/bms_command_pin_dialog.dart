import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_env.dart';
import '../../core/localization/app_localizations.dart';

/// Asks for the BMS Commands PIN. Returns true only when the PIN matches.
///
/// When no PIN is configured the page stays locked.
Future<bool> showBmsCommandPinDialog(
  BuildContext context, {
  String expectedPin = AppEnv.bmsCommandPin,
}) async {
  if (expectedPin.isEmpty) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.translate(
              'BMS Commands PIN is not configured in this build.',
              'PIN Perintah BMS belum dikonfigurasi pada build ini.',
            ),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    return false;
  }

  final unlocked = await showDialog<bool>(
    context: context,
    builder: (_) => _PinDialog(expectedPin: expectedPin),
  );
  return unlocked ?? false;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.expectedPin});

  final String expectedPin;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text == widget.expectedPin) {
      Navigator.of(context).pop(true);
      return;
    }
    _controller.clear();
    setState(() => _showError = true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.translate('Enter PIN', 'Masukkan PIN')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'PIN',
          errorText: _showError
              ? context.translate('Incorrect PIN.', 'PIN salah.')
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.translate('Cancel', 'Batal')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.translate('Unlock', 'Buka')),
        ),
      ],
    );
  }
}
