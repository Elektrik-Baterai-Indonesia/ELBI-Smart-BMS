import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_theme.dart';
import '../devices/saved_device_repository.dart';
import '../monitoring/bms_csv_logger.dart';
import 'app_settings.dart';
import 'app_settings_controller.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  static const _appVersion = '1.0.4';
  static const _buildNumber = '4';

  @override
  Widget build(BuildContext context) {
    final controller = AppSettingsScope.maybeOf(context);
    final settings = controller?.settings ?? const AppSettings();
    final colors = Theme.of(context).colorScheme;
    final isIndonesian = settings.language == AppLanguage.indonesian;
    String text(String english, String indonesian) {
      return isIndonesian ? indonesian : english;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          text('Settings', 'Pengaturan'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _SettingsSection(
            title: text('DISPLAY', 'TAMPILAN'),
            children: [
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: Text(text('Language', 'Bahasa')),
                subtitle: Text(
                  settings.language == AppLanguage.indonesian
                      ? 'Bahasa Indonesia'
                      : 'English',
                ),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<AppLanguage>(
                    value: settings.language,
                    items: const [
                      DropdownMenuItem(
                        value: AppLanguage.english,
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: AppLanguage.indonesian,
                        child: Text('Bahasa Indonesia'),
                      ),
                    ],
                    onChanged: controller == null
                        ? null
                        : (language) {
                            if (language != null) {
                              controller.setLanguage(language);
                            }
                          },
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.device_thermostat_rounded),
                title: Text(text('Temperature unit', 'Satuan suhu')),
                subtitle: Text(
                  settings.temperatureUnit == TemperatureUnit.celsius
                      ? 'Celsius (°C)'
                      : 'Fahrenheit (°F)',
                ),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<TemperatureUnit>(
                    value: settings.temperatureUnit,
                    items: const [
                      DropdownMenuItem(
                        value: TemperatureUnit.celsius,
                        child: Text('°C'),
                      ),
                      DropdownMenuItem(
                        value: TemperatureUnit.fahrenheit,
                        child: Text('°F'),
                      ),
                    ],
                    onChanged: controller == null
                        ? null
                        : (unit) {
                            if (unit != null) {
                              controller.setTemperatureUnit(unit);
                            }
                          },
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  settings.themeMode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                ),
                title: Text(text('Theme', 'Tema')),
                subtitle: Text(
                  settings.themeMode == ThemeMode.dark
                      ? text('Dark', 'Gelap')
                      : text('Light', 'Terang'),
                ),
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded, size: 17),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded, size: 17),
                    ),
                  ],
                  selected: {settings.themeMode},
                  showSelectedIcon: false,
                  onSelectionChanged: controller == null
                      ? null
                      : (selection) {
                          controller.setThemeMode(selection.first);
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: text('MONITORING', 'PEMANTAUAN'),
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.data_object_rounded),
                title: Text(text('Show Raw JSON', 'Tampilkan JSON Mentah')),
                subtitle: Text(
                  text(
                    'Show the Raw JSON floating button while connected',
                    'Tampilkan tombol JSON Mentah saat perangkat terhubung',
                  ),
                ),
                value: settings.showRawJson,
                activeThumbColor: AppColors.accent,
                onChanged: controller?.setShowRawJson,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.table_view_rounded),
                title: Text(text('Record data', 'Rekam data')),
                subtitle: Text(
                  text(
                    'Record Bluetooth telemetry from connection until '
                        'disconnection. CSV files are saved in '
                        'Download/ELBI Smart BMS.',
                    'Rekam telemetri Bluetooth sejak terhubung hingga '
                        'terputus. File CSV disimpan di '
                        'Download/ELBI Smart BMS.',
                  ),
                ),
                value: settings.recordData,
                activeThumbColor: AppColors.accent,
                onChanged: controller == null
                    ? null
                    : (value) => _setRecordData(context, controller, value),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: text('SAVED DEVICES', 'PERANGKAT TERSIMPAN'),
            children: [
              ListTile(
                leading: Icon(Icons.delete_sweep_outlined, color: colors.error),
                title: Text(
                  text('Clear saved devices', 'Hapus perangkat tersimpan'),
                  style: TextStyle(color: colors.error),
                ),
                subtitle: Text(
                  text(
                    'Remove every saved BMS from this app',
                    'Hapus semua BMS yang tersimpan dari aplikasi',
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _confirmClearDevices(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: text('ABOUT', 'TENTANG'),
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('ELBI Smart BMS'),
                subtitle: Text(
                  '${text('Version', 'Versi')} '
                  '$_appVersion ($_buildNumber)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            AppTheme.brandName,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.accent, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _setRecordData(
    BuildContext context,
    AppSettingsController controller,
    bool value,
  ) async {
    if (value && defaultTargetPlatform == TargetPlatform.android) {
      final needsPermission =
          await DownloadsCsvStorage.requiresLegacyStoragePermission();
      if (needsPermission) {
        final permission = await Permission.storage.request();
        if (!permission.isGranted) {
          if (!context.mounted) return;
          final isIndonesian = controller.language == AppLanguage.indonesian;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  isIndonesian
                      ? 'Izin penyimpanan diperlukan untuk menyimpan CSV '
                            'ke folder Download.'
                      : 'Storage permission is required to save CSV files '
                            'to the Download folder.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          return;
        }
      }
    }
    await controller.setRecordData(value);
  }

  Future<void> _confirmClearDevices(BuildContext context) async {
    final isIndonesian =
        AppSettingsScope.maybeOf(context)?.language == AppLanguage.indonesian;
    String text(String english, String indonesian) {
      return isIndonesian ? indonesian : english;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          text('Clear all saved devices?', 'Hapus semua perangkat tersimpan?'),
        ),
        content: Text(
          text(
            'Every saved BMS will be removed. This action cannot be undone.',
            'Semua BMS tersimpan akan dihapus. Tindakan ini tidak dapat dibatalkan.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(text('Cancel', 'Batal')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(text('Clear devices', 'Hapus perangkat')),
          ),
        ],
      ),
    );
    if (shouldClear != true || !context.mounted) return;

    await SavedDeviceRepository().clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text(
              'All saved devices have been cleared.',
              'Semua perangkat tersimpan telah dihapus.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 6),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
