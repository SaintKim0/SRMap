import 'package:sqflite/sqflite.dart';
import '../models/scene.dart';
import '../services/database_helper.dart';

class SceneRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create
  Future<int> create(Scene scene) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'scenes',
      _toMap(scene),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read all
  Future<List<Scene>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('scenes', orderBy: 'scene_order ASC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Read by location ID
  Future<List<Scene>> getByLocationId(String locationId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'scenes',
      where: 'location_id = ?',
      whereArgs: [locationId],
      orderBy: 'scene_order ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Read by content ID
  Future<List<Scene>> getByContentId(String contentId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'scenes',
      where: 'content_id = ?',
      whereArgs: [contentId],
      orderBy: 'scene_order ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Update
  Future<int> update(Scene scene) async {
    final db = await _dbHelper.database;
    return await db.update(
      'scenes',
      _toMap(scene),
      where: 'id = ?',
      whereArgs: [scene.id],
    );
  }

  // Delete
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'scenes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Helper methods
  Map<String, dynamic> _toMap(Scene scene) {
    return {
      'id': scene.id,
      'location_id': scene.locationId,
      'content_id': scene.contentId,
      'description': scene.description,
      'episode': scene.episode,
      'scene_image_url': scene.sceneImageUrl,
      'scene_order': scene.sceneOrder,
    };
  }

  Scene _fromMap(Map<String, dynamic> map) {
    return Scene(
      id: map['id'] as String,
      locationId: map['location_id'] as String,
      contentId: map['content_id'] as String,
      description: map['description'] as String,
      episode: map['episode'] as String?,
      sceneImageUrl: map['scene_image_url'] as String?,
      sceneOrder: map['scene_order'] as int,
    );
  }
}
