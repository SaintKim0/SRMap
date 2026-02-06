import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/location.dart';
import 'location_service.dart';
import 'preferences_service.dart';
import '../../data/repositories/location_repository.dart';
import '../../presentation/providers/location_provider.dart';

/// 근처 맛집 알림: 사용자 위치 반경(기본 500m, 설정 가능) 내 맛집이 있으면 알림 표시
class NearbyNotificationService {
  static final NearbyNotificationService instance = NearbyNotificationService._init();
  final _locationService = LocationService.instance;
  final _prefs = PreferencesService.instance;

  NearbyNotificationService._init();

  /// 앱 재개 시 홈에서 다시 근처 맛집 검사를 하려면 true로 설정
  static bool requestCheckOnNextBuild = false;

  static const Duration _throttleDuration = Duration(minutes: 1); // Debug: 1 minute

  /// 현재 위치 기준 반경 내 맛집(blackwhite, guide, show)이 있는지 검사 후 알림 표시.
  /// 기준: LocationService.getCurrentPosition() (실제 GPS, 하드코딩 없음) + 설정 반경(기본 500m).
  /// [forceShow] true면 1시간 제한 무시 (알림 다시보기용)
  /// [showEmptyMessage] true면 반경 내 맛집이 없을 때도 안내 메시지 표시
  Future<void> checkAndNotify(
    BuildContext context, {
    required List<Location> allLocations,
    VoidCallback? onTapShowOnMap,
    bool forceShow = false,
    bool showEmptyMessage = false,
    int? overrideRadiusMeters,
    String? sectorName,
    bool ignoreThrottle = false,
    String? targetMediaType,
  }) async {
    if (!forceShow && !ignoreThrottle && !_prefs.nearbyNotificationEnabled) return;
    if (!context.mounted) return;

    final position = await _locationService.getCurrentPosition();
    if (position == null || !context.mounted) {
      if (showEmptyMessage && context.mounted) {
        _showEmptySnackBar(context);
      }
      return;
    }

    final radiusMeters = overrideRadiusMeters ?? _prefs.notificationRadiusMeters;
    final radiusKm = radiusMeters / 1000.0;

    final tasteMapTypes = LocationRepository.tasteMapMediaTypes;
    final nearby = allLocations.where((loc) {
      if (loc.mediaType == null) return false;
      if (targetMediaType != null) {
        if (loc.mediaType!.toLowerCase() != targetMediaType.toLowerCase()) return false;
      } else if (!tasteMapTypes.contains(loc.mediaType!.toLowerCase())) {
        return false;
      }
      final distanceKm = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        loc.latitude,
        loc.longitude,
      );
      // Debug print for Lee Dubu-ya
      if (loc.name.contains('이두부야')) {
        print('[Notification] 이두부야 Distance: ${distanceKm}km (Radius: ${radiusKm}km)');
      }
      return distanceKm <= radiusKm;
    }).toList();

    print('[Notification] Nearby count: ${nearby.length} (Radius: ${radiusMeters}m)');

    if (nearby.isEmpty) {
      if (showEmptyMessage && context.mounted) {
        _showNoNearbySnackBar(context, radiusMeters);
      }
      return;
    }
    if (!context.mounted) return;

    // 같은 반경에서 1시간 이내에 이미 알림을 보여줬으면 스킵 (스팸 방지). 수동 다시보기는 제외
    if (!forceShow && !ignoreThrottle) {
      final lastTime = _prefs.lastNearbyNotificationTime;
      if (lastTime != null &&
          DateTime.now().difference(lastTime) < _throttleDuration) {
        return;
      }
    }

    await _prefs.setLastNearbyNotificationTime(DateTime.now());

    if (!context.mounted) return;
    // "보기" 탭 시 지도가 이 맛집들 + 내 위치를 같이 보이도록 저장 (알림 기준 위치와 실제 위치 불일치 대응)
    context.read<LocationDataProvider>().setNearbyNotificationLocations(nearby);
    _showNearbySnackBar(context, count: nearby.length, radiusMeters: radiusMeters, onTapShowOnMap: onTapShowOnMap, sectorName: sectorName);
  }

  void _showEmptySnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('위치를 가져올 수 없어요. 위치 권한을 확인해 주세요.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNoNearbySnackBar(BuildContext context, int radiusMeters) {
    final radiusText = radiusMeters >= 1000
        ? '${(radiusMeters / 1000).toStringAsFixed(1)}km'
        : '${radiusMeters}m';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('주변 $radiusText 이내에 맛집이 없어요.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNearbySnackBar(
    BuildContext context, {
    required int count,
    required int radiusMeters,
    VoidCallback? onTapShowOnMap,
    String? sectorName,
  }) {
    final radiusText = radiusMeters >= 1000
        ? '${(radiusMeters / 1000).toStringAsFixed(1)}km'
        : '${radiusMeters}m';
    
    final message = sectorName != null
        ? '주변 $radiusText 이내에 $sectorName 맛집 ${count}곳이 있어요!'
        : '주변 $radiusText 이내에 맛집 ${count}곳이 있어요!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(child: Text(message)),
            if (onTapShowOnMap != null)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onTapShowOnMap();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('보기', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              tooltip: '닫기',
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
