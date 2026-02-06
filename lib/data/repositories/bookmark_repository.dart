import 'package:sqflite/sqflite.dart';
import '../models/bookmark.dart';
import '../services/database_helper.dart';

class BookmarkRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create
  Future<int> create(Bookmark bookmark) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'bookmarks',
      _toMap(bookmark),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read all by user ID
  Future<List<Bookmark>> getByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'bookmarks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Check if location is bookmarked
  Future<bool> isBookmarked(String userId, String locationId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'bookmarks',
      where: 'user_id = ? AND location_id = ?',
      whereArgs: [userId, locationId],
    );
    return maps.isNotEmpty;
  }

  // Get bookmark by user and location
  Future<Bookmark?> getByUserAndLocation(String userId, String locationId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'bookmarks',
      where: 'user_id = ? AND location_id = ?',
      whereArgs: [userId, locationId],
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Delete
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete by user and location
  Future<int> deleteByUserAndLocation(String userId, String locationId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'bookmarks',
      where: 'user_id = ? AND location_id = ?',
      whereArgs: [userId, locationId],
    );
  }

  // Get bookmark count for location
  Future<int> getCountForLocation(String locationId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM bookmarks WHERE location_id = ?',
      [locationId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Helper methods
  Map<String, dynamic> _toMap(Bookmark bookmark) {
    return {
      'id': bookmark.id,
      'user_id': bookmark.userId,
      'location_id': bookmark.locationId,
      'created_at': bookmark.createdAt.toIso8601String(),
    };
  }

  Bookmark _fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      locationId: map['location_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
