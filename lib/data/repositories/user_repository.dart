import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../services/database_helper.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create
  Future<int> create(User user) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'users',
      _toMap(user),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read by ID
  Future<User?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Update
  Future<int> update(User user) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      _toMap(user),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Update theme
  Future<int> updateTheme(String userId, String theme) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {'theme': theme},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Update language
  Future<int> updateLanguage(String userId, String language) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {'language': language},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Delete
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Helper methods
  Map<String, dynamic> _toMap(User user) {
    return {
      'id': user.id,
      'theme': user.theme,
      'language': user.language,
      'created_at': user.createdAt.toIso8601String(),
    };
  }

  User _fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      theme: map['theme'] as String,
      language: map['language'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
