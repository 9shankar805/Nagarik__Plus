import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/transfer_file_model.dart';

class FileQueueTile extends StatelessWidget {
  final TransferFileModel file;
  final VoidCallback? onRemove;
  const FileQueueTile({super.key, required this.file, this.onRemove});

  static const _kText = Color(0xFF0D1B34);
  static const _kSub  = Color(0xFF8A96A8);
  static const _kBord = Color(0xFFE4EAF4);

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(file.category);
    final icon  = _iconFor(file.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBord),
      ),
      child: Row(children: [
        // Thumbnail or icon
        _buildThumb(icon, color),
        const SizedBox(width: 12),
        // Info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(file.name,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _kText,
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(file.category.toUpperCase(),
                  style: TextStyle(color: color,
                      fontSize: 8, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            Text(file.sizeLabel,
                style: const TextStyle(color: _kSub, fontSize: 11)),
          ]),
        ])),
        // Remove
        if (onRemove != null)
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.red, size: 16),
            ),
          ),
      ]),
    );
  }

  Widget _buildThumb(IconData icon, Color color) {
    // Try to show a thumbnail for images
    if (file.category == 'image' && file.path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 46, height: 46,
          child: Image.file(File(file.path), fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _iconBox(icon, color)),
        ),
      );
    }
    return _iconBox(icon, color);
  }

  Widget _iconBox(IconData icon, Color color) => Container(
    width: 46, height: 46,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: color, size: 22),
  );

  IconData _iconFor(String cat) {
    switch (cat) {
      case 'image':    return Icons.image_rounded;
      case 'video':    return Icons.videocam_rounded;
      case 'audio':    return Icons.music_note_rounded;
      case 'apk':      return Icons.android_rounded;
      case 'document': return Icons.description_rounded;
      default:         return Icons.insert_drive_file_rounded;
    }
  }

  Color _colorFor(String cat) {
    switch (cat) {
      case 'image':    return const Color(0xFF4E8FFF);
      case 'video':    return const Color(0xFFFF4E6A);
      case 'audio':    return const Color(0xFF9B6BFF);
      case 'apk':      return const Color(0xFF2DC97E);
      case 'document': return const Color(0xFFFF9B2F);
      default:         return const Color(0xFF3BBFFF);
    }
  }
}
