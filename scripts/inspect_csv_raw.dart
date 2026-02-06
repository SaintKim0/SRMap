import 'dart:io';
import 'package:cp949_codec/cp949_codec.dart';

void main() async {
  final file = File('assets/data/locations.csv');
  final bytes = await file.readAsBytes();
  final content = cp949.decode(bytes);
  final lines = content.split(RegExp(r'\r\n|\r|\n'));
  
  if (lines.length > 100) {
    print('Line 100 raw: |${lines[100]}|');
    print('Line 100 bytes (CP949): ${cp949.encode(lines[100])}');
  }
}
