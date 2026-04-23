import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background
  static const Color bgPrimary = Color(0xFF0A0F0D);
  static const Color bgSecondary = Color(0xFF111A14);
  static const Color bgTertiary = Color(0xFF192219);

  // Accents
  static const Color accentPrimary = Color(0xFF39FF89);
  static const Color accentSecondary = Color(0xFFFFAA33);
  static const Color accentTertiary = Color(0xFF7EC8E3);

  // Rarity
  static const Color colorLegendary = Color(0xFFFFD700);
  static const Color colorEpic = Color(0xFFC77DFF);
  static const Color colorRare = Color(0xFF4895EF);
  static const Color colorUncommon = Color(0xFF52B788);
  static const Color colorCommon = Color(0xFF8D99AE);

  // Text
  static const Color textPrimary = Color(0xFFEDF2EF);
  static const Color textSecondary = Color(0xFF7A9E7E);
  static const Color textMuted = Color(0xFF4A5553);

  // Status
  static const Color danger = Color(0xFFFF4757);
  static const Color success = Color(0xFF2ED573);

  static Color rarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return colorLegendary;
      case 'epic':
        return colorEpic;
      case 'rare':
        return colorRare;
      case 'uncommon':
        return colorUncommon;
      default:
        return colorCommon;
    }
  }
}
