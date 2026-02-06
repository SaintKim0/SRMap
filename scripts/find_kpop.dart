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
  
  final artists = ['방탄소년단', '블랙핑크', '슈퍼주니어', '세븐틴', '트와이스', '동방신기', '데몬 헌터스'];
  
  print('Searching for K-Pop artists in CSV...');
  for (final line in lines) {
    for (final artist in artists) {
      if (line.contains(artist)) {
        print('Found: $line');
      }
    }
  }
}
