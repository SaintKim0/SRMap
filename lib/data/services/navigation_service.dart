import 'package:url_launcher/url_launcher.dart';

/// 외부 지도 앱 연동 서비스
class NavigationService {
  static final NavigationService instance = NavigationService._init();

  NavigationService._init();

  /// 네이버 지도 앱으로 길찾기
  /// [destLat] 목적지 위도
  /// [destLng] 목적지 경도
  /// [destName] 목적지 이름
  Future<bool> openNaverMap({
    required double destLat,
    required double destLng,
    required String destName,
  }) async {
    // 네이버 지도 앱 URL Scheme
    final appUrl = Uri.parse(
      'nmap://route/public?'
      'dlat=$destLat&'
      'dlng=$destLng&'
      'dname=${Uri.encodeComponent(destName)}&'
      'appname=com.scenemap',
    );

    // 웹 폴백 URL
    final webUrl = Uri.parse(
      'https://map.naver.com/v5/directions/-,-,-/-,-,-/$destLng,$destLat',
    );

    return await _launchUrl(appUrl, webUrl);
  }

  /// 카카오맵 앱으로 길찾기
  Future<bool> openKakaoMap({
    required double destLat,
    required double destLng,
    required String destName,
  }) async {
    // 카카오맵 앱 URL Scheme
    final appUrl = Uri.parse(
      'kakaomap://route?'
      'ep=$destLat,$destLng&'
      'by=CAR',
    );

    // 웹 폴백 URL
    final webUrl = Uri.parse(
      'https://map.kakao.com/link/to/${Uri.encodeComponent(destName)},$destLat,$destLng',
    );

    return await _launchUrl(appUrl, webUrl);
  }

  /// 구글 지도 앱으로 길찾기
  Future<bool> openGoogleMap({
    required double destLat,
    required double destLng,
    required String destName,
  }) async {
    // 구글 지도 URL (앱이 설치되어 있으면 자동으로 앱이 열림)
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&'
      'destination=$destLat,$destLng&'
      'destination_place_id=${Uri.encodeComponent(destName)}',
    );

    return await _launchUrl(url, url);
  }

  /// URL 실행 (앱 URL 시도 후 실패하면 웹 URL로 폴백)
  Future<bool> _launchUrl(Uri appUrl, Uri webUrl) async {
    try {
      // 먼저 앱 URL 시도
      if (await canLaunchUrl(appUrl)) {
        return await launchUrl(
          appUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('앱 URL 실행 실패: $e');
    }

    // 앱 URL 실패 시 웹 URL로 폴백
    try {
      return await launchUrl(
        webUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('웹 URL 실행 실패: $e');
      return false;
    }
  }

  /// 사용자에게 지도 앱 선택 옵션 제공
  /// UI에서 바텀시트 등으로 표시할 옵션 목록
  List<NavigationOption> getNavigationOptions() {
    return [
      NavigationOption(
        name: '네이버 지도',
        icon: '🗺️',
        action: NavigationAction.naver,
      ),
      NavigationOption(
        name: '카카오맵',
        icon: '🚗',
        action: NavigationAction.kakao,
      ),
      NavigationOption(
        name: '구글 지도',
        icon: '🌍',
        action: NavigationAction.google,
      ),
    ];
  }

  /// 선택한 옵션으로 내비게이션 실행
  Future<bool> navigate({
    required NavigationAction action,
    required double destLat,
    required double destLng,
    required String destName,
  }) async {
    switch (action) {
      case NavigationAction.naver:
        return await openNaverMap(
          destLat: destLat,
          destLng: destLng,
          destName: destName,
        );
      case NavigationAction.kakao:
        return await openKakaoMap(
          destLat: destLat,
          destLng: destLng,
          destName: destName,
        );
      case NavigationAction.google:
        return await openGoogleMap(
          destLat: destLat,
          destLng: destLng,
          destName: destName,
        );
    }
  }
}

/// 내비게이션 옵션 모델
class NavigationOption {
  final String name;
  final String icon;
  final NavigationAction action;

  NavigationOption({
    required this.name,
    required this.icon,
    required this.action,
  });
}

/// 내비게이션 액션 타입
enum NavigationAction {
  naver,
  kakao,
  google,
}
