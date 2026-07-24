import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/scanner_controller.dart';
import '../models/scan_document.dart';

/// Bottom sheet for naming, categorising and saving a scan.
class SaveSheet extends StatefulWidget {
  const SaveSheet({super.key});

  @override
  State<SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<SaveSheet> {
  final _nameCtrl   = TextEditingController();
  DocCategory _cat  = DocCategory.other;
  SaveFormat  _fmt  = SaveFormat.pdf;
  PdfPageSize _size = PdfPageSize.a4;
  DateTime?   _expiry;
  bool _runOcr      = false; // default off — faster save
  bool _compressed  = false;
  int  _compQuality = 80;
  bool _saving      = false;
  String _saveStatus = '';

  static const _categories = DocCategory.values;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(children: [
              const Text('Save to Digital Locker',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller:    _nameCtrl,
              enabled:       !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText:   'Document Name',
                hintText:    'e.g. My Passport',
                border:      OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon:  const Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            _SectionLabel('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _categories.map((c) {
                final sel = _cat == c;
                return GestureDetector(
                  onTap: _saving ? null : () => setState(() => _cat = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? AppColors.primary
                              : AppColors.divider),
                    ),
                    child: Text(c.label,
                        style: TextStyle(
                            color: sel ? Colors.white : AppColors.textMedium,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Format + page size
            Row(children: [
              _SectionLabel('Format'),
              const Spacer(),
              _Chip('PDF',  _fmt == SaveFormat.pdf,
                  () => setState(() => _fmt = SaveFormat.pdf)),
              const SizedBox(width: 8),
              _Chip('JPEG', _fmt == SaveFormat.jpeg,
                  () => setState(() => _fmt = SaveFormat.jpeg)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _SectionLabel('Page Size'),
              const Spacer(),
              _Chip('A4',     _size == PdfPageSize.a4,
                  () => setState(() => _size = PdfPageSize.a4)),
              const SizedBox(width: 6),
              _Chip('Letter', _size == PdfPageSize.letter,
                  () => setState(() => _size = PdfPageSize.letter)),
            ]),
            const SizedBox(height: 14),

            // Options
            _ToggleRow(
              label: 'Extract text (OCR) — slower',
              value: _runOcr,
              enabled: !_saving,
              onChanged: (v) => setState(() => _runOcr = v),
            ),
            _ToggleRow(
              label: 'Compress file',
              value: _compressed,
              enabled: !_saving,
              onChanged: (v) => setState(() => _compressed = v),
            ),
            if (_compressed) ...[
              const SizedBox(height: 6),
              _SectionLabel('Quality: $_compQuality%'),
              Row(children: [
                const Text('50%', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                Expanded(
                  child: Slider(
                    value: _compQuality.toDouble(),
                    min: 50, max: 90, divisions: 4,
                    activeColor: AppColors.primary,
                    label: '$_compQuality%',
                    onChanged: _saving ? null : (v) => setState(() => _compQuality = v.round()),
                  ),
                ),
                const Text('90%', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
              ]),
            ],
            const SizedBox(height: 10),

            // Expiry date
            GestureDetector(
              onTap: _saving ? null : _pickExpiry,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppColors.textMedium),
                  const SizedBox(width: 8),
                  Text(
                    _expiry != null
                        ? 'Expires: ${_expiry!.year}/'
                          '${_expiry!.month.toString().padLeft(2, '0')}/'
                          '${_expiry!.day.toString().padLeft(2, '0')}'
                        : 'Add expiry date (optional)',
                    style: TextStyle(
                        color: _expiry != null
                            ? AppColors.textDark
                            : AppColors.textLight,
                        fontSize: 13),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // Save progress status
            if (_saving) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _saveStatus.isEmpty ? 'Preparing…' : _saveStatus,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMedium),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_rounded),
                label: Text(
                    _saving ? 'Saving…' : 'Save to Digital Locker'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExpiry() async {
    final d = await showDatePicker(
      context:     context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime(2099),
    );
    if (d != null) setState(() => _expiry = d);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a document name')));
      return;
    }

    setState(() {
      _saving = true;
      _saveStatus = 'Processing pages…';
    });

    final ctrl = context.read<ScannerController>();

    // Run save in background — update status labels so user knows it's working
    final doc = await ctrl.saveDocument(
      name:               name,
      category:           _cat,
      format:             _fmt,
      pageSize:           _size,
      runOcr:             _runOcr,
      compressed:         _compressed,
      compressionQuality: _compQuality,
      expiryDate:         _expiry,
      onProgress:         (msg) {
        if (mounted) setState(() => _saveStatus = msg);
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (doc != null) {
      // Capture navigator + messenger BEFORE any pop (context is valid here)
      final nav = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      // Close the save sheet
      nav.pop();

      messenger.showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Saved "${doc.name}"',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));

      // Pop back past review + camera screens to home
      nav.popUntil((route) => route.isFirst);
    } else {
      final errorMsg = ctrl.errorMessage ?? 'Save failed';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMsg),
        backgroundColor: AppColors.danger,
      ));
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textMedium));
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppColors.textMedium,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.label, required this.value, required this.onChanged,
       this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textMedium)),
      const Spacer(),
      Switch(
          value:           value,
          onChanged:       enabled ? onChanged : null,
          activeTrackColor: AppColors.primary),
    ]);
  }
}
