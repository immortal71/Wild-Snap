import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sighting.dart';
import '../theme/app_colors.dart';
import 'rarity_badge.dart';
import 'points_counter.dart';

class CaptureResultSheet extends StatelessWidget {
  final Sighting sighting;
  final bool isOffline;
  final VoidCallback? onAddToCollection;
  final VoidCallback? onRetake;

  const CaptureResultSheet({
    super.key,
    required this.sighting,
    this.isOffline = false,
    this.onAddToCollection,
    this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildAnimalInfo(),
                const SizedBox(height: 24),
                if (isOffline) _buildOfflineIndicator(),
                const SizedBox(height: 24),
                _buildActions(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentPrimary.withOpacity(0.1),
            border: Border.all(
              color: AppColors.accentPrimary.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.accentPrimary,
            size: 30,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'CAUGHT!',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: AppColors.accentPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimalInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            sighting.animalName ?? 'Unknown Animal',
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            sighting.scientificName ?? '',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (sighting.rarity != null)
            RarityBadge(rarity: sighting.rarity!, fontSize: 12),
          const SizedBox(height: 20),
          if (sighting.pointsEarned > 0)
            PointsCounter(targetValue: sighting.pointsEarned)
          else
            Text(
              'Queued for sync',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                color: AppColors.accentSecondary,
              ),
            ),
          if (sighting.pointsEarned > 0)
            Text(
              'POINTS EARNED',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                letterSpacing: 2,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.accentSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.accentSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Queued for sync when connection is restored',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.accentSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddToCollection ?? () => Navigator.of(context).pop(),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add to Collection'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRetake ?? () => Navigator.of(context).pop(),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Retake'),
            ),
          ),
        ],
      ),
    );
  }
}
