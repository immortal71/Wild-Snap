import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sighting_provider.dart';
import '../../models/animal.dart';
import '../../models/sighting.dart';
import '../../services/connectivity_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/rarity_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Animal> _nearbyAnimals = Animal.mockAnimals().sublist(0, 5);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final connectivity = context.watch<ConnectivityService>();
    final sightings = context.watch<SightingProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(user?.username ?? 'Explorer', user?.currentStreak ?? 0, user?.totalPoints ?? 0),
          if (!connectivity.isOnline)
            const SliverToBoxAdapter(child: OfflineBanner()),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildDailyChallenge(),
                const SizedBox(height: 24),
                _buildSectionHeader('Nearby Sightings', icon: Icons.location_on_outlined),
                const SizedBox(height: 12),
                _buildNearbyScroll(),
                const SizedBox(height: 24),
                _buildSectionHeader('Recent Catches', icon: Icons.camera_alt_outlined),
                const SizedBox(height: 12),
                _buildRecentCatches(sightings),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(String username, int streak, int points) {
    return SliverAppBar(
      backgroundColor: AppColors.bgPrimary,
      floating: true,
      snap: true,
      elevation: 0,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, $username 👋',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'What will you discover?',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StreakBadge(streak: streak),
          const SizedBox(width: 12),
          _buildPointsBadge(points),
        ],
      ),
    );
  }

  Widget _buildPointsBadge(int points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accentPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, size: 13, color: AppColors.accentPrimary),
          const SizedBox(width: 3),
          Text(
            _formatPoints(points),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.accentPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.accentPrimary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallenge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentPrimary.withOpacity(0.12),
              AppColors.accentTertiary.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accentPrimary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentSecondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DAILY CHALLENGE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Photograph a Bird',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Any bird species counts • +100 bonus pts',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0,
                    backgroundColor: AppColors.bgTertiary,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accentPrimary),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '0/1 completed',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text('🦅', style: TextStyle(fontSize: 48)),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyScroll() {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _nearbyAnimals.length,
        itemBuilder: (context, index) {
          final animal = _nearbyAnimals[index];
          final rarityColor = AppColors.rarityColor(animal.rarity);
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: rarityColor.withOpacity(0.3), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RarityBadge(rarity: animal.rarity),
                      const Spacer(),
                      Icon(
                        Icons.location_on,
                        size: 11,
                        color: AppColors.textMuted,
                      ),
                      Text(
                        ' ${(index + 1) * 0.3}km',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    animal.commonName,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    animal.category,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentCatches(SightingProvider sightings) {
    if (sightings.isLoading) {
      return _buildShimmerList();
    }

    final recent = sightings.recentSightings;
    if (recent.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: recent.length > 5 ? 5 : recent.length,
      itemBuilder: (context, index) => _buildSightingRow(recent[index]),
    );
  }

  Widget _buildSightingRow(Sighting s) {
    final rarityColor = s.rarity != null
        ? AppColors.rarityColor(s.rarity!)
        : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: rarityColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.animalName ?? 'Unknown',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  s.scientificName ?? '',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (s.rarity != null) RarityBadge(rarity: s.rarity!),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.bolt, size: 12, color: AppColors.accentSecondary),
                  Text(
                    '+${s.pointsEarned}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.bgSecondary,
      highlightColor: AppColors.bgTertiary,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No catches yet',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the scan button to photograph your first animal!',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatPoints(int points) {
    if (points >= 1000) return '${(points / 1000).toStringAsFixed(1)}k';
    return points.toString();
  }
}
