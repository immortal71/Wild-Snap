import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class RarityBadge extends StatelessWidget {
  final String rarity;
  final double fontSize;

  const RarityBadge({
    super.key,
    required this.rarity,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        rarity.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
