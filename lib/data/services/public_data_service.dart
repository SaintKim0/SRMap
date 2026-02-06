import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/location.dart';

/// 한국문화정보원_미디어콘텐츠 영상 촬영지 데이터 API (공공데이터포털)
/// OpenAPI: https://infuser.odcloud.kr/oas/docs?namespace=15111405/v1
/// Base URL: https://api.odcloud.kr/api
class PublicDataService {
  static final PublicDataService instance = PublicDataService._();
  PublicDataService._();

  static const String _odcloudBaseUrl =
      'https://api.odcloud.kr/api/15111405/v1/uddi:d8741b9c-f484-4ea8-8f54-bd21ab62de14';

  Future<List<Location>> fetchLocations() async {
    final String? serviceKey = dotenv.env['DATA_GO_KR_API_KEY'];

    if (serviceKey == null || serviceKey.isEmpty) {
      print('DATA_GO_KR_API_KEY not found in .env');
      return [];
    }

    try {
      final uri = Uri.parse(_odcloudBaseUrl).replace(queryParameters: {
        'serviceKey': serviceKey,
        'page': '1',
        'perPage': '100',
        'returnType': 'json',
      });

      print('Fetching data from: ${uri.origin}${uri.path}?serviceKey=***&page=1&perPage=100&returnType=json');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic>? data = body['data'] as List<dynamic>?;

        if (data == null || data.isEmpty) {
          print('API returned no data.');
          return [];
        }

        final List<Location> locations = [];
        for (final raw in data) {
          try {
            final Map<String, dynamic> item = raw as Map<String, dynamic>;
            String getStr(String k) => (item[k]?.toString() ?? '').trim();

            final String placeName = getStr('place_name');
            final String latStr = getStr('latitude');
            final String lngStr = getStr('longitude');
            if (placeName.isEmpty || latStr.isEmpty || lngStr.isEmpty) continue;

            final double lat = double.tryParse(latStr) ?? 0.0;
            final double lng = double.tryParse(lngStr) ?? 0.0;
            if (lat == 0.0 || lng == 0.0) continue;

            final String title = getStr('title');
            final String mediaType = getStr('media_type');
            final String desc = getStr('description');
            final String address = getStr('address');
            final String hours = getStr('opening_hours');
            final String restDay = getStr('closed_days');
            final String phone = getStr('phone');
            final int seq = item['no'] is int ? item['no'] as int : 0;

            String openingHours = hours;
            if (restDay.isNotEmpty && restDay != 'null') {
              openingHours = openingHours.isEmpty ? restDay : '$openingHours ($restDay)';
            }
            if (openingHours == 'null') openingHours = '';

            locations.add(Location(
              id: 'api_$seq',
              name: placeName,
              address: address,
              latitude: lat,
              longitude: lng,
              category: 'etc',
              mediaType: mediaType.isEmpty ? null : mediaType,
              contentTitle: title.isEmpty ? null : title,
              phoneNumber: phone.isEmpty || phone == 'null' ? null : phone,
              openingHours: openingHours.isEmpty ? null : openingHours,
              description: '[$mediaType] $title\n$desc',
              imageUrls: const [],
              createdAt: DateTime.now(),
            ));
          } catch (e) {
            print('JSON parse error for item: $e');
          }
        }
        print('Successfully fetched ${locations.length} locations from API.');
        return locations;
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('PublicDataService Error: $e');
      if (e.toString().contains('SocketException')) {
        print('Tip: Check internet connection or if the host is blocked by cleartext policy.');
      }
      return [];
    }
  }
}
