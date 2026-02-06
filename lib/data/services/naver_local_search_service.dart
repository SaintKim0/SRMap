import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NaverLocalSearchService {
  static const String _baseUrl = 'https://openapi.naver.com/v1/search/local.json';

  /// 검색어(POI)를 입력받아 가장 관련성 높은 장소의 '주소(address)'를 반환합니다.
  /// 검색 결과가 없으면 null을 반환합니다.
  /// 반환된 주소는 Geocoding API에 넣어 좌표로 변환할 수 있습니다.
  static Future<String?> searchPlaceAddress(String query) async {
    try {
      final clientId = dotenv.env['NAVER_SEARCH_CLIENT_ID'];
      final clientSecret = dotenv.env['NAVER_SEARCH_CLIENT_SECRET'];

      if (clientId == null || clientSecret == null) {
        throw Exception('Naver Search API keys not found in .env');
      }

      final url = Uri.parse('$_baseUrl?query=$query&display=1&sort=random');
      final response = await http.get(
        url,
        headers: {
          'X-Naver-Client-Id': clientId,
          'X-Naver-Client-Secret': clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>;

        if (items.isNotEmpty) {
          final firstItem = items[0];
          // 'address' 필드는 지번 주소, 'roadAddress'는 도로명 주소입니다.
          // Geocoding API는 둘 다 지원하지만 도로명이 더 정확할 수 있습니다.
          // 값이 비어있을 수 있으므로 확인 필요
          String address = firstItem['roadAddress'] ?? '';
          if (address.isEmpty) {
            address = firstItem['address'] ?? '';
          }
          
          // HTML 태그 제거 (<b> 등)
          return _cleanHtmlTags(address);
        }
      } else {
        print('Naver Local Search Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Naver Local Search Exception: $e');
    }
    return null;
  }

  static String _cleanHtmlTags(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
