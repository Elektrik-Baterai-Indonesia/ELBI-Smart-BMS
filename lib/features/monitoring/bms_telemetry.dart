import 'dart:convert';

import '../settings/bms_settings.dart';

class BmsTelemetry {
  const BmsTelemetry({
    required this.serialNumber,
    required this.soc,
    required this.voltage,
    required this.current,
    required this.temperature,
    required this.errorCode,
    required this.cellVoltageMillivolts,
    this.settings,
  });

  final String serialNumber;
  final int soc;
  final double voltage;
  final double current;
  final double temperature;
  final int errorCode;
  final List<int> cellVoltageMillivolts;
  final BmsSettings? settings;

  List<int> get monitoringCellVoltageMillivolts {
    var reportedLength = cellVoltageMillivolts.length;
    while (reportedLength > 0 &&
        cellVoltageMillivolts[reportedLength - 1] == 0) {
      reportedLength--;
    }
    return List.unmodifiable(cellVoltageMillivolts.take(reportedLength));
  }

  int get monitoringCellCount => monitoringCellVoltageMillivolts.length;

  List<int> get activeCellVoltageMillivolts {
    return monitoringCellVoltageMillivolts
        .where((voltage) => voltage > 0)
        .toList();
  }

  int get activeCellCount => activeCellVoltageMillivolts.length;

  double get averageCellVoltage {
    final cells = activeCellVoltageMillivolts;
    if (cells.isEmpty) return 0;
    return cells.reduce((first, second) => first + second) /
        cells.length /
        1000;
  }

  double get cellVoltageDelta {
    final cells = activeCellVoltageMillivolts;
    if (cells.isEmpty) return 0;
    final minimum = cells.reduce(
      (first, second) => first < second ? first : second,
    );
    final maximum = cells.reduce(
      (first, second) => first > second ? first : second,
    );
    return (maximum - minimum) / 1000;
  }

  bool get hasError => errorCode != 0;

  static BmsTelemetry? tryParse(String payload) {
    try {
      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) return null;

      final serialNumber = json['serial_number'];
      final soc = json['soc'];
      final voltage = json['voltage'];
      final current = json['current'];
      final temperature = json['temperature'];
      final errorCode = json['error_code'];
      final cellVoltage = json['cell_voltage'];
      final settingsJson = json['settings'];

      if (serialNumber is! String ||
          soc is! num ||
          voltage is! num ||
          current is! num ||
          temperature is! num ||
          errorCode is! num ||
          cellVoltage is! List) {
        return null;
      }

      final cells = <int>[];
      for (final value in cellVoltage) {
        if (value is! num) return null;
        cells.add(value.round());
      }

      BmsSettings? settings;
      if (settingsJson is Map) {
        settings = BmsSettings.fromBluetoothJson(
          Map<String, dynamic>.from(settingsJson),
        );
      }

      return BmsTelemetry(
        serialNumber: serialNumber,
        soc: soc.round().clamp(0, 100),
        voltage: voltage.toDouble(),
        current: current.toDouble(),
        temperature: temperature.toDouble(),
        errorCode: errorCode.round(),
        cellVoltageMillivolts: List.unmodifiable(cells),
        settings: settings,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
