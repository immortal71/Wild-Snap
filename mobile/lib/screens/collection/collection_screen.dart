import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/collection_provider.dart';
import '../../services/connectivity_service.dart';
import '../../models/animal.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animal_card.dart';
import '../../widgets/offline_banner.dart';
import 'animal_detail_screen.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectionProvider>().loadCollection();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();
    final collection = context.watch<CollectionProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            if (!connectivity.isOnline) const OfflineBanner(),
            _buildHeader(collection),
            _buildSearchBar(collection),
            _buildFilterTabs(collection),
            Expanded(
              child: collection.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accentPrimary),
                    )
                  : collection.animals.isEmpty
                      ? _buildEmptyState()
                      : _buildGrid(collection),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CollectionProvider collection) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collection',
                  style: GoogleFonts.dmSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${collection.caughtCount} / ${collection.totalCount} caught',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildProgressRing(collection),
        ],
      ),
    );
  }

  Widget _buildProgressRing(CollectionProvider collection) {
    final progress = collection.totalCount > 0
        ? collection.caughtCount / collection.totalCount
        : 0.0;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: AppColors.bgTertiary,
            valueColor: const AlwaysStoppedAnimation(AppColors.accentPrimary),
            strokeWidth: 4,
          ),
          Text(
            '${(progress * 100).round()}%',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.accentPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(CollectionProvider collection) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14),
        onChanged: (q) => collection.searchAnimals(q),
        decoration: InputDecoration(
          hintText: 'Search animals...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    collection.searchAnimals('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(CollectionProvider collection) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isActive: collection.activeFilter == CollectionFilter.all,
            onTap: () => collection.setFilter(CollectionFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Caught',
            isActive: collection.activeFilter == CollectionFilter.caught,
            onTap: () => collection.setFilter(CollectionFilter.caught),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Uncaught',
            isActive: collection.activeFilter == CollectionFilter.uncaught,
            onTap: () => collection.setFilter(CollectionFilter.uncaught),
          ),
          const SizedBox(width: 8),
          ...[
            'legendary', 'epic', 'rare', 'uncommon', 'common'
          ].map((rarity) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: rarity,
                  isActive: collection.activeFilter == CollectionFilter.byRarity &&
                      collection.selectedRarity == rarity,
                  color: AppColors.rarityColor(rarity),
                  onTap: () {
                    collection.setFilter(CollectionFilter.byRarity);
                    collection.setRarityFilter(rarity);
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildGrid(CollectionProvider collection) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: collection.animals.length,
      itemBuilder: (context, index) {
        final animal = collection.animals[index];
        return AnimalCard(
          animal: animal,
          onTap: () => _navigateToDetail(context, animal),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No animals found',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different filter or search term',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Animal animal) {
    context.read<CollectionProvider>().selectAnimal(animal);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimalDetailScreen(animal: animal),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.accentPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.5) : AppColors.textMuted.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label[0].toUpperCase() + label.substring(1),
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
