import 'package:flutter/material.dart';

class EditToolbar extends StatelessWidget {
  final VoidCallback onRotateCW;
  final VoidCallback onRotateCCW;
  final VoidCallback onFlip;
  final VoidCallback onUndo;
  final VoidCallback onReset;
  final bool canUndo;

  const EditToolbar({
    super.key,
    required this.onRotateCW,
    required this.onRotateCCW,
    required this.onFlip,
    required this.onUndo,
    required this.onReset,
    required this.canUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Btn(
            icon:    Icons.rotate_left_rounded,
            label:   'CCW',
            onTap:   onRotateCCW,
          ),
          _Btn(
            icon:    Icons.rotate_right_rounded,
            label:   'CW',
            onTap:   onRotateCW,
          ),
          _Btn(
            icon:    Icons.flip_rounded,
            label:   'Flip',
            onTap:   onFlip,
          ),
          _Btn(
            icon:    Icons.undo_rounded,
            label:   'Undo',
            onTap:   canUndo ? onUndo : null,
            enabled: canUndo,
          ),
          _Btn(
            icon:    Icons.restart_alt_rounded,
            label:   'Reset',
            onTap:   onReset,
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _Btn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFF424242) : Colors.grey.shade400;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 9, color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
