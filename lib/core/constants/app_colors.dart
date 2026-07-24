import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF003c8f);
  static const Color primaryLight = Color(0xFF5e92f3);

  // Secondary
  static const Color secondary = Color(0xFF2E7D32);
  static const Color secondaryLight = Color(0xFF60ad5e);
  static const Color secondaryDark = Color(0xFF005005);

  // Accent
  static const Color accent = Color(0xFFF9A825);
  static const Color accentLight = Color(0xFFffd95a);
  static const Color accentDark = Color(0xFFc17900);

  // Background
  static const Color background = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF121212);

  // Cards
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);

  // Danger
  static const Color danger = Color(0xFFD32F2F);

  // Text
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF616161);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Others
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF0288D1);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
