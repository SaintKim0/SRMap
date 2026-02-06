import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/kmdb_work_info.dart';

/// 한국영상자료원 KMDb OPEN API - 영화 상세정보 (제목, 감독, 연도, 줄거리)
/// API 안내: https://www.kmdb.or.kr/info/api/apiDetail/6
/// 인증키: kmdb.or.kr 회원가입 후 오픈API안내에서 인증키 신청
class KmdbApiService {
  static final KmdbApiService instance = KmdbApiService._();
  KmdbApiService._();

  static const String _baseUrl =
      'http://api.koreafilm.or.kr/openapi-data2/wisenut/search_api/search_json2.jsp';

  String? get _serviceKey => dotenv.env['KMDB_SERVICE_KEY'];

  /// 영화명(작품명)으로 검색하여 작품 정보 반환. 첫 번째 검색 결과 사용.
  Future<KmdbWorkInfo?> fetchMovieByTitle(String title) async {
    final key = _serviceKey;
    if (key == null || key.isEmpty) {
      debugPrint('KmdbApiService: KMDB_SERVICE_KEY not set in .env');
      return null;
    }

    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: <String, String>{
          'collection': 'kmdb_new2',
          'detail': 'Y',
          'ServiceKey': key,
          'title': title,
          'listCount': '5',
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('', 408),
      );

      if (response.statusCode != 200) {
        debugPrint('KmdbApiService: HTTP ${response.statusCode}');
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;

      // 응답 구조: Data[0].Row (검색 결과 배열) 또는 Data[0].Result
      List<dynamic>? rows;
      final data = body['Data'];
      if (data is List && data.isNotEmpty) {
        final first = data[0] as Map<String, dynamic>?;
        if (first != null) {
          rows = first['Row'] as List<dynamic>?;
          if (rows == null) rows = first['Result'] as List<dynamic>?;
        }
      }
      if (rows == null && data is Map<String, dynamic>) {
        rows = data['Row'] as List<dynamic>? ?? data['Result'] as List<dynamic>?;
      }
      if (rows == null || rows.isEmpty) return null;

      final row = rows[0] is Map<String, dynamic> ? rows[0] as Map<String, dynamic> : null;
      if (row == null) return null;

      String getStr(String k) => (row[k]?.toString() ?? '').trim();
      final plot = getStr('plot');
      final directorNm = getStr('directorNm');
      final prodYear = getStr('prodYear');
      final nation = getStr('nation');
      final genre = getStr('genre');
      final kmdbUrl = getStr('kmdbUrl');
      final resultTitle = getStr('title').isEmpty ? title : getStr('title');

      return KmdbWorkInfo(
        title: resultTitle,
        directorNm: directorNm.isEmpty ? null : directorNm,
        prodYear: prodYear.isEmpty ? null : prodYear,
        plot: plot.isEmpty ? null : plot,
        nation: nation.isEmpty ? null : nation,
        genre: genre.isEmpty ? null : genre,
        kmdbUrl: kmdbUrl.isEmpty ? null : kmdbUrl,
      );
    } catch (e, st) {
      debugPrint('KmdbApiService: $e');
      debugPrint('$st');
      return null;
    }
  }
}
