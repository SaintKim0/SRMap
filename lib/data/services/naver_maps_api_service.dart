import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:screen_map/core/constants/map_constants.dart';

/// 네이버 Maps API 서비스 (Client Secret 필요)
class NaverMapsApiService {
  static final NaverMapsApiService instance = NaverMapsApiService._init();

  NaverMapsApiService._init();

  // Client Secret (보안 주의!)
  static const String _clientSecret = 'VLYEdk6O1lWGo7idcRx3PvUXzdF2RhVHt0iwkeU5';

  /// Reverse Geocoding: 좌표 → 주소 변환
  /// 
  /// [latitude] 위도
  /// [longitude] 경도
  /// 
  /// Returns: 주소 문자열 또는 null
  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc'
        '?coords=$longitude,$latitude'
        '&orders=roadaddr,addr'
        '&output=json',
      );

      final response = await http.get(
        url,
        headers: {
          'X-NCP-APIGW-API-KEY-ID': MapConstants.naverMapClientId,
          'X-NCP-APIGW-API-KEY': _clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 도로명 주소 우선
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          
          if (result['region'] != null) {
            final region = result['region'];
            final area1 = region['area1']?['name'] ?? '';
            final area2 = region['area2']?['name'] ?? '';
            final area3 = region['area3']?['name'] ?? '';
            
            return '$area1 $area2 $area3'.trim();
          }
          
          if (result['land'] != null) {
            return result['land']['name'] ?? '';
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Reverse Geocoding 오류: $e');
      return null;
    }
  }

  /// Static Map URL 생성
  /// 
  /// [latitude] 중심 위도
  /// [longitude] 중심 경도
  /// [width] 이미지 너비 (기본: 300)
  /// [height] 이미지 높이 (기본: 300)
  /// [zoom] 줌 레벨 (기본: 15)
  /// [markers] 마커 리스트 (선택)
  /// 
  /// Returns: Static Map 이미지 URL
  String getStaticMapUrl({
    required double latitude,
    required double longitude,
    int width = 300,
    int height = 300,
    int zoom = 15,
    List<MapMarker>? markers,
  }) {
    final center = '$longitude,$latitude';
    final size = '${width}x$height';
    
    var url = 'https://naveropenapi.apigw.ntruss.com/map-static/v2/raster'
        '?center=$center'
        '&level=$zoom'
        '&w=$width'
        '&h=$height';
    
    // 마커 추가
    if (markers != null && markers.isNotEmpty) {
      for (var marker in markers) {
        url += '&markers=type:d|size:mid|pos:${marker.longitude}%20${marker.latitude}';
      }
    }
    
    return url;
  }

  /// Static Map 이미지 다운로드
  /// 
  /// [url] getStaticMapUrl()로 생성한 URL
  /// 
  /// Returns: 이미지 바이트 데이터 또는 null
  Future<List<int>?> downloadStaticMap(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-NCP-APIGW-API-KEY-ID': MapConstants.naverMapClientId,
          'X-NCP-APIGW-API-KEY': _clientSecret,
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      
      return null;
    } catch (e) {
      print('Static Map 다운로드 오류: $e');
      return null;
    }
  }
}

/// Static Map 마커 정보
class MapMarker {
  final double latitude;
  final double longitude;
  final String? label;

  MapMarker({
    required this.latitude,
    required this.longitude,
    this.label,
  });
}
