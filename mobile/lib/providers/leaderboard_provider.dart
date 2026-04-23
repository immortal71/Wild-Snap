import 'package:flutter/foundation.dart';
import '../models/leaderboard_entry.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';

enum LeaderboardTab { global, country, friends }
enum LeaderboardPeriod { allTime, weekly }

class LeaderboardProvider extends ChangeNotifier {
  final ApiService _api;
  final ConnectivityService _connectivity;

  List<LeaderboardEntry> _entries = [];
  LeaderboardEntry? _myEntry;
  LeaderboardTab _activeTab = LeaderboardTab.global;
  LeaderboardPeriod _activePeriod = LeaderboardPeriod.allTime;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  LeaderboardProvider(this._api, this._connectivity);

  List<LeaderboardEntry> get entries => _entries;
  LeaderboardEntry? get myEntry => _myEntry;
  LeaderboardTab get activeTab => _activeTab;
  LeaderboardPeriod get activePeriod => _activePeriod;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadLeaderboard({
    required String userId,
    String? country,
  }) async {
    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_connectivity.isOnline) {
        _entries = LeaderboardEntry.mockEntries(userId);
        _setMyEntry(userId);
        return;
      }

      final period = _activePeriod == LeaderboardPeriod.weekly ? 'weekly' : 'alltime';

      switch (_activeTab) {
        case LeaderboardTab.global:
          final response = await _api.getGlobalLeaderboard(period: period);
          if (response['success'] == true && response['data'] != null) {
            final data = response['data'];
            final list = (data['leaderboard'] as List?) ?? [];
            _entries = list
                .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          break;

        case LeaderboardTab.country:
          if (country != null && country.isNotEmpty) {
            final response = await _api.getCountryLeaderboard(
              country: country,
              period: period,
            );
            if (response['success'] == true && response['data'] != null) {
              final data = response['data'];
              final list = (data['leaderboard'] as List?) ?? [];
              _entries = list
                  .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          } else {
            _entries = LeaderboardEntry.mockEntries(userId);
          }
          break;

        case LeaderboardTab.friends:
          // Friends leaderboard — use mock for now
          _entries = LeaderboardEntry.mockEntries(userId);
          break;
      }

      // Assign rank + current user flag
      _entries = _entries.asMap().entries.map((e) {
        final entry = e.value;
        return LeaderboardEntry(
          rank: e.key + 1,
          userId: entry.userId,
          username: entry.username,
          avatarUrl: entry.avatarUrl,
          points: entry.points,
          catchCount: entry.catchCount,
          country: entry.country,
          isCurrentUser: entry.userId == userId,
        );
      }).toList();

      _setMyEntry(userId);
    } catch (_) {
      _entries = LeaderboardEntry.mockEntries(userId);
      _setMyEntry(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTab(LeaderboardTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    if (_currentUserId != null) {
      loadLeaderboard(userId: _currentUserId!);
    }
  }

  void setPeriod(LeaderboardPeriod period) {
    if (_activePeriod == period) return;
    _activePeriod = period;
    if (_currentUserId != null) {
      loadLeaderboard(userId: _currentUserId!);
    }
  }

  void _setMyEntry(String userId) {
    try {
      _myEntry = _entries.firstWhere((e) => e.userId == userId);
    } catch (_) {
      _myEntry = null;
    }
  }
}
