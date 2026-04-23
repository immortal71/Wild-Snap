import 'package:flutter/foundation.dart';
import '../models/animal.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../services/connectivity_service.dart';

enum CollectionFilter { all, caught, uncaught, byRarity }

class CollectionProvider extends ChangeNotifier {
  final ApiService _api;
  final LocalDbService _localDb;
  final ConnectivityService _connectivity;

  List<Animal> _allAnimals = [];
  List<Animal> _filteredAnimals = [];
  CollectionFilter _activeFilter = CollectionFilter.all;
  String _searchQuery = '';
  String? _selectedRarity;
  bool _isLoading = false;
  String? _errorMessage;
  Animal? _selectedAnimal;

  CollectionProvider(this._api, this._localDb, this._connectivity);

  List<Animal> get animals => _filteredAnimals;
  List<Animal> get allAnimals => _allAnimals;
  CollectionFilter get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  String? get selectedRarity => _selectedRarity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Animal? get selectedAnimal => _selectedAnimal;

  int get caughtCount => _allAnimals.where((a) => a.isCaught).length;
  int get totalCount => _allAnimals.length;

  Future<void> loadCollection() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_connectivity.isOnline) {
        final response = await _api.getAnimals(limit: 100);
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          final list = (data['animals'] as List?) ?? [];
          _allAnimals = list
              .map((a) => Animal.fromJson(a as Map<String, dynamic>))
              .toList();
          await _localDb.cacheAnimals(_allAnimals);
        }
      } else {
        _allAnimals = await _localDb.getCachedAnimals();
        if (_allAnimals.isEmpty) {
          _allAnimals = Animal.mockAnimals();
        }
      }
    } catch (_) {
      _allAnimals = await _localDb.getCachedAnimals();
      if (_allAnimals.isEmpty) {
        _allAnimals = Animal.mockAnimals();
      }
    } finally {
      _isLoading = false;
      _applyFilters();
    }
  }

  Future<void> searchAnimals(String query) async {
    _searchQuery = query;
    if (query.length >= 2 && _connectivity.isOnline) {
      try {
        final response = await _api.searchAnimals(query);
        if (response['success'] == true && response['data'] != null) {
          final list = (response['data'] as List?) ?? [];
          _filteredAnimals = list
              .map((a) => Animal.fromJson(a as Map<String, dynamic>))
              .toList();
          notifyListeners();
          return;
        }
      } catch (_) {}
    }
    _applyFilters();
  }

  void setFilter(CollectionFilter filter) {
    _activeFilter = filter;
    _applyFilters();
  }

  void setRarityFilter(String? rarity) {
    _selectedRarity = rarity;
    _applyFilters();
  }

  void selectAnimal(Animal animal) {
    _selectedAnimal = animal;
    notifyListeners();
  }

  Future<Animal?> getAnimalById(String id) async {
    try {
      final local = _allAnimals.where((a) => a.id == id).firstOrNull;
      if (local != null) return local;

      if (_connectivity.isOnline) {
        final response = await _api.getAnimalById(id);
        if (response['success'] == true && response['data'] != null) {
          return Animal.fromJson(response['data'] as Map<String, dynamic>);
        }
      }
      return await _localDb.getCachedAnimalById(id);
    } catch (_) {
      return null;
    }
  }

  void _applyFilters() {
    var filtered = List<Animal>.from(_allAnimals);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((a) =>
              a.commonName.toLowerCase().contains(q) ||
              a.scientificName.toLowerCase().contains(q) ||
              a.category.toLowerCase().contains(q))
          .toList();
    }

    switch (_activeFilter) {
      case CollectionFilter.caught:
        filtered = filtered.where((a) => a.isCaught).toList();
        break;
      case CollectionFilter.uncaught:
        filtered = filtered.where((a) => !a.isCaught).toList();
        break;
      case CollectionFilter.byRarity:
        if (_selectedRarity != null) {
          filtered = filtered
              .where((a) => a.rarity.toLowerCase() == _selectedRarity!.toLowerCase())
              .toList();
        }
        filtered.sort((a, b) => _rarityOrder(a.rarity) - _rarityOrder(b.rarity));
        break;
      case CollectionFilter.all:
        break;
    }

    _filteredAnimals = filtered;
    notifyListeners();
  }

  int _rarityOrder(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return 0;
      case 'epic':
        return 1;
      case 'rare':
        return 2;
      case 'uncommon':
        return 3;
      default:
        return 4;
    }
  }
}
