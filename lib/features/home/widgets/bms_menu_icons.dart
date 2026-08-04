import 'dart:math' as math;

import 'package:flutter/material.dart';

class AddDeviceIcon extends StatelessWidget {
  const AddDeviceIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 43,
      child: CustomPaint(painter: _AddDevicePainter()),
    );
  }
}

class BatteryIcon extends StatelessWidget {
  const BatteryIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 41,
      height: 28,
      child: CustomPaint(painter: _BatteryPainter()),
    );
  }
}

class _AddDevicePainter extends CustomPainter {
  const _AddDevicePainter();

  static const _dashCount = 12;
  static const _dashSweep = 0.34;
  static const _radius = 19.0;
  static const _plusRadius = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < _dashCount; index++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: _radius),
        index * (2 * math.pi / _dashCount),
        _dashSweep,
        false,
        paint,
      );
    }

    canvas
      ..drawLine(
        center.translate(-_plusRadius, 0),
        center.translate(_plusRadius, 0),
        paint,
      )
      ..drawLine(
        center.translate(0, -_plusRadius),
        center.translate(0, _plusRadius),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _AddDevicePainter oldDelegate) => false;
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter();

  static const _segmentCount = 3;
  static const _segmentGap = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = Colors.white;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 3, size.width - 7, size.height - 6),
      const Radius.circular(1),
    );
    canvas
      ..drawRRect(body, stroke)
      ..drawRect(Rect.fromLTWH(size.width - 6, 9, 5, size.height - 18), stroke);

    final segmentWidth =
        (size.width - 16 - (_segmentGap * (_segmentCount - 1))) / _segmentCount;
    for (var index = 0; index < _segmentCount; index++) {
      canvas.drawRect(
        Rect.fromLTWH(
          5 + index * (segmentWidth + _segmentGap),
          7,
          segmentWidth,
          size.height - 14,
        ),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) => false;
}
