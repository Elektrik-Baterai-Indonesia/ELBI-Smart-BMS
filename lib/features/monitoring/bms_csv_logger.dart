import 'package:flutter/services.dart';

import '../devices/saved_device.dart';
import 'bms_telemetry.dart';

class CsvDownloadSession {
  const CsvDownloadSession({required this.id, required this.location});

  final String id;
  final String location;
}

abstract interface class CsvStorage {
  Future<CsvDownloadSession> create({
    required String filename,
    required String header,
  });

  Future<void> append(String sessionId, String content);

  Future<String> finish(String sessionId);
}

class DownloadsCsvStorage implements CsvStorage {
  const DownloadsCsvStorage();

  static const MethodChannel _channel = MethodChannel(
    'com.elbi.smart_bms/downloads_csv',
  );

  static Future<bool> requiresLegacyStoragePermission() async {
    return await _channel.invokeMethod<bool>(
          'requiresLegacyStoragePermission',
        ) ??
        false;
  }

  @override
  Future<CsvDownloadSession> create({
    required String filename,
    required String header,
  }) async {
    final result = await _channel.invokeMapMethod<String, dynamic>('create', {
      'filename': filename,
      'header': header,
    });
    final id = result?['id'];
    final location = result?['location'];
    if (id is! String || location is! String) {
      throw const FormatException('Android returned an invalid CSV session.');
    }
    return CsvDownloadSession(id: id, location: location);
  }

  @override
  Future<void> append(String sessionId, String content) {
    return _channel.invokeMethod<void>('append', {
      'id': sessionId,
      'content': content,
    });
  }

  @override
  Future<String> finish(String sessionId) async {
    final location = await _channel.invokeMethod<String>('finish', {
      'id': sessionId,
    });
    if (location == null) {
      throw const FormatException('Android did not return the CSV location.');
    }
    return location;
  }
}

class BmsCsvLogger {
  BmsCsvLogger({required this.device, CsvStorage? storage, DateTime? startedAt})
    : _storage = storage ?? const DownloadsCsvStorage(),
      _startedAt = startedAt ?? DateTime.now() {
    _operations = _create();
  }

  static const _cellCount = 24;

  final SavedDevice device;
  final CsvStorage _storage;
  final DateTime _startedAt;
  late Future<void> _operations;
  CsvDownloadSession? _session;
  bool _finishing = false;

  Future<void> get ready => _operations;

  String get filename {
    final timestamp = _filenameTimestamp(_startedAt);
    final deviceName = device.name
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'ELBI_${deviceName.isEmpty ? 'BMS' : deviceName}_$timestamp.csv';
  }

  void record(BmsTelemetry telemetry, DateTime receivedAt) {
    if (_finishing) return;
    final row = _rowFor(telemetry, receivedAt);
    _operations = _operations.then((_) {
      return _storage.append(_session!.id, row);
    });
  }

  Future<String> finish() async {
    if (_finishing) {
      await _operations;
      return _session!.location;
    }
    _finishing = true;
    String? savedLocation;
    _operations = _operations.then((_) async {
      savedLocation = await _storage.finish(_session!.id);
    });
    await _operations;
    return savedLocation ?? _session!.location;
  }

  Future<void> _create() async {
    _session = await _storage.create(filename: filename, header: _header);
  }

  String _rowFor(BmsTelemetry telemetry, DateTime receivedAt) {
    final cells = [
      for (var index = 0; index < _cellCount; index++)
        index < telemetry.cellVoltageMillivolts.length
            ? telemetry.cellVoltageMillivolts[index].toString()
            : '',
    ];
    final columns = <String>[
      _csvCell(receivedAt.toIso8601String()),
      _csvCell(device.id),
      _csvCell(device.name),
      _csvCell(telemetry.serialNumber),
      telemetry.soc.toString(),
      telemetry.voltage.toString(),
      telemetry.current.toString(),
      telemetry.temperature.toString(),
      telemetry.errorCode.toString(),
      ...cells,
    ];
    return '${columns.join(',')}\n';
  }

  static String get _header {
    final columns = <String>[
      'timestamp',
      'device_id',
      'device_name',
      'serial_number',
      'soc_percent',
      'voltage_v',
      'current_a',
      'temperature_c',
      'error_code',
      for (var index = 1; index <= _cellCount; index++)
        'cell_${index.toString().padLeft(2, '0')}_mv',
    ];
    return '${columns.join(',')}\n';
  }

  static String _csvCell(String value) {
    if (!value.contains(RegExp(r'[,"\r\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _filenameTimestamp(DateTime value) {
    String twoDigits(int part) => part.toString().padLeft(2, '0');
    return '${value.year}${twoDigits(value.month)}${twoDigits(value.day)}_'
        '${twoDigits(value.hour)}${twoDigits(value.minute)}'
        '${twoDigits(value.second)}';
  }
}
