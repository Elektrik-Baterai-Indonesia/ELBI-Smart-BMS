import 'package:flutter_test/flutter_test.dart';

import 'package:bms_mobile_apps/features/monitoring/bms_error_catalog.dart';

void main() {
  test('catalog defines every supported BMS error bit', () {
    expect(bmsErrorDefinitions, hasLength(18));
    expect(
      bmsErrorDefinitions.map((definition) => definition.bit),
      orderedEquals(List.generate(18, (index) => index)),
    );
    expect(bmsErrorDefinitions[0].englishDescription, 'Short Circuit');
    expect(bmsErrorDefinitions[6].englishDescription, 'Relay Precharge Error');
    expect(bmsErrorDefinitions[17].englishDescription, 'Setting Mode');
  });

  test('decodes every active bit from a decimal error bitmask', () {
    final errorCode = (1 << 0) | (1 << 10) | (1 << 17);

    final errors = activeBmsErrors(errorCode);

    expect(errors.map((error) => error.bit), [0, 10, 17]);
    expect(errors.map((error) => error.englishDescription), [
      'Short Circuit',
      'Overvoltage',
      'Setting Mode',
    ]);
    expect(unknownBmsErrorBits(errorCode), isEmpty);
  });

  test('reports unsupported set bits separately', () {
    final errorCode = (1 << 2) | (1 << 19) | (1 << 21);

    expect(activeBmsErrors(errorCode).map((error) => error.bit), [2]);
    expect(unknownBmsErrorBits(errorCode), [19, 21]);
    expect(activeBmsErrors(0), isEmpty);
    expect(unknownBmsErrorBits(0), isEmpty);
  });
}
