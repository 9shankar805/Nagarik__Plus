import 'package:flutter/material.dart';

// ─── 14.1  Theme constants ────────────────────────────────────────────────────

class NsTheme {
  const NsTheme._();

  static const Color bg       = Color(0xFFF5F5F5);
  static const Color blue     = Color(0xFF1677FF);
  static const Color textDark = Color(0xFF212121);
  static const Color textSub  = Color(0xFF757575);
  static const Color card     = Color(0xFFFFFFFF);
  static const Color divider  = Color(0xFFE0E0E0);
  static const Color green    = Color(0xFF4CAF50);
  static const Color orange   = Color(0xFFFF9800);
  static const Color red      = Color(0xFFF44336);
}

// ─── 14.2  NsSectionCard ─────────────────────────────────────────────────────

/// White rounded card used across Files tab and Home screen.
class NsSectionCard extends StatelessWidget {
  const NsSectionCard({
    super.key,
    this.title,
    required this.child,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NsTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: NsTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

// ─── 14.3  NsSegmentedControl ─────────────────────────────────────────────────

/// Pill-style segmented control: selected option has white bg + subtle shadow;
/// unselected options are transparent.
class NsSegmentedControl extends StatelessWidget {
  const NsSegmentedControl({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (index) {
          final isSelected = index == selected;
          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? NsTheme.card : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                labels[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? NsTheme.textDark : NsTheme.textSub,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── 14.4  NsPermissionPlaceholder ───────────────────────────────────────────

/// Centred placeholder shown when a permission is not yet granted.
/// Displays a stacked-icon illustration, a message, and an action button.
class NsPermissionPlaceholder extends StatelessWidget {
  const NsPermissionPlaceholder({
    super.key,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stacked illustration — phone base + person overlay
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  Icon(
                    Icons.phone_android_rounded,
                    size: 80,
                    color: Color(0xFFBBDEFB),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: Color(0xFFFFB74D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: NsTheme.textSub,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onPressed,
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: NsTheme.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 14.5  NsStorageMeter ─────────────────────────────────────────────────────

/// 60×60 circular progress widget showing the used/total storage ratio.
/// Orange arc, percent integer in the centre.
class NsStorageMeter extends StatelessWidget {
  const NsStorageMeter({
    super.key,
    required this.usedBytes,
    required this.totalBytes,
  });

  final double usedBytes;
  final double totalBytes;

  @override
  Widget build(BuildContext context) {
    final ratio = (totalBytes > 0) ? (usedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
    final percent = (ratio * 100).round();

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: ratio,
            strokeWidth: 6,
            backgroundColor: NsTheme.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(NsTheme.orange),
          ),
          Text(
            '$percent%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: NsTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
