
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageService {
  static final ImageService instance = ImageService._internal();
  
  factory ImageService() {
    return instance;
  }
  
  ImageService._internal();

  // Cache to prevent repetitive API calls
  final Map<String, List<String>> _imageCache = {};

  /// Used by LocationRepository
  Future<List<String>> fetchImagesForLocation(
    String locationName, 
    String contentTitle, {
    String? category,
    String? locationId,
  }) async {
    return _searchImages(locationName);
  }

  /// Used by LocationDetailScreen
  Future<List<String>> searchImagesForLocation({
    required String locationName,
    String? address,
    String? locationId,
    int maxResults = 3,
  }) async {
    // Try to use cache first if locationId is provided
    if (locationId != null && _imageCache.containsKey(locationId)) {
      return _imageCache[locationId]!;
    }

    final results = await _searchImages(locationName, maxResults: maxResults);
    
    if (locationId != null && results.isNotEmpty) {
      _imageCache[locationId] = results;
    }
    
    return results;
  }

  /// Internal method to perform the actual search
  /// Currently uses Naver Search API (Image/Local) if keys are available
  Future<List<String>> _searchImages(String query, {int maxResults = 3}) async {
    // Feature disabled by user request due to inaccurate results
    return [];
  }
}
