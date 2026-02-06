import 'dart:io';
import 'package:cp949_codec/cp949_codec.dart';

void main() async {
  final csvPath = 'assets/data/locations.csv';
  final file = File(csvPath);
  
  if (!file.existsSync()) {
    print('File not found: $csvPath');
    return;
  }

  final bytes = await file.readAsBytes();
  final content = cp949.decode(bytes);
  final lines = content.split('\n');
  
  print('Total lines: ${lines.length}');
  print('Last 10 lines:');
  for (var i = lines.length - 11; i < lines.length; i++) {
    if (i >= 0) print('[$i] ${lines[i]}');
  }
}
