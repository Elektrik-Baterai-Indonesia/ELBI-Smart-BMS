import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleDebugMessage {
  const BleDebugMessage({
    required this.timestamp,
    required this.serviceId,
    required this.characteristicId,
    required this.source,
    required this.text,
    required this.hex,
    required this.prettyJson,
  });

  final DateTime timestamp;
  final String serviceId;
  final String characteristicId;
  final String source;
  final String text;
  final String hex;
  final String? prettyJson;

  bool get containsJson => prettyJson != null;

  factory BleDebugMessage.fromBytes({
    required String serviceId,
    required String characteristicId,
    required String source,
    required List<int> bytes,
    DateTime? timestamp,
  }) {
    final text = utf8.decode(bytes, allowMalformed: true).trim();
    String? prettyJson;

    if (text.isNotEmpty) {
      try {
        final decoded = jsonDecode(text);
        prettyJson = const JsonEncoder.withIndent('  ').convert(decoded);
      } on FormatException {
        // The original text and bytes remain available for non-JSON packets.
      }
    }

    return BleDebugMessage(
      timestamp: timestamp ?? DateTime.now(),
      serviceId: serviceId,
      characteristicId: characteristicId,
      source: source,
      text: text,
      hex: bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(' ')
          .toUpperCase(),
      prettyJson: prettyJson,
    );
  }
}

class BleDebugController extends ChangeNotifier {
  factory BleDebugController({
    required FlutterReactiveBle ble,
    required String deviceId,
  }) {
    return BleDebugController._(ble, deviceId);
  }

  BleDebugController._(this._ble, this._deviceId);

  static const String uartServiceUuid = 'ffe0';
  static const String uartWriteUuid = 'ffe1';
  static const String uartNotifyUuid = 'ffe2';

  static const _maximumMessages = 100;
  static const _defaultMtu = 23;
  static const _targetMtu = 247;
  static const _writeChunkSize = 20;
  static const _writeWithoutResponseDelay = Duration(milliseconds: 15);

  final FlutterReactiveBle _ble;
  final String _deviceId;
  final List<BleDebugMessage> _messages = [];
  final List<StreamSubscription<List<int>>> _subscriptions = [];
  final List<Characteristic> _writableCharacteristics = [];

  bool _isDiscovering = false;
  bool _servicesDiscovered = false;
  bool _isCapturing = false;
  bool _disposed = false;
  int _serviceCount = 0;
  int _characteristicCount = 0;
  int _negotiatedMtu = _defaultMtu;
  String? _errorMessage;
  Completer<void>? _discoveryCompleter;

  List<BleDebugMessage> get messages => List.unmodifiable(_messages);
  bool get isDiscovering => _isDiscovering;
  bool get isCapturing => _isCapturing;
  int get serviceCount => _serviceCount;
  int get characteristicCount => _characteristicCount;
  String? get errorMessage => _errorMessage;

  Future<void> start() async {
    if (_disposed || _servicesDiscovered) return;
    if (_isDiscovering) {
      await _discoveryCompleter?.future;
      return;
    }

    _isDiscovering = true;
    _discoveryCompleter = Completer<void>();
    _errorMessage = null;
    notifyListeners();

    try {
      await _ble.discoverAllServices(_deviceId);
      final services = await _ble.getDiscoveredServices(_deviceId);
      if (_disposed) return;

      _negotiatedMtu = await _negotiateMtu();
      _writableCharacteristics.clear();

      Service? uartService;
      for (final service in services) {
        if (_matchesUuid(service.id, uartServiceUuid)) {
          uartService = service;
          break;
        }
      }
      if (uartService == null) {
        throw StateError('UART service FFE0 was not found.');
      }

      Characteristic? writeCharacteristic;
      Characteristic? notifyCharacteristic;
      for (final characteristic in uartService.characteristics) {
        if (_matchesUuid(characteristic.id, uartWriteUuid)) {
          writeCharacteristic = characteristic;
        } else if (_matchesUuid(characteristic.id, uartNotifyUuid)) {
          notifyCharacteristic = characteristic;
        }
      }
      if (writeCharacteristic == null ||
          (!writeCharacteristic.isWritableWithResponse &&
              !writeCharacteristic.isWritableWithoutResponse)) {
        throw StateError('UART write characteristic FFE1 was not found.');
      }
      if (notifyCharacteristic == null ||
          (!notifyCharacteristic.isNotifiable &&
              !notifyCharacteristic.isIndicatable)) {
        throw StateError('UART notify characteristic FFE2 was not found.');
      }

      _serviceCount = 1;
      _characteristicCount = uartService.characteristics.length;
      _writableCharacteristics.add(writeCharacteristic);

      if (notifyCharacteristic.isReadable) {
        try {
          final value = await notifyCharacteristic.read();
          _addPacket(
            serviceId: uartService.id.toString(),
            characteristicId: notifyCharacteristic.id.toString(),
            source: 'READ',
            bytes: value,
          );
        } on Object {
          // FFE2 is primarily a notification channel and may reject reads.
        }
      }

      final subscription = notifyCharacteristic.subscribe().listen(
        (value) => _addPacket(
          serviceId: uartService!.id.toString(),
          characteristicId: notifyCharacteristic!.id.toString(),
          source: notifyCharacteristic.isIndicatable ? 'INDICATE' : 'NOTIFY',
          bytes: value,
        ),
        onError: (_) {
          if (_disposed) return;
          _errorMessage = 'UART notifications stopped unexpectedly.';
          _isCapturing = false;
          notifyListeners();
        },
      );
      _subscriptions.add(subscription);

      _isCapturing = _subscriptions.isNotEmpty;
      _servicesDiscovered = true;
    } on Object {
      _errorMessage =
          'GATT services could not be inspected on this connection.';
    } finally {
      _isDiscovering = false;
      _discoveryCompleter?.complete();
      _discoveryCompleter = null;
      if (!_disposed) notifyListeners();
    }
  }

  Future<int> _negotiateMtu() async {
    try {
      return await _ble.requestMtu(deviceId: _deviceId, mtu: _targetMtu);
    } on Object {
      return _defaultMtu;
    }
  }

  bool _matchesUuid(Object uuid, String shortUuid) {
    final normalized = uuid.toString().toLowerCase().replaceAll('-', '');
    return normalized == shortUuid || normalized.startsWith('0000$shortUuid');
  }

  Future<void> writeJson(String payload) async {
    if (_disposed) {
      throw const BleWriteException(BleWriteFailure.disconnected);
    }

    await start();
    if (_writableCharacteristics.isEmpty) {
      throw const BleWriteException(BleWriteFailure.noWritableCharacteristic);
    }

    final characteristic = _writableCharacteristics.firstWhere(
      (candidate) => candidate.isWritableWithResponse,
      orElse: () => _writableCharacteristics.first,
    );
    final withResponse = characteristic.isWritableWithResponse;
    final bytes = utf8.encode(payload);
    final chunkSize = (_negotiatedMtu - 3).clamp(
      _writeChunkSize,
      _targetMtu - 3,
    );

    try {
      for (var offset = 0; offset < bytes.length; offset += chunkSize) {
        final end = (offset + chunkSize).clamp(0, bytes.length);
        final chunk = bytes.sublist(offset, end);
        await characteristic.write(chunk, withResponse: withResponse);
        if (!withResponse && end < bytes.length) {
          await Future<void>.delayed(_writeWithoutResponseDelay);
        }
      }

      _addPacket(
        serviceId: characteristic.service.id.toString(),
        characteristicId: characteristic.id.toString(),
        source: 'WRITE',
        bytes: bytes,
      );
    } on Object {
      throw const BleWriteException(BleWriteFailure.transmissionFailed);
    }
  }

  Future<void> stop() async {
    final subscriptions = [..._subscriptions];
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    _isCapturing = false;
    if (!_disposed) notifyListeners();
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }

  void _addPacket({
    required String serviceId,
    required String characteristicId,
    required String source,
    required List<int> bytes,
  }) {
    if (_disposed) return;
    _messages.insert(
      0,
      BleDebugMessage.fromBytes(
        serviceId: serviceId,
        characteristicId: characteristicId,
        source: source,
        bytes: bytes,
      ),
    );
    if (_messages.length > _maximumMessages) {
      _messages.removeRange(_maximumMessages, _messages.length);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}

enum BleWriteFailure {
  disconnected,
  noWritableCharacteristic,
  transmissionFailed,
}

class BleWriteException implements Exception {
  const BleWriteException(this.failure);

  final BleWriteFailure failure;
}
