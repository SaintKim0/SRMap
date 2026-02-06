import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/peat_profile.dart';
import '../models/food_preference.dart';

class PreferencesService {
  static final PreferencesService instance = PreferencesService._init();
  SharedPreferences? _preferences;

  PreferencesService._init();

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_preferences == null) {
      throw Exception('PreferencesService not initialized. Call init() first.');
    }
    return _preferences!;
  }

  // User ID
  static const String _keyUserId = 'user_id';
  
  String? getUserId() => prefs.getString(_keyUserId);
  
  Future<bool> setUserId(String userId) => 
      prefs.setString(_keyUserId, userId);

  // Theme
  static const String _keyTheme = 'theme';
  
  String getTheme() => prefs.getString(_keyTheme) ?? 'system';
  
  Future<bool> setTheme(String theme) => 
      prefs.setString(_keyTheme, theme);

  // Language
  static const String _keyLanguage = 'language';
  
  String getLanguage() => prefs.getString(_keyLanguage) ?? 'ko';
  
  Future<bool> setLanguage(String language) => 
      prefs.setString(_keyLanguage, language);

  // Recent searches
  static const String _keyRecentSearches = 'recent_searches';
  
  List<String> getRecentSearches() => 
      prefs.getStringList(_keyRecentSearches) ?? [];
  
  Future<bool> addRecentSearch(String query) async {
    final searches = getRecentSearches();
    searches.remove(query); // Remove if exists
    searches.insert(0, query); // Add to front
    if (searches.length > 10) {
      searches.removeLast(); // Keep only 10 items
    }
    return prefs.setStringList(_keyRecentSearches, searches);
  }
  
  Future<bool> clearRecentSearches() => 
      prefs.remove(_keyRecentSearches);

  // Bookmarks
  static const String _keyBookmarks = 'bookmarks';
  
  List<String> getBookmarkedLocationIds() => 
      prefs.getStringList(_keyBookmarks) ?? [];
  
  Future<bool> addBookmarkedLocationId(String locationId) async {
    final bookmarks = getBookmarkedLocationIds();
    if (!bookmarks.contains(locationId)) {
      bookmarks.add(locationId);
      return prefs.setStringList(_keyBookmarks, bookmarks);
    }
    return true;
  }

  Future<bool> removeBookmarkedLocationId(String locationId) async {
    final bookmarks = getBookmarkedLocationIds();
    if (bookmarks.contains(locationId)) {
      bookmarks.remove(locationId);
      return prefs.setStringList(_keyBookmarks, bookmarks);
    }
    return true;
  }

  // Visited (다녀온 곳) — id|iso8601 형식으로 날짜 포함 저장
  static const String _keyVisited = 'visited_location_ids';
  static const String _keyVisitedEntries = 'visited_entries';

  List<String> getVisitedLocationIds() {
    final entries = _getVisitedEntriesRaw();
    if (entries.isNotEmpty) {
      return entries.map((s) => s.split('|').first).toList();
    }
    return prefs.getStringList(_keyVisited) ?? [];
  }

  /// 방문 항목 (id, 방문일). 기존 키만 있으면 날짜는 오늘로 간주
  List<MapEntry<String, DateTime>> getVisitedEntries() {
    final raw = _getVisitedEntriesRaw();
    final now = DateTime.now();
    return raw.map((s) {
      final parts = s.split('|');
      final id = parts.first;
      final at = parts.length > 1
          ? DateTime.tryParse(parts[1]) ?? now
          : now;
      return MapEntry(id, at);
    }).toList();
  }

  List<String> _getVisitedEntriesRaw() {
    final entries = prefs.getStringList(_keyVisitedEntries);
    if (entries != null && entries.isNotEmpty) return entries;
    final legacy = prefs.getStringList(_keyVisited);
    if (legacy != null && legacy.isNotEmpty) {
      final migrated = legacy.map((id) => '$id|${DateTime.now().toIso8601String()}').toList();
      prefs.setStringList(_keyVisitedEntries, migrated);
      return migrated;
    }
    return [];
  }

  Future<bool> addVisitedLocationId(String locationId) async {
    final raw = _getVisitedEntriesRaw();
    final next = '$locationId|${DateTime.now().toIso8601String()}';
    raw.removeWhere((s) => s.startsWith('$locationId|'));
    raw.add(next);
    return prefs.setStringList(_keyVisitedEntries, raw);
  }

  Future<bool> removeVisitedLocationId(String locationId) async {
    final raw = _getVisitedEntriesRaw();
    final before = raw.length;
    raw.removeWhere((s) => s.startsWith('$locationId|'));
    if (raw.length == before) return true;
    return prefs.setStringList(_keyVisitedEntries, raw);
  }

  // Recent viewed (최근 본 촬영지, 최대 50개)
  static const String _keyRecentViewed = 'recent_viewed_location_ids';
  static const int _maxRecentViewed = 50;

  List<String> getRecentViewedLocationIds() =>
      prefs.getStringList(_keyRecentViewed) ?? [];

  Future<bool> addRecentViewedLocationId(String locationId) async {
    var list = getRecentViewedLocationIds();
    list.remove(locationId);
    list.insert(0, locationId);
    if (list.length > _maxRecentViewed) {
      list = list.take(_maxRecentViewed).toList();
    }
    return prefs.setStringList(_keyRecentViewed, list);
  }

  Future<bool> removeRecentViewedLocationId(String locationId) async {
    final list = getRecentViewedLocationIds();
    if (list.contains(locationId)) {
      list.remove(locationId);
      return prefs.setStringList(_keyRecentViewed, list);
    }
    return true;
  }

  Future<bool> clearRecentViewedLocationIds() =>
      prefs.remove(_keyRecentViewed);

  // 장소별 "이 장소와 맞지 않음"으로 숨긴 이미지 URL (실제 장소와 다른 이미지 제거)
  static String _rejectedKey(String locationId) => 'rejected_images_$locationId';

  List<String> getRejectedImageUrls(String locationId) =>
      prefs.getStringList(_rejectedKey(locationId)) ?? [];

  Future<bool> addRejectedImageUrl(String locationId, String imageUrl) async {
    final list = getRejectedImageUrls(locationId);
    if (list.contains(imageUrl)) return true;
    list.add(imageUrl);
    return prefs.setStringList(_rejectedKey(locationId), list);
  }

  // 근처 맛집 알림 (기본 500m, 사용자 설정 가능)
  static const String _keyNearbyNotificationEnabled = 'nearby_notification_enabled';
  static const String _keyNotificationRadiusMeters = 'notification_radius_meters';
  static const String _keyLastNearbyNotificationTime = 'last_nearby_notification_time';

  static const int defaultNotificationRadiusMeters = 500;
  static const List<int> notificationRadiusOptions = [300, 500, 1000, 2000];

  bool get nearbyNotificationEnabled => prefs.getBool(_keyNearbyNotificationEnabled) ?? true;

  Future<bool> setNearbyNotificationEnabled(bool value) =>
      prefs.setBool(_keyNearbyNotificationEnabled, value);

  int get notificationRadiusMeters =>
      prefs.getInt(_keyNotificationRadiusMeters) ?? defaultNotificationRadiusMeters;

  Future<bool> setNotificationRadiusMeters(int meters) =>
      prefs.setInt(_keyNotificationRadiusMeters, meters);

  DateTime? get lastNearbyNotificationTime {
    final s = prefs.getString(_keyLastNearbyNotificationTime);
    return s != null ? DateTime.tryParse(s) : null;
  }

  Future<bool> setLastNearbyNotificationTime(DateTime time) =>
      prefs.setString(_keyLastNearbyNotificationTime, time.toIso8601String());

  // First launch
  static const String _keyFirstLaunch = 'first_launch';

  bool isFirstLaunch() => prefs.getBool(_keyFirstLaunch) ?? true;

  Future<bool> setFirstLaunchComplete() =>
      prefs.setBool(_keyFirstLaunch, false);

  // User Profile
  static const String _keyUserProfile = 'user_profile';

  UserProfile? getUserProfile() {
    final jsonStr = prefs.getString(_keyUserProfile);
    if (jsonStr == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveUserProfile(UserProfile profile) {
    final jsonStr = jsonEncode(profile.toJson());
    return prefs.setString(_keyUserProfile, jsonStr);
  }

  // PEAT Profile
  static const String _keyPeatProfile = 'peat_profile';

  PeatProfile? getPeatProfile() {
    final jsonStr = prefs.getString(_keyPeatProfile);
    if (jsonStr == null) return null;
    try {
      return PeatProfile.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      return null;
    }
  }

  Future<bool> savePeatProfile(PeatProfile profile) {
    final jsonStr = jsonEncode(profile.toJson());
    return prefs.setString(_keyPeatProfile, jsonStr);
  }

  Future<bool> clearPeatProfile() => prefs.remove(_keyPeatProfile);

  // Food Preference
  static const String _keyFoodPreference = 'food_preference';

  FoodPreference? getFoodPreference() {
    final jsonStr = prefs.getString(_keyFoodPreference);
    if (jsonStr == null) return null;
    try {
      return FoodPreference.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveFoodPreference(FoodPreference preference) {
    final jsonStr = jsonEncode(preference.toJson());
    return prefs.setString(_keyFoodPreference, jsonStr);
  }

  // Clear all preferences
  Future<bool> clearAll() => prefs.clear();
}
