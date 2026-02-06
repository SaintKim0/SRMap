import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location.dart';
import '../services/database_helper.dart';
import '../services/csv_data_service.dart';
import '../services/public_data_service.dart';
import '../services/image_service.dart';

class LocationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Initialize data from CSV and API
  Future<void> initializeData() async {
    final db = await _dbHelper.database;
    // final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM locations'));
    
    // Check if we need to sync CSV (first run or force reset)
    // CHANGED: Set to true to allow metadata updates from CSV, but we use a non-destructive merge now.
    bool needsSync = true; 
    
    // Check if database is empty - if so, we definitely MUST sync
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM locations')) ?? 0;
    if (count == 0) {
      needsSync = true;
    }
    
    print('Checking for CSV data updates... Sync enabled: $needsSync');
    
    if (needsSync) {
      print('Loading locations from CSV...');
      final csvLocations = await CsvDataService.instance.loadLocations();
      print('Loaded ${csvLocations.length} locations from CSV.');
      
      // Get existing location IDs to decide between INSERT and UPDATE
      final List<Map<String, dynamic>> existingData = await db.query(
        'locations', 
        columns: ['id', 'view_count', 'bookmark_count', 'created_at']
      );
      final Map<String, Map<String, dynamic>> existingMap = {
        for (var row in existingData) row['id'] as String: row
      };

      print('Safe Syncing ${csvLocations.length} locations from CSV to DB (merging interaction counts)...');
      final batch = db.batch();
      
      for (final loc in csvLocations) {
        if (existingMap.containsKey(loc.id)) {
          // UPDATE: Metadata only, preserve user interaction stats
          final map = _toMap(loc);
          
          // These columns are managed by the app, don't overwrite with CSV defaults (0)
          map.remove('view_count');
          map.remove('bookmark_count');
          map.remove('created_at'); // Preserve original creation date if exists
          
          batch.update(
            'locations', 
            map, 
            where: 'id = ?', 
            whereArgs: [loc.id]
          );
        } else {
          // INSERT: New location
          batch.insert('locations', _toMap(loc));
        }
      }
      
      await batch.commit(noResult: true, continueOnError: true);
      print('CSV Safe Sync complete.');
    }

    // Force-inject "K-Pop Demon Hunters" data just in case CSV sync failed or assets are old
    // Post-processing will fix categorization if needed, but we insert correctly here.
    await _forceInjectDemonHunters(db);

    // Always try to fetch fresh data from API
    // We do this in background usually, but here await it for simplicity or fire and forget.
    try {
      print('Fetching data from Public API...');
      final apiLocations = await PublicDataService.instance.fetchLocations();
      if (apiLocations.isNotEmpty) {
        print('Fetched ${apiLocations.length} locations from API');
        final batchApi = db.batch();
        for (final loc in apiLocations) {
          batchApi.insert(
            'locations',
            _toMap(loc),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batchApi.commit(noResult: true, continueOnError: true);
      }
    } catch (e) {
      print('API Fetch Error: $e');
    }

    // NEW: Post-processing refinement to ensure all K-POP related titles are correctly categorized,
    // even those fetched from API with generic 'drama' or 'etc' tags.
    await _refineCategorization(db);
  }

  Future<void> _refineCategorization(Database db) async {
    print('Refining K-POP categorization for all locations...');
    final List<String> kpopKeywords = [
      '방탄소년단', 'bts', '블랙핑크', 'blackpink', '슈퍼주니어', '슈퍼쥬니어', 'super junior',
      '세븐틴', 'seventeen', '트와이스', 'twice', '동방신기', 'tvxq', 'btob', '비투비',
      '소녀시대', 'girls generation', '엑소', 'exo', 'nct', '레드벨벳', 'red velvet',
      '에이핑크', 'apink', '오마이걸', 'oh my girl', '인피니트', 'infinite', '샤이니', 'shinee',
      '마마무', 'mamamoo', '아이유', 'iu', 'txt', 'tomorrow x together', '아이브', 'ive',
      '뉴진스', 'newjeans', '에스파', 'aespa', '데몬 헌터스', 'k-pop', 'kpop'
    ];

    final batch = db.batch();
    for (final keyword in kpopKeywords) {
      // Changed target media_type from 'kpop' to 'artist' to match Provider
      batch.rawUpdate('''
        UPDATE locations 
        SET media_type = 'artist' 
        WHERE (content_title LIKE ? OR name LIKE ? OR description LIKE ?) 
        AND media_type != 'artist'
      ''', ['%$keyword%', '%$keyword%', '%$keyword%']);
    }
    await batch.commit(noResult: true, continueOnError: true);
    print('Refinement complete.');
  }

  Future<void> _forceInjectDemonHunters(Database db) async {
    print('Force-injecting K-Pop Demon Hunters data...');
    // Using 'artist' instead of 'kpop'
    final List<Map<String, dynamic>> demonHuntersData = [
      {
        'id': 'csv_901', 'media_type': 'artist', 'content_title': 'K-Pop: 데몬 헌터스', 'name': '코엑스 K-POP 광장', 'category': 'building', 'description': '[artist] K-Pop: 데몬 헌터스\n영화 오프닝 명소', 'opening_hours': '24시간', 'address': '서울특별시 강남구 영동대로 513', 'latitude': 37.5072, 'longitude': 127.0553, 'phone_number': '02-6000-0114', 'created_at': DateTime.now().toIso8601String(), 'image_urls': '[]', 'view_count': 0, 'bookmark_count': 0
      },
      {
        'id': 'csv_902', 'media_type': 'artist', 'content_title': 'K-Pop: 데몬 헌터스', 'name': '명동 거리', 'category': 'street', 'description': '[artist] K-Pop: 데몬 헌터스\n사자 보이즈 배경', 'opening_hours': '명동 상점가 운영시간', 'address': '서울특별시 중구 명동길', 'latitude': 37.5640, 'longitude': 126.9850, 'phone_number': '', 'created_at': DateTime.now().toIso8601String(), 'image_urls': '[]', 'view_count': 0, 'bookmark_count': 0
      },
      {
        'id': 'csv_903', 'media_type': 'artist', 'content_title': 'K-Pop: 데몬 헌터스', 'name': '남산공원 (N서울타워)', 'category': 'park', 'description': '[artist] K-Pop: 데몬 헌터스\n주요 전투 배경', 'opening_hours': '10:00 - 23:00', 'address': '서울특별시 용산구 남산공원길 105', 'latitude': 37.5512, 'longitude': 126.9882, 'phone_number': '02-3455-9277', 'created_at': DateTime.now().toIso8601String(), 'image_urls': '[]', 'view_count': 0, 'bookmark_count': 0
      },
      {
        'id': 'csv_904', 'media_type': 'artist', 'content_title': 'K-Pop: 데몬 헌터스', 'name': '낙산공원', 'category': 'park', 'description': '[artist] K-Pop: 데몬 헌터스\n성곽길 감성 명소', 'opening_hours': '24시간', 'address': '서울특별시 종로구 낙산길 41', 'latitude': 37.5807, 'longitude': 127.0083, 'phone_number': '02-743-7985', 'created_at': DateTime.now().toIso8601String(), 'image_urls': '[]', 'view_count': 0, 'bookmark_count': 0
      },
      {
        'id': 'csv_905', 'media_type': 'artist', 'content_title': 'K-Pop: 데몬 헌터스', 'name': '자양역 (청담대교)', 'category': 'street', 'description': '[artist] K-Pop: 데몬 헌터스\n지하철 열차 전투', 'opening_hours': '24시간', 'address': '서울특별시 광진구 자양동 227', 'latitude': 37.5261, 'longitude': 127.0642, 'phone_number': '', 'created_at': DateTime.now().toIso8601String(), 'image_urls': '[]', 'view_count': 0, 'bookmark_count': 0
      },
      {
        'id': 'csv_906', 'media_type': 'artist', 'content_title': 'K-Pop: 데몬 헌터스', 'name': '서울 올림픽 주경기장', 'category': 'building', 'description': '[artist] K-Pop: 데몬 헌터스\n공연 및 시상식 무대', 'opening_hours': '상이함', 'address': '서울특별시 송파구 올림픽로 25', 'latitude': 37.5139, 'longitude': 127.0736, 'phone_number': '02-2240-8800', 'created_at': DateTime.now().toIso8601String(), 'image_urls': '[]', 'view_count': 0, 'bookmark_count': 0
      },
      {
        'id': 'csv_907', 'media_type': 'artist', 'content_title': 'K-Pop: 데몬 헌터스', 'name': '북촌 한옥마을', 'category': 'street', 'description': '[artist] K-Pop: 데몬 헌터스\n전통 가옥 대화 장면', 'opening_hours': '09:00 - 18:00', 'address': '서울특별시 종로구 계동길 37', 'latitude': 37.5826, 'longitude': 126.9835, 'phone_number': '02-2133-1372', 'created_at': DateTime.now().toIso8601String(), 'image_urls': '[]', 'view_count': 0, 'bookmark_count': 0
      },
      {
        'id': 'csv_908', 'media_type': 'artist', 'content_title': 'K-Pop: 데몬 헌터스', 'name': '롯데월드타워', 'category': 'building', 'description': '[artist] K-Pop: 데몬 헌터스\n본부 건물 영감', 'opening_hours': '10:30 - 22:00', 'address': '서울특별시 송파구 올림픽로 300', 'latitude': 37.5126, 'longitude': 127.1025, 'phone_number': '1661-2000', 'created_at': DateTime.now().toIso8601String(), 'image_urls': '[]', 'view_count': 0, 'bookmark_count': 0
      },
    ];

    final batch = db.batch();
    for (final data in demonHuntersData) {
      batch.insert('locations', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true, continueOnError: true);
    print('Force-injection complete.');
  }

  // Create
  Future<int> create(Location location) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'locations',
      _toMap(location),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read all
  Future<List<Location>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('locations', orderBy: 'created_at DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Read by ID
  Future<Location?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Read by category
  Future<List<Location>> getByCategory(String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'locations',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  /// 맛집지도 앱: 홈 최근/인기에는 blackwhite, guide, show만 표시
  static const List<String> tasteMapMediaTypes = ['blackwhite', 'guide', 'show'];

  // Get popular locations (by view count + bookmark count)
  Future<List<Location>> getPopular({int limit = 10, List<String>? allowedMediaTypes}) async {
    final db = await _dbHelper.database;
    final where = allowedMediaTypes != null && allowedMediaTypes.isNotEmpty
        ? "media_type IN (${List.filled(allowedMediaTypes.length, '?').join(',')})"
        : null;
    final whereArgs = allowedMediaTypes;
    final maps = await db.query(
      'locations',
      where: where,
      whereArgs: whereArgs,
      orderBy: '(view_count + bookmark_count * 2) DESC',
      limit: limit,
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Get recent locations
  Future<List<Location>> getRecent({int limit = 10, List<String>? allowedMediaTypes}) async {
    final db = await _dbHelper.database;
    final where = allowedMediaTypes != null && allowedMediaTypes.isNotEmpty
        ? "media_type IN (${List.filled(allowedMediaTypes.length, '?').join(',')})"
        : null;
    final whereArgs = allowedMediaTypes;
    final maps = await db.query(
      'locations',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Read by media type
  Future<List<Location>> getByMediaType(String mediaType) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'locations',
      where: 'media_type = ?',
      whereArgs: [mediaType],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Read by content title
  Future<List<Location>> getByContentTitle(String contentTitle) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'locations',
      where: 'content_title = ?',
      whereArgs: [contentTitle],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Get unique content titles for UI
  Future<List<String>> getUniqueContentTitles({String? mediaType}) async {
    final db = await _dbHelper.database;
    
    String whereClause = "content_title IS NOT NULL AND content_title != ''";
    List<dynamic> args = [];

    if (mediaType != null) {
      whereClause += " AND media_type = ?";
      args.add(mediaType);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT content_title, COUNT(*) as count 
      FROM locations 
      WHERE $whereClause
      GROUP BY content_title 
      ORDER BY (CASE WHEN content_title = 'K-Pop: 데몬 헌터스' THEN 0 ELSE 1 END), count DESC
    ''', args);
    
    return maps.map((e) => e['content_title'] as String).toList();
  }

  /// 작품(콘텐츠)별 촬영지 개수. mediaType 지정 시 해당 분야만.
  Future<Map<String, int>> getContentTitlesWithCount({String? mediaType}) async {
    final db = await _dbHelper.database;
    String whereClause = "content_title IS NOT NULL AND content_title != ''";
    List<dynamic> args = [];
    if (mediaType != null) {
      whereClause += " AND media_type = ?";
      args.add(mediaType);
    }
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT content_title, COUNT(*) as count 
      FROM locations 
      WHERE $whereClause
      GROUP BY content_title 
      ORDER BY (CASE WHEN content_title = 'K-Pop: 데몬 헌터스' THEN 0 ELSE 1 END), count DESC
    ''', args);
    return Map.fromEntries(
      maps.map((e) => MapEntry(e['content_title'] as String, (e['count'] as num).toInt())),
    );
  }

  /// 작품(콘텐츠)별 제작·공개 연도. mediaType 지정 시 해당 분야만. (content_release_year 컬럼 값)
  Future<Map<String, int?>> getContentTitleReleaseYears({String? mediaType}) async {
    final db = await _dbHelper.database;
    String whereClause = "content_title IS NOT NULL AND content_title != ''";
    List<dynamic> args = [];
    if (mediaType != null) {
      whereClause += " AND media_type = ?";
      args.add(mediaType);
    }
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT content_title, MIN(content_release_year) as release_year 
      FROM locations 
      WHERE $whereClause
      GROUP BY content_title 
      ORDER BY (CASE WHEN content_title = 'K-Pop: 데몬 헌터스' THEN 0 ELSE 1 END), content_title
    ''', args);
    return Map.fromEntries(
      maps.map((e) => MapEntry(
        e['content_title'] as String,
        (e['release_year'] as num?)?.toInt(),
      )),
    );
  }

  // Search by name, address, or content title with optional filters
  Future<List<Location>> search(String query, {
    String? category, 
    String? mediaType,
    String? contentTitle,
  }) async {
    final db = await _dbHelper.database;
    
    String sql = '''
      SELECT DISTINCT l.* FROM locations l
      LEFT JOIN scenes s ON l.id = s.location_id
      LEFT JOIN contents c ON s.content_id = c.id
      WHERE (l.name LIKE ? 
         OR l.address LIKE ? 
         OR c.title LIKE ?
         OR l.content_title LIKE ?)
    ''';
    
    List<dynamic> args = ['%$query%', '%$query%', '%$query%', '%$query%'];

    if (category != null && category.isNotEmpty) {
      sql += ' AND l.category = ?';
      args.add(category);
    }
    
    if (mediaType != null && mediaType.isNotEmpty) {
      sql += ' AND l.media_type = ?';
      args.add(mediaType);
    }

    if (contentTitle != null && contentTitle.isNotEmpty) {
      sql += ' AND l.content_title = ?';
      args.add(contentTitle);
    }

    sql += ' ORDER BY l.view_count DESC';

    final maps = await db.rawQuery(sql, args);
    
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Update
  Future<int> update(Location location) async {
    final db = await _dbHelper.database;
    return await db.update(
      'locations',
      _toMap(location),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  // Increment view count
  Future<void> incrementViewCount(String id) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE locations SET view_count = view_count + 1 WHERE id = ?',
      [id],
    );
  }

  // Increment bookmark count
  Future<void> incrementBookmarkCount(String id) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE locations SET bookmark_count = bookmark_count + 1 WHERE id = ?',
      [id],
    );
  }

  // Decrement bookmark count
  Future<void> decrementBookmarkCount(String id) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE locations SET bookmark_count = bookmark_count - 1 WHERE id = ?',
      [id],
    );
  }

  // Delete
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Enrich locations with real images (서버 > TourAPI > Wikimedia Commons > Unsplash > Pexels)
  Future<List<Location>> enrichLocationImages(List<Location> locations) async {
    final List<Location> updatedLocations = [];
    // bool hasUpdates = false;

    for (var location in locations) {
      // Check if image is placeholder/empty or assets
      bool needsUpdate = false;
      if (location.imageUrls.isEmpty ||
          location.imageUrls.first.contains('picsum.photos') ||
          location.imageUrls.first.startsWith('assets/')) {
        needsUpdate = true;
      }

      if (needsUpdate) {
        try {
          final List<String> newUrls = await ImageService.instance.fetchImagesForLocation(
            location.name,
            location.contentTitle ?? '',
            category: location.category,
            locationId: location.id,
          );

          if (newUrls.isNotEmpty) {
            final updatedLocation = location.copyWith(
              imageUrls: newUrls,
              updatedAt: DateTime.now(),
            );

            await update(updatedLocation);
            updatedLocations.add(updatedLocation);
            // hasUpdates = true;
          }
        } catch (e) {
          print('Error enriching image: $e');
        }
        
        // Rate limiting precaution
        // await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }
      updatedLocations.add(location);
    }
    
    return updatedLocations;
  }

  // Helper methods
  Map<String, dynamic> _toMap(Location location) {
    return {
      'id': location.id,
      'name': location.name,
      'address': location.address,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'category': location.category,
      'media_type': location.mediaType,
      'content_title': location.contentTitle,
      'content_release_year': location.contentReleaseYear,
      'michelin_tier': location.michelinTier,
      'phone_number': location.phoneNumber,
      'website': location.website,
      'opening_hours': location.openingHours,
      'image_urls': jsonEncode(location.imageUrls),
      'parking': location.parking,
      'transportation': location.transportation,
      'view_count': location.viewCount,
      'bookmark_count': location.bookmarkCount,
      'description': location.description,
      'created_at': location.createdAt.toIso8601String(),
      'updated_at': location.updatedAt?.toIso8601String(),
    };
  }

  Location _fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      category: map['category'] as String,
      mediaType: map['media_type'] as String?,
      contentTitle: map['content_title'] as String?,
      contentReleaseYear: (map['content_release_year'] as num?)?.toInt(),
      michelinTier: map['michelin_tier'] as String?,
      phoneNumber: map['phone_number'] as String?,
      website: map['website'] as String?,
      openingHours: map['opening_hours'] as String?,
      imageUrls: List<String>.from(jsonDecode(map['image_urls'] as String)),
      parking: map['parking'] as String?,
      transportation: map['transportation'] as String?,
      viewCount: map['view_count'] as int,
      bookmarkCount: map['bookmark_count'] as int,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
