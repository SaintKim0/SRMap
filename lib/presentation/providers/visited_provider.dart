import 'package:flutter/foundation.dart';
import '../../data/models/location.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/services/preferences_service.dart';

/// 다녀온 곳(방문) 로컬 저장 및 목록 관리
class VisitedProvider with ChangeNotifier {
  final LocationRepository _locationRepository = LocationRepository();
  final PreferencesService _prefs = PreferencesService.instance;

  List<String> _visitedLocationIds = [];
  List<Location> _visitedLocations = [];
  List<MapEntry<String, DateTime>> _visitedEntries = [];
  bool _isLoading = false;
  String? _error;

  List<String> get visitedLocationIds => _visitedLocationIds;
  List<Location> get visitedLocations => _visitedLocations;
  int get visitedCount => _visitedLocationIds.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 이번 달 방문한 장소 수 (고유 장소)
  int get visitedThisMonthCount {
    final now = DateTime.now();
    final thisMonth = <String>{};
    for (final e in _visitedEntries) {
      if (e.value.year == now.year && e.value.month == now.month) {
        thisMonth.add(e.key);
      }
    }
    return thisMonth.length;
  }

  /// 달성한 뱃지 목록 (예: ["촬영지 5곳 달성", "촬영지 10곳 달성"])
  List<String> get achievedBadges {
    const milestones = [1, 5, 10, 20, 50];
    final n = visitedCount;
    return milestones.where((m) => n >= m).map((m) => '촬영지 ${m}곳 달성').toList();
  }

  bool isVisited(String locationId) {
    _ensureVisitedIdsLoaded();
    return _visitedLocationIds.contains(locationId);
  }

  void _ensureVisitedIdsLoaded() {
    if (_visitedLocationIds.isEmpty) {
      _visitedLocationIds = _prefs.getVisitedLocationIds();
      _visitedEntries = _prefs.getVisitedEntries();
    }
  }

  Future<void> loadVisited() async {
    try {
      _isLoading = true;
      notifyListeners();

      _visitedLocationIds = _prefs.getVisitedLocationIds();
      _visitedEntries = _prefs.getVisitedEntries();
      _visitedLocations = [];
      for (final id in _visitedLocationIds) {
        final location = await _locationRepository.getById(id);
        if (location != null) {
          _visitedLocations.add(location);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '방문 목록을 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleVisited(String locationId) async {
    try {
      if (isVisited(locationId)) {
        await _prefs.removeVisitedLocationId(locationId);
        _visitedLocationIds.remove(locationId);
        _visitedLocations.removeWhere((loc) => loc.id == locationId);
      } else {
        await _prefs.addVisitedLocationId(locationId);
        _visitedLocationIds.add(locationId);
        final location = await _locationRepository.getById(locationId);
        if (location != null) {
          _visitedLocations.add(location);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = '방문 기록에 실패했습니다: $e';
      notifyListeners();
      return false;
    }
  }
}
