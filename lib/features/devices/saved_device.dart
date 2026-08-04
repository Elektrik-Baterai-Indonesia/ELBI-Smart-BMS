class SavedDevice {
  const SavedDevice({
    required this.id,
    required this.name,
    required this.savedAt,
  });

  final String id;
  final String name;
  final DateTime savedAt;

  factory SavedDevice.fromIdentifier(String id, {String? name}) {
    final trimmedName = name?.trim() ?? '';
    final suffix = id.length > 5 ? id.substring(id.length - 5) : id;

    return SavedDevice(
      id: id,
      name: trimmedName.isEmpty ? 'BMS $suffix' : trimmedName,
      savedAt: DateTime.now(),
    );
  }

  factory SavedDevice.fromJson(Map<String, Object?> json) {
    return SavedDevice(
      id: json['id']! as String,
      name: json['name']! as String,
      savedAt: DateTime.parse(json['savedAt']! as String),
    );
  }

  Map<String, Object?> toJson() {
    return {'id': id, 'name': name, 'savedAt': savedAt.toIso8601String()};
  }
}
