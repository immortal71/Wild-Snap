import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sighting_provider.dart';
import '../../models/animal.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animal_card.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sightings = context.watch<SightingProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              if (user != null) ...[
                _buildAvatar(user.username, user.avatarUrl),
                const SizedBox(height: 20),
                _buildStatsRow(
                  user.totalPoints,
                  user.catchCount,
                  user.currentStreak,
                ),
                const SizedBox(height: 24),
                _buildAchievements(),
                const SizedBox(height: 24),
                _buildCollectionPreview(),
                const SizedBox(height: 24),
                _buildSyncStatus(sightings.pendingCount),
                const SizedBox(height: 24),
              ],
              _buildSignOutButton(context, auth),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Profile',
              style: GoogleFonts.dmSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textSecondary, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String username, String? avatarUrl) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.accentPrimary, Color(0xFF1FA855)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPrimary.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: GoogleFonts.dmSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.bgPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            username,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Wildlife Explorer',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int totalPoints, int catchCount, int streak) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _StatItem(
              label: 'Total Points',
              value: _formatPoints(totalPoints),
              icon: Icons.bolt,
              color: AppColors.accentSecondary,
            ),
            _verticalDivider(),
            _StatItem(
              label: 'Catches',
              value: catchCount.toString(),
              icon: Icons.camera_alt_outlined,
              color: AppColors.accentPrimary,
            ),
            _verticalDivider(),
            _StatItem(
              label: 'Streak',
              value: '$streak days',
              icon: Icons.local_fire_department_outlined,
              color: AppColors.accentSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.textMuted.withOpacity(0.2),
    );
  }

  Widget _buildAchievements() {
    final achievements = [
      _Achievement('🌱', 'First Catch', 'Caught your first animal'),
      _Achievement('📸', 'Shutterbug', '10 photos taken'),
      _Achievement('🔥', 'On Fire', '7-day streak'),
      _Achievement('🦁', 'Safari Pro', 'Caught a legendary'),
      _Achievement('🌍', 'Explorer', 'Visited 5 regions'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Achievements',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              return _buildAchievementCard(achievements[index], index < 3);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(_Achievement a, bool unlocked) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.accentPrimary.withOpacity(0.08)
            : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? AppColors.accentPrimary.withOpacity(0.3)
              : AppColors.textMuted.withOpacity(0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            unlocked ? a.emoji : '🔒',
            style: TextStyle(fontSize: unlocked ? 28 : 22),
          ),
          const SizedBox(height: 6),
          Text(
            a.label,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionPreview() {
    final animals = Animal.mockAnimals().where((a) => a.isCaught).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Recent Collection',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'View all →',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.accentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 130,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimalCard(animal: animals[index], compact: true),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatus(int pendingCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: pendingCount > 0
                ? AppColors.accentSecondary.withOpacity(0.3)
                : AppColors.bgTertiary,
          ),
        ),
        child: Row(
          children: [
            Icon(
              pendingCount > 0
                  ? Icons.cloud_upload_outlined
                  : Icons.cloud_done_outlined,
              color: pendingCount > 0 ? AppColors.accentSecondary : AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pendingCount > 0
                    ? '$pendingCount photo${pendingCount != 1 ? 's' : ''} pending sync'
                    : 'All photos synced',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: pendingCount > 0
                      ? AppColors.accentSecondary
                      : AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _confirmSignOut(context, auth),
          icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
          label: const Text(
            'Sign Out',
            style: TextStyle(color: AppColors.danger),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.danger, width: 1),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text(
          'Sign Out',
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.dmSans(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  String _formatPoints(int points) {
    if (points >= 1000) return '${(points / 1000).toStringAsFixed(1)}k';
    return points.toString();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  final String emoji;
  final String label;
  final String description;

  const _Achievement(this.emoji, this.label, this.description);
}
