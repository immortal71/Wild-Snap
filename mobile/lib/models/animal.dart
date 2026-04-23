class Animal {
  final String id;
  final String commonName;
  final String scientificName;
  final String category;
  final String rarity;
  final int basePoints;
  final String? imageUrl;
  final String? description;
  final String? habitat;
  final String? conservationStatus;
  final String? region;
  final bool isCaught;
  final int? mySightingsCount;

  const Animal({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.category,
    required this.rarity,
    required this.basePoints,
    this.imageUrl,
    this.description,
    this.habitat,
    this.conservationStatus,
    this.region,
    this.isCaught = false,
    this.mySightingsCount,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id']?.toString() ?? '',
      commonName: json['common_name']?.toString() ?? '',
      scientificName: json['scientific_name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      rarity: json['rarity']?.toString() ?? 'common',
      basePoints: (json['base_points'] as num?)?.toInt() ?? 10,
      imageUrl: json['image_url']?.toString(),
      description: json['description']?.toString(),
      habitat: json['habitat']?.toString(),
      conservationStatus: json['conservation_status']?.toString(),
      region: json['region']?.toString(),
      isCaught: json['is_caught'] == true || json['is_caught'] == 1,
      mySightingsCount: (json['my_sightings_count'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'common_name': commonName,
      'scientific_name': scientificName,
      'category': category,
      'rarity': rarity,
      'base_points': basePoints,
      'image_url': imageUrl,
      'description': description,
      'habitat': habitat,
      'conservation_status': conservationStatus,
      'region': region,
      'is_caught': isCaught,
      'my_sightings_count': mySightingsCount,
    };
  }

  Animal copyWith({
    String? id,
    String? commonName,
    String? scientificName,
    String? category,
    String? rarity,
    int? basePoints,
    String? imageUrl,
    String? description,
    String? habitat,
    String? conservationStatus,
    String? region,
    bool? isCaught,
    int? mySightingsCount,
  }) {
    return Animal(
      id: id ?? this.id,
      commonName: commonName ?? this.commonName,
      scientificName: scientificName ?? this.scientificName,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      basePoints: basePoints ?? this.basePoints,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      habitat: habitat ?? this.habitat,
      conservationStatus: conservationStatus ?? this.conservationStatus,
      region: region ?? this.region,
      isCaught: isCaught ?? this.isCaught,
      mySightingsCount: mySightingsCount ?? this.mySightingsCount,
    );
  }

  // Mock data for UI development
  static List<Animal> mockAnimals() {
    return [
      const Animal(
        id: '1',
        commonName: 'Snow Leopard',
        scientificName: 'Panthera uncia',
        category: 'Mammal',
        rarity: 'legendary',
        basePoints: 500,
        imageUrl: null,
        description:
            'The snow leopard is a large cat native to the mountain ranges of Central and South Asia.',
        habitat: 'Alpine meadows and rocky terrain at 3,000–4,500 m elevation.',
        conservationStatus: 'Vulnerable',
        region: 'Central Asia',
        isCaught: false,
      ),
      const Animal(
        id: '2',
        commonName: 'Bengal Tiger',
        scientificName: 'Panthera tigris tigris',
        category: 'Mammal',
        rarity: 'epic',
        basePoints: 300,
        imageUrl: null,
        description: 'The Bengal tiger is a tiger subspecies native to the Indian subcontinent.',
        habitat: 'Tropical and subtropical moist broadleaf forests.',
        conservationStatus: 'Endangered',
        region: 'South Asia',
        isCaught: true,
        mySightingsCount: 2,
      ),
      const Animal(
        id: '3',
        commonName: 'Red Fox',
        scientificName: 'Vulpes vulpes',
        category: 'Mammal',
        rarity: 'common',
        basePoints: 25,
        imageUrl: null,
        description: 'The red fox is the largest of the true foxes and one of the most widely distributed.',
        habitat: 'Diverse habitats including forests, grasslands, and urban areas.',
        conservationStatus: 'Least Concern',
        region: 'Global',
        isCaught: true,
        mySightingsCount: 8,
      ),
      const Animal(
        id: '4',
        commonName: 'Blue Morpho Butterfly',
        scientificName: 'Morpho menelaus',
        category: 'Insect',
        rarity: 'rare',
        basePoints: 100,
        imageUrl: null,
        description: 'Known for their brilliant iridescent blue wings.',
        habitat: 'Tropical forests of South America.',
        conservationStatus: 'Least Concern',
        region: 'South America',
        isCaught: false,
      ),
      const Animal(
        id: '5',
        commonName: 'Mandarin Duck',
        scientificName: 'Aix galericulata',
        category: 'Bird',
        rarity: 'uncommon',
        basePoints: 60,
        imageUrl: null,
        description: 'Widely regarded as the most beautiful duck in the world.',
        habitat: 'Wooded areas near water.',
        conservationStatus: 'Least Concern',
        region: 'East Asia',
        isCaught: true,
        mySightingsCount: 3,
      ),
      const Animal(
        id: '6',
        commonName: 'Axolotl',
        scientificName: 'Ambystoma mexicanum',
        category: 'Amphibian',
        rarity: 'epic',
        basePoints: 280,
        imageUrl: null,
        description: 'A neotenic salamander known for its ability to regenerate limbs.',
        habitat: 'Lake Xochimilco, Mexico City.',
        conservationStatus: 'Critically Endangered',
        region: 'Mexico',
        isCaught: false,
      ),
      const Animal(
        id: '7',
        commonName: 'Common Sparrow',
        scientificName: 'Passer domesticus',
        category: 'Bird',
        rarity: 'common',
        basePoints: 10,
        imageUrl: null,
        description: 'One of the most familiar birds worldwide.',
        habitat: 'Urban and suburban areas.',
        conservationStatus: 'Least Concern',
        region: 'Global',
        isCaught: true,
        mySightingsCount: 15,
      ),
      const Animal(
        id: '8',
        commonName: 'Leafy Sea Dragon',
        scientificName: 'Phycodurus eques',
        category: 'Fish',
        rarity: 'legendary',
        basePoints: 450,
        imageUrl: null,
        description: 'A marine fish related to seahorses with elaborate leaf-like appendages.',
        habitat: 'Coastal waters of southern Australia.',
        conservationStatus: 'Least Concern',
        region: 'Australia',
        isCaught: false,
      ),
    ];
  }
}
