// 지도 관련 상수
class MapConstants {
  // 네이버 지도 Client ID
  static const String naverMapClientId = '17wprh5927';

  // 기본 지도 중심 좌표 (서울 시청)
  static const double defaultLatitude = 37.5665;
  static const double defaultLongitude = 126.9780;

  // 기본 줌 레벨
  static const double defaultZoom = 15.0;
  static const double minZoom = 5.0;
  static const double maxZoom = 18.0;

  // 마커 관련
  static const double markerWidth = 40.0;
  static const double markerHeight = 50.0;

  // 거리 필터 (미터)
  static const double nearbyDistance = 5000; // 5km 이내를 "근처"로 간주
}
