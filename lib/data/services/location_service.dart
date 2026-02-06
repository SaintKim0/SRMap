import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService instance = LocationService._init();

  LocationService._init();

  /// 위치 권한 확인
  Future<bool> checkPermission() async {
    final permission = await Permission.location.status;
    return permission.isGranted;
  }

  /// 위치 권한 요청
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// 현재 위치 가져오기
  Future<Position?> getCurrentPosition() async {
    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // 현재 위치 가져오기
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// 두 지점 간 거리 계산 (km)
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(
          startLat,
          startLng,
          endLat,
          endLng,
        ) /
        1000; // 미터를 킬로미터로 변환
  }

  /// 거리를 사람이 읽기 쉬운 형식으로 변환
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)}m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceInKm.toStringAsFixed(0)}km';
    }
  }

  /// 위치 업데이트 스트림
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10미터 이동 시 업데이트
      ),
    );
  }

  /// 설정 화면으로 이동
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// 앱 설정 화면으로 이동
  Future<void> openAppSettings() async {
    await Permission.location.request();
  }
}
