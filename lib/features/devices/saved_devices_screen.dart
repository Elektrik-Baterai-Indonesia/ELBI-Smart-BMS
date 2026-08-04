import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../monitoring/device_monitoring_screen.dart';
import '../monitoring/monitoring_demo_screen.dart';
import '../scanner/qr_scanner_screen.dart';
import 'saved_device.dart';
import 'saved_device_repository.dart';

class SavedDevicesScreen extends StatefulWidget {
  const SavedDevicesScreen({super.key});

  @override
  State<SavedDevicesScreen> createState() => _SavedDevicesScreenState();
}

class _SavedDevicesScreenState extends State<SavedDevicesScreen> {
  final SavedDeviceRepository _repository = SavedDeviceRepository();

  late Future<List<SavedDevice>> _devicesFuture;
  String? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    _reloadDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('Monitoring Device', 'Pemantauan Perangkat'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: context.translate(
              'Preview monitoring demo',
              'Pratinjau demo pemantauan',
            ),
            onPressed: _openDemo,
            icon: const Icon(Icons.visibility_outlined),
          ),
          IconButton(
            tooltip: context.translate(
              'Add another device',
              'Tambah perangkat lain',
            ),
            onPressed: _addDevice,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<SavedDevice>>(
        future: _devicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }
          if (snapshot.hasError) {
            return _LoadError(onRetry: _reloadDevices);
          }

          final devices = snapshot.data ?? const [];
          if (devices.isEmpty) {
            return _EmptySavedDevices(
              onAddDevice: _addDevice,
              onPreviewDemo: _openDemo,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                child: Text(
                  context.translate(
                    'Choose a saved BMS device to monitor.',
                    'Pilih perangkat BMS tersimpan untuk dipantau.',
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: RadioGroup<String>(
                  groupValue: _selectedDeviceId,
                  onChanged: (deviceId) {
                    setState(() => _selectedDeviceId = deviceId);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: devices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 11),
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return _SavedDeviceCard(
                        device: device,
                        selected: device.id == _selectedDeviceId,
                        onSelected: () {
                          setState(() => _selectedDeviceId = device.id);
                        },
                        onRemove: () => _confirmRemove(device),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton.icon(
          onPressed: _selectedDeviceId == null ? null : _monitorSelectedDevice,
          icon: const Icon(Icons.monitor_heart_outlined),
          label: Text(
            context.translate(
              'Monitor selected device',
              'Pantau perangkat terpilih',
            ),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: AppColors.accent,
          ),
        ),
      ),
    );
  }

  void _reloadDevices() {
    setState(() {
      _devicesFuture = _repository.load();
    });
  }

  Future<void> _addDevice() async {
    final device = await Navigator.of(context).push<SavedDevice>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (!mounted || device == null) return;

    await _repository.save(device);
    if (!mounted) return;
    _selectedDeviceId = device.id;
    _reloadDevices();
  }

  Future<void> _confirmRemove(SavedDevice device) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.translate(
            'Remove saved device?',
            'Hapus perangkat tersimpan?',
          ),
        ),
        content: Text('${device.name}\n${device.id}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.translate('Cancel', 'Batal')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.translate('Remove', 'Hapus')),
          ),
        ],
      ),
    );
    if (shouldRemove != true) return;

    await _repository.remove(device.id);
    if (!mounted) return;
    if (_selectedDeviceId == device.id) _selectedDeviceId = null;
    _reloadDevices();
  }

  Future<void> _monitorSelectedDevice() async {
    final selectedId = _selectedDeviceId;
    if (selectedId == null) return;

    final devices = await _repository.load();
    if (!mounted) return;

    final selectedDevice = devices
        .where((device) => device.id == selectedId)
        .firstOrNull;
    if (selectedDevice == null) {
      _reloadDevices();
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DeviceMonitoringScreen(device: selectedDevice),
      ),
    );
  }

  Future<void> _openDemo() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MonitoringDemoScreen()),
    );
  }
}

class _SavedDeviceCard extends StatelessWidget {
  const _SavedDeviceCard({
    required this.device,
    required this.selected,
    required this.onSelected,
    required this.onRemove,
  });

  final SavedDevice device;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent.withValues(alpha: 0.12) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(color: AppColors.accent, width: selected ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          child: Row(
            children: [
              Radio<String>(value: device.id, activeColor: AppColors.accent),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      device.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.translate(
                  'Remove ${device.name}',
                  'Hapus ${device.name}',
                ),
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySavedDevices extends StatelessWidget {
  const _EmptySavedDevices({
    required this.onAddDevice,
    required this.onPreviewDemo,
  });

  final VoidCallback onAddDevice;
  final VoidCallback onPreviewDemo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.battery_unknown_outlined,
              color: AppColors.accent,
              size: 58,
            ),
            const SizedBox(height: 16),
            Text(
              context.translate(
                'No saved BMS devices',
                'Tidak ada perangkat BMS tersimpan',
              ),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              context.translate(
                'Add a device by scanning its QR code or searching nearby.',
                'Tambahkan perangkat dengan memindai kode QR atau mencari perangkat terdekat.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddDevice,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.translate('Add device', 'Tambah perangkat')),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onPreviewDemo,
              icon: const Icon(Icons.visibility_outlined),
              label: Text(context.translate('Preview demo', 'Pratinjau demo')),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.translate(
              'Saved devices could not be loaded.',
              'Perangkat tersimpan tidak dapat dimuat.',
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(context.translate('Try again', 'Coba lagi')),
          ),
        ],
      ),
    );
  }
}
