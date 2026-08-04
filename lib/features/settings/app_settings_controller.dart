import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'app_settings_repository.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({AppSettingsRepository? repository})
    : _repository = repository ?? AppSettingsRepository();

  final AppSettingsRepository _repository;
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;
  TemperatureUnit get temperatureUnit => _settings.temperatureUnit;
  ThemeMode get themeMode => _settings.themeMode;
  bool get showRawJson => _settings.showRawJson;
  bool get recordData => _settings.recordData;
  AppLanguage get language => _settings.language;

  Future<void> load() async {
    try {
      _settings = await _repository.load();
      notifyListeners();
    } on StateError {
      // Platform preferences can be unavailable in previews and widget tests.
    }
  }

  Future<void> setTemperatureUnit(TemperatureUnit unit) {
    return _update(_settings.copyWith(temperatureUnit: unit));
  }

  Future<void> setThemeMode(ThemeMode mode) {
    return _update(_settings.copyWith(themeMode: mode));
  }

  Future<void> setShowRawJson(bool value) {
    return _update(_settings.copyWith(showRawJson: value));
  }

  Future<void> setRecordData(bool value) {
    return _update(_settings.copyWith(recordData: value));
  }

  Future<void> setLanguage(AppLanguage language) {
    return _update(_settings.copyWith(language: language));
  }

  Future<void> _update(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    try {
      await _repository.save(settings);
    } on StateError {
      // Keep the in-memory setting if platform preferences are unavailable.
    }
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    required AppSettingsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppSettingsController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>()
        ?.notifier;
  }
}
