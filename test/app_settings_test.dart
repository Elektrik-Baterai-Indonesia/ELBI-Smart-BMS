import 'package:flutter_test/flutter_test.dart';

import 'package:bms_mobile_apps/features/settings/app_settings.dart';

void main() {
  test('Raw JSON is disabled by default', () {
    expect(const AppSettings().showRawJson, isFalse);
    expect(const AppSettings().recordData, isFalse);
  });

  test('English is the default language', () {
    expect(const AppSettings().language, AppLanguage.english);
  });
}
