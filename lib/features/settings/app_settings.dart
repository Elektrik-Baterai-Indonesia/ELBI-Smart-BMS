import 'package:flutter/material.dart';

enum TemperatureUnit {
  celsius,
  fahrenheit;

  String get symbol => this == celsius ? '°C' : '°F';

  double convertFromCelsius(double value) {
    return this == celsius ? value : (value * 9 / 5) + 32;
  }
}

enum AppLanguage {
  english('en'),
  indonesian('id');

  const AppLanguage(this.languageCode);

  final String languageCode;
}

class AppSettings {
  const AppSettings({
    this.temperatureUnit = TemperatureUnit.celsius,
    this.themeMode = ThemeMode.light,
    this.showRawJson = false,
    this.recordData = false,
    this.language = AppLanguage.english,
  });

  final TemperatureUnit temperatureUnit;
  final ThemeMode themeMode;
  final bool showRawJson;
  final bool recordData;
  final AppLanguage language;

  AppSettings copyWith({
    TemperatureUnit? temperatureUnit,
    ThemeMode? themeMode,
    bool? showRawJson,
    bool? recordData,
    AppLanguage? language,
  }) {
    return AppSettings(
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      themeMode: themeMode ?? this.themeMode,
      showRawJson: showRawJson ?? this.showRawJson,
      recordData: recordData ?? this.recordData,
      language: language ?? this.language,
    );
  }
}
