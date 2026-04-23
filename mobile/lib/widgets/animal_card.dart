import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal.dart';
import '../theme/app_colors.dart';
import 'rarity_badge.dart';

class AnimalCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback? onTap;
  final bool compact;

  const AnimalCard({
    super.key,
    required this.animal,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.rarityColor(animal.rarity);
    final isCaught = animal.isCaught;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: rarityColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withOpacity(isCaught ? 0.25 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              _buildContent(rarityColor, isCaught),
              if (!isCaught) _buildUncaughtOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color rarityColor, bool isCaught) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageSection(isCaught),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCaught ? animal.commonName : '???',
                style: GoogleFonts.dmSans(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                isCaught ? animal.scientificName : '??? ???',
                style: GoogleFonts.dmSans(
                  fontSize: compact ? 10 : 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  RarityBadge(rarity: animal.rarity),
                  const Spacer(),
                  if (isCaught)
                    Row(
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 13,
                          color: AppColors.accentSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${animal.basePoints}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (animal.region != null && isCaught) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 11,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        animal.region!,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(bool isCaught) {
    return SizedBox(
      height: compact ? 90 : 110,
      width: double.infinity,
      child: animal.imageUrl != null && isCaught
          ? CachedNetworkImage(
              imageUrl: animal.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.bgTertiary),
              errorWidget: (_, __, ___) => _buildPlaceholderImage(isCaught),
            )
          : _buildPlaceholderImage(isCaught),
    );
  }

  Widget _buildPlaceholderImage(bool isCaught) {
    return Container(
      color: AppColors.bgTertiary,
      child: Center(
        child: Icon(
          _categoryIcon(animal.category),
          size: compact ? 32 : 40,
          color: isCaught
              ? AppColors.rarityColor(animal.rarity).withOpacity(0.5)
              : AppColors.textMuted.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildUncaughtOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgPrimary.withOpacity(0.65),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(
            Icons.lock_outline,
            color: AppColors.textMuted,
            size: 28,
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mammal':
        return Icons.pets;
      case 'bird':
        return Icons.flutter_dash;
      case 'fish':
        return Icons.set_meal;
      case 'insect':
        return Icons.bug_report_outlined;
      case 'reptile':
        return Icons.align_vertical_bottom_outlined;
      case 'amphibian':
        return Icons.water_outlined;
      default:
        return Icons.cruelty_free_outlined;
    }
  }
}
