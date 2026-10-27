import 'dart:convert';

/// One-shot commands sent to the BMS through the FFE1 write characteristic.
enum BmsCommand {
  resetSoc(1),
  resetBms(2);

  const BmsCommand(this.code);

  final int code;

  String toBluetoothPayload() => jsonEncode({'cmd': code});
}
