import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nagarik_plus/core/providers/locale_provider.dart';

class LanguageSwitcherWidget extends StatelessWidget {
  final bool compact;
  const LanguageSwitcherWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleProvider>();
    final isNepali = provider.locale.languageCode == 'ne';

    if (compact) {
      return Semantics(
        label: isNepali
            ? 'Current language: Nepali. Tap to switch to English.'
            : 'Current language: English. Tap to switch to Nepali.',
        child: GestureDetector(
          onTap: () => provider.setLocale(
            isNepali ? const Locale('en') : const Locale('ne'),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white38),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isNepali ? 'NE' : 'EN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.swap_horiz, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LocaleTab(
            label: 'EN',
            isActive: !isNepali,
            onTap: () => provider.setLocale(const Locale('en')),
            semanticsLabel: isNepali ? 'Switch to English' : 'English selected',
          ),
          _LocaleTab(
            label: 'NE',
            isActive: isNepali,
            onTap: () => provider.setLocale(const Locale('ne')),
            semanticsLabel: isNepali ? 'Nepali selected' : 'Switch to Nepali',
          ),
        ],
      ),
    );
  }
}

class _LocaleTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String semanticsLabel;

  const _LocaleTab({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF1A237E)
                  : const Color(0xFF90A4AE),
            ),
          ),
        ),
      ),
    );
  }
}
