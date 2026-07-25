import 'package:flutter/material.dart';
import '../../data/models/transfer_record_model.dart';
import '../../services/transfer_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _transfer = TransferService();
  List<TransferRecord> _records = [];
  bool _loading = true;

  static const _kBg   = Color(0xFFF0F4FF);
  static const _kBlue = Color(0xFF3461FF);
  static const _kText = Color(0xFF0D1B34);
  static const _kSub  = Color(0xFF8A96A8);
  static const _kCard = Colors.white;
  static const _kBord = Color(0xFFE4EAF4);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _transfer.loadHistory();
    if (mounted) setState(() { _records = records; _loading = false; });
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all transfer history?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _transfer.clearHistory();
      _load();
    }
  }

  Future<void> _deleteRecord(String id) async {
    await _transfer.deleteHistory(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            color: _kCard,
            child: Row(children: [
              const Text('Transfer History',
                  style: TextStyle(color: _kText, fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              if (_records.isNotEmpty)
                GestureDetector(
                  onTap: _clearAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Clear All',
                        style: TextStyle(color: Colors.red,
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
            ]),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kBlue))
                : _records.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                        itemCount: _records.length,
                        itemBuilder: (_, i) => _buildTile(_records[i]),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTile(TransferRecord r) {
    final isSent = r.direction == TransferDirection.sent;
    final icon   = _iconForCategory(r.category);
    final color  = _colorForCategory(r.category);

    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      onDismissed: (_) => _deleteRecord(r.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBord),
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.fileName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _kText,
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSent
                      ? _kBlue.withValues(alpha: 0.1)
                      : const Color(0xFF00C17C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(isSent ? 'SENT' : 'RECEIVED',
                    style: TextStyle(
                        color: isSent ? _kBlue : const Color(0xFF00C17C),
                        fontSize: 9, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Text(r.sizeLabel,
                  style: const TextStyle(color: _kSub, fontSize: 11)),
              const SizedBox(width: 8),
              if (r.checksumVerified)
                const Icon(Icons.verified_rounded,
                    color: Color(0xFF00C17C), size: 13),
            ]),
          ])),
          // Date & peer
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_formatDate(r.timestamp),
                style: const TextStyle(color: _kSub, fontSize: 11)),
            const SizedBox(height: 4),
            Text(r.peerName, maxLines: 1,
                style: const TextStyle(color: _kSub, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: _kBlue.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(Icons.history_rounded,
            color: _kBlue.withValues(alpha: 0.5), size: 36),
      ),
      const SizedBox(height: 14),
      const Text('No Transfer History',
          style: TextStyle(color: _kText,
              fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Completed transfers will appear here',
          style: TextStyle(color: _kSub, fontSize: 13)),
    ]),
  );

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'image':    return Icons.image_rounded;
      case 'video':    return Icons.videocam_rounded;
      case 'audio':    return Icons.music_note_rounded;
      case 'apk':      return Icons.android_rounded;
      case 'document': return Icons.description_rounded;
      default:         return Icons.insert_drive_file_rounded;
    }
  }

  Color _colorForCategory(String cat) {
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
