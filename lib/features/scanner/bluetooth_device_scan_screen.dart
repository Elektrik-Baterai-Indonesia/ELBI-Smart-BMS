import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../devices/saved_device.dart';

class BluetoothDeviceScanScreen extends StatefulWidget {
  const BluetoothDeviceScanScreen({super.key});

  @override
  State<BluetoothDeviceScanScreen> createState() =>
      _BluetoothDeviceScanScreenState();
}

class _BluetoothDeviceScanScreenState extends State<BluetoothDeviceScanScreen> {
  static const _scanDuration = Duration(seconds: 10);

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final Map<String, DiscoveredDevice> _devices = {};

  StreamSubscription<BleStatus>? _statusSubscription;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  Timer? _scanTimer;

  BleStatus _status = BleStatus.unknown;
  bool _isScanning = false;
  bool _isStartingScan = false;
  bool _hasRequestedInitialScan = false;
  String? _errorMessage;

  List<DiscoveredDevice> get _sortedDevices {
    return _devices.values.toList()..sort((first, second) {
      final firstHasName = first.name.trim().isNotEmpty;
      final secondHasName = second.name.trim().isNotEmpty;
      if (firstHasName != secondHasName) return firstHasName ? -1 : 1;
      return second.rssi.compareTo(first.rssi);
    });
  }

  @override
  void initState() {
    super.initState();
    _statusSubscription = _ble.statusStream.listen(_handleStatusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsAndScan();
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _scanSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = _sortedDevices;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('Bluetooth Devices', 'Perangkat Bluetooth'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            tooltip: context.translate('Scan again', 'Pindai lagi'),
            onPressed: _isScanning ? null : _requestPermissionsAndScan,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _DiscoveryStatus(
            status: _status,
            isScanning: _isScanning,
            deviceCount: devices.length,
            errorMessage: _errorMessage,
          ),
          Expanded(
            child: devices.isEmpty
                ? _EmptyDeviceList(
                    status: _status,
                    isScanning: _isScanning,
                    onScan: _requestPermissionsAndScan,
                  )
                : RefreshIndicator(
                    onRefresh: _requestPermissionsAndScan,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: devices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return _BluetoothDeviceTile(
                          device: device,
                          onTap: () => _selectDevice(device),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissionsAndScan() async {
    if (_isScanning || _isStartingScan) return;
    _hasRequestedInitialScan = true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      if (!mounted) return;

      final scanDenied =
          !(statuses[Permission.bluetoothScan]?.isGranted ?? false);
      final connectDenied =
          !(statuses[Permission.bluetoothConnect]?.isGranted ?? false);
      if (scanDenied || connectDenied) {
        setState(() {
          _errorMessage = context.translate(
            'Nearby-device permission is required to discover BMS devices.',
            'Izin perangkat terdekat diperlukan untuk menemukan perangkat BMS.',
          );
        });
        return;
      }
    }

    if (_ble.status == BleStatus.ready) {
      await _startScan();
    }
  }

  void _handleStatusChange(BleStatus status) {
    if (!mounted) return;
    setState(() => _status = status);

    if (status == BleStatus.ready &&
        _hasRequestedInitialScan &&
        !_isScanning &&
        !_isStartingScan) {
      _startScan();
    }
  }

  Future<void> _startScan() async {
    if (_isScanning || _isStartingScan) return;
    _isStartingScan = true;
    await _stopScan(updateState: false);
    if (!mounted) {
      _isStartingScan = false;
      return;
    }

    setState(() {
      _devices.clear();
      _errorMessage = null;
      _isScanning = true;
    });
    _isStartingScan = false;

    _scanSubscription = _ble
        .scanForDevices(
          withServices: const [],
          scanMode: ScanMode.lowLatency,
          requireLocationServicesEnabled: false,
        )
        .listen(
          (device) {
            if (!mounted) return;
            setState(() => _devices[device.id] = device);
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _errorMessage = context.translate(
                'Bluetooth scan failed. Check permissions and '
                    'make sure Bluetooth is turned on.',
                'Pemindaian Bluetooth gagal. Periksa izin dan pastikan '
                    'Bluetooth telah dinyalakan.',
              );
            });
            _stopScan();
          },
        );

    _scanTimer = Timer(_scanDuration, _stopScan);
  }

  Future<void> _stopScan({bool updateState = true}) async {
    _scanTimer?.cancel();
    _scanTimer = null;
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    if (updateState && mounted && _isScanning) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _selectDevice(DiscoveredDevice device) async {
    await _stopScan();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(SavedDevice.fromIdentifier(device.id, name: device.name));
  }
}

class _DiscoveryStatus extends StatelessWidget {
  const _DiscoveryStatus({
    required this.status,
    required this.isScanning,
    required this.deviceCount,
    required this.errorMessage,
  });

  final BleStatus status;
  final bool isScanning;
  final int deviceCount;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final message = errorMessage ?? _messageForStatus(context);
    final isError = errorMessage != null || status != BleStatus.ready;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? const Color(0xFFFFF1F1)
            : AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (isScanning)
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            )
          else
            Icon(
              isError ? Icons.info_outline : Icons.bluetooth_rounded,
              size: 20,
              color: isError ? Colors.red.shade700 : AppColors.accent,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red.shade800 : AppColors.text,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _messageForStatus(BuildContext context) {
    return switch (status) {
      BleStatus.ready when isScanning => context.translate(
        'Scanning for nearby BLE devices…',
        'Memindai perangkat BLE terdekat…',
      ),
      BleStatus.ready => context.translate(
        '$deviceCount nearby device(s) found.',
        '$deviceCount perangkat terdekat ditemukan.',
      ),
      BleStatus.poweredOff => context.translate(
        'Turn on Bluetooth to scan for BMS devices.',
        'Nyalakan Bluetooth untuk memindai perangkat BMS.',
      ),
      BleStatus.unauthorized => context.translate(
        'Allow nearby-device access to scan for BMS devices.',
        'Izinkan akses perangkat terdekat untuk memindai perangkat BMS.',
      ),
      BleStatus.unsupported => context.translate(
        'Bluetooth LE is not supported on this device.',
        'Bluetooth LE tidak didukung pada perangkat ini.',
      ),
      BleStatus.locationServicesDisabled => context.translate(
        'Turn on location services to scan on this Android device.',
        'Nyalakan layanan lokasi untuk memindai pada perangkat Android ini.',
      ),
      BleStatus.unknown => context.translate(
        'Preparing Bluetooth…',
        'Menyiapkan Bluetooth…',
      ),
    };
  }
}

class _EmptyDeviceList extends StatelessWidget {
  const _EmptyDeviceList({
    required this.status,
    required this.isScanning,
    required this.onScan,
  });

  final BleStatus status;
  final bool isScanning;
  final Future<void> Function() onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 54,
              color: AppColors.accent.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 14),
            Text(
              isScanning
                  ? context.translate(
                      'Looking for available BMS devices…',
                      'Mencari perangkat BMS yang tersedia…',
                    )
                  : context.translate(
                      'No Bluetooth devices found.',
                      'Tidak ada perangkat Bluetooth ditemukan.',
                    ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text, fontSize: 15),
            ),
            if (!isScanning && status == BleStatus.ready) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.translate('Scan again', 'Pindai lagi')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BluetoothDeviceTile extends StatelessWidget {
  const _BluetoothDeviceTile({required this.device, required this.onTap});

  final DiscoveredDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final deviceName = device.name.trim().isEmpty
        ? context.translate('Unnamed BLE device', 'Perangkat BLE tanpa nama')
        : device.name.trim();

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.accent),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          child: Icon(Icons.battery_charging_full_rounded),
        ),
        title: Text(
          deviceName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(device.id, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.network_cell_rounded, size: 18),
            Text('${device.rssi} dBm', style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
