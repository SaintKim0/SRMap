import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:screen_map/core/constants/map_constants.dart';

/// 네이버 지도 서비스
class MapService {
  static final MapService instance = MapService._init();

  MapService._init();

  /// 네이버 지도 SDK 초기화
  Future<void> initialize() async {
    try {
      await FlutterNaverMap().init(
        clientId: MapConstants.naverMapClientId,
        onAuthFailed: (ex) {
          print('네이버 지도 인증 실패: $ex');
        },
      );
      print('네이버 지도 SDK 초기화 완료');
    } catch (e) {
      print('네이버 지도 SDK 초기화 실패: $e');
    }
  }

  /// 기본 지도 옵션 생성
  NaverMapViewOptions getDefaultMapOptions() {
    return NaverMapViewOptions(
      initialCameraPosition: NCameraPosition(
        target: NLatLng(
          MapConstants.defaultLatitude,
          MapConstants.defaultLongitude,
        ),
        zoom: MapConstants.defaultZoom,
      ),
      extent: const NLatLngBounds(
        southWest: NLatLng(33.0, 124.0), // 한국 남서쪽 경계
        northEast: NLatLng(39.0, 132.0), // 한국 북동쪽 경계
      ),
      minZoom: MapConstants.minZoom,
      maxZoom: MapConstants.maxZoom,
      locationButtonEnable: true, // 현재 위치 버튼 활성화
      consumeSymbolTapEvents: false,
      scaleBarEnable: true, // 축척 표시 활성화
      logoClickEnable: false, // 로고 클릭 비활성화 (선택사항)
      indoorLevelPickerEnable: true, // 실내 지도 층 피커 활성화
    );
  }

  /// 마커 생성
  /// 마커 생성
  NMarker createMarker({
    required String id,
    required double latitude,
    required double longitude,
    required String caption,
    NOverlayImage? icon,
    NSize? size,
  }) {
    final marker = NMarker(
      id: id,
      position: NLatLng(latitude, longitude),
      size: size ?? const NSize(25, 25), // Default to square 1:1 if not specified
    );

    // 캡션 설정
    marker.setCaption(NOverlayCaption(text: caption));

    // 아이콘 설정 (제공된 경우)
    if (icon != null) {
      marker.setIcon(icon);
    }

    return marker;
  }

  /// 여러 마커를 포함하도록 카메라 이동
  NCameraUpdate getCameraUpdateForMarkers(List<NLatLng> positions) {
    if (positions.isEmpty) {
      return NCameraUpdate.scrollAndZoomTo(
        target: NLatLng(
          MapConstants.defaultLatitude,
          MapConstants.defaultLongitude,
        ),
        zoom: MapConstants.defaultZoom,
      );
    }

    if (positions.length == 1) {
      return NCameraUpdate.scrollAndZoomTo(
        target: positions.first,
        zoom: MapConstants.defaultZoom,
      );
    }

    // 모든 마커를 포함하는 경계 계산
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    final bounds = NLatLngBounds(
      southWest: NLatLng(minLat, minLng),
      northEast: NLatLng(maxLat, maxLng),
    );

    return NCameraUpdate.fitBounds(bounds);
  }

  /// 특정 위치로 카메라 이동
  NCameraUpdate moveCameraTo({
    required double latitude,
    required double longitude,
    double? zoom,
  }) {
    return NCameraUpdate.scrollAndZoomTo(
      target: NLatLng(latitude, longitude),
      zoom: zoom ?? MapConstants.defaultZoom,
    );
  }

  /// 현재 위치로 카메라 이동
  NCameraUpdate moveCameraToCurrentLocation({
    required double latitude,
    required double longitude,
  }) {
    return NCameraUpdate.scrollAndZoomTo(
      target: NLatLng(latitude, longitude),
      zoom: 16.0, // 현재 위치는 더 가까이
    );
  }

  /// 위치 정보에 따른 마커 이미지 경로 반환
  String getMarkerAssetForLocation(dynamic location) {
    // location can be a Location model object
    final mediaType = location.mediaType?.toString().toLowerCase();
    
    if (mediaType == null) return 'assets/images/markers/marker_default.png';

    if (mediaType == 'blackwhite') {
      final title = location.contentTitle?.toString() ?? '';
      if (title.contains('시즌1')) {
        return 'assets/images/markers/bw_s1.png';
      } else if (title.contains('시즌2')) {
        return 'assets/images/markers/bw_s2.png';
      }
      return 'assets/images/markers/marker_black_white.png';
    } 
    
    if (mediaType == 'guide') {
      final tier = location.michelinTier?.toString().toLowerCase() ?? '';
      if (tier.contains('3')) {
        return 'assets/images/markers/michelin_3star.png';
      } else if (tier.contains('2')) {
        return 'assets/images/markers/michelin_2star.png';
      } else if (tier.contains('1')) {
        return 'assets/images/markers/michelin_1star.png';
      } else if (tier.contains('bib') || tier.contains('빕')) {
        return 'assets/images/markers/michelin_bib.png';
      }
      return 'assets/images/markers/michelin_reg.png';
    }

    if (mediaType == 'show' || mediaType == 'artist') {
      return 'assets/images/markers/sector_entertainment.png';
    }

    return 'assets/images/markers/marker_default.png';
  }
}
