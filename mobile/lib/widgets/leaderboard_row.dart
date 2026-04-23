import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/leaderboard_entry.dart';
import '../theme/app_colors.dart';

class LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const LeaderboardRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = entry.isCurrentUser;
    final rankColor = _rankColor(entry.rank);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.accentPrimary.withOpacity(0.08)
            : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.accentPrimary.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: entry.rank <= 3
                ? Text(
                    _rankEmoji(entry.rank),
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  )
                : Text(
                    '#${entry.rank}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: rankColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.username,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                          color: isCurrentUser
                              ? AppColors.accentPrimary
                              : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.country != null)
                      Text(
                        '  ${entry.country}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                Text(
                  '${entry.catchCount} catches',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPoints(entry.points),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isCurrentUser ? AppColors.accentPrimary : AppColors.textPrimary,
                ),
              ),
              Text(
                'pts',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgTertiary,
        border: Border.all(
          color: entry.isCurrentUser
              ? AppColors.accentPrimary.withOpacity(0.5)
              : AppColors.textMuted.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.accentPrimary,
          ),
        ),
      ),
    );
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.colorLegendary;
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textMuted;
    }
  }

  String _formatPoints(int points) {
    if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}k';
    }
    return points.toString();
  }
}
