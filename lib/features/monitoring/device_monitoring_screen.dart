import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../devices/saved_device.dart';
import '../settings/app_settings.dart';
import '../settings/app_settings_controller.dart';
import '../settings/bms_settings.dart';
import '../settings/bms_settings_screen.dart';
import 'ble_debug_controller.dart';
import 'ble_debug_screen.dart';
import 'bms_csv_logger.dart';
import 'bms_telemetry.dart';

class DeviceMonitoringScreen extends StatefulWidget {
  const DeviceMonitoringScreen({
    required this.device,
    this.demoMode = false,
    super.key,
  });

  final SavedDevice device;
  final bool demoMode;

  @override
  State<DeviceMonitoringScreen> createState() => _DeviceMonitoringScreenState();
}

class _DeviceMonitoringScreenState extends State<DeviceMonitoringScreen> {
  static const _kConnectionTimeout = Duration(seconds: 12);
  static const _kDisconnectDelay = Duration(milliseconds: 300);
  static const _kDemoInterval = Duration(seconds: 2);
  static const _kTelemetryBufferSize = 32768;
  static const _kLowBatteryThreshold = 0.15;
  static const _kChargingCurrentThreshold = 0.5;
  static const _kDemoVoltageMin = 48.0;
  static const _kDemoVoltageMax = 58.0;
  static const _kDemoTempMin = 15.0;
  static const _kDemoTempMax = 65.0;
  static const _kDemoCellVoltageDelta = 15;
  static const _kDemoChargeMin = 0.05;
  static const _kDemoChargeMax = 0.98;
  static const _kDemoChargeLowMax = 0.14;
  static const _kDemoChargeDelta = 0.008;
  static const _kDemoChargeBias = 0.54;
  static const _kDemoChargeNormal = 0.52;
  static const _kDemoChargeLow = 0.12;
  static const _kDemoCellVoltageClampMin = 0;
  static const _kDemoCellVoltageClampMax = 5000;
  static const _kDemoVoltageRange = 0.8;
  static const _kDemoVoltageNormal = 54.6;
  static const _kDemoTempBase = 30.0;
  static const _kDemoTempVariance = 3.0;
  static const _kDemoCurrentNormal = 18.0;
  bool _showPackMetrics = true;
  bool _demoRunning = true;
  bool _demoFault = false;
  bool _demoLowBattery = false;
  bool _hasTelemetry = false;
  double _charge = 0.52;
  double _voltage = _kDemoVoltageNormal;
  double _current = _kDemoCurrentNormal;
  double _temperature = 30;
  List<int> _cellVoltageMillivolts = [
    3650,
    3156,
    2684,
    1650,
    516,
    2568,
    1165,
    1210,
    1256,
    3251,
    2785,
    3051,
    3120,
    2015,
    3551,
    2017,
    2320,
    3020,
    3881,
    3255,
    3210,
    2650,
    2054,
    3561,
  ];
  int _errorCode = 0;
  String? _serialNumber;
  DateTime? _lastTelemetryAt;
  BleDebugMessage? _lastTelemetryMessage;
  String _telemetryBuffer = '';
  String? _telemetryCharacteristicId;
  Timer? _demoTimer;
  final math.Random _random = math.Random(3);
  late final List<_ErrorLogEntry> _errorLogs;

  FlutterReactiveBle? _ble;
  StreamSubscription<BleStatus>? _bleStatusSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  BleStatus _bleStatus = BleStatus.unknown;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;
  bool _connectionRequested = false;
  bool _connectionAttemptActive = false;
  bool _isClosing = false;
  bool _allowPop = false;
  int _connectionGeneration = 0;
  String? _connectionError;
  BleDebugController? _debugController;
  BmsCsvLogger? _csvLogger;
  BmsSettings? _deviceSettings;

  @override
  void initState() {
    super.initState();
    if (widget.demoMode) {
      _errorLogs = [];
      _startDemo();
    } else {
      _errorLogs = [];
      _charge = 0;
      _initializeBluetoothConnection();
    }
  }

  @override
  void dispose() {
    _isClosing = true;
    _connectionRequested = false;
    _connectionGeneration++;
    _demoTimer?.cancel();
    unawaited(_finishDataRecording(notify: false));
    _debugController?.dispose();
    _bleStatusSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = AppSettingsScope.maybeOf(context);
    final temperatureUnit =
        appSettings?.temperatureUnit ?? TemperatureUnit.celsius;
    final hasData = _hasTelemetry || widget.demoMode;
    final packVoltage = hasData ? '${_voltage.toStringAsFixed(2)} V' : '--';
    final packCurrent = hasData ? '${_current.toStringAsFixed(2)} A' : '--';
    final temperature = hasData
        ? '${temperatureUnit.convertFromCelsius(_temperature).toStringAsFixed(1)}'
              '${temperatureUnit.symbol}'
        : '--';
    final status = widget.demoMode
        ? (_demoFault ? context.translate('FAULT', 'GANGGUAN') : 'OK')
        : !_hasTelemetry
        ? '--'
        : _errorCode == 0
        ? 'OK'
        : context.translate('ERROR', 'KESALAHAN');

    final metrics = [
      _MetricData(
        label: context.translate('Voltage', 'Tegangan'),
        value: packVoltage,
        icon: Icons.battery_charging_full_rounded,
      ),
      _MetricData(
        label: context.translate('Current', 'Arus'),
        value: packCurrent,
        icon: Icons.electric_bolt_rounded,
      ),
      _MetricData(
        label: context.translate('Temperature', 'Suhu'),
        value: temperature,
        icon: Icons.device_thermostat_rounded,
      ),
      _MetricData(
        label: context.translate('Status', 'Status'),
        value: status,
        icon: Icons.adjust_rounded,
      ),
    ];

    return PopScope(
      canPop: widget.demoMode || _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_closeAndPop());
      },
      child: Scaffold(
        floatingActionButton:
            !widget.demoMode &&
                (appSettings?.showRawJson ?? false) &&
                _connectionState == DeviceConnectionState.connected
            ? FloatingActionButton.extended(
                tooltip: context.translate(
                  'Open raw BLE debug',
                  'Buka debug BLE mentah',
                ),
                onPressed: _openDebugPage,
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.data_object_rounded),
                label: const Text(''),
              )
            : null,
        body: SafeArea(
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(36, 46, 36, 14),
                sliver: SliverList.list(
                  children: [
                    _MonitoringHeader(
                      onBack: _closeAndPop,
                      onSettings: _showSettingsMessage,
                    ),
                    const SizedBox(height: 43),
                    _DeviceBanner(name: _serialNumber ?? widget.device.name),
                    if (widget.demoMode) ...[
                      const SizedBox(height: 10),
                      _DemoControls(
                        running: _demoRunning,
                        faultActive: _demoFault,
                        lowBatteryActive: _demoLowBattery,
                        onToggleRunning: _toggleDemo,
                        onNewSample: _updateDemoData,
                        onToggleFault: _toggleDemoFault,
                        onToggleLowBattery: _toggleDemoLowBattery,
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      _ConnectionPanel(
                        deviceId: widget.device.id,
                        bleStatus: _bleStatus,
                        connectionState: _connectionState,
                        errorMessage: _connectionError,
                        onRetry: _prepareConnection,
                        onDisconnect: _disconnect,
                      ),
                    ],
                    const SizedBox(height: 18),
                    _StateOfChargeCard(
                      charge: _charge,
                      hasData: hasData,
                      isCharging:
                          hasData && _current > _kChargingCurrentThreshold,
                      isLow: hasData && _charge < _kLowBatteryThreshold,
                      statusLabel: _chargeStatusLabel(context),
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: _PackCellToggle(
                        showPack: _showPackMetrics,
                        onChanged: (showPack) {
                          setState(() => _showPackMetrics = showPack);
                        },
                      ),
                    ),
                    const SizedBox(height: 11),
                    if (_showPackMetrics) ...[
                      _MetricGrid(metrics: metrics),
                      const SizedBox(height: 22),
                      Text(
                        context.translate('Error Logs', 'Log Kesalahan'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ErrorLogTable(rows: _errorLogs),
                    ] else
                      _CellMonitoringSection(
                        cellVoltages: hasData
                            ? _cellVoltageMillivolts
                            : const [],
                      ),
                    const SizedBox(height: 31),
                    const Text(
                      AppTheme.brandName,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.accent, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSettingsMessage() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BmsSettingsScreen(
          device: widget.device,
          demoMode: widget.demoMode,
          initialSettings: _deviceSettings,
          onSendParameters:
              !widget.demoMode &&
                  _connectionState == DeviceConnectionState.connected
              ? _debugController?.writeJson
              : null,
        ),
      ),
    );
  }

  void _initializeBluetoothConnection() {
    final ble = FlutterReactiveBle();
    _ble = ble;
    _bleStatusSubscription = ble.statusStream.listen((status) {
      if (!mounted || _isClosing) return;
      setState(() => _bleStatus = status);

      if (status == BleStatus.ready &&
          _connectionRequested &&
          !_connectionAttemptActive &&
          _connectionState != DeviceConnectionState.connected) {
        _connect();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareConnection());
  }

  Future<void> _prepareConnection() async {
    if (widget.demoMode || _connectionAttemptActive || _isClosing) return;
    _connectionRequested = true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final permission = await Permission.bluetoothConnect.request();
      if (!mounted || _isClosing) return;
      if (!permission.isGranted) {
        setState(() {
          _connectionError = context.translate(
            'Nearby-device permission is required to connect.',
            'Izin perangkat terdekat diperlukan untuk menghubungkan.',
          );
          _connectionRequested = false;
        });
        return;
      }
    }

    final ble = _ble;
    if (ble == null) return;
    if (ble.status == BleStatus.ready) {
      await _connect();
    } else if (mounted) {
      setState(() {
        _connectionError = _messageForBleStatus(context, ble.status);
      });
    }
  }

  Future<void> _connect() async {
    final ble = _ble;
    if (ble == null || _connectionAttemptActive || _isClosing) return;

    final generation = ++_connectionGeneration;
    _connectionAttemptActive = true;
    await _connectionSubscription?.cancel();
    if (!mounted ||
        _isClosing ||
        generation != _connectionGeneration ||
        !_connectionRequested) {
      _connectionAttemptActive = false;
      return;
    }

    setState(() {
      _connectionState = DeviceConnectionState.connecting;
      _connectionError = null;
    });

    _connectionSubscription = ble
        .connectToDevice(
          id: widget.device.id,
          connectionTimeout: _kConnectionTimeout,
        )
        .listen(
          (update) {
            if (!mounted || _isClosing || generation != _connectionGeneration) {
              return;
            }
            if (update.connectionState == DeviceConnectionState.connected) {
              _startDataRecording();
              _startDebugCapture();
            }
            setState(() {
              _connectionState = update.connectionState;
              _connectionError = update.failure == null
                  ? null
                  : context.translate(
                      'The BMS reported a Bluetooth connection failure.',
                      'BMS melaporkan kegagalan koneksi Bluetooth.',
                    );
            });

            if (update.connectionState == DeviceConnectionState.disconnected) {
              _debugController?.stop();
              unawaited(_finishDataRecording());
              _connectionAttemptActive = false;
              _connectionRequested = false;
            }
          },
          onError: (Object error) {
            if (!mounted || _isClosing || generation != _connectionGeneration) {
              return;
            }
            setState(() {
              _connectionState = DeviceConnectionState.disconnected;
              _connectionError = context.translate(
                'Could not connect. Keep the BMS nearby and advertising.',
                'Tidak dapat terhubung. Pastikan BMS berada di dekat dan sedang mengirim sinyal.',
              );
            });
            _connectionAttemptActive = false;
            _connectionRequested = false;
            unawaited(_finishDataRecording());
          },
          onDone: () {
            if (generation != _connectionGeneration) return;
            _connectionAttemptActive = false;
          },
        );
  }

  Future<void> _disconnect() async {
    if (_isClosing) return;
    _connectionRequested = false;
    _connectionGeneration++;
    if (mounted) {
      setState(() {
        _connectionState = DeviceConnectionState.disconnecting;
        _connectionError = null;
      });
    }

    await _debugController?.stop();
    await _finishDataRecording();
    await Future<void>.delayed(_kDisconnectDelay);
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _connectionAttemptActive = false;
    if (!mounted) return;
    setState(() {
      _connectionState = DeviceConnectionState.disconnected;
    });
  }

  Future<void> _closeAndPop() async {
    if (widget.demoMode) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (_isClosing) return;

    _isClosing = true;
    _connectionRequested = false;
    _connectionGeneration++;
    _demoTimer?.cancel();

    await _debugController?.stop();
    await _finishDataRecording();
    await Future<void>.delayed(_kDisconnectDelay);
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _bleStatusSubscription?.cancel();
    _bleStatusSubscription = null;
    _connectionAttemptActive = false;

    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  String _messageForBleStatus(BuildContext context, BleStatus status) {
    return switch (status) {
      BleStatus.poweredOff => context.translate(
        'Turn on Bluetooth to connect to this BMS.',
        'Nyalakan Bluetooth untuk terhubung ke BMS ini.',
      ),
      BleStatus.unauthorized => context.translate(
        'Allow nearby-device access to connect to this BMS.',
        'Izinkan akses perangkat terdekat untuk terhubung ke BMS ini.',
      ),
      BleStatus.unsupported => context.translate(
        'Bluetooth LE is not supported on this device.',
        'Bluetooth LE tidak didukung pada perangkat ini.',
      ),
      BleStatus.locationServicesDisabled => context.translate(
        'Turn on location services to connect on this Android device.',
        'Nyalakan layanan lokasi untuk terhubung pada perangkat Android ini.',
      ),
      BleStatus.unknown => context.translate(
        'Preparing Bluetooth…',
        'Menyiapkan Bluetooth…',
      ),
      BleStatus.ready => context.translate(
        'Ready to connect.',
        'Siap terhubung.',
      ),
    };
  }

  void _startDebugCapture() {
    final ble = _ble;
    if (ble == null) return;
    final controller = _debugController ??= BleDebugController(
      ble: ble,
      deviceId: widget.device.id,
    );
    controller.removeListener(_handleDebugPackets);
    controller.addListener(_handleDebugPackets);
    controller.start();
  }

  void _handleDebugPackets() {
    final controller = _debugController;
    if (controller == null || controller.messages.isEmpty || !mounted) return;

    final message = controller.messages.first;
    if (identical(message, _lastTelemetryMessage)) return;
    _lastTelemetryMessage = message;

    final telemetry = _decodeTelemetryMessage(message);
    if (telemetry == null) return;

    final receivedAt = DateTime.now();
    _csvLogger?.record(telemetry, receivedAt);
    setState(() {
      _hasTelemetry = true;
      _serialNumber = telemetry.serialNumber;
      _charge = telemetry.soc / 100;
      _voltage = telemetry.voltage;
      _current = telemetry.current;
      _temperature = telemetry.temperature;
      _cellVoltageMillivolts = telemetry.monitoringCellVoltageMillivolts;
      _errorCode = telemetry.errorCode;
      _lastTelemetryAt = receivedAt;
      if (telemetry.settings != null) {
        _deviceSettings = telemetry.settings;
      }

      if (!telemetry.hasError) {
        _errorLogs.clear();
      } else {
        _errorLogs.removeWhere((log) => log.liveTelemetry);
        _errorLogs.insert(
          0,
          _ErrorLogEntry(
            timestamp: _formatTimestamp(receivedAt),
            code: 'F${telemetry.errorCode}',
            description: context.translate(
              'BMS error code ${telemetry.errorCode}',
              'Kode kesalahan BMS ${telemetry.errorCode}',
            ),
            liveTelemetry: true,
          ),
        );
      }
    });
  }

  void _startDataRecording() {
    if (_csvLogger != null || widget.demoMode) return;
    final shouldRecord = AppSettingsScope.maybeOf(context)?.recordData ?? false;
    if (!shouldRecord) return;

    final logger = BmsCsvLogger(device: widget.device);
    _csvLogger = logger;
    unawaited(
      logger.ready.then<void>(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          if (!identical(_csvLogger, logger)) return;
          _csvLogger = null;
          _showDataRecordingError();
        },
      ),
    );
  }

  Future<void> _finishDataRecording({bool notify = true}) async {
    final logger = _csvLogger;
    if (logger == null) return;
    _csvLogger = null;
    try {
      final location = await logger.finish();
      if (!notify || !mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.translate(
                'Data recording saved to $location',
                'Rekaman data disimpan di $location',
              ),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
    } on Object {
      if (notify) _showDataRecordingError();
    }
  }

  void _showDataRecordingError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.translate(
              'Could not save the CSV data recording.',
              'Tidak dapat menyimpan rekaman data CSV.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  BmsTelemetry? _decodeTelemetryMessage(BleDebugMessage message) {
    final direct = BmsTelemetry.tryParse(message.text);
    if (direct != null) {
      _telemetryBuffer = '';
      _telemetryCharacteristicId = message.characteristicId;
      return direct;
    }

    if (_telemetryCharacteristicId == message.characteristicId &&
        _telemetryBuffer.isNotEmpty) {
      _telemetryBuffer += message.text;
    } else {
      final objectStart = message.text.indexOf('{');
      if (objectStart < 0) return null;
      _telemetryBuffer = message.text.substring(objectStart);
      _telemetryCharacteristicId = message.characteristicId;
    }

    if (_telemetryBuffer.length > _kTelemetryBufferSize) {
      _telemetryBuffer = '';
      return null;
    }

    final buffered = BmsTelemetry.tryParse(_telemetryBuffer);
    if (buffered != null) _telemetryBuffer = '';
    return buffered;
  }

  String _chargeStatusLabel(BuildContext context) {
    if (widget.demoMode) {
      return context.translate(
        'Live simulated\ndata',
        'Data simulasi\nlangsung',
      );
    }
    final lastTelemetryAt = _lastTelemetryAt;
    if (lastTelemetryAt == null) {
      return context.translate('Waiting for\nBMS data', 'Menunggu data\nBMS');
    }
    return '${context.translate('Updated', 'Diperbarui')}\n'
        '${lastTelemetryAt.hour.toString().padLeft(2, '0')}:'
        '${lastTelemetryAt.minute.toString().padLeft(2, '0')}:'
        '${lastTelemetryAt.second.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day.toString().padLeft(2, '0')}-'
        '${timestamp.month.toString().padLeft(2, '0')}-'
        '${timestamp.year} '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  Future<void> _openDebugPage() async {
    final controller = _debugController;
    if (controller == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            BleDebugScreen(device: widget.device, controller: controller),
      ),
    );
  }

  void _startDemo() {
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(_kDemoInterval, (_) => _updateDemoData());
  }

  void _toggleDemo() {
    setState(() => _demoRunning = !_demoRunning);
    if (_demoRunning) {
      _startDemo();
    } else {
      _demoTimer?.cancel();
    }
  }

  void _updateDemoData() {
    if (!mounted) return;
    setState(() {
      _charge =
          (_charge +
                  (_random.nextDouble() - _kDemoChargeBias) * _kDemoChargeDelta)
              .clamp(
                _kDemoChargeMin,
                _demoLowBattery ? _kDemoChargeLowMax : _kDemoChargeMax,
              );
      _voltage =
          (_kDemoVoltageNormal +
                  (_random.nextDouble() - 0.5) * _kDemoVoltageRange)
              .clamp(_kDemoVoltageMin, _kDemoVoltageMax);
      _current = -80 + (_random.nextDouble() * 110);
      _temperature =
          (_kDemoTempBase + (_random.nextDouble() - 0.5) * _kDemoTempVariance)
              .clamp(_kDemoTempMin, _kDemoTempMax);
      _cellVoltageMillivolts = [
        for (final voltage in _cellVoltageMillivolts)
          (voltage + _random.nextInt(_kDemoCellVoltageDelta) - 7).clamp(
            _kDemoCellVoltageClampMin,
            _kDemoCellVoltageClampMax,
          ),
      ];
    });
  }

  void _toggleDemoFault() {
    setState(() {
      _demoFault = !_demoFault;
      if (_demoFault) {
        final now = TimeOfDay.now();
        _errorLogs.insert(
          0,
          _ErrorLogEntry(
            timestamp:
                'Demo ${now.hour.toString().padLeft(2, '0')}:'
                '${now.minute.toString().padLeft(2, '0')}',
            code: 'DF',
            description: context.translate(
              'Demo pack fault injected',
              'Gangguan paket demo disimulasikan',
            ),
          ),
        );
      } else {
        _errorLogs.removeWhere((log) => log.code == 'DF');
      }
    });
  }

  void _toggleDemoLowBattery() {
    setState(() {
      _demoLowBattery = !_demoLowBattery;
      _charge = _demoLowBattery ? _kDemoChargeLow : _kDemoChargeNormal;
    });
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({
    required this.deviceId,
    required this.bleStatus,
    required this.connectionState,
    required this.errorMessage,
    required this.onRetry,
    required this.onDisconnect,
  });

  final String deviceId;
  final BleStatus bleStatus;
  final DeviceConnectionState connectionState;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onDisconnect;

  bool get _isBusy =>
      connectionState == DeviceConnectionState.connecting ||
      connectionState == DeviceConnectionState.disconnecting;

  bool get _isConnected => connectionState == DeviceConnectionState.connected;

  @override
  Widget build(BuildContext context) {
    final statusColor = _isConnected
        ? const Color(0xFF008447)
        : _isBusy
        ? Colors.orange.shade700
        : Colors.red.shade700;
    final statusLabel = switch (connectionState) {
      DeviceConnectionState.connecting => context.translate(
        'Connecting…',
        'Menghubungkan…',
      ),
      DeviceConnectionState.connected => context.translate(
        'Connected',
        'Terhubung',
      ),
      DeviceConnectionState.disconnecting => context.translate(
        'Disconnecting…',
        'Memutuskan…',
      ),
      DeviceConnectionState.disconnected => context.translate(
        'Disconnected',
        'Terputus',
      ),
    };
    final detail =
        errorMessage ??
        (_isConnected
            ? deviceId
            : bleStatus == BleStatus.ready
            ? context.translate(
                'Ready to connect to $deviceId',
                'Siap terhubung ke $deviceId',
              )
            : context.translate(
                'Bluetooth is not ready.',
                'Bluetooth belum siap.',
              ));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          if (_isBusy)
            SizedBox.square(
              dimension: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            )
          else
            Icon(
              _isConnected
                  ? Icons.bluetooth_connected_rounded
                  : Icons.bluetooth_disabled_rounded,
              size: 21,
              color: statusColor,
            ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.text, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          TextButton(
            onPressed: _isBusy
                ? null
                : _isConnected
                ? onDisconnect
                : onRetry,
            child: Text(
              _isConnected
                  ? context.translate('Disconnect', 'Putuskan')
                  : context.translate('Retry', 'Coba lagi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoControls extends StatelessWidget {
  const _DemoControls({
    required this.running,
    required this.faultActive,
    required this.lowBatteryActive,
    required this.onToggleRunning,
    required this.onNewSample,
    required this.onToggleFault,
    required this.onToggleLowBattery,
  });

  final bool running;
  final bool faultActive;
  final bool lowBatteryActive;
  final VoidCallback onToggleRunning;
  final VoidCallback onNewSample;
  final VoidCallback onToggleFault;
  final VoidCallback onToggleLowBattery;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 9,
                color: running ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                running
                    ? context.translate('Live demo data', 'Data demo langsung')
                    : context.translate('Demo paused', 'Demo dijeda'),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 5,
            children: [
              ActionChip(
                avatar: Icon(
                  running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 17,
                ),
                label: Text(
                  running
                      ? context.translate('Pause', 'Jeda')
                      : context.translate('Resume', 'Lanjutkan'),
                ),
                onPressed: onToggleRunning,
                visualDensity: VisualDensity.compact,
              ),
              ActionChip(
                avatar: const Icon(Icons.refresh_rounded, size: 17),
                label: Text(context.translate('New sample', 'Sampel baru')),
                onPressed: onNewSample,
                visualDensity: VisualDensity.compact,
              ),
              ActionChip(
                avatar: Icon(
                  faultActive
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  size: 17,
                ),
                label: Text(
                  faultActive
                      ? context.translate('Clear fault', 'Hapus gangguan')
                      : context.translate(
                          'Simulate fault',
                          'Simulasikan gangguan',
                        ),
                ),
                onPressed: onToggleFault,
                visualDensity: VisualDensity.compact,
              ),
              ActionChip(
                avatar: Icon(
                  lowBatteryActive
                      ? Icons.battery_std_rounded
                      : Icons.battery_alert_rounded,
                  size: 17,
                ),
                label: Text(
                  lowBatteryActive
                      ? context.translate(
                          'Clear low battery',
                          'Hapus baterai lemah',
                        )
                      : context.translate(
                          'Simulate low battery',
                          'Simulasikan baterai lemah',
                        ),
                ),
                onPressed: onToggleLowBattery,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonitoringHeader extends StatelessWidget {
  const _MonitoringHeader({required this.onBack, required this.onSettings});

  final VoidCallback onBack;
  final VoidCallback onSettings;

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
          child: Text(
            context.translate('Monitoring Device', 'Pemantauan Perangkat'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: context.translate('Device settings', 'Pengaturan perangkat'),
          onPressed: onSettings,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          icon: const Icon(
            Icons.settings_outlined,
            color: AppColors.accent,
            size: 30,
          ),
        ),
      ],
    );
  }
}

class _DeviceBanner extends StatelessWidget {
  const _DeviceBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.developer_board_rounded,
            color: Color(0xFF00A521),
            size: 19,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateOfChargeCard extends StatelessWidget {
  const _StateOfChargeCard({
    required this.charge,
    required this.hasData,
    required this.isCharging,
    required this.isLow,
    required this.statusLabel,
  });

  final double charge;
  final bool hasData;
  final bool isCharging;
  final bool isLow;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      padding: const EdgeInsets.fromLTRB(18, 11, 17, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.translate('Stage of Charge', 'Tingkat Daya'),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _SegmentedBattery(
                    charge: charge,
                    isCharging: isCharging,
                    isLow: isLow,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 17),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasData ? '${(charge * 100).round()}%' : '--%',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                if (isLow)
                  const _LowBatteryBadge()
                else if (isCharging)
                  const _ChargingBadge()
                else
                  Text(
                    statusLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 11,
                      height: 1.05,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedBattery extends StatelessWidget {
  const _SegmentedBattery({
    required this.charge,
    required this.isCharging,
    required this.isLow,
  });

  static const _segmentCount = 8;
  final double charge;
  final bool isCharging;
  final bool isLow;

  @override
  Widget build(BuildContext context) {
    final chargedSegments = (charge * _segmentCount).ceil();

    return Row(
      children: [
        for (var index = 0; index < _segmentCount; index++) ...[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: index < chargedSegments
                    ? isLow
                          ? const Color(0xFFFF5364)
                          : isCharging
                          ? const Color(0xFF0D82F8)
                          : const Color(0xFF008447)
                    : const Color(0xFFD8D8D8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (index < _segmentCount - 1) const SizedBox(width: 4),
        ],
        const SizedBox(width: 6),
        Container(
          width: 10,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFD8D8D8),
            borderRadius: BorderRadius.horizontal(right: Radius.circular(7)),
          ),
        ),
      ],
    );
  }
}

class _LowBatteryBadge extends StatelessWidget {
  const _LowBatteryBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 6, 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9EC),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.translate('Low', 'Lemah'),
            style: const TextStyle(
              color: Color(0xFFFF5364),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.error_rounded, color: Color(0xFFFF5364), size: 13),
        ],
      ),
    );
  }
}

class _ChargingBadge extends StatelessWidget {
  const _ChargingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 5, 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.translate('Charging', 'Mengisi daya'),
            style: const TextStyle(
              color: Color(0xFF0D82F8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.bolt_rounded, color: Color(0xFF0D82F8), size: 14),
        ],
      ),
    );
  }
}

class _PackCellToggle extends StatelessWidget {
  const _PackCellToggle({required this.showPack, required this.onChanged});

  final bool showPack;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 162,
      height: 25,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: context.translate('Pack', 'Paket'),
              selected: showPack,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleOption(
              label: context.translate('Cell', 'Sel'),
              selected: !showPack,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _CellMonitoringSection extends StatelessWidget {
  const _CellMonitoringSection({required this.cellVoltages});

  final List<int> cellVoltages;

  @override
  Widget build(BuildContext context) {
    final activeCells = <MapEntry<int, int>>[
      for (final entry in cellVoltages.indexed)
        if (entry.$2 > 0) MapEntry(entry.$1, entry.$2),
    ];
    final maximum = activeCells.isEmpty
        ? null
        : activeCells.reduce((a, b) => a.value >= b.value ? a : b);
    final minimum = activeCells.isEmpty
        ? null
        : activeCells.reduce((a, b) => a.value <= b.value ? a : b);
    final difference = maximum == null || minimum == null
        ? null
        : maximum.value - minimum.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate('Statistic', 'Statistik'),
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _CellStatisticCard(
                label: context.translate('VCell Max (mV)', 'VCell Maks (mV)'),
                value: maximum?.value,
                cellIndex: maximum?.key,
                valueColor: const Color(0xFF087CFF),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _CellStatisticCard(
                label: context.translate('VCell Min (mV)', 'VCell Min (mV)'),
                value: minimum?.value,
                cellIndex: minimum?.key,
                valueColor: const Color(0xFFFF5364),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _CellStatisticCard(
                label: context.translate('VCell Diff', 'Selisih VCell'),
                value: difference,
                valueColor: const Color(0xFF008447),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                context.translate('Cell Voltage (mV)', 'Tegangan Sel (mV)'),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (cellVoltages.isNotEmpty)
              Text(
                context.translate(
                  '${cellVoltages.length} cells',
                  '${cellVoltages.length} sel',
                ),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (cellVoltages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              context.translate(
                'Waiting for cell voltage data',
                'Menunggu data tegangan sel',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text, fontSize: 12),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellVoltages.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: math.min(4, cellVoltages.length),
              mainAxisExtent: 31,
              crossAxisSpacing: 18,
              mainAxisSpacing: 11,
            ),
            itemBuilder: (context, index) => _CellVoltageTile(
              index: index,
              voltage: cellVoltages[index],
              isMaximum: maximum?.key == index,
              isMinimum: minimum?.key == index,
            ),
          ),
      ],
    );
  }
}

class _CellStatisticCard extends StatelessWidget {
  const _CellStatisticCard({
    required this.label,
    required this.value,
    required this.valueColor,
    this.cellIndex,
  });

  final String label;
  final int? value;
  final int? cellIndex;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value?.toString() ?? '--',
            style: TextStyle(
              color: value == null ? Colors.grey : valueColor,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (cellIndex != null)
            Text(
              '${context.translate('Cell', 'Sel')} '
              '${(cellIndex! + 1).toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.text, fontSize: 9),
            ),
        ],
      ),
    );
  }
}

class _CellVoltageTile extends StatelessWidget {
  const _CellVoltageTile({
    required this.index,
    required this.voltage,
    required this.isMaximum,
    required this.isMinimum,
  });

  final int index;
  final int voltage;
  final bool isMaximum;
  final bool isMinimum;

  @override
  Widget build(BuildContext context) {
    final highlightColor = isMinimum
        ? const Color(0xFFFF5364)
        : isMaximum
        ? const Color(0xFF087CFF)
        : AppColors.accent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(
            width: 26,
            alignment: Alignment.center,
            color: highlightColor,
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              voltage.toString(),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: isMinimum ? highlightColor : AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          Row(
            children: [
              Expanded(child: _MetricCard(metric: metrics[row * 2])),
              const SizedBox(width: 18),
              Expanded(child: _MetricCard(metric: metrics[row * 2 + 1])),
            ],
          ),
          if (row == 0) const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.fromLTRB(18, 20, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                child: Icon(metric.icon, size: 15),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.text, fontSize: 11),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.value,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _ErrorLogTable extends StatelessWidget {
  const _ErrorLogTable({required this.rows});

  static const _columnWidths = <int, TableColumnWidth>{
    0: FlexColumnWidth(1.55),
    1: FlexColumnWidth(0.64),
    2: FlexColumnWidth(1.35),
  };

  final List<_ErrorLogEntry> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Table(
            columnWidths: _columnWidths,
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(5),
                ),
                children: [
                  _HeaderCell(context.translate('Timestamp', 'Waktu')),
                  _HeaderCell(context.translate('Code', 'Kode')),
                  _HeaderCell(context.translate('Description', 'Deskripsi')),
                ],
              ),
            ],
          ),
          if (rows.isEmpty)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Center(
                child: Text(
                  context.translate(
                    'No error code',
                    'Tidak ada kode kesalahan',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text, fontSize: 10),
                ),
              ),
            )
          else
            Table(
              columnWidths: _columnWidths,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                for (final row in rows)
                  TableRow(
                    children: [
                      _LogCell(row.timestamp),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD6D6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              row.code,
                              style: const TextStyle(
                                color: Color(0xFFFF4747),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _LogCell(row.description),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ErrorLogEntry {
  const _ErrorLogEntry({
    required this.timestamp,
    required this.code,
    required this.description,
    this.liveTelemetry = false,
  });

  final String timestamp;
  final String code;
  final String description;
  final bool liveTelemetry;
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class _LogCell extends StatelessWidget {
  const _LogCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.text, fontSize: 9),
      ),
    );
  }
}
