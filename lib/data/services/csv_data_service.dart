import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/location.dart';

class CsvDataService {
  static final CsvDataService instance = CsvDataService._();
  CsvDataService._();

  Future<List<Location>> loadLocations() async {
    try {
      print('Attempting to load CSV from assets/data/locations.csv');
      
      // Load as bytes and decode using UTF-8
      final ByteData data = await rootBundle.load('assets/data/locations.csv');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final String rawData = utf8.decode(bytes);
      
      print('CSV raw data loaded. Length: ${rawData.length} chars');
      
      // Parse CSV
      List<List<dynamic>> rows = CsvToListConverter(
        shouldParseNumbers: false
      ).convert(rawData);

      print('CSV Parsed. Rows found: ${rows.length}');
      if (rows.isNotEmpty) {
        print('Header row (Row 0): ${rows[0]}');
      }

      // Check if header exists (Row 1 has "no" or similar)
      int startIndex = 0;
      if (rows.isNotEmpty && rows[0][0].toString().toLowerCase().contains('no')) {
        startIndex = 1;
      }

      final List<Location> locations = [];
      
      // Fixed Indices based on inspection
      // 0: id, 1: type, 2: title, 3: place, 4: category, 5: desc, 6: hours, 7: info, 8: rest, 9: address, 10: lat, 11: lng, 12: phone, 13: date
      const int colMediaType = 1;
      const int colTitle = 2;
      const int colName = 3;
      const int colCategory = 4;
      const int colDesc = 5;
      const int colHours = 6;
      // const int colInfo = 7;
      const int colRest = 8;
      const int colAddress = 9;
      const int colLat = 10;
      const int colLng = 11;
      const int colPhone = 12;
      const int colMichelinTier = 14;

      int successCount = 0;
      int failCount = 0;

      for (int i = startIndex; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 12) {
           // print('Skipping row $i: length ${row.length}');
           continue; 
        }

        try {
          if (i < 5) {
             print('Row $i raw: $row');
             print('Lat/Lng raw: ${row[colLat]} / ${row[colLng]}');
          }

          // Stable columns
          final String mediaTypeRaw = row[colMediaType].toString();
          final String title = row[colTitle].toString();
          final String placeName = row[colName].toString();
          final String rawCategory = row[colCategory].toString();
          final String descRaw = row[colDesc].toString();

          // Coordinate Parsing
          // Remove quotes just in case, though converter should handle it
          final String latStr = row[colLat].toString().replaceAll('"', '').trim();
          final String lngStr = row[colLng].toString().replaceAll('"', '').trim();
          
          final double lat = double.tryParse(latStr) ?? 0.0;
          final double lng = double.tryParse(lngStr) ?? 0.0;
          
          // Allow coordinates even if 0.0 or out of bounds - we'll just not show them on map
          // But still store the location data for list view
          if (lat == 0.0 && lng == 0.0) {
             if (i < 20) print('Warning: No coordinates for location: "$placeName"');
             // Continue to save the location even without coordinates
          }

          // Note: We no longer filter out locations with invalid coordinates
          // They will be stored but may not be displayed on map

          final String address = row[colAddress].toString();
          final String phone = row[colPhone].toString();
          
          // Hours formatting
          final String hours = row[colHours].toString();
          final String restDay = row[colRest].toString();
          
          String combinedHours = hours;
          if (restDay.isNotEmpty && restDay != 'null' && restDay != '정보없음') {
             if (combinedHours.isNotEmpty && combinedHours != 'null' && combinedHours != '정보없음') {
                combinedHours += ' ($restDay)';
             } else {
                combinedHours = restDay;
             }
          }
           
          final String description = '[$mediaTypeRaw] $title\n$descRaw';

          // Category mapping
          String category = 'etc';
          if (rawCategory.toLowerCase().contains('cafe') || rawCategory.contains('카페')) category = 'cafe';
          else if (rawCategory.toLowerCase().contains('restaurant') || rawCategory.contains('식당')) category = 'restaurant';
          else if (rawCategory.toLowerCase().contains('park') || rawCategory.contains('공원')) category = 'park';
          else category = 'street'; 
          
          // Media Type normalization
          final String lowerTitle = title.toLowerCase();
          final String lowerMediaType = mediaTypeRaw.toLowerCase();
          
          final kpopKeywords = [
            'k-pop', 'kpop', 'bts', '방탄소년단', 'blackpink', '블랙핑크', 
            'twice', '트와이스', 'exo', '엑소', 'nct', 'seventeen', '세븐틴',
            'super junior', '슈퍼주니어', '슈퍼쥬니어', 'tvxq', '동방신기', 'btob', '비투비',
            'girls generation', '소녀시대', 'red velvet', '레드벨벳', 
            'apink', '에이핑크', 'oh my girl', '오마이걸', 'infinite', '인피니트',
            'shinee', '샤이니', 'mamamoo', '마마무', 'iu', '아이유', 
            'txt', '투모로우바이투게더', 'ive', '아이브', 'newjeans', '뉴진스',
            'aespa', '에스파', 'stray kids', '스트레이 키즈', 'itzy', '있지',
            'monsta x', '몬스타엑스', 'astro', '아스트로', 'winner', '위너',
            'ikon', '아이콘', 'got7', '갓세븐', '2pm', '빅뱅', 'bigbang', '뮤직비디오', '콘서트'
          ];

          bool isKpop = lowerMediaType.contains('artist') || 
                        lowerMediaType.contains('kpop') ||
                        kpopKeywords.any((k) => lowerTitle.contains(k));

          String normalizedMediaType = 'drama';
          if (isKpop) {
            normalizedMediaType = 'artist'; 
          } else if (lowerMediaType.contains('movie')) {
            normalizedMediaType = 'movie';
          } else if (lowerMediaType.contains('show') || lowerMediaType.contains('variety')) {
            normalizedMediaType = 'show';
          } else if (lowerMediaType.contains('blackwhite')) {
            normalizedMediaType = 'blackwhite';
          } else if (lowerMediaType.contains('guide')) {
            normalizedMediaType = 'guide';
          } else if (lowerMediaType.isNotEmpty) {
            // Keep original media type if it doesn't match any known type
            normalizedMediaType = mediaTypeRaw.toLowerCase();
          }
          
          List<String> finalImageUrls = const [];
          // Fix for specific locations having video links instead of images
          if (placeName.contains('육일점') || placeName.contains('신효귤향과즐')) {
             finalImageUrls = const [];
          }

          String? michelinTier = row.length > colMichelinTier
              ? (row[colMichelinTier].toString().trim().isEmpty ? null : row[colMichelinTier].toString().trim())
              : null;
          // guide일 때 michelin_tier가 비어 있으면 description에서 등급 추출 (셀렉티드, 빕 구르망, 1스타, 2스타, 3스타)
          if (normalizedMediaType == 'guide' && (michelinTier == null || michelinTier.isEmpty)) {
            final d = descRaw;
            if (d.contains('3스타')) {
              michelinTier = '3star';
            } else if (d.contains('2스타')) {
              michelinTier = '2star';
            } else if (d.contains('1스타')) {
              michelinTier = '1star';
            } else if (d.contains('빕 구르망') || d.contains('빕구르망')) {
              michelinTier = 'bib';
            } else if (d.contains('셀렉티드')) {
              michelinTier = 'michelin';
            }
          }

          locations.add(Location(
            id: 'csv_${row[0]}', 
            name: placeName,
            address: address,
            latitude: lat,
            longitude: lng,
            category: category,
            mediaType: normalizedMediaType,
            contentTitle: title,
            contentReleaseYear: null,
            michelinTier: michelinTier,
            phoneNumber: phone == 'null' || phone.isEmpty ? null : phone,
            openingHours: combinedHours == 'null' || combinedHours.isEmpty ? null : combinedHours,
            imageUrls: finalImageUrls,
            description: description,
            createdAt: DateTime.now(),
          ));
          successCount++;
        } catch (e) {
          print('Error parsing row $i: $e');
          failCount++;
        }
      }

      print('CSV Load Summary: Found ${rows.length} rows. Loaded: $successCount, Failed: $failCount');
      
      // Debug specific count of movies
      print('DEBUG: Movie count in loaded: ${locations.where((l) => l.mediaType == 'movie').length}');

      return locations;
    } catch (e) {
      print('Error loading CSV: $e');
      return [];
    }
  }
}
