import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/localization/app_localizations.dart';
import '../devices/saved_device.dart';
import 'bluetooth_device_scan_screen.dart';
import 'bluetooth_mac_address.dart';
import 'widgets/scanner_overlay.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  static const _backgroundColor = Color(0xFF606060);

  late final MobileScannerController _controller;
  bool _isHandlingResult = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
      facing: CameraFacing.back,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _backgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final scanSize = (constraints.maxWidth - 116).clamp(220.0, 296.0);
            final scanWindow = Rect.fromCenter(
              center: Offset(
                constraints.maxWidth / 2,
                constraints.maxHeight * 0.48,
              ),
              width: scanSize,
              height: scanSize,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  scanWindow: scanWindow,
                  scanWindowUpdateThreshold: 1,
                  tapToFocus: true,
                  onDetect: _handleCapture,
                  placeholderBuilder: (_) =>
                      const ColoredBox(color: _backgroundColor),
                  errorBuilder: (_, error) => _ScannerErrorView(
                    error: error,
                    onRetry: _controller.start,
                  ),
                ),
                ScannerOverlay(scanWindow: scanWindow),
                SafeArea(
                  child: Stack(
                    children: [
                      _ScannerHeader(onBack: () => Navigator.of(context).pop()),
                      Positioned(
                        top: scanWindow.top - 52,
                        left: 24,
                        right: 24,
                        child: Text(
                          context.translate(
                            'Scan BMS battery QR code',
                            'Pindai kode QR baterai BMS',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Positioned(
                        top: scanWindow.bottom + 18,
                        left: 32,
                        right: 32,
                        child: Column(
                          children: [
                            _ScannerControls(controller: _controller),
                            const SizedBox(height: 6),
                            OutlinedButton.icon(
                              onPressed: _openBluetoothScanner,
                              icon: const Icon(Icons.bluetooth_searching),
                              label: Text(
                                context.translate(
                                  'Scan nearby Bluetooth devices',
                                  'Pindai perangkat Bluetooth terdekat',
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 11,
                                ),
                              ),
                            ),
                            if (_validationMessage case final message?) ...[
                              const SizedBox(height: 12),
                              Text(
                                message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFFD6D6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openBluetoothScanner() async {
    if (_isHandlingResult) return;

    await _controller.stop();
    if (!mounted) return;

    final device = await Navigator.of(context).push<SavedDevice>(
      MaterialPageRoute(builder: (_) => const BluetoothDeviceScanScreen()),
    );
    if (!mounted) return;

    if (device != null) {
      _isHandlingResult = true;
      Navigator.of(context).pop(device);
      return;
    }

    await _controller.start();
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_isHandlingResult) return;

    BluetoothMacAddress? macAddress;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;

      macAddress = BluetoothMacAddress.tryParse(rawValue);
      if (macAddress != null) break;
    }

    if (macAddress == null) {
      if (mounted) {
        setState(() {
          _validationMessage = context.translate(
            'QR code does not contain a valid Bluetooth MAC address.',
            'Kode QR tidak berisi alamat MAC Bluetooth yang valid.',
          );
        });
      }
      return;
    }

    _isHandlingResult = true;
    await _controller.stop();
    if (!mounted) return;
    Navigator.of(context).pop(SavedDevice.fromIdentifier(macAddress.value));
  }
}

class _ScannerHeader extends StatelessWidget {
  const _ScannerHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(35, 35, 35, 0),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(6),
              child: const SizedBox.square(
                dimension: 27,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF606060),
                  size: 17,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 27),
              child: Text(
                context.translate('Add Device', 'Tambah Perangkat'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerControls extends StatelessWidget {
  const _ScannerControls({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, _) {
        final isTorchOn = state.torchState == TorchState.on;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: isTorchOn
                  ? context.translate('Turn flash off', 'Matikan lampu kilat')
                  : context.translate('Turn flash on', 'Nyalakan lampu kilat'),
              onPressed: state.torchState == TorchState.unavailable
                  ? null
                  : controller.toggleTorch,
              icon: Icon(
                isTorchOn
                    ? Icons.flashlight_on_outlined
                    : Icons.flashlight_off_outlined,
              ),
              color: Colors.white,
              disabledColor: Colors.white54,
              iconSize: 29,
            ),
            const SizedBox(width: 20),
            IconButton(
              tooltip: context.translate('Switch camera', 'Ganti kamera'),
              onPressed: controller.switchCamera,
              icon: const Icon(Icons.cameraswitch_outlined),
              color: Colors.white,
              iconSize: 29,
            ),
          ],
        );
      },
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final permissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: _QrScannerScreenState._backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white,
                size: 44,
              ),
              const SizedBox(height: 14),
              Text(
                permissionDenied
                    ? context.translate(
                        'Camera permission is required to scan a BMS QR code.',
                        'Izin kamera diperlukan untuk memindai kode QR BMS.',
                      )
                    : context.translate(
                        'The camera could not be started.',
                        'Kamera tidak dapat dijalankan.',
                      ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              if (!permissionDenied) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRetry,
                  child: Text(
                    context.translate('Try again', 'Coba lagi'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
