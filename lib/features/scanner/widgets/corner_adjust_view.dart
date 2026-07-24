import 'package:flutter/material.dart';
import '../models/scan_document.dart';
import 'edge_overlay.dart';

/// Interactive four-corner drag widget for manual perspective adjustment.
/// Shows a magnifier near the active handle for precise positioning.
class CornerAdjustView extends StatefulWidget {
  final String imagePath;
  final DocumentCorners corners;
  final ValueChanged<DocumentCorners> onCornersChanged;

  const CornerAdjustView({
    super.key,
    required this.imagePath,
    required this.corners,
    required this.onCornersChanged,
  });

  @override
  State<CornerAdjustView> createState() => _CornerAdjustViewState();
}

class _CornerAdjustViewState extends State<CornerAdjustView> {
  late DocumentCorners _corners;
  int? _dragging;            // index of corner being dragged: 0-TL,1-TR,2-BR,3-BL
  Offset? _magnifierPos;

  @override
  void initState() {
    super.initState();
    _corners = widget.corners;
  }

  @override
  void didUpdateWidget(CornerAdjustView old) {
    super.didUpdateWidget(old);
    if (old.corners != widget.corners && _dragging == null) {
      _corners = widget.corners;
    }
  }

  List<Offset> _pixelCorners(Size size) => [
    Offset(_corners.topLeft.dx     * size.width, _corners.topLeft.dy     * size.height),
    Offset(_corners.topRight.dx    * size.width, _corners.topRight.dy    * size.height),
    Offset(_corners.bottomRight.dx * size.width, _corners.bottomRight.dy * size.height),
    Offset(_corners.bottomLeft.dx  * size.width, _corners.bottomLeft.dy  * size.height),
  ];

  DocumentCorners _fromPixels(List<Offset> px, Size size) => DocumentCorners(
    topLeft:     Offset(px[0].dx / size.width, px[0].dy / size.height),
    topRight:    Offset(px[1].dx / size.width, px[1].dy / size.height),
    bottomRight: Offset(px[2].dx / size.width, px[2].dy / size.height),
    bottomLeft:  Offset(px[3].dx / size.width, px[3].dy / size.height),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final px   = _pixelCorners(size);

      return GestureDetector(
        onPanStart: (d) {
          for (int i = 0; i < px.length; i++) {
            if ((d.localPosition - px[i]).distance < 36) {
              setState(() {
                _dragging     = i;
                _magnifierPos = px[i];
              });
              return;
            }
          }
        },
        onPanUpdate: (d) {
          if (_dragging == null) return;
          final np = px..[_dragging!] = Offset(
            d.localPosition.dx.clamp(0.0, size.width),
            d.localPosition.dy.clamp(0.0, size.height),
          );
          final newCorners = _fromPixels(np, size);
          setState(() {
            _corners      = newCorners;
            _magnifierPos = d.localPosition;
          });
          widget.onCornersChanged(newCorners);
        },
        onPanEnd: (_) => setState(() {
          _dragging     = null;
          _magnifierPos = null;
        }),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset(
              widget.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.network(
                widget.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12),
              ),
            ),

            // Edge overlay
            EdgeOverlay(corners: _corners, detected: true),

            // Drag handles
            ...List.generate(4, (i) {
              final c = px[i];
              return Positioned(
                left: c.dx - 22,
                top:  c.dy - 22,
                child: AnimatedScale(
                  scale:    _dragging == i ? 1.3 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.open_with_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              );
            }),

            // Magnifier
            if (_magnifierPos != null && _dragging != null)
              _Magnifier(position: _magnifierPos!, imagePath: widget.imagePath),
          ],
        ),
      );
    });
  }
}

/// Simple magnifier circle near drag point.
class _Magnifier extends StatelessWidget {
  final Offset position;
  final String imagePath;

  const _Magnifier({required this.position, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    // Place magnifier above the finger
    const radius = 48.0;
    return Positioned(
      left:  position.dx - radius,
      top:   position.dy - radius * 2.8,
      child: Container(
        width:  radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8),
          ],
        ),
        child: ClipOval(
          child: OverflowBox(
            maxWidth:  radius * 4,
            maxHeight: radius * 4,
            child: Transform.scale(
              scale: 2.5,
              child: Image.asset(imagePath, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          ),
        ),
      ),
    );
  }
}
