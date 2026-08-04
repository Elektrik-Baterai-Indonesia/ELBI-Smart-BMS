import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../devices/saved_device.dart';
import 'ble_debug_controller.dart';

class BleDebugScreen extends StatelessWidget {
  const BleDebugScreen({
    required this.device,
    required this.controller,
    super.key,
  });

  final SavedDevice device;
  final BleDebugController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('Raw BLE Debug', 'Debug BLE Mentah'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            tooltip: context.translate(
              'Copy latest packet',
              'Salin paket terbaru',
            ),
            onPressed: () => _copyLatest(context),
            icon: const Icon(Icons.copy_all_outlined),
          ),
          IconButton(
            tooltip: context.translate('Clear packets', 'Hapus paket'),
            onPressed: controller.clear,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Column(
            children: [
              _DebugSummary(device: device, controller: controller),
              Expanded(
                child: controller.messages.isEmpty
                    ? _EmptyDebugState(controller: controller)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: controller.messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _PacketCard(
                            message: controller.messages[index],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _copyLatest(BuildContext context) async {
    if (controller.messages.isEmpty) return;
    final message = controller.messages.first;
    await Clipboard.setData(
      ClipboardData(text: message.prettyJson ?? message.text),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.translate(
              'Latest BLE packet copied.',
              'Paket BLE terbaru telah disalin.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _DebugSummary extends StatelessWidget {
  const _DebugSummary({required this.device, required this.controller});

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
                icon: controller.isCapturing
                    ? Icons.sensors_rounded
                    : Icons.sensors_off_rounded,
                label: controller.isDiscovering
                    ? context.translate('Discovering…', 'Mencari…')
                    : controller.isCapturing
                    ? context.translate('Listening', 'Mendengarkan')
                    : context.translate(
                        'No notification stream',
                        'Tidak ada aliran notifikasi',
                      ),
              ),
              _SummaryChip(
                icon: Icons.hub_outlined,
                label: context.translate(
                  '${controller.serviceCount} services',
                  '${controller.serviceCount} layanan',
                ),
              ),
              _SummaryChip(
                icon: Icons.data_object_rounded,
                label: context.translate(
                  '${controller.characteristicCount} characteristics',
                  '${controller.characteristicCount} karakteristik',
                ),
              ),
              _SummaryChip(
                icon: Icons.receipt_long_outlined,
                label: context.translate(
                  '${controller.messages.length} packets',
                  '${controller.messages.length} paket',
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

class _EmptyDebugState extends StatelessWidget {
  const _EmptyDebugState({required this.controller});

  final BleDebugController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.isDiscovering)
              const CircularProgressIndicator(color: AppColors.accent)
            else
              const Icon(
                Icons.data_object_rounded,
                size: 54,
                color: AppColors.accent,
              ),
            const SizedBox(height: 15),
            Text(
              controller.isDiscovering
                  ? context.translate(
                      'Discovering GATT characteristics…',
                      'Mencari karakteristik GATT…',
                    )
                  : context.translate(
                      'Waiting for readable or notified BLE data.',
                      'Menunggu data BLE yang dapat dibaca atau dinotifikasikan.',
                    ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
            ),
            const SizedBox(height: 7),
            Text(
              context.translate(
                'Valid UTF-8 JSON will be formatted automatically. Binary data '
                    'will remain available as text and hexadecimal bytes.',
                'JSON UTF-8 yang valid akan diformat otomatis. Data biner '
                    'tetap tersedia sebagai teks dan byte heksadesimal.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _PacketCard extends StatelessWidget {
  const _PacketCard({required this.message});

  final BleDebugMessage message;

  @override
  Widget build(BuildContext context) {
    final content =
        message.prettyJson ??
        (message.text.isEmpty
            ? context.translate('<binary packet>', '<paket biner>')
            : message.text);
    final time =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:'
        '${message.timestamp.minute.toString().padLeft(2, '0')}:'
        '${message.timestamp.second.toString().padLeft(2, '0')}';

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: message.containsJson
              ? const Color(0xFF008447)
              : AppColors.accent,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(
          message.containsJson
              ? Icons.data_object_rounded
              : Icons.memory_rounded,
          color: message.containsJson
              ? const Color(0xFF008447)
              : AppColors.accent,
        ),
        title: Text(
          '${message.source} • $time',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          message.characteristicId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9),
        ),
        children: [
          _CodeBlock(
            label: message.containsJson ? 'JSON' : 'RAW',
            text: content,
          ),
          const SizedBox(height: 8),
          _CodeBlock(label: 'HEX', text: message.hex),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              '${context.translate('Service', 'Layanan')}: '
              '${message.serviceId}\n'
              '${context.translate('Characteristic', 'Karakteristik')}: '
              '${message.characteristicId}',
              style: const TextStyle(fontSize: 9, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 9),
          ),
          const SizedBox(height: 4),
          SelectableText(
            text,
            style: const TextStyle(
              color: Color(0xFFB9F6CA),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
