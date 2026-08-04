class BluetoothMacAddress {
  const BluetoothMacAddress._(this.value);

  final String value;

  static final _separatedPattern = RegExp(
    r'(?:^|[^0-9A-Fa-f])((?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2})(?:$|[^0-9A-Fa-f])',
  );
  static final _compactPattern = RegExp(
    r'(?:^|[^0-9A-Fa-f])([0-9A-Fa-f]{12})(?:$|[^0-9A-Fa-f])',
  );

  static BluetoothMacAddress? tryParse(String payload) {
    final trimmedPayload = payload.trim();
    final match =
        _separatedPattern.firstMatch(trimmedPayload) ??
        _compactPattern.firstMatch(trimmedPayload);
    final candidate = match?.group(1);
    if (candidate == null) return null;

    final hex = candidate.replaceAll(RegExp('[:-]'), '').toUpperCase();
    if (hex == '000000000000' || hex == 'FFFFFFFFFFFF') return null;

    final normalized = [
      for (var index = 0; index < hex.length; index += 2)
        hex.substring(index, index + 2),
    ].join(':');

    return BluetoothMacAddress._(normalized);
  }

  @override
  String toString() => value;
}
