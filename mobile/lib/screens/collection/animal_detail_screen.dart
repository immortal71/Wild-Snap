import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/animal.dart';
import '../../models/sighting.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rarity_badge.dart';

class AnimalDetailScreen extends StatelessWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.rarityColor(animal.rarity);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, rarityColor),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildTabBar(),
                  _buildTabViews(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, Color rarityColor) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.bgPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    rarityColor.withOpacity(0.2),
                    AppColors.bgPrimary,
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgTertiary,
                      border: Border.all(color: rarityColor.withOpacity(0.4), width: 2),
                    ),
                    child: Icon(
                      Icons.cruelty_free_outlined,
                      size: 48,
                      color: rarityColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    animal.isCaught ? animal.commonName : '???',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    animal.isCaught ? animal.scientificName : '??? ???',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RarityBadge(rarity: animal.rarity, fontSize: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.bgPrimary,
      child: TabBar(
        isScrollable: false,
        labelColor: AppColors.accentPrimary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.accentPrimary,
        indicatorWeight: 2,
        labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Habitat'),
          Tab(text: 'Conservation'),
          Tab(text: 'My Sightings'),
        ],
      ),
    );
  }

  Widget _buildTabViews(BuildContext context) {
    return SizedBox(
      height: 450,
      child: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildOverviewTab(),
          _buildHabitatTab(),
          _buildConservationTab(),
          _buildMySightingsTab(context),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Category', animal.category),
          _infoRow('Rarity', animal.rarity.toUpperCase()),
          _infoRow('Base Points', '${animal.basePoints} pts'),
          if (animal.region != null) _infoRow('Region', animal.region!),
          if (animal.mySightingsCount != null)
            _infoRow('My Sightings', '${animal.mySightingsCount}'),
          if (animal.description != null) ...[
            const SizedBox(height: 20),
            Text(
              'About',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              animal.description!,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHabitatTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Natural Habitat',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            animal.habitat ?? 'Habitat information not available.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (animal.region != null) ...[
            const SizedBox(height: 20),
            _infoRow('Native Region', animal.region!),
          ],
        ],
      ),
    );
  }

  Widget _buildConservationTab() {
    final status = animal.conservationStatus ?? 'Unknown';
    final statusColor = _conservationColor(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _conservationDescription(status),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentPrimary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('🌍', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your sightings help researchers track wildlife populations worldwide.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMySightingsTab(BuildContext context) {
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    final sightings = animal.isCaught
        ? Sighting.mockSightings(userId)
            .where((s) => s.animalId == animal.id)
            .toList()
        : <Sighting>[];

    if (!animal.isCaught) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Not caught yet',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Photograph this animal to unlock',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (sightings.isEmpty) {
      return Center(
        child: Text(
          'No sightings recorded yet',
          style: GoogleFonts.dmSans(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sightings.length,
      itemBuilder: (context, index) {
        final s = sightings[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.camera_alt_outlined,
                  size: 18, color: AppColors.accentPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.capturedAt.day}/${s.capturedAt.month}/${s.capturedAt.year}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (s.latitude != null)
                      Text(
                        '${s.latitude!.toStringAsFixed(3)}°, ${s.longitude!.toStringAsFixed(3)}°',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.bolt, size: 13, color: AppColors.accentSecondary),
                  Text(
                    '+${s.pointsEarned}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _conservationColor(String status) {
    switch (status.toLowerCase()) {
      case 'critically endangered':
        return AppColors.danger;
      case 'endangered':
        return AppColors.accentSecondary;
      case 'vulnerable':
        return const Color(0xFFFFD700);
      case 'near threatened':
        return AppColors.colorUncommon;
      default:
        return AppColors.success;
    }
  }

  String _conservationDescription(String status) {
    switch (status.toLowerCase()) {
      case 'critically endangered':
        return 'This species faces an extremely high risk of extinction in the wild. Urgent conservation action is needed.';
      case 'endangered':
        return 'This species faces a very high risk of extinction in the wild. Conservation efforts are crucial.';
      case 'vulnerable':
        return 'This species faces a high risk of extinction in the wild if circumstances threatening its survival continue.';
      case 'near threatened':
        return 'This species is close to qualifying for a threatened category or is likely to qualify in the near future.';
      default:
        return 'This species is not considered to be facing a significant risk of extinction at present.';
    }
  }
}
