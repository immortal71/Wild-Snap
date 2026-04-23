import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../services/connectivity_service.dart';
import '../../models/leaderboard_entry.dart';
import '../../theme/app_colors.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/leaderboard_row.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id ?? '';
    final country = auth.currentUser?.country;
    await context.read<LeaderboardProvider>().loadLeaderboard(
          userId: userId,
          country: country,
        );
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();
    final leaderboard = context.watch<LeaderboardProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            if (!connectivity.isOnline) const OfflineBanner(),
            _buildHeader(),
            _buildTabs(leaderboard),
            _buildPeriodToggle(leaderboard),
            Expanded(
              child: leaderboard.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accentPrimary),
                    )
                  : leaderboard.entries.isEmpty
                      ? _buildEmpty()
                      : _buildList(leaderboard, auth.currentUser?.id ?? ''),
            ),
            if (leaderboard.myEntry != null)
              _buildMyRankBar(leaderboard.myEntry!),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Leaderboard',
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const Text('🏆', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  Widget _buildTabs(LeaderboardProvider leaderboard) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _TabChip(
            label: 'Global',
            isActive: leaderboard.activeTab == LeaderboardTab.global,
            onTap: () => leaderboard.setTab(LeaderboardTab.global),
          ),
          const SizedBox(width: 8),
          _TabChip(
            label: 'Country',
            isActive: leaderboard.activeTab == LeaderboardTab.country,
            onTap: () => leaderboard.setTab(LeaderboardTab.country),
          ),
          const SizedBox(width: 8),
          _TabChip(
            label: 'Friends',
            isActive: leaderboard.activeTab == LeaderboardTab.friends,
            onTap: () => leaderboard.setTab(LeaderboardTab.friends),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(LeaderboardProvider leaderboard) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildToggleButton(
            'All Time',
            leaderboard.activePeriod == LeaderboardPeriod.allTime,
            () => leaderboard.setPeriod(LeaderboardPeriod.allTime),
          ),
          const SizedBox(width: 8),
          _buildToggleButton(
            'This Week',
            leaderboard.activePeriod == LeaderboardPeriod.weekly,
            () => leaderboard.setPeriod(LeaderboardPeriod.weekly),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentPrimary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.accentPrimary.withOpacity(0.4)
                : AppColors.textMuted.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.accentPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildList(LeaderboardProvider leaderboard, String currentUserId) {
    final topThree = leaderboard.entries.take(3).toList();
    final rest = leaderboard.entries.skip(3).toList();

    return ListView(
      children: [
        if (topThree.length >= 3) _buildPodium(topThree),
        const SizedBox(height: 8),
        ...rest.map((e) => LeaderboardRow(entry: e)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildPodiumItem(top3[1], 2, 80)),
          Expanded(child: _buildPodiumItem(top3[0], 1, 100)),
          Expanded(child: _buildPodiumItem(top3[2], 3, 65)),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(LeaderboardEntry entry, int rank, double height) {
    final medals = ['🥇', '🥈', '🥉'];
    final colors = [AppColors.colorLegendary, const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];
    final color = colors[rank - 1];

    return Column(
      children: [
        Text(medals[rank - 1], style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgTertiary,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.username,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: entry.isCurrentUser ? AppColors.accentPrimary : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          _formatPoints(entry.points),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
        ),
      ],
    );
  }

  Widget _buildMyRankBar(LeaderboardEntry myEntry) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.accentPrimary.withOpacity(0.2))),
      ),
      child: LeaderboardRow(entry: myEntry),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'No data available',
        style: GoogleFonts.dmSans(color: AppColors.textMuted),
      ),
    );
  }

  String _formatPoints(int points) {
    if (points >= 1000) return '${(points / 1000).toStringAsFixed(1)}k';
    return points.toString();
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentPrimary.withOpacity(0.15) : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.accentPrimary.withOpacity(0.4)
                : AppColors.textMuted.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.accentPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
