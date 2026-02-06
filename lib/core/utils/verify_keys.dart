import 'dart:io';
import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Removed to allow running with 'dart' command

// Standalone script to verify Naver Map API keys
// Usage:
// 1. Ensure your .env file in project root has valid keys
// 2. Run this script with: dart lib/core/utils/verify_keys.dart

void main() async {
  print('--- Naver API Key Verification ---');
  
  // 1. Manual Key Input (Uncomment to test specific keys directly if dotenv fails)
  // String clientId = "YOUR_CLIENT_ID";
  // String clientSecret = "YOUR_CLIENT_SECRET";
  
  // 2. Try to load from .env manually since this is a script
  // Note: dotenv.load defaults to '.env', but we might need absolute path if run from wrong dir
  // Let's assume user runs from project root
  
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file not found in current directory.');
    print('Current execution path: ${Directory.current.path}');
    return;
  }
  
  // Parse .env manually to avoid Flutter dependencies in pure Dart script if possible,
  // but we imported flutter_dotenv. flutter_dotenv requires Flutter binding usually,
  // but basic parsing might work or we just parse string manually.
  // Let's just parse manually to be safe and dependency-free for a script.
  
  String? clientId;
  String? clientSecret;
  
  final lines = await envFile.readAsLines();
  for (var line in lines) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      final key = parts[0].trim();
      final value = parts.sublist(1).join('=').trim();
      if (key == 'NAVER_MAP_CLIENT_ID') clientId = value;
      if (key == 'NAVER_MAP_CLIENT_SECRET') clientSecret = value;
    }
  }

  if (clientId == null || clientSecret == null) {
    print('Error: NAVER_MAP_CLIENT_ID or NAVER_MAP_CLIENT_SECRET not found in .env');
    return;
  }

  print('Loaded Keys:');
  print('Client ID: $clientId');
  // print('Client Secret: $clientSecret'); // Do not print secret

  // 3. Test Geocoding API (Using maps.apigw.ntruss.com as per docs)
  print('\nTesting Geocoding API (maps.apigw.ntruss.com)...');
  final query = '강남구'; // Simple query
  final url = Uri.parse('https://maps.apigw.ntruss.com/map-geocode/v2/geocode?query=$query');
  
  try {
    final response = await http.get(
      url,
      headers: {
        'X-NCP-APIGW-API-KEY-ID': clientId,
        'X-NCP-APIGW-API-KEY': clientSecret,
        'Accept': 'application/json',
      },
    );

    print('Response Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print('\nSUCCESS: API Key is valid and Geocoding API is working.');
    } else if (response.statusCode == 401) {
      print('\nFAILED: Permission Denied (401).');
      print('Common causes:');
      print('1. Wrong Client ID/Secret keys.');
      print('2. Geocoding API not selected in Console (Application > Edit > Check Geocoding).');
      print('3. Package Name mismatch (though less likely for API calls unless checked).');
    } else {
      print('\nFAILED with status code ${response.statusCode}');
    }

  } catch (e) {
    print('Exception during request: $e');
  }
}
