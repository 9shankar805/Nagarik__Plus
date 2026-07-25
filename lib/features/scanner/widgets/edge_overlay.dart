import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/scan_document.dart';

/// Animated edge-detection overlay drawn on top of the camera preview.
class EdgeOverlay extends StatefulWidget {
  final DocumentCorners corners;
  final bool detected;
  final double stabilityProgress; // 0.0 → 1.0 (auto-capture countdown)

  const EdgeOverlay({
    super.key,
    required this.corners,
    required this.detected,
    this.stabilityProgress = 0.0,
  });

  @override
  State<EdgeOverlay> createState() => _EdgeOverlayState();
}

class _EdgeOverlayState extends State<EdgeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => CustomPaint(
        painter: _EdgePainter(
          corners:           widget.corners,
          detected:          widget.detected,
          pulseOpacity:      _pulse.value,
          stabilityProgress: widget.stabilityProgress,
        ),
      ),
    );
  }
}

class _EdgePainter extends CustomPainter {
  final DocumentCorners corners;
  final bool detected;
  final double pulseOpacity;
  final double stabilityProgress;

  const _EdgePainter({
    required this.corners,
    required this.detected,
    required this.pulseOpacity,
    required this.stabilityProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [
      Offset(corners.topLeft.dx     * size.width, corners.topLeft.dy     * size.height),
      Offset(corners.topRight.dx    * size.width, corners.topRight.dy    * size.height),
      Offset(corners.bottomRight.dx * size.width, corners.bottomRight.dy * size.height),
      Offset(corners.bottomLeft.dx  * size.width, corners.bottomLeft.dy  * size.height),
    ];

    // Dim overlay outside detected region
    final outerPath = Path()..addRect(Offset.zero & size);
    final innerPath = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[2].dx, pts[2].dy)
      ..lineTo(pts[3].dx, pts[3].dy)
      ..close();

    canvas.drawPath(
      Path.combine(PathOperation.difference, outerPath, innerPath),
      Paint()..color = Colors.black.withValues(alpha: 0.52),
    );

    // Border
    final borderColor = detected
        ? Color.lerp(const Color(0xFF4CAF50),
              Colors.white, 1.0 - pulseOpacity)!
        : Colors.white54;

    canvas.drawPath(
      innerPath,
      Paint()
        ..color       = borderColor
        ..style       = PaintingStyle.stroke
        ..strokeWidth = detected ? 2.5 : 1.5,
    );

    // Corner handles
    _drawCornerHandles(canvas, pts, borderColor);

    // Stability arc
    if (detected && stabilityProgress > 0) {
      _drawStabilityArc(canvas, size, stabilityProgress);
    }
  }

  void _drawCornerHandles(Canvas canvas, List<Offset> pts, Color color) {
    const len  = 22.0;
    const width = 3.5;
    final paint = Paint()
      ..color       = color
      ..strokeWidth = width
      ..strokeCap   = StrokeCap.round
      ..style       = PaintingStyle.stroke;

    for (int i = 0; i < pts.length; i++) {
      final c  = pts[i];
      final nx = pts[(i + 1) % 4];
      final px = pts[(i + 3) % 4];

      _drawHandleLine(canvas, c, nx, len, paint);
      _drawHandleLine(canvas, c, px, len, paint);
    }
  }

  void _drawHandleLine(
      Canvas canvas, Offset from, Offset to, double len, Paint paint) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final d  = math.sqrt(dx * dx + dy * dy);
    if (d == 0) return;
    canvas.drawLine(from,
        Offset(from.dx + dx / d * len, from.dy + dy / d * len), paint);
  }

  void _drawStabilityArc(Canvas canvas, Size size, double progress) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 32.0;
    final sweep  = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color       = const Color(0xFF4CAF50)
        ..strokeWidth = 4
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.corners           != corners ||
      old.detected          != detected ||
      old.pulseOpacity      != pulseOpacity ||
      old.stabilityProgress != stabilityProgress;
}
