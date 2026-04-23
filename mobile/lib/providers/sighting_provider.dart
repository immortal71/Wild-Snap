import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/sighting.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../services/connectivity_service.dart';

class SightingProvider extends ChangeNotifier {
  final ApiService _api;
  final LocalDbService _localDb;
  final ConnectivityService _connectivity;

  List<Sighting> _recentSightings = [];
  List<Sighting> _pendingSightings = [];
  Sighting? _lastCapture;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;
  int _pendingCount = 0;

  SightingProvider(this._api, this._localDb, this._connectivity);

  List<Sighting> get recentSightings => _recentSightings;
  List<Sighting> get pendingSightings => _pendingSightings;
  Sighting? get lastCapture => _lastCapture;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  int get pendingCount => _pendingCount;

  Future<void> initialize(String userId) async {
    await _loadPendingCount();
    await loadRecentSightings(userId);
  }

  Future<void> loadRecentSightings(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_connectivity.isOnline) {
        final response = await _api.getMySightings(page: 1, limit: 10);
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          final list = (data['sightings'] as List?) ?? [];
          _recentSightings = list
              .map((s) => Sighting.fromJson(s as Map<String, dynamic>))
              .toList();
        }
      } else {
        _recentSightings = await _localDb.getAllSightings();
        if (_recentSightings.isEmpty) {
          _recentSightings = Sighting.mockSightings(userId);
        }
      }
    } catch (_) {
      _recentSightings = Sighting.mockSightings(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Sighting?> submitSighting({
    required String userId,
    required String imagePath,
    required double latitude,
    required double longitude,
    required DateTime capturedAt,
    String? notes,
  }) async {
    _errorMessage = null;
    const uuid = Uuid();
    final tempId = uuid.v4();

    if (!_connectivity.isOnline) {
      final pending = Sighting(
        id: tempId,
        userId: userId,
        localPhotoPath: imagePath,
        latitude: latitude,
        longitude: longitude,
        capturedAt: capturedAt,
        isSynced: false,
        notes: notes,
        pointsEarned: 0,
      );
      await _localDb.savePendingSighting(pending);
      _pendingCount++;
      _lastCapture = pending;
      notifyListeners();
      return pending;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await _api.submitSighting(
        imagePath: imagePath,
        latitude: latitude,
        longitude: longitude,
        capturedAt: capturedAt,
        notes: notes,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final sighting = Sighting.fromJson(data['sighting'] as Map<String, dynamic>);
        _lastCapture = sighting;
        _recentSightings.insert(0, sighting);
        if (_recentSightings.length > 20) {
          _recentSightings = _recentSightings.sublist(0, 20);
        }
        notifyListeners();
        return sighting;
      } else {
        _errorMessage = response['error']?.toString() ?? 'Submission failed';
        notifyListeners();
        return null;
      }
    } catch (e) {
      // On network error, queue locally
      final pending = Sighting(
        id: tempId,
        userId: userId,
        localPhotoPath: imagePath,
        latitude: latitude,
        longitude: longitude,
        capturedAt: capturedAt,
        isSynced: false,
        notes: notes,
        pointsEarned: 0,
      );
      await _localDb.savePendingSighting(pending);
      _pendingCount++;
      _lastCapture = pending;
      _errorMessage = 'Queued for sync when connection is restored.';
      notifyListeners();
      return pending;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncPendingSightings() async {
    if (_isSyncing || !_connectivity.isOnline) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final pending = await _localDb.getPendingSightings();
      for (final sighting in pending) {
        if (sighting.localPhotoPath == null) continue;
        try {
          final response = await _api.submitSighting(
            imagePath: sighting.localPhotoPath!,
            latitude: sighting.latitude ?? 0,
            longitude: sighting.longitude ?? 0,
            capturedAt: sighting.capturedAt,
            notes: sighting.notes,
          );
          if (response['success'] == true) {
            await _localDb.markSightingSynced(sighting.id);
          }
        } catch (_) {
          // Leave for next sync attempt
        }
      }
      await _loadPendingCount();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _loadPendingCount() async {
    _pendingCount = await _localDb.getPendingSightingsCount();
  }

  void clearLastCapture() {
    _lastCapture = null;
    notifyListeners();
  }
}
