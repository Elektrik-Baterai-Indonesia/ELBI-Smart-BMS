import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../devices/saved_device.dart';
import 'ble_debug_controller.dart';

class RawJsonSenderScreen extends StatefulWidget {
  const RawJsonSenderScreen({
    required this.device,
    required this.controller,
    super.key,
  });

  final SavedDevice device;
  final BleDebugController controller;

  @override
  State<RawJsonSenderScreen> createState() => _RawJsonSenderScreenState();
}

class _RawJsonSenderScreenState extends State<RawJsonSenderScreen> {
  static const _maxHistoryEntries = 20;

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<_SentEntry> _sentHistory = [];
  bool _isValidJson = false;
  bool _hasValidationError = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = _inputController.text.trim();
    var isValid = false;
    var hasError = false;

    if (text.isEmpty) {
      isValid = false;
      hasError = false;
    } else {
      try {
        jsonDecode(text);
        isValid = true;
        hasError = false;
      } on FormatException {
        isValid = false;
        hasError = true;
      }
    }

    if (isValid != _isValidJson || hasError != _hasValidationError) {
      setState(() {
        _isValidJson = isValid;
        _hasValidationError = hasError;
      });
    }
  }

  void _formatJson() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    try {
      final decoded = jsonDecode(text);
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      _inputController
        ..text = formatted
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: formatted.length),
        );
    } on FormatException {
      // Can't format invalid JSON — silently ignore.
    }
  }

  void _clearInput() {
    _inputController.clear();
    _focusNode.requestFocus();
  }

  void _reusePayload(String payload) {
    _inputController
      ..text = payload
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: payload.length),
      );
    _focusNode.requestFocus();
  }

  Future<void> _sendJson() async {
    final payload = _inputController.text.trim();
    if (payload.isEmpty || !_isValidJson || _isSending) return;

    setState(() => _isSending = true);

    try {
      await widget.controller.writeJson(payload);
      if (!mounted) return;
      setState(() {
        _sentHistory.insert(
          0,
          _SentEntry(
            payload: payload,
            sentAt: DateTime.now(),
            success: true,
          ),
        );
        if (_sentHistory.length > _maxHistoryEntries) {
          _sentHistory.removeRange(
            _maxHistoryEntries,
            _sentHistory.length,
          );
        }
        _isSending = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.translate('JSON sent.', 'JSON dikirim.')),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on BleWriteException catch (e) {
      if (!mounted) return;
      final message = _messageForWriteFailure(e.failure);
      setState(() {
        _sentHistory.insert(
          0,
          _SentEntry(
            payload: payload,
            sentAt: DateTime.now(),
            success: false,
            errorMessage: message,
          ),
        );
        if (_sentHistory.length > _maxHistoryEntries) {
          _sentHistory.removeRange(
            _maxHistoryEntries,
            _sentHistory.length,
          );
        }
        _isSending = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on Object {
      if (!mounted) return;
      final fallback = context.translate(
        'Failed to send JSON.',
        'Gagal mengirim JSON.',
      );
      setState(() {
        _sentHistory.insert(
          0,
          _SentEntry(
            payload: payload,
            sentAt: DateTime.now(),
            success: false,
            errorMessage: fallback,
          ),
        );
        if (_sentHistory.length > _maxHistoryEntries) {
          _sentHistory.removeRange(
            _maxHistoryEntries,
            _sentHistory.length,
          );
        }
        _isSending = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(fallback),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  String _messageForWriteFailure(BleWriteFailure failure) {
    return switch (failure) {
      BleWriteFailure.disconnected => context.translate(
        'Bluetooth is disconnected.',
        'Bluetooth terputus.',
      ),
      BleWriteFailure.noWritableCharacteristic => context.translate(
        'No writable characteristic found.',
        'Tidak ada karakteristik yang dapat ditulis.',
      ),
      BleWriteFailure.transmissionFailed => context.translate(
        'Transmission failed.',
        'Transmisi gagal.',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('Send Raw JSON', 'Kirim JSON Mentah'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            tooltip: context.translate('Format JSON', 'Format JSON'),
            onPressed: _formatJson,
            icon: const Icon(Icons.format_align_left_rounded),
          ),
          IconButton(
            tooltip: context.translate('Clear input', 'Hapus input'),
            onPressed: _clearInput,
            icon: const Icon(Icons.clear_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) => _DeviceSummary(
              device: widget.device,
              controller: widget.controller,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _JsonInputSection(
                    controller: _inputController,
                    focusNode: _focusNode,
                    isValidJson: _isValidJson,
                    hasValidationError: _hasValidationError,
                    isSending: _isSending,
                    onSend: _sendJson,
                  ),
                  if (_sentHistory.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SentHistorySection(
                      entries: _sentHistory,
                      onReuse: _reusePayload,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSummary extends StatelessWidget {
  const _DeviceSummary({required this.device, required this.controller});

  final SavedDevice device;
  final BleDebugController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device.name,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            device.id,
            style: const TextStyle(color: AppColors.text, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _SummaryChip(
                icon: controller.isDiscovering
                    ? Icons.search_rounded
                    : Icons.bluetooth_connected_rounded,
                label: controller.isDiscovering
                    ? context.translate('Discovering…', 'Mencari…')
                    : context.translate('Ready', 'Siap'),
              ),
              _SummaryChip(
                icon: Icons.data_object_rounded,
                label: context.translate(
                  '${controller.characteristicCount} characteristics',
                  '${controller.characteristicCount} karakteristik',
                ),
              ),
            ],
          ),
          if (controller.errorMessage case final error?) ...[
            const SizedBox(height: 9),
            Text(
              error ==
                      'GATT services could not be inspected on this connection.'
                  ? context.translate(
                      error,
                      'Layanan GATT tidak dapat diperiksa pada koneksi ini.',
                    )
                  : error,
              style: TextStyle(color: Colors.red.shade700, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.text, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _JsonInputSection extends StatelessWidget {
  const _JsonInputSection({
    required this.controller,
    required this.focusNode,
    required this.isValidJson,
    required this.hasValidationError,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isValidJson;
  final bool hasValidationError;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasValidationError
        ? Colors.red.shade700
        : isValidJson
        ? const Color(0xFF008447)
        : AppColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.translate('JSON Payload', 'Muatan JSON'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: 8,
          minLines: 4,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(
            hintText: '{"serial_number": "00BB1000", "soc": 50}',
            hintStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.grey,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
          ),
        ),
        if (hasValidationError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade700,
                size: 15,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  context.translate(
                    'Invalid JSON format.',
                    'Format JSON tidak valid.',
                  ),
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
        ] else if (isValidJson) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF008447),
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                context.translate('Valid JSON', 'JSON valid'),
                style: const TextStyle(
                  color: Color(0xFF008447),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: (isSending || !isValidJson) ? null : onSend,
          icon: isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded),
          label: Text(
            isSending
                ? context.translate('Sending…', 'Mengirim…')
                : context.translate('Send JSON', 'Kirim JSON'),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

class _SentHistorySection extends StatelessWidget {
  const _SentHistorySection({
    required this.entries,
    required this.onReuse,
  });

  final List<_SentEntry> entries;
  final ValueChanged<String> onReuse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.translate('Sent History', 'Riwayat Kirim'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SentEntryCard(entry: entry, onReuse: onReuse),
          ),
      ],
    );
  }
}

class _SentEntryCard extends StatelessWidget {
  const _SentEntryCard({required this.entry, required this.onReuse});

  final _SentEntry entry;
  final ValueChanged<String> onReuse;

  @override
  Widget build(BuildContext context) {
    final time =
        '${entry.sentAt.hour.toString().padLeft(2, '0')}:'
        '${entry.sentAt.minute.toString().padLeft(2, '0')}:'
        '${entry.sentAt.second.toString().padLeft(2, '0')}';

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: entry.success
              ? const Color(0xFF008447)
              : Colors.red.shade700,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(
          entry.success ? Icons.check_circle_rounded : Icons.error_rounded,
          color: entry.success
              ? const Color(0xFF008447)
              : Colors.red.shade700,
          size: 20,
        ),
        title: Text(
          '${entry.success ? 'SENT' : 'FAILED'} • $time',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(7),
            ),
            child: SelectableText(
              entry.payload,
              style: const TextStyle(
                color: Color(0xFFB9F6CA),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          if (entry.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              entry.errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 11),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => onReuse(entry.payload),
              icon: const Icon(Icons.replay_rounded, size: 16),
              label: Text(
                context.translate('Reuse', 'Gunakan ulang'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentEntry {
  const _SentEntry({
    required this.payload,
    required this.sentAt,
    required this.success,
    this.errorMessage,
  });

  final String payload;
  final DateTime sentAt;
  final bool success;
  final String? errorMessage;
}