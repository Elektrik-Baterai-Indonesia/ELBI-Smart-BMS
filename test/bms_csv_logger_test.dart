import 'package:flutter_test/flutter_test.dart';

import 'package:bms_mobile_apps/features/devices/saved_device.dart';
import 'package:bms_mobile_apps/features/monitoring/bms_csv_logger.dart';
import 'package:bms_mobile_apps/features/monitoring/bms_telemetry.dart';

void main() {
  test(
    'CSV logger writes telemetry rows and returns the Downloads location',
    () async {
      final storage = _MemoryCsvStorage();
      final logger = BmsCsvLogger(
        device: SavedDevice(
          id: 'TEST-BMS-01',
          name: 'BMS, Test',
          savedAt: DateTime.utc(2026, 8, 4),
        ),
        storage: storage,
        startedAt: DateTime(2026, 8, 4, 9, 7, 6),
      );

      logger.record(
        const BmsTelemetry(
          serialNumber: '00BB1000',
          soc: 16,
          voltage: 50.89,
          current: -18.34,
          temperature: 25,
          errorCode: 0,
          cellVoltageMillivolts: [3153, 3185],
        ),
        DateTime.parse('2026-08-04T09:07:08.000'),
      );

      final location = await logger.finish();

      expect(logger.filename, 'ELBI_BMS_Test_20260804_090706.csv');
      expect(location, 'Download/ELBI Smart BMS/${logger.filename}');
      final lines = storage.content.trimRight().split('\n');
      expect(lines, hasLength(2));
      expect(lines.first, contains('timestamp,device_id,device_name'));
      expect(lines.first, contains('cell_01_mv,cell_02_mv'));
      expect(lines.first, isNot(contains('cell_03_mv')));
      expect(lines.first.split(','), hasLength(11));
      expect(lines.last, contains('2026-08-04T09:07:08.000'));
      expect(lines.last, contains('TEST-BMS-01,"BMS, Test",00BB1000'));
      expect(lines.last, contains('16,50.89,-18.34,25.0,0,3153,3185'));
    },
  );

  test('CSV cell columns ignore values below the valid-cell range', () async {
    final storage = _MemoryCsvStorage();
    final logger = BmsCsvLogger(
      device: SavedDevice(
        id: 'TEST-BMS-02',
        name: 'BMS Test',
        savedAt: DateTime.utc(2026, 8, 4),
      ),
      storage: storage,
    );

    logger.record(
      const BmsTelemetry(
        serialNumber: 'TEST0002',
        soc: 80,
        voltage: 13.2,
        current: 2,
        temperature: 24,
        errorCode: 0,
        cellVoltageMillivolts: [3300, 499, 3290, 0],
      ),
      DateTime.parse('2026-08-04T10:00:00.000'),
    );
    await logger.finish();

    final lines = storage.content.trimRight().split('\n');
    expect(lines.first, contains('cell_01_mv,cell_02_mv'));
    expect(lines.first, isNot(contains('cell_03_mv')));
    expect(lines.last, endsWith(',3300,3290'));
  });
}

class _MemoryCsvStorage implements CsvStorage {
  String content = '';
  String? _location;

  @override
  Future<CsvDownloadSession> create({
    required String filename,
    required String header,
  }) async {
    content = header;
    _location = 'Download/ELBI Smart BMS/$filename';
    return CsvDownloadSession(id: 'test-session', location: _location!);
  }

  @override
  Future<void> append(String sessionId, String value) async {
    expect(sessionId, 'test-session');
    content += value;
  }

  @override
  Future<String> finish(String sessionId) async {
    expect(sessionId, 'test-session');
    return _location!;
  }
}
