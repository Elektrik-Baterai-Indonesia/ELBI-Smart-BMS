import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../devices/saved_device.dart';
import '../devices/saved_device_repository.dart';
import '../devices/saved_devices_screen.dart';
import '../manual/user_manual_screen.dart';
import '../scanner/qr_scanner_screen.dart';
import '../settings/app_settings.dart';
import '../settings/app_settings_controller.dart';
import '../settings/app_settings_screen.dart';
import 'widgets/bms_menu_icons.dart';
import 'widgets/home_menu_card.dart';

const _menuItems = [
  _MenuItem(
    englishTitle: 'Add Device',
    indonesianTitle: 'Tambah Perangkat',
    englishSubtitle: 'Add BMS by scanning QR Code',
    indonesianSubtitle: 'Tambahkan BMS dengan memindai kode QR',
    icon: AddDeviceIcon(),
    action: _MenuAction.scanDevice,
  ),
  _MenuItem(
    englishTitle: 'Monitoring Device',
    indonesianTitle: 'Pemantauan Perangkat',
    englishSubtitle: 'Connect and monitor BMS devices',
    indonesianSubtitle: 'Hubungkan dan pantau perangkat BMS',
    icon: BatteryIcon(),
    action: _MenuAction.monitorDevice,
  ),
  _MenuItem(
    englishTitle: 'User Manual',
    indonesianTitle: 'Panduan Pengguna',
    englishSubtitle: 'How to use the application and BMS',
    indonesianSubtitle: 'Cara menggunakan aplikasi dan BMS',
    icon: Icon(Icons.help_outline_rounded),
    action: _MenuAction.userManual,
  ),
  _MenuItem(
    englishTitle: 'Settings',
    indonesianTitle: 'Pengaturan',
    englishSubtitle: 'User control using the app',
    indonesianSubtitle: 'Kontrol pengguna pada aplikasi',
    icon: Icon(Icons.settings_outlined),
    action: _MenuAction.appSettings,
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final language =
        AppSettingsScope.maybeOf(context)?.language ?? AppLanguage.english;
    final isIndonesian = language == AppLanguage.indonesian;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Column(
                  children: [
                    const SizedBox(height: 43),
                    Text(
                      'ELBI Smart BMS',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isIndonesian
                            ? 'Pantau status baterai secara langsung melalui Bluetooth.'
                            : 'Monitor battery status in real-time via Bluetooth.',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (var index = 0; index < _menuItems.length; index++) ...[
                      HomeMenuCard(
                        title: _menuItems[index].title(language),
                        subtitle: _menuItems[index].subtitle(language),
                        icon: _menuItems[index].icon,
                        onTap: () => _handleMenuTap(context, _menuItems[index]),
                      ),
                      if (index < _menuItems.length - 1)
                        const SizedBox(height: 17),
                    ],
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(top: 36, bottom: 13),
                      child: Text(
                        AppTheme.brandName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuTap(BuildContext context, _MenuItem item) async {
    switch (item.action) {
      case _MenuAction.scanDevice:
        await _scanAndSaveDevice(context);
      case _MenuAction.monitorDevice:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const SavedDevicesScreen()),
        );
      case _MenuAction.userManual:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const UserManualScreen()),
        );
      case _MenuAction.appSettings:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
        );
    }
  }

  Future<void> _scanAndSaveDevice(BuildContext context) async {
    final device = await Navigator.of(context).push<SavedDevice>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (!context.mounted || device == null) return;

    await SavedDeviceRepository().save(device);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.translate(
              '${device.name} saved successfully.',
              '${device.name} berhasil disimpan.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.englishTitle,
    required this.indonesianTitle,
    required this.englishSubtitle,
    required this.indonesianSubtitle,
    required this.icon,
    required this.action,
  });

  final String englishTitle;
  final String indonesianTitle;
  final String englishSubtitle;
  final String indonesianSubtitle;
  final Widget icon;
  final _MenuAction action;

  String title(AppLanguage language) {
    return language == AppLanguage.indonesian ? indonesianTitle : englishTitle;
  }

  String subtitle(AppLanguage language) {
    return language == AppLanguage.indonesian
        ? indonesianSubtitle
        : englishSubtitle;
  }
}

enum _MenuAction { scanDevice, monitorDevice, userManual, appSettings }
