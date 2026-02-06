import 'dart:io';
import 'package:cp949_codec/cp949_codec.dart';
import 'package:csv/csv.dart';

void main() async {
  final file = File('assets/data/locations.csv');
  final bytes = await file.readAsBytes();
  final content = cp949.decode(bytes);
  
  final rows = CsvToListConverter().convert(content);
  if (rows.length > 100) {
    final row100 = rows[100];
    print('Row 100 column count: ${row100.length}');
    print('Row 100 content: $row100');
  }
}
