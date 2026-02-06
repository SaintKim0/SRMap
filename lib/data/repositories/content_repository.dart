import 'package:sqflite/sqflite.dart';
import '../models/content.dart';
import '../services/database_helper.dart';

class ContentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create
  Future<int> create(Content content) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'contents',
      _toMap(content),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read all
  Future<List<Content>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('contents', orderBy: 'release_year DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Read by ID
  Future<Content?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contents',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Read by type
  Future<List<Content>> getByType(String type) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contents',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'release_year DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Search by title
  Future<List<Content>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contents',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'release_year DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Update
  Future<int> update(Content content) async {
    final db = await _dbHelper.database;
    return await db.update(
      'contents',
      _toMap(content),
      where: 'id = ?',
      whereArgs: [content.id],
    );
  }

  // Delete
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'contents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Helper methods
  Map<String, dynamic> _toMap(Content content) {
    return {
      'id': content.id,
      'title': content.title,
      'type': content.type,
      'poster_url': content.posterUrl,
      'release_year': content.releaseYear,
      'genre': content.genre,
      'description': content.description,
      'created_at': content.createdAt.toIso8601String(),
    };
  }

  Content _fromMap(Map<String, dynamic> map) {
    return Content(
      id: map['id'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      posterUrl: map['poster_url'] as String?,
      releaseYear: map['release_year'] as int?,
      genre: map['genre'] as String?,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
