import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService.instance;

  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _locationError;

  Position? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get locationError => _locationError;
  bool get hasLocation => _currentPosition != null;

  /// 현재 위치 가져오기
  Future<void> getCurrentLocation() async {
    _isLoadingLocation = true;
    _locationError = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentPosition();
      
      if (position != null) {
        _currentPosition = position;
        _locationError = null;
      } else {
        _locationError = '위치 정보를 가져올 수 없습니다';
      }
    } catch (e) {
      _locationError = '위치 정보 오류: $e';
      debugPrint('Location error: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// 위치 정보 직접 업데이트 (외부에서 이미 가져온 Position 사용)
  void updateCurrentPosition(Position position) {
    _currentPosition = position;
    _locationError = null;
    notifyListeners();
  }

  /// 특정 위치까지의 거리 계산 (km)
  double? calculateDistanceToLocation(double lat, double lng) {
    if (_currentPosition == null) return null;

    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
  }

  /// 거리를 포맷팅된 문자열로 반환
  String? formatDistanceToLocation(double lat, double lng) {
    final distance = calculateDistanceToLocation(lat, lng);
    if (distance == null) return null;

    return _locationService.formatDistance(distance);
  }

  /// 위치 권한 확인
  Future<bool> checkPermission() async {
    return await _locationService.checkPermission();
  }

  /// 위치 권한 요청
  Future<bool> requestPermission() async {
    return await _locationService.requestPermission();
  }

  /// 설정 화면 열기
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// 앱 설정 화면 열기
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  /// 위치 초기화
  void clearLocation() {
    _currentPosition = null;
    _locationError = null;
    notifyListeners();
  }
}
