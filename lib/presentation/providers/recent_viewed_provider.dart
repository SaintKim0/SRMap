import 'package:flutter/foundation.dart';
import '../../data/models/location.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/services/preferences_service.dart';

/// 최근 본 촬영지 로컬 저장 및 목록 관리
class RecentViewedProvider with ChangeNotifier {
  final LocationRepository _locationRepository = LocationRepository();
  final PreferencesService _prefs = PreferencesService.instance;

  List<Location> _recentLocations = [];
  bool _isLoading = false;
  String? _error;

  List<Location> get recentLocations => _recentLocations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRecentViewed() async {
    try {
      _isLoading = true;
      notifyListeners();

      final ids = _prefs.getRecentViewedLocationIds();
      _recentLocations = [];
      for (final id in ids) {
        final location = await _locationRepository.getById(id);
        if (location != null) {
          _recentLocations.add(location);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '최근 본 목록을 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecentViewed(String locationId) async {
    try {
      await _prefs.addRecentViewedLocationId(locationId);
      notifyListeners();
    } catch (e) {
      debugPrint('최근 본 기록 실패: $e');
    }
  }

  Future<void> removeRecentViewed(String locationId) async {
    try {
      await _prefs.removeRecentViewedLocationId(locationId);
      await loadRecentViewed(); // Reload list
    } catch (e) {
      debugPrint('최근 본 기록 삭제 실패: $e');
    }
  }

  Future<void> clearAllRecentViewed() async {
    try {
      await _prefs.clearRecentViewedLocationIds();
      await loadRecentViewed(); // Reload list
    } catch (e) {
      debugPrint('최근 본 목록 전체 삭제 실패: $e');
    }
  }
}
