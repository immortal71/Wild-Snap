class User {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final int totalPoints;
  final int weeklyPoints;
  final int catchCount;
  final int currentStreak;
  final int longestStreak;
  final String? country;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.totalPoints = 0,
    this.weeklyPoints = 0,
    this.catchCount = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.country,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      weeklyPoints: (json['weekly_points'] as num?)?.toInt() ?? 0,
      catchCount: (json['catch_count'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      country: json['country']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'total_points': totalPoints,
      'weekly_points': weeklyPoints,
      'catch_count': catchCount,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'country': country,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    int? totalPoints,
    int? weeklyPoints,
    int? catchCount,
    int? currentStreak,
    int? longestStreak,
    String? country,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      catchCount: catchCount ?? this.catchCount,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
