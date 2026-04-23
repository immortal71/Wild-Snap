import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sighting.dart';
import '../models/animal.dart';

class LocalDbService {
  static const String _dbName = 'wildsnap.db';
  static const int _dbVersion = 1;

  static const String _pendingSightingsTable = 'pending_sightings';
  static const String _cachedAnimalsTable = 'cached_animals';
  static const String _cachedCollectionTable = 'cached_collection';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_pendingSightingsTable (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            animal_id TEXT,
            animal_name TEXT,
            scientific_name TEXT,
            rarity TEXT,
            points_earned INTEGER DEFAULT 0,
            latitude REAL,
            longitude REAL,
            photo_url TEXT,
            local_photo_path TEXT,
            captured_at TEXT NOT NULL,
            is_synced INTEGER DEFAULT 0,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $_cachedAnimalsTable (
            id TEXT PRIMARY KEY,
            common_name TEXT NOT NULL,
            scientific_name TEXT NOT NULL,
            category TEXT NOT NULL,
            rarity TEXT NOT NULL,
            base_points INTEGER DEFAULT 10,
            image_url TEXT,
            description TEXT,
            habitat TEXT,
            conservation_status TEXT,
            region TEXT,
            is_caught INTEGER DEFAULT 0,
            my_sightings_count INTEGER,
            cached_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $_cachedCollectionTable (
            animal_id TEXT PRIMARY KEY,
            sightings_json TEXT,
            cached_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ── Pending Sightings ─────────────────────────────────

  Future<void> savePendingSighting(Sighting sighting) async {
    final db = await database;
    await db.insert(
      _pendingSightingsTable,
      sighting.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Sighting>> getPendingSightings() async {
    final db = await database;
    final maps = await db.query(
      _pendingSightingsTable,
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'captured_at ASC',
    );
    return maps.map((m) => Sighting.fromJson(m)).toList();
  }

  Future<int> getPendingSightingsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_pendingSightingsTable WHERE is_synced = 0',
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markSightingSynced(String id) async {
    final db = await database;
    await db.update(
      _pendingSightingsTable,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearSyncedSightings() async {
    final db = await database;
    await db.delete(
      _pendingSightingsTable,
      where: 'is_synced = ?',
      whereArgs: [1],
    );
  }

  Future<List<Sighting>> getAllSightings() async {
    final db = await database;
    final maps = await db.query(
      _pendingSightingsTable,
      orderBy: 'captured_at DESC',
    );
    return maps.map((m) => Sighting.fromJson(m)).toList();
  }

  // ── Cached Animals ────────────────────────────────────

  Future<void> cacheAnimals(List<Animal> animals) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final animal in animals) {
      final data = animal.toJson();
      data['cached_at'] = now;
      data['is_caught'] = animal.isCaught ? 1 : 0;
      batch.insert(
        _cachedAnimalsTable,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Animal>> getCachedAnimals() async {
    final db = await database;
    final maps = await db.query(_cachedAnimalsTable, orderBy: 'common_name ASC');
    return maps.map((m) => Animal.fromJson(m)).toList();
  }

  Future<Animal?> getCachedAnimalById(String id) async {
    final db = await database;
    final maps = await db.query(
      _cachedAnimalsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Animal.fromJson(maps.first);
  }

  Future<void> clearCachedAnimals() async {
    final db = await database;
    await db.delete(_cachedAnimalsTable);
  }

  // ── Cached Collection ─────────────────────────────────

  Future<void> cacheCollection(String animalId, List<Map<String, dynamic>> sightings) async {
    final db = await database;
    await db.insert(
      _cachedCollectionTable,
      {
        'animal_id': animalId,
        'sightings_json': jsonEncode(sightings),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>?> getCachedCollection(String animalId) async {
    final db = await database;
    final maps = await db.query(
      _cachedCollectionTable,
      where: 'animal_id = ?',
      whereArgs: [animalId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    try {
      final decoded = jsonDecode(maps.first['sightings_json'] as String);
      return (decoded as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
