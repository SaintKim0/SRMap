import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

class NaverGeocodingService {
  static const String _baseUrl = 'https://maps.apigw.ntruss.com/map-geocode/v2/geocode';

  /// 주소를 입력받아 좌표(Position)를 반환합니다.
  /// 실패하거나 결과가 없으면 null을 반환합니다.
  static Future<Position?> fetchGeocode(String query) async {
    try {
      final clientId = dotenv.env['NAVER_MAP_CLIENT_ID'];
      final clientSecret = dotenv.env['NAVER_MAP_CLIENT_SECRET'];

      if (clientId == null || clientSecret == null) {
        throw Exception('Naver Map API keys not found in .env');
      }

      // Use Uri.https to ensure query parameters (Korean) are properly encoded
      final url = Uri.https(
        'maps.apigw.ntruss.com', 
        '/map-geocode/v2/geocode', 
        {'query': query}
      );

      final response = await http.get(
        url,
        headers: {
          'X-NCP-APIGW-API-KEY-ID': clientId,
          'X-NCP-APIGW-API-KEY': clientSecret,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final addresses = data['addresses'] as List<dynamic>;

        if (addresses.isNotEmpty) {
          final firstResult = addresses[0];
          // Naver API: x = longitude, y = latitude
          final double lat = double.parse(firstResult['y']);
          final double lng = double.parse(firstResult['x']);

          return Position(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0, 
            headingAccuracy: 0.0
          );
        }
      } else {
        print('Naver Geocoding Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Naver Geocoding Exception: $e');
    }
    return null;
  }
}
