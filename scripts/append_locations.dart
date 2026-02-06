import 'dart:io';
import 'package:cp949_codec/cp949_codec.dart';

void main() async {
  final csvPath = 'assets/data/locations.csv';
  final file = File(csvPath);
  
  if (!file.existsSync()) {
    print('File not found: $csvPath');
    return;
  }

  // Get current last ID (optional, let's just use 901-908)
  // Data to append
  final newData = [
    ['901', 'movie', 'K-Pop: 데몬 헌터스', '코엑스 K-POP 광장', 'building', '영화 오프닝 명소', '24시간', '연중무휴', '서울특별시 강남구 영동대로 513', '37.5072', '127.0553', '02-6000-0114', '2026-01-24'],
    ['902', 'movie', 'K-Pop: 데몬 헌터스', '명동 거리', 'street', '사자 보이즈 배경', '명동 상점가 운영시간', '없음', '서울특별시 중구 명동길', '37.5640', '126.9850', '', '2026-01-24'],
    ['903', 'movie', 'K-Pop: 데몬 헌터스', '남산공원 (N서울타워)', 'park', '주요 전투 배경', '10:00 - 23:00', '없음', '서울특별시 용산구 남산공원길 105', '37.5512', '126.9882', '02-3455-9277', '2026-01-24'],
    ['904', 'movie', 'K-Pop: 데몬 헌터스', '낙산공원', 'park', '성곽길 감성 명소', '24시간', '없음', '서울특별시 종로구 낙산길 41', '37.5807', '127.0083', '02-743-7985', '2026-01-24'],
    ['905', 'movie', 'K-Pop: 데몬 헌터스', '자양역 (청담대교)', 'street', '지하철 열차 전투', '24시간', '없음', '서울특별시 광진구 자양동 227', '37.5261', '127.0642', '', '2026-01-24'],
    ['906', 'movie', 'K-Pop: 데몬 헌터스', '서울 올림픽 주경기장', 'building', '공연 및 시상식 무대', '상이함', '없음', '서울특별시 송파구 올림픽로 25', '37.5139', '127.0736', '02-2240-8800', '2026-01-24'],
    ['907', 'movie', 'K-Pop: 데몬 헌터스', '북촌 한옥마을', 'street', '전통 가옥 대화 장면', '09:00 - 18:00', '일요일 휴식권 권고', '서울특별시 종로구 계동길 37', '37.5826', '126.9835', '02-2133-1372', '2026-01-24'],
    ['908', 'movie', 'K-Pop: 데몬 헌터스', '롯데월드타워', 'building', '본부 건물 영감', '10:30 - 22:00', '없음', '서울특별시 송파구 올림픽로 300', '37.5126', '127.1025', '1661-2000', '2026-01-24'],
  ];

  final IOSink sink = file.openWrite(mode: FileMode.append);

  for (final row in newData) {
    // Convert to CSV row string
    final line = row.map((e) => '"$e"').join(',') + '\n';
    // Encode to CP949
    final encoded = cp949.encode(line);
    sink.add(encoded);
  }

  await sink.flush();
  await sink.close();
  print('Successfully added 8 locations to locations.csv');
}
