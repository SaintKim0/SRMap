import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../../data/models/location.dart';
import '../../data/models/kmdb_work_info.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/services/kmdb_api_service.dart';
import '../../core/utils/error_handler.dart';

class LocationDataProvider with ChangeNotifier {
  final LocationRepository _repository = LocationRepository();

  List<String> _contentTitles = [];
  String? _selectedGenre;
  List<Location> _popularLocations = [];
  List<Location> _recentLocations = [];
  List<Location> _allLocations = [];
  List<Location> _sectorLocations = [];
  bool _isLoading = false;
  String? _error;
  Location? _focusedLocation;
  bool _requestMoveToMyLocation = false;
  /// 알림에서 "보기" 탭 시 지도에 같이 보여줄 맛집 목록 (내 위치 + 이 목록으로 bounds 맞춤)
  List<Location>? _nearbyNotificationLocations;

  // Sector filtering
  String? _selectedSector;
  String? _selectedSubSector;
  bool _showNearbyOnly = false; // 내 주변 5km 필터 활성화 여부
  double _radiusKm = 5.0; // 기본 반경 5km

  // 촬영현장: 작품(콘텐츠) 탭 시 해당 작품의 촬영지 리스트
  String? _expandedContentTitle;
  List<Location> _locationsForExpandedWork = [];
  Map<String, int> _contentTitleCounts = {};
  Map<String, int?> _contentTitleYears = {};
  KmdbWorkInfo? _kmdbInfoForExpandedWork;
  bool _kmdbInfoLoading = false;

  List<String> get contentTitles => _contentTitles;
  String? get expandedContentTitle => _expandedContentTitle;
  List<Location> get locationsForExpandedWork => _locationsForExpandedWork;
  Map<String, int> get contentTitleCounts => _contentTitleCounts;
  Map<String, int?> get contentTitleYears => _contentTitleYears;
  KmdbWorkInfo? get kmdbInfoForExpandedWork => _kmdbInfoForExpandedWork;
  bool get kmdbInfoLoading => _kmdbInfoLoading;
  String? get selectedGenre => _selectedGenre;
  List<Location> get popularLocations => _popularLocations;
  List<Location> get recentLocations => _recentLocations;
  List<Location> get allLocations => _allLocations;
  List<Location> get sectorLocations => _sectorLocations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Location? get focusedLocation => _focusedLocation;
  bool get requestMoveToMyLocation => _requestMoveToMyLocation;
  List<Location>? get nearbyNotificationLocations => _nearbyNotificationLocations;
  String? get selectedSector => _selectedSector;
  String? get selectedSubSector => _selectedSubSector;
  bool get showNearbyOnly => _showNearbyOnly;
  double get radiusKm => _radiusKm;

  // Initialize data
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.initializeData();
      
      // Load initial data
      await Future.wait([
        loadContentTitles(),
        loadPopularLocations(),
        loadRecentLocations(),
      ]);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Initialization error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load content titles
  Future<void> loadContentTitles({String? mediaType}) async {
    try {
      _contentTitles = await _repository.getUniqueContentTitles(mediaType: mediaType);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load content titles: $e');
    }
  }

  // Get content titles grouped by sector (for sector cards) — 맛집지도: 흑백요리사, 미슐렝, 예능만
  Future<Map<String, List<String>>> getContentTitlesBySector() async {
    try {
      final result = <String, List<String>>{};
      result['blackwhite'] = await _repository.getUniqueContentTitles(mediaType: 'blackwhite');
      result['guide'] = await _repository.getUniqueContentTitles(mediaType: 'guide');
      result['show'] = await _repository.getUniqueContentTitles(mediaType: 'show');
      return result;
    } catch (e) {
      debugPrint('Failed to load content titles by sector: $e');
      return {
        'blackwhite': [],
        'guide': [],
        'show': [],
      };
    }
  }

  // Filter content titles by genre
  Future<void> filterContentTitles(String? mediaType) async {
    _selectedGenre = mediaType;
    await loadContentTitles(mediaType: mediaType);
  }

  // Load popular locations
  Future<void> loadPopularLocations() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _popularLocations = await _repository.getPopular(
        limit: 10,
        allowedMediaTypes: LocationRepository.tasteMapMediaTypes,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _error = ErrorHandler.handleError(e, stackTrace);
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load recent locations
  Future<void> loadRecentLocations() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _recentLocations = await _repository.getRecent(
        limit: 10,
        allowedMediaTypes: LocationRepository.tasteMapMediaTypes,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _error = ErrorHandler.handleError(e, stackTrace);
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all locations
  Future<void> loadAllLocations() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _allLocations = await _repository.getAll();
      notifyListeners();

      /*
      // Enrichment DISABLED by user request
      _enrichImages(_allLocations, (updated) {
        _allLocations = updated;
        notifyListeners();
      });
      */
      
      _isLoading = false;
    } catch (e, stackTrace) {
      _error = ErrorHandler.handleError(e, stackTrace);
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get location by ID
  Future<Location?> getLocationById(String id) async {
    try {
      return await _repository.getById(id);
    } catch (e, stackTrace) {
      _error = ErrorHandler.handleError(e, stackTrace);
      notifyListeners();
      return null;
    }
  }

  // Search locations
  Future<List<Location>> searchLocations(String query, {String? category}) async {
    try {
      if (query.trim().isEmpty) {
        // Return all locations to allow client-side filtering (e.g. by sector or distance)
        return await _repository.getAll();
      }
      return await _repository.search(query, category: category);
    } catch (e, stackTrace) {
      _error = ErrorHandler.handleError(e, stackTrace);
      notifyListeners();
      return [];
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String id) async {
    try {
      await _repository.incrementViewCount(id);
    } catch (e) {
      debugPrint('Failed to increment view count: $e');
    }
  }

  Future<void> _enrichImages(
      List<Location> locations, Function(List<Location>) onUpdate) async {
    // Check if any location actually needs update to avoid unnecessary processing
    final needsUpdate = locations.any((l) => 
      l.imageUrls.isEmpty || l.imageUrls.first.contains('picsum.photos') || l.imageUrls.first.startsWith('assets/'));
      
    if (!needsUpdate) return;

    final updated = await _repository.enrichLocationImages(locations);
    onUpdate(updated);
  }

  // Set focused location for map
  void setFocusedLocation(Location? location) {
    _focusedLocation = location;
    notifyListeners();
  }

  /// 홈에서 "내 주변 맛집 보기" 탭 시 지도가 현재 위치로 이동하도록 요청
  void requestMoveToMyLocationOnce() {
    _requestMoveToMyLocation = true;
    notifyListeners();
  }

  void clearMoveToMyLocationRequest() {
    _requestMoveToMyLocation = false;
    notifyListeners();
  }

  void setNearbyNotificationLocations(List<Location>? locations) {
    _nearbyNotificationLocations = locations;
    notifyListeners();
  }

  void clearNearbyNotificationLocations() {
    _nearbyNotificationLocations = null;
    notifyListeners();
  }

  /// Toggle "내 주변 5km" / "전체 보기" filter
  void toggleNearbyFilter() {
    _showNearbyOnly = !_showNearbyOnly;
    notifyListeners();
    // Reload sector locations with new filter
    if (_selectedSector != null) {
      loadLocationsBySector(_selectedSector!, _selectedSubSector);
    }
  }

  /// Set radius for nearby filter (예능 촬영 맛집 드롭다운)
  void setRadiusKm(double radius) {
    _radiusKm = radius;
    notifyListeners();
    if (_showNearbyOnly && _selectedSector != null) {
      loadLocationsBySector(_selectedSector!, _selectedSubSector);
    }
  }

  /// 미슐렝 등급별 서브 옵션 (기본: 미슐렝 = 셀렉티드)
  static const List<String> michelinSubOptions = ['3 Star', '2 Star', '1 Star', '빕구르망', '미슐렝'];

  /// 흑백요리사 시즌별 서브 옵션 (시즌1, 시즌2, 시즌3)
  static const List<String> blackwhiteSubOptions = ['시즌1', '시즌2', '시즌3'];

  /// UI 등급 라벨 → CSV/description tier 값 (3star, 2star, 1star, bib, michelin)
  static String _michelinSubToTierValue(String subSector) {
    switch (subSector) {
      case '미슐렝': return 'michelin';
      case '빕구르망': return 'bib';
      case '예능 촬영 맛집':
        return 'show';
      case '1 Star': return '1star';
      case '2 Star': return '2star';
      case '3 Star': return '3star';
      default: return subSector.toLowerCase().replaceAll(' ', '');
    }
  }

  // Sector filtering methods — 맛집지도: 흑백요리사, 미슐렝 코리아, 예능 촬영 맛집
  void setSector(String? sector) {
    _selectedSector = sector;
    if (sector == '미슐렝 코리아') {
      _selectedSubSector = '미슐렝'; // 기본: 미슐렝 레스토랑 전체
    } else if (sector == '흑백요리사') {
      _selectedSubSector = '시즌1'; // 기본: 시즌1
    } else if (sector == '예능 촬영 맛집') {
      _selectedSubSector = null;
    } else {
      _selectedSubSector = null;
    }
    notifyListeners();
    if (sector != null) {
      loadLocationsBySector(sector, _selectedSubSector);
    }
  }

  void setSubSector(String? subSector) {
    _selectedSubSector = subSector;
    _expandedContentTitle = null;
    _locationsForExpandedWork = [];
    if (subSector == null) {
      _contentTitleCounts = {};
      _contentTitleYears = {};
    }
    notifyListeners();
    if (_selectedSector != null) {
      loadLocationsBySector(_selectedSector!, subSector);
    }
  }

  Future<void> loadLocationsBySector(String sector, String? subSector) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      List<Location> allLocs = await _repository.getAll();

      // 맛집지도: 흑백요리사, 미슐렝 코리아, 예능 촬영 맛집만
      if (sector == '흑백요리사') {
        _contentTitles = await _repository.getUniqueContentTitles(mediaType: 'blackwhite');
        _contentTitleCounts = await _repository.getContentTitlesWithCount(mediaType: 'blackwhite');
        _contentTitleYears = await _repository.getContentTitleReleaseYears(mediaType: 'blackwhite');
        var blackwhiteLocs = allLocs.where((loc) => loc.mediaType?.toLowerCase() == 'blackwhite').toList();
        // 시즌 버튼에 따라 필터 (시즌1/시즌2=contentTitle 기준, 시즌3=데이터 없음)
        if (subSector == '시즌1') {
          blackwhiteLocs = blackwhiteLocs.where((loc) => (loc.contentTitle ?? '').contains('시즌1')).toList();
        } else if (subSector == '시즌2') {
          blackwhiteLocs = blackwhiteLocs.where((loc) => (loc.contentTitle ?? '').contains('시즌2')).toList();
        } else if (subSector == '시즌3') {
          blackwhiteLocs = []; // 업데이트 예정
        }
        _sectorLocations = blackwhiteLocs;
      } else if (sector == '미슐렝 코리아') {
        _contentTitles = await _repository.getUniqueContentTitles(mediaType: 'guide');
        _contentTitleCounts = await _repository.getContentTitlesWithCount(mediaType: 'guide');
        _contentTitleYears = await _repository.getContentTitleReleaseYears(mediaType: 'guide');
        var guideLocs = allLocs.where((loc) => loc.mediaType?.toLowerCase() == 'guide').toList();
        // 등급 버튼에 따라 해당 tier만 표시 (기본: 미슐렝 = michelin). UI 라벨 → CSV tier 값 매핑
        if (subSector != null && subSector.isNotEmpty) {
          final tierValue = _michelinSubToTierValue(subSector);
          guideLocs = guideLocs.where((loc) => (loc.michelinTier ?? '').trim().toLowerCase() == tierValue).toList();
        }
        _sectorLocations = guideLocs;
      } else if (sector == '예능 촬영 맛집') {
        _contentTitles = await _repository.getUniqueContentTitles(mediaType: 'show');
        _contentTitleCounts = await _repository.getContentTitlesWithCount(mediaType: 'show');
        _contentTitleYears = await _repository.getContentTitleReleaseYears(mediaType: 'show');
        _sectorLocations = allLocs.where((loc) => loc.mediaType?.toLowerCase() == 'show').toList();
      } else {
        _sectorLocations = [];
      }

      // Apply radius filter if "내 주변 5km" is enabled
      if (_showNearbyOnly && _sectorLocations.isNotEmpty) {
        // Need to import LocationProvider to get current position
        // This will be handled in the UI layer by passing current position
        // For now, we'll add a method to filter by distance
      }

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _error = ErrorHandler.handleError(e, stackTrace);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate distance between two points in km (public helper)
  double calculateDistanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  void applyRadiusFilter(double userLat, double userLng) {
    if (!_showNearbyOnly) return;
    
    _sectorLocations = _sectorLocations.where((loc) {
      final distance = calculateDistanceBetween(userLat, userLng, loc.latitude, loc.longitude);
      return distance <= _radiusKm;
    }).toList();
    notifyListeners();
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  void clearSectorFilter() {
    _selectedSector = null;
    _selectedSubSector = null;
    _sectorLocations = [];
    _expandedContentTitle = null;
    _locationsForExpandedWork = [];
    _contentTitleCounts = {};
    _contentTitleYears = {};
    notifyListeners();
  }

  /// 촬영현장: 작품 탭 시 해당 작품의 촬영지 + KMDb 작품 정보 로드. null이면 접기.
  Future<void> expandWorkContentTitle(String? contentTitle) async {
    if (contentTitle == null) {
      _expandedContentTitle = null;
      _locationsForExpandedWork = [];
      _kmdbInfoForExpandedWork = null;
      notifyListeners();
      return;
    }
    if (_expandedContentTitle == contentTitle) {
      _expandedContentTitle = null;
      _locationsForExpandedWork = [];
      _kmdbInfoForExpandedWork = null;
      notifyListeners();
      return;
    }
    try {
      _expandedContentTitle = contentTitle;
      _kmdbInfoForExpandedWork = null;
      _kmdbInfoLoading = true;
      notifyListeners();

      _locationsForExpandedWork = await _repository.getByContentTitle(contentTitle);
      notifyListeners(); // 촬영지 목록 먼저 표시

      final kmdb = await KmdbApiService.instance.fetchMovieByTitle(contentTitle);
      _kmdbInfoForExpandedWork = kmdb;
      _kmdbInfoLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load locations for work $contentTitle: $e');
      _locationsForExpandedWork = [];
      _kmdbInfoForExpandedWork = null;
      _kmdbInfoLoading = false;
      notifyListeners();
    }
  }
}

