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
  final lines = content.split(RegExp(r'\r\n|\r|\n'));
  
  if (lines.isEmpty) return;
  
  final lastLines = lines.length > 10 ? lines.sublist(lines.length - 10) : lines;
  final result = lastLines.join('\n');
  
  await File('csv_check_utf8.txt').writeAsString(result);
  print('Exported last 10 lines to csv_check_utf8.txt');
}
