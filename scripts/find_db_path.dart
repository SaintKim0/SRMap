import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;
  final path = await databaseFactory.getDatabasesPath();
  print('Databases Path: $path');
  
  final dbFile = File('$path/scenemap.db');
  if (dbFile.existsSync()) {
    print('scenemap.db FOUND at: ${dbFile.path}');
  } else {
    print('scenemap.db NOT FOUND at: ${dbFile.path}');
    // List files in that directory
    final dir = Directory(path);
    if (dir.existsSync()) {
      print('Files in $path:');
      dir.listSync().forEach((f) => print(' - ${f.path}'));
    }
  }
}
