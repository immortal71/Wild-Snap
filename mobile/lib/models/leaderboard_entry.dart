class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? avatarUrl;
  final int points;
  final int catchCount;
  final String? country;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.points,
    this.catchCount = 0,
    this.country,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      points: (json['points'] as num?)?.toInt() ??
          (json['total_points'] as num?)?.toInt() ??
          (json['weekly_points'] as num?)?.toInt() ??
          0,
      catchCount: (json['catch_count'] as num?)?.toInt() ?? 0,
      country: json['country']?.toString(),
      isCurrentUser: json['is_current_user'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'points': points,
      'catch_count': catchCount,
      'country': country,
      'is_current_user': isCurrentUser,
    };
  }

  // Mock data
  static List<LeaderboardEntry> mockEntries(String currentUserId) {
    return [
      LeaderboardEntry(
        rank: 1,
        userId: 'u1',
        username: 'WildHunter99',
        points: 12450,
        catchCount: 87,
        country: 'US',
        isCurrentUser: 'u1' == currentUserId,
      ),
      LeaderboardEntry(
        rank: 2,
        userId: 'u2',
        username: 'NatureSnap',
        points: 10200,
        catchCount: 71,
        country: 'UK',
        isCurrentUser: 'u2' == currentUserId,
      ),
      LeaderboardEntry(
        rank: 3,
        userId: 'u3',
        username: 'Safari_Pro',
        points: 9800,
        catchCount: 65,
        country: 'ZA',
        isCurrentUser: 'u3' == currentUserId,
      ),
      LeaderboardEntry(
        rank: 4,
        userId: 'u4',
        username: 'BioExplorer',
        points: 7600,
        catchCount: 52,
        country: 'AU',
        isCurrentUser: 'u4' == currentUserId,
      ),
      LeaderboardEntry(
        rank: 5,
        userId: 'u5',
        username: 'ForestWatcher',
        points: 6300,
        catchCount: 44,
        country: 'BR',
        isCurrentUser: 'u5' == currentUserId,
      ),
      LeaderboardEntry(
        rank: 6,
        userId: 'u6',
        username: 'CreatureSeeker',
        points: 5100,
        catchCount: 38,
        country: 'IN',
        isCurrentUser: 'u6' == currentUserId,
      ),
      LeaderboardEntry(
        rank: 7,
        userId: 'u7',
        username: 'WildEye',
        points: 4800,
        catchCount: 33,
        country: 'JP',
        isCurrentUser: 'u7' == currentUserId,
      ),
      LeaderboardEntry(
        rank: 8,
        userId: 'u8',
        username: 'NightCrawler',
        points: 3950,
        catchCount: 28,
        country: 'DE',
        isCurrentUser: 'u8' == currentUserId,
      ),
    ];
  }
}
