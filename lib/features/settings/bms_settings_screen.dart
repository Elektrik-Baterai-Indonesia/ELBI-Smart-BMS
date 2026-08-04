import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../devices/saved_device.dart';
import '../monitoring/ble_debug_controller.dart';
import 'bms_settings.dart';
import 'bms_settings_repository.dart';

class BmsSettingsScreen extends StatefulWidget {
  const BmsSettingsScreen({
    required this.device,
    this.demoMode = false,
    this.initialSettings,
    this.onSendParameters,
    super.key,
  });

  final SavedDevice device;
  final bool demoMode;
  final BmsSettings? initialSettings;
  final Future<void> Function(String payload)? onSendParameters;

  @override
  State<BmsSettingsScreen> createState() => _BmsSettingsScreenState();
}

class _BmsSettingsScreenState extends State<BmsSettingsScreen> {
  BmsSettingsRepository? _settingsRepository;
  final _controllers = <BmsSettingKey, TextEditingController>{};
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  BmsBatteryType? _selectedBatteryType;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            : Form(
                key: _formKey,
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 46, 16, 14),
                      sliver: SliverList.list(
                        children: [
                          _SettingsHeader(
                            onBack: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 50),
                          _BatteryTypePresetCard(
                            selectedType: _selectedBatteryType,
                            onSelected: _applyBatteryTypePreset,
                          ),
                          const SizedBox(height: 16),
                          for (final section in BmsSettingsSection.values) ...[
                            _SettingsSectionCard(
                              section: section,
                              definitions: bmsSettingDefinitions
                                  .where(
                                    (definition) =>
                                        definition.section == section,
                                  )
                                  .toList(),
                              controllers: _controllers,
                            ),
                            const SizedBox(height: 16),
                          ],
                          FilledButton.icon(
                            onPressed: _saving ? null : _saveSettings,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(49),
                              backgroundColor: AppColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _saving
                                  ? context.translate('Saving…', 'Menyimpan…')
                                  : context.translate(
                                      'Save Parameters',
                                      'Simpan Parameter',
                                    ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            AppTheme.brandName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _loadSettings() async {
    final settings =
        widget.initialSettings ??
        await (_settingsRepository ??= BmsSettingsRepository()).load(
          widget.device.id,
        );
    if (!mounted) return;

    for (final definition in bmsSettingDefinitions) {
      _controllers[definition.key] = TextEditingController(
        text: definition
            .toDisplayValue(settings.valueFor(definition.key))
            .toStringAsFixed(definition.decimalPlaces),
      );
    }
    setState(() {
      _selectedBatteryType = settings.matchingBatteryType;
      _loading = false;
    });
  }

  void _applyBatteryTypePreset(BmsBatteryType batteryType) {
    for (final entry in batteryType.presetValues.entries) {
      final definition = bmsSettingDefinitions.firstWhere(
        (candidate) => candidate.key == entry.key,
      );
      _controllers[entry.key]!.text = definition
          .toDisplayValue(entry.value)
          .toStringAsFixed(definition.decimalPlaces);
    }
    setState(() => _selectedBatteryType = batteryType);
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final settings = BmsSettings({
      for (final definition in bmsSettingDefinitions)
        definition.key: definition.toProtocolValue(
          double.parse(_controllers[definition.key]!.text),
        ),
    });

    final sender = widget.onSendParameters;
    if (!widget.demoMode && sender == null) {
      _showMessage(
        context.translate(
          'Connect to the BMS before sending parameters.',
          'Hubungkan ke BMS sebelum mengirim parameter.',
        ),
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (!widget.demoMode) {
        await sender!(settings.toBluetoothPayload());
      }
      await (_settingsRepository ??= BmsSettingsRepository()).save(
        widget.device.id,
        settings,
      );
      if (!mounted) return;

      _showMessage(
        widget.demoMode
            ? context.translate(
                'Demo parameters saved.',
                'Parameter demo telah disimpan.',
              )
            : context.translate(
                'Parameters sent to ${widget.device.name} and saved locally.',
                'Parameter dikirim ke ${widget.device.name} dan disimpan secara lokal.',
              ),
      );
    } on BleWriteException catch (error) {
      if (!mounted) return;
      final message = switch (error.failure) {
        BleWriteFailure.disconnected => context.translate(
          'The BMS disconnected before parameters could be sent.',
          'BMS terputus sebelum parameter dapat dikirim.',
        ),
        BleWriteFailure.noWritableCharacteristic => context.translate(
          'No writable Bluetooth characteristic was found on this BMS.',
          'Karakteristik Bluetooth yang dapat ditulis tidak ditemukan pada BMS ini.',
        ),
        BleWriteFailure.transmissionFailed => context.translate(
          'Bluetooth parameter transmission failed. Please try again.',
          'Pengiriman parameter melalui Bluetooth gagal. Silakan coba lagi.',
        ),
      };
      _showMessage(message, isError: true);
    } on Object {
      if (!mounted) return;
      _showMessage(
        context.translate(
          'Parameters could not be sent. Please try again.',
          'Parameter tidak dapat dikirim. Silakan coba lagi.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack});

  final VoidCallback onBack;

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
          child: Padding(
            padding: const EdgeInsets.only(right: 27),
            child: Text(
              context.translate('BMS Setting', 'Pengaturan BMS'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BatteryTypePresetCard extends StatelessWidget {
  const _BatteryTypePresetCard({
    required this.selectedType,
    required this.onSelected,
  });

  final BmsBatteryType? selectedType;
  final ValueChanged<BmsBatteryType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.accent),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(1, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.translate('BATTERY TYPE', 'JENIS BATERAI'),
            style: const TextStyle(
              color: Color(0xFF5F7F9C),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.translate(
              'Choose a chemistry preset, then review the values before saving.',
              'Pilih preset kimia, lalu periksa nilainya sebelum menyimpan.',
            ),
            style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<BmsBatteryType>(
              segments: [
                for (final batteryType in BmsBatteryType.values)
                  ButtonSegment(
                    value: batteryType,
                    label: Text(batteryType.label),
                  ),
              ],
              selected: selectedType == null
                  ? <BmsBatteryType>{}
                  : <BmsBatteryType>{selectedType!},
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) onSelected(selection.first);
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : AppColors.text,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.accent
                      : const Color(0xFFF1F4F7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.section,
    required this.definitions,
    required this.controllers,
  });

  final BmsSettingsSection section;
  final List<BmsSettingDefinition> definitions;
  final Map<BmsSettingKey, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.accent),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(1, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sectionTitle(context, section),
            style: const TextStyle(
              color: Color(0xFF5F7F9C),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          for (var index = 0; index < definitions.length; index++) ...[
            _SettingRow(
              definition: definitions[index],
              controller: controllers[definitions[index].key]!,
            ),
            if (index < definitions.length - 1)
              const Divider(height: 1, color: Color(0xFFE5E5E5)),
          ],
        ],
      ),
    );
  }

  String _sectionTitle(BuildContext context, BmsSettingsSection section) {
    return switch (section) {
      BmsSettingsSection.voltageProtection => context.translate(
        'VOLTAGE PROTECTION',
        'PERLINDUNGAN TEGANGAN',
      ),
      BmsSettingsSection.currentAndDelay => context.translate(
        'CURRENT & DELAY CONTROLS',
        'KONTROL ARUS & JEDA',
      ),
      BmsSettingsSection.temperature => context.translate(
        'TEMPERATURE CONTROLS',
        'KONTROL SUHU',
      ),
      BmsSettingsSection.systemAndBalancing => context.translate(
        'SYSTEM & BALANCING',
        'SISTEM & PENYEIMBANGAN',
      ),
    };
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.definition, required this.controller});

  final BmsSettingDefinition definition;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 49),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _localizedSettingLabel(context, definition),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            height: 29,
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F4F7),
                contentPadding: const EdgeInsets.fromLTRB(8, 5, 7, 5),
                suffixText: definition.unit == 'days'
                    ? context.translate('days', 'hari')
                    : definition.unit,
                suffixStyle: const TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFD0D9E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 1.5,
                  ),
                ),
                errorStyle: const TextStyle(fontSize: 0, height: 0),
              ),
              validator: (value) {
                final number = double.tryParse(value ?? '');
                return number == null || number < 0 ? '' : null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _localizedSettingLabel(
  BuildContext context,
  BmsSettingDefinition definition,
) {
  final indonesian = switch (definition.key) {
    BmsSettingKey.overVoltageProtection => 'Perlindungan Tegangan Berlebih',
    BmsSettingKey.overVoltageRelease =>
      'Pelepasan Perlindungan\nTegangan Berlebih',
    BmsSettingKey.underVoltageProtection => 'Perlindungan Tegangan Rendah',
    BmsSettingKey.underVoltageRelease =>
      'Pelepasan Perlindungan\nTegangan Rendah',
    BmsSettingKey.overCurrentCharge => 'Arus Pengisian Berlebih',
    BmsSettingKey.delayOverCurrentCharge => 'Jeda Arus Pengisian Berlebih',
    BmsSettingKey.overCurrentDischarge => 'Arus Pengosongan Berlebih',
    BmsSettingKey.delayOverCurrentDischarge =>
      'Jeda Arus Pengosongan\nBerlebih',
    BmsSettingKey.overTemperatureBattery => 'Suhu Baterai Berlebih',
    BmsSettingKey.overTemperatureBatteryRelease =>
      'Pelepasan Suhu Baterai Berlebih',
    BmsSettingKey.overTemperatureMosfet => 'Suhu MOSFET Berlebih',
    BmsSettingKey.overTemperatureMosfetRelease =>
      'Pelepasan Suhu MOSFET Berlebih',
    BmsSettingKey.batteryCapacity => 'Kapasitas Baterai',
    BmsSettingKey.resistorShunt => 'Resistor Shunt',
    BmsSettingKey.balancingMinimum => 'Minimum Penyeimbangan',
    BmsSettingKey.balancingDifferent => 'Selisih Penyeimbangan',
    BmsSettingKey.dayToSleep => 'Hari Menuju Tidur',
  };
  return context.translate(definition.label, indonesian);
}
