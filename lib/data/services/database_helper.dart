import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scenemap.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE locations ADD COLUMN description TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE locations ADD COLUMN media_type TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE locations ADD COLUMN content_title TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE locations ADD COLUMN content_release_year INTEGER');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE locations ADD COLUMN michelin_tier TEXT');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const intTypeNullable = 'INTEGER';
    const realType = 'REAL NOT NULL';

    // Locations table
    await db.execute('''
      CREATE TABLE locations (
        id $idType,
        name $textType,
        address $textType,
        latitude $realType,
        longitude $realType,
        category $textType,
        media_type $textTypeNullable,
        content_title $textTypeNullable,
        content_release_year $intTypeNullable,
        michelin_tier $textTypeNullable,
        phone_number $textTypeNullable,
        website $textTypeNullable,
        opening_hours $textTypeNullable,
        image_urls $textType,
        parking $textTypeNullable,
        transportation $textTypeNullable,
        view_count $intType DEFAULT 0,
        bookmark_count $intType DEFAULT 0,
        description $textTypeNullable,
        created_at $textType,
        updated_at $textTypeNullable
      )
    ''');

    // Contents table
    await db.execute('''
      CREATE TABLE contents (
        id $idType,
        title $textType,
        type $textType CHECK(type IN ('drama', 'movie')),
        poster_url $textTypeNullable,
        release_year $intTypeNullable,
        genre $textTypeNullable,
        description $textTypeNullable,
        created_at $textType
      )
    ''');

    // Scenes table
    await db.execute('''
      CREATE TABLE scenes (
        id $idType,
        location_id $textType,
        content_id $textType,
        description $textType,
        episode $textTypeNullable,
        scene_image_url $textTypeNullable,
        scene_order $intType DEFAULT 0,
        FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
        FOREIGN KEY (content_id) REFERENCES contents(id) ON DELETE CASCADE
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        theme $textType DEFAULT 'system',
        language $textType DEFAULT 'ko',
        created_at $textType
      )
    ''');

    // Bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks (
        id $idType,
        user_id $textType,
        location_id $textType,
        created_at $textType,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
        UNIQUE(user_id, location_id)
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_locations_category ON locations(category)');
    await db.execute('CREATE INDEX idx_locations_created_at ON locations(created_at)');
    await db.execute('CREATE INDEX idx_contents_type ON contents(type)');
    await db.execute('CREATE INDEX idx_scenes_location_id ON scenes(location_id)');
    await db.execute('CREATE INDEX idx_scenes_content_id ON scenes(content_id)');
    await db.execute('CREATE INDEX idx_bookmarks_user_id ON bookmarks(user_id)');
    await db.execute('CREATE INDEX idx_bookmarks_location_id ON bookmarks(location_id)');
    
    // Insert sample data
    await _insertSampleData(db);
  }

  Future _insertSampleData(Database db) async {
    // Import sample data
    final sampleData = await _loadSampleData();
    
    // Insert contents
    final contents = sampleData['contents'] as List<Map<String, dynamic>>?;
    if (contents != null) {
      for (final content in contents) {
        await db.insert('contents', content);
      }
    }
    
    // Insert locations
    final locations = sampleData['locations'] as List<Map<String, dynamic>>?;
    if (locations != null) {
      for (final location in locations) {
        await db.insert('locations', location);
      }
    }
    
    // Insert scenes
    final scenes = sampleData['scenes'] as List<Map<String, dynamic>>?;
    if (scenes != null) {
      for (final scene in scenes) {
        await db.insert('scenes', scene);
      }
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadSampleData() async {
    // For now, return hardcoded sample data
    // In the future, this could load from JSON files
    return {
      'contents': [
        {
          'id': 'content_001',
          'title': '도깨비',
          'type': 'drama',
          'poster_url': null,
          'release_year': 2016,
          'genre': '판타지, 로맨스',
          'description': '불멸의 삶을 끝내기 위해 인간 신부가 필요한 도깨비',
          'created_at': DateTime(2024, 1, 15).toIso8601String(),
        },
        {
          'id': 'content_002',
          'title': '이태원 클라쓰',
          'type': 'drama',
          'poster_url': null,
          'release_year': 2020,
          'genre': '드라마',
          'description': '이태원의 작은 포장마차에서 시작된 젊은이들의 도전기',
          'created_at': DateTime(2024, 1, 15).toIso8601String(),
        },
      ],
      'locations': [
        {
          'id': 'loc_001',
          'name': '인왕산 돌담길',
          'address': '서울특별시 종로구 옥인동',
          'latitude': 37.5876,
          'longitude': 126.9658,
          'category': 'street',
          'phone_number': null,
          'website': null,
          'opening_hours': '24시간',
          'image_urls': '[]',
          'parking': '주변 공영주차장 이용',
          'transportation': '지하철 3호선 경복궁역 3번 출구에서 도보 15분',
          'view_count': 1250,
          'bookmark_count': 340,
          'created_at': DateTime(2024, 1, 15).toIso8601String(),
          'updated_at': null,
        },
        {
          'id': 'loc_002',
          'name': '덕수궁 돌담길',
          'address': '서울특별시 중구 정동길',
          'latitude': 37.5658,
          'longitude': 126.9751,
          'category': 'street',
          'phone_number': null,
          'website': null,
          'opening_hours': '24시간',
          'image_urls': '[]',
          'parking': '덕수궁 주차장 이용',
          'transportation': '지하철 1호선 시청역 2번 출구',
          'view_count': 980,
          'bookmark_count': 280,
          'created_at': DateTime(2024, 1, 16).toIso8601String(),
          'updated_at': null,
        },
        {
          'id': 'loc_003',
          'name': '담바 이태원점',
          'address': '서울특별시 용산구 이태원로 203',
          'latitude': 37.5345,
          'longitude': 126.9945,
          'category': 'restaurant',
          'phone_number': '02-749-1942',
          'website': null,
          'opening_hours': '11:00 - 22:00',
          'image_urls': '[]',
          'parking': '주변 유료 주차장 이용',
          'transportation': '지하철 6호선 이태원역 1번 출구',
          'view_count': 2100,
          'bookmark_count': 520,
          'created_at': DateTime(2024, 1, 17).toIso8601String(),
          'updated_at': null,
        },
        {
          'id': 'loc_004',
          'name': '경복궁',
          'address': '서울특별시 종로구 사직로 161',
          'latitude': 37.5796,
          'longitude': 126.9770,
          'category': 'building',
          'phone_number': '02-3700-3900',
          'website': 'www.royalpalace.go.kr',
          'opening_hours': '09:00 - 18:00 (월요일 휴무)',
          'image_urls': '[]',
          'parking': '경복궁 주차장 이용',
          'transportation': '지하철 3호선 경복궁역 5번 출구',
          'view_count': 1500,
          'bookmark_count': 400,
          'created_at': DateTime(2024, 1, 18).toIso8601String(),
          'updated_at': null,
        },
        {
          'id': 'loc_005',
          'name': '북촌 한옥마을',
          'address': '서울특별시 종로구 계동길 37',
          'latitude': 37.5826,
          'longitude': 126.9833,
          'category': 'street',
          'phone_number': null,
          'website': null,
          'opening_hours': '24시간',
          'image_urls': '[]',
          'parking': '주변 공영주차장 이용',
          'transportation': '지하철 3호선 안국역 3번 출구',
          'view_count': 1800,
          'bookmark_count': 450,
          'created_at': DateTime(2024, 1, 19).toIso8601String(),
          'updated_at': null,
        },
      ],
      'scenes': [
        {
          'id': 'scene_001',
          'location_id': 'loc_001',
          'content_id': 'content_001',
          'description': '은탁이와 도깨비가 처음 만나는 장면',
          'episode': '1회',
          'scene_image_url': null,
          'scene_order': 1,
        },
        {
          'id': 'scene_002',
          'location_id': 'loc_002',
          'content_id': 'content_001',
          'description': '도깨비와 은탁이 데이트하는 장면',
          'episode': '5회',
          'scene_image_url': null,
          'scene_order': 1,
        },
        {
          'id': 'scene_003',
          'location_id': 'loc_003',
          'content_id': 'content_002',
          'description': '단밤 포차 외관 및 내부 장면',
          'episode': '여러 회',
          'scene_image_url': null,
          'scene_order': 1,
        },
      ],
    };
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
