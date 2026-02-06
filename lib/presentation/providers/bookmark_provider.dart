import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/location.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/services/preferences_service.dart';

class BookmarkProvider with ChangeNotifier {
  final LocationRepository _locationRepository = LocationRepository();
  final PreferencesService _prefs = PreferencesService.instance;

  List<String> _bookmarkedLocationIds = [];
  List<Location> _bookmarkedLocations = [];
  bool _isLoading = false;
  String? _error;

  List<String> get bookmarkedLocationIds => _bookmarkedLocationIds;
  List<Location> get bookmarkedLocations => _bookmarkedLocations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if location is bookmarked
  bool isBookmarked(String locationId) {
    return _bookmarkedLocationIds.contains(locationId);
  }

  // Load user's bookmarks
  Future<void> loadBookmarks() async {
    try {
      _isLoading = true;
      notifyListeners();

      _bookmarkedLocationIds = _prefs.getBookmarkedLocationIds();
      
      // Load actual location objects
      _bookmarkedLocations = [];
      for (final id in _bookmarkedLocationIds) {
        final location = await _locationRepository.getById(id);
        if (location != null) {
          _bookmarkedLocations.add(location);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '북마크를 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle bookmark
  Future<bool> toggleBookmark(String locationId) async {
    try {
      if (isBookmarked(locationId)) {
        // Remove bookmark
        await _prefs.removeBookmarkedLocationId(locationId);
        _bookmarkedLocationIds.remove(locationId);
        _bookmarkedLocations.removeWhere((loc) => loc.id == locationId);
        
        // Update location stats
        await _locationRepository.decrementBookmarkCount(locationId);
      } else {
        // Add bookmark
        await _prefs.addBookmarkedLocationId(locationId);
        _bookmarkedLocationIds.add(locationId);
        
        final location = await _locationRepository.getById(locationId);
        if (location != null) {
          _bookmarkedLocations.add(location);
        }
        
        // Update location stats
        await _locationRepository.incrementBookmarkCount(locationId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = '북마크 저장에 실패했습니다: $e';
      notifyListeners();
      return false;
    }
  }

  /// 찜한 장소 중 현재 위치에서 500m 이내인 곳이 있으면 그 장소명 반환. 없으면 null.
  /// 권한/위치 실패 시 null.
  static const double nearRadiusMeters = 500;

  Future<String?> checkIfNearBookmarkedLocations() async {
    if (_bookmarkedLocations.isEmpty) return null;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8), onTimeout: () => throw Exception('timeout'));
      String? nearestName;
      double nearestM = nearRadiusMeters + 1;
      for (final loc in _bookmarkedLocations) {
        final m = distanceInMeters(
          position.latitude,
          position.longitude,
          loc.latitude,
          loc.longitude,
        );
        if (m < nearestM && m <= nearRadiusMeters) {
          nearestM = m;
          nearestName = loc.name;
        }
      }
      return nearestName;
    } catch (e) {
      debugPrint('근처 찜 장소 확인 실패: $e');
      return null;
    }
  }
}
