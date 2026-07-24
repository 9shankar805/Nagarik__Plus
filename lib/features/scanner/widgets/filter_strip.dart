import 'package:flutter/material.dart';
import '../models/scan_document.dart';

/// Horizontal scrollable filter chip strip shown in the review screen.
class FilterStrip extends StatelessWidget {
  final ScanFilter selected;
  final ValueChanged<ScanFilter> onFilterSelected;

  const FilterStrip({
    super.key,
    required this.selected,
    required this.onFilterSelected,
  });

  static const _filters = ScanFilter.values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final f      = _filters[i];
          final active = f == selected;
          return GestureDetector(
            onTap: () => onFilterSelected(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF1565C0).withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active
                      ? const Color(0xFF1565C0)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _iconFor(f),
                    size: 22,
                    color: active
                        ? const Color(0xFF1565C0)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w400,
                      color: active
                          ? const Color(0xFF1565C0)
                          : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(ScanFilter f) {
    switch (f) {
      case ScanFilter.original:      return Icons.image_outlined;
      case ScanFilter.auto:          return Icons.auto_fix_high_rounded;
      case ScanFilter.magicColor:    return Icons.color_lens_rounded;
      case ScanFilter.blackAndWhite: return Icons.contrast_rounded;
      case ScanFilter.gray:          return Icons.gradient_rounded;
      case ScanFilter.color:         return Icons.palette_rounded;
      case ScanFilter.document:      return Icons.description_rounded;
      case ScanFilter.highContrast:  return Icons.brightness_high_rounded;
      case ScanFilter.sharpen:       return Icons.center_focus_strong_rounded;
      case ScanFilter.cleanPaper:    return Icons.article_outlined;
      case ScanFilter.vintage:       return Icons.photo_filter_rounded;
    }
  }
}
