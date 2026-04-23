class Sighting {
  final String id;
  final String userId;
  final String? animalId;
  final String? animalName;
  final String? scientificName;
  final String? rarity;
  final int pointsEarned;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? localPhotoPath;
  final DateTime capturedAt;
  final bool isSynced;
  final String? notes;

  const Sighting({
    required this.id,
    required this.userId,
    this.animalId,
    this.animalName,
    this.scientificName,
    this.rarity,
    this.pointsEarned = 0,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.localPhotoPath,
    required this.capturedAt,
    this.isSynced = false,
    this.notes,
  });

  factory Sighting.fromJson(Map<String, dynamic> json) {
    return Sighting(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      animalId: json['animal_id']?.toString(),
      animalName: json['animal_name']?.toString() ?? json['common_name']?.toString(),
      scientificName: json['scientific_name']?.toString(),
      rarity: json['rarity']?.toString(),
      pointsEarned: (json['points_earned'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      photoUrl: json['photo_url']?.toString(),
      localPhotoPath: json['local_photo_path']?.toString(),
      capturedAt: json['captured_at'] != null
          ? DateTime.tryParse(json['captured_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isSynced: json['is_synced'] == true || json['is_synced'] == 1,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'animal_id': animalId,
      'animal_name': animalName,
      'scientific_name': scientificName,
      'rarity': rarity,
      'points_earned': pointsEarned,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
      'local_photo_path': localPhotoPath,
      'captured_at': capturedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'notes': notes,
    };
  }

  Sighting copyWith({
    String? id,
    String? userId,
    String? animalId,
    String? animalName,
    String? scientificName,
    String? rarity,
    int? pointsEarned,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? localPhotoPath,
    DateTime? capturedAt,
    bool? isSynced,
    String? notes,
  }) {
    return Sighting(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      animalId: animalId ?? this.animalId,
      animalName: animalName ?? this.animalName,
      scientificName: scientificName ?? this.scientificName,
      rarity: rarity ?? this.rarity,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      capturedAt: capturedAt ?? this.capturedAt,
      isSynced: isSynced ?? this.isSynced,
      notes: notes ?? this.notes,
    );
  }

  // Mock sightings
  static List<Sighting> mockSightings(String userId) {
    return [
      Sighting(
        id: 's1',
        userId: userId,
        animalId: '2',
        animalName: 'Bengal Tiger',
        scientificName: 'Panthera tigris tigris',
        rarity: 'epic',
        pointsEarned: 300,
        latitude: 27.1751,
        longitude: 78.0421,
        capturedAt: DateTime.now().subtract(const Duration(hours: 2)),
        isSynced: true,
      ),
      Sighting(
        id: 's2',
        userId: userId,
        animalId: '3',
        animalName: 'Red Fox',
        scientificName: 'Vulpes vulpes',
        rarity: 'common',
        pointsEarned: 25,
        latitude: 51.5074,
        longitude: -0.1278,
        capturedAt: DateTime.now().subtract(const Duration(days: 1)),
        isSynced: true,
      ),
      Sighting(
        id: 's3',
        userId: userId,
        animalId: '5',
        animalName: 'Mandarin Duck',
        scientificName: 'Aix galericulata',
        rarity: 'uncommon',
        pointsEarned: 60,
        latitude: 35.6762,
        longitude: 139.6503,
        capturedAt: DateTime.now().subtract(const Duration(days: 3)),
        isSynced: true,
      ),
    ];
  }
}
