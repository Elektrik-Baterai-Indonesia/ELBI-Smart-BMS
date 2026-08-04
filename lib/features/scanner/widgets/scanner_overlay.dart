import 'package:flutter/material.dart';

class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({required this.scanWindow, super.key});

  final Rect scanWindow;

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScannerOverlayPainter(
          scanWindow: widget.scanWindow,
          animation: _animation,
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.scanWindow, required this.animation})
    : super(repaint: animation);

  final Rect scanWindow;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final window = RRect.fromRectAndRadius(
      scanWindow,
      const Radius.circular(20),
    );
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(window);

    canvas.drawPath(mask, Paint()..color = const Color(0x99000000));
    canvas.drawRRect(
      window,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    const lineInset = 12.0;
    final lineY =
        scanWindow.top +
        lineInset +
        (scanWindow.height - (lineInset * 2)) * animation.value;
    canvas.drawLine(
      Offset(scanWindow.left + lineInset, lineY),
      Offset(scanWindow.right - lineInset, lineY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}
