import 'package:flutter/material.dart';
import '../../data/models/transfer_file_model.dart';

/// Displays a single file's transfer progress with speed + ETA
class TransferProgressPanel extends StatelessWidget {
  final TransferFileModel file;
  const TransferProgressPanel({super.key, required this.file});

  static const _kText  = Color(0xFF0D1B34);
  static const _kSub   = Color(0xFF8A96A8);
  static const _kBord  = Color(0xFFE4EAF4);
  static const _kBlue  = Color(0xFF3461FF);
  static const _kGreen = Color(0xFF00C17C);

  @override
  Widget build(BuildContext context) {
    final pct      = (file.progress * 100).toInt();
    final isDone   = file.status == TransferStatus.completed;
    final isFailed = file.status == TransferStatus.failed;
    final barColor = isFailed ? Colors.red : isDone ? _kGreen : _kBlue;
    final icon     = _iconFor(file.category);
    final catColor = _colorFor(file.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBord),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Icon
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: catColor, size: 20),
          ),
          const SizedBox(width: 12),
          // File info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(file.name,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _kText,
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(file.sizeLabel,
                style: const TextStyle(color: _kSub, fontSize: 11)),
          ])),
          // Status badge
          if (isDone)
            const Icon(Icons.check_circle_rounded, color: _kGreen, size: 22)
          else if (isFailed)
            const Icon(Icons.error_rounded, color: Colors.red, size: 22)
          else
            Text('$pct%', style: TextStyle(
                color: barColor, fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: file.progress,
            backgroundColor: barColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: 6,
          ),
        ),
        if (!isDone && !isFailed) ...[
          const SizedBox(height: 8),
          Row(children: [
            Text(file.speedLabel,
                style: const TextStyle(color: _kSub, fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            if (file.etaSeconds > 0)
              Text(_formatEta(file.etaSeconds),
                  style: const TextStyle(color: _kSub, fontSize: 11)),
          ]),
        ],
        if (isFailed) ...[
          const SizedBox(height: 6),
          const Text('Transfer failed — file may be corrupted',
              style: TextStyle(color: Colors.red, fontSize: 11)),
        ],
      ]),
    );
  }

  String _formatEta(int seconds) {
    if (seconds < 60)   return '$seconds s left';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s left';
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m left';
  }

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
