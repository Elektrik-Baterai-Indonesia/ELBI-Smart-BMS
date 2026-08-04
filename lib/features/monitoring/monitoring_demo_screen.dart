import 'package:flutter/material.dart';

import '../devices/saved_device.dart';
import 'device_monitoring_screen.dart';

class MonitoringDemoScreen extends StatelessWidget {
  const MonitoringDemoScreen({super.key});

  static final _demoDevice = SavedDevice(
    id: 'AA:BB:CC:DD:EE:03',
    name: 'BMS-003',
    savedAt: DateTime(2026, 7, 29),
  );

  @override
  Widget build(BuildContext context) {
    return DeviceMonitoringScreen(device: _demoDevice, demoMode: true);
  }
}
