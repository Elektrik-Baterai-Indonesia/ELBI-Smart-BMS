class BmsErrorDefinition {
  const BmsErrorDefinition({
    required this.bit,
    required this.englishDescription,
    required this.indonesianDescription,
  });

  final int bit;
  final String englishDescription;
  final String indonesianDescription;

  int get mask => 1 << bit;

  String description({required bool useIndonesian}) {
    return useIndonesian ? indonesianDescription : englishDescription;
  }
}

const bmsErrorDefinitions = <BmsErrorDefinition>[
  BmsErrorDefinition(
    bit: 0,
    englishDescription: 'Short Circuit',
    indonesianDescription: 'Hubung Singkat',
  ),
  BmsErrorDefinition(
    bit: 1,
    englishDescription: 'Over Charging Current',
    indonesianDescription: 'Arus Pengisian Berlebih',
  ),
  BmsErrorDefinition(
    bit: 2,
    englishDescription: 'Over Discharge Current',
    indonesianDescription: 'Arus Pengosongan Berlebih',
  ),
  BmsErrorDefinition(
    bit: 3,
    englishDescription: 'Over Temperature',
    indonesianDescription: 'Suhu Berlebih',
  ),
  BmsErrorDefinition(
    bit: 4,
    englishDescription: 'Stand By',
    indonesianDescription: 'Siaga',
  ),
  BmsErrorDefinition(
    bit: 5,
    englishDescription: 'Relay Positive Error',
    indonesianDescription: 'Kesalahan Relai Positif',
  ),
  BmsErrorDefinition(
    bit: 6,
    englishDescription: 'Relay Precharge Error',
    indonesianDescription: 'Kesalahan Relai Prapengisian',
  ),
  BmsErrorDefinition(
    bit: 7,
    englishDescription: 'Wrong Polarity',
    indonesianDescription: 'Polaritas Terbalik',
  ),
  BmsErrorDefinition(
    bit: 8,
    englishDescription: 'Relay Negative Error',
    indonesianDescription: 'Kesalahan Relai Negatif',
  ),
  BmsErrorDefinition(
    bit: 9,
    englishDescription: 'Undervoltage',
    indonesianDescription: 'Tegangan Rendah',
  ),
  BmsErrorDefinition(
    bit: 10,
    englishDescription: 'Overvoltage',
    indonesianDescription: 'Tegangan Berlebih',
  ),
  BmsErrorDefinition(
    bit: 11,
    englishDescription: 'Positive Insulation Fault',
    indonesianDescription: 'Gangguan Isolasi Positif',
  ),
  BmsErrorDefinition(
    bit: 12,
    englishDescription: 'Negative Insulation Fault',
    indonesianDescription: 'Gangguan Isolasi Negatif',
  ),
  BmsErrorDefinition(
    bit: 13,
    englishDescription: 'Cell Undervoltage',
    indonesianDescription: 'Tegangan Sel Rendah',
  ),
  BmsErrorDefinition(
    bit: 14,
    englishDescription: 'Cell Overvoltage',
    indonesianDescription: 'Tegangan Sel Berlebih',
  ),
  BmsErrorDefinition(
    bit: 15,
    englishDescription: 'Cell Overtemperature',
    indonesianDescription: 'Suhu Sel Berlebih',
  ),
  BmsErrorDefinition(
    bit: 16,
    englishDescription: 'Connection Fault',
    indonesianDescription: 'Gangguan Koneksi',
  ),
  BmsErrorDefinition(
    bit: 17,
    englishDescription: 'Setting Mode',
    indonesianDescription: 'Mode Pengaturan',
  ),
];

final int knownBmsErrorMask = bmsErrorDefinitions.fold(
  0,
  (mask, definition) => mask | definition.mask,
);

List<BmsErrorDefinition> activeBmsErrors(int errorCode) {
  if (errorCode <= 0) return const [];
  return [
    for (final definition in bmsErrorDefinitions)
      if (errorCode & definition.mask != 0) definition,
  ];
}

List<int> unknownBmsErrorBits(int errorCode) {
  if (errorCode <= 0) return const [];
  final unknownMask = errorCode & ~knownBmsErrorMask;
  return [
    for (var bit = 18; bit < unknownMask.bitLength; bit++)
      if (unknownMask & (1 << bit) != 0) bit,
  ];
}
