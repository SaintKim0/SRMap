import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../providers/location_provider.dart';
import '../providers/location_provider_service.dart';
import '../providers/bottom_navigation_provider.dart';
import '../../data/models/location.dart';
import '../../data/services/location_service.dart';
import '../../data/services/map_service.dart';
import '../../data/services/navigation_service.dart';
import '../../data/services/naver_maps_api_service.dart';
import 'location_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  NaverMapController? _mapController;
  Position? _currentPosition;
  final _mapService = MapService.instance;
  final _locationService = LocationService.instance;
  final _navigationService = NavigationService.instance;
  final _mapsApiService = NaverMapsApiService.instance;
  
  String? _selectedCategory;
  bool _hasLoadedData = false;
  final Set<String> _currentMarkerIds = {};
  bool _isUpdatingMarkers = false;
  
  // Single Location Mode
  bool _isSingleViewMode = false;
  Location? _singleModeLocation;
  
  // Visible List Mode
  List<Location> _visibleLocations = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      Future.microtask(() {
        if (mounted) {
          context.read<LocationDataProvider>().loadAllLocations();
          _getCurrentLocation();
        }
      });
    }
  }

  /// 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
  }

  /// 지도 준비 완료 콜백
  void _onMapReady(NaverMapController controller) {
    _mapController = controller;
    final provider = context.read<LocationDataProvider>();
    
    // 1. Priority 1: Check if there is a focused location from detail screen
    if (provider.focusedLocation != null) {
      final location = provider.focusedLocation!;
      _singleModeLocation = location;
      _isSingleViewMode = true; // Enable single view mode
      
      _mapController!.updateCamera(
        _mapService.moveCameraTo(
          latitude: location.latitude,
          longitude: location.longitude,
          zoom: 16.0,
        ),
      );
      
      // Clear focused location
      provider.setFocusedLocation(null);
    } 
    // 2. Priority 2: "내 주변 맛집 보기" 또는 알림 "보기" 진입
    else if (provider.requestMoveToMyLocation) {
      provider.clearMoveToMyLocationRequest();
      final nearbyList = provider.nearbyNotificationLocations;
      provider.clearNearbyNotificationLocations();
      if (nearbyList != null && nearbyList.isNotEmpty) {
        _moveToCurrentLocationAndFitNearby(nearbyList);
      } else {
        _moveToCurrentLocation();
      }
    } 
    // 3. Priority 3: Default entry - move to current location
    else {
      final locProv = context.read<LocationProvider>();
      if (locProv.hasLocation) {
         _moveToCurrentLocation();
      } else {
        _moveToCurrentLocation();
      }
    }

    // Initial update
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _updateVisibleMarkers();
    });
  }

  /// 카메라 유휴 상태 (이동 멈춤) 콜백
  void _onCameraIdle() {
    _updateVisibleMarkers();
  }

  /// 화면에 보이는 마커 업데이트
  Future<void> _updateVisibleMarkers() async {
    if (_mapController == null || _isUpdatingMarkers || !mounted) return;

    try {
      _isUpdatingMarkers = true;
      
      List<Location> visibleLocations = [];

      if (_isSingleViewMode && _singleModeLocation != null) {
         // In Single View Mode, only show the target location
         visibleLocations = [_singleModeLocation!];
      } else {
        // Normal Mode: Viewport filtering
        final bounds = await _mapController!.getContentBounds();
        final provider = context.read<LocationDataProvider>();
        final allLocations = provider.allLocations;
        
        visibleLocations = allLocations.where((loc) {
          if (_selectedCategory != null && loc.category != _selectedCategory) return false;
          return bounds.containsPoint(NLatLng(loc.latitude, loc.longitude));
        }).toList();
      }
      
      setState(() {
        _visibleLocations = visibleLocations;
      });

      // 3. Update markers on map
      await _updateMarkersOnMap(visibleLocations);
      
    } catch (e) {
      print('Error updating visible markers: $e');
    } finally {
      _isUpdatingMarkers = false;
    }
  }

  /// 마커 델타 업데이트 (추가/삭제)
  Future<void> _updateMarkersOnMap(List<Location> visibleLocations) async {
    if (_mapController == null) return;

    final newResults = visibleLocations;
    final Set<String> newIds = newResults.map((e) => e.id).toSet();

    // A. Remove markers that are no longer visible
    final toRemove = _currentMarkerIds.difference(newIds);
    for (final id in toRemove) {
      // Note: deleteOverlay requires NOverlayInfo. We construct it assuming marker type.
      _mapController!.deleteOverlay(NOverlayInfo(type: NOverlayType.marker, id: id));
    }

    // B. Add new markers
    final toAddIds = newIds.difference(_currentMarkerIds);
    final Set<NAddableOverlay> overlaysToAdd = {};

    for (final id in toAddIds) {
      final location = newResults.firstWhere((e) => e.id == id);
      
      final markerAsset = _mapService.getMarkerAssetForLocation(location);
      
      final marker = _mapService.createMarker(
        id: location.id,
        latitude: location.latitude,
        longitude: location.longitude,
        caption: location.name,
        icon: NOverlayImage.fromAssetImage(markerAsset),
        size: const NSize(30, 30), // Using 1:1 square ratio for circular markers
      );

      // Using distinctive color for single mode target? Optional.
      if (_isSingleViewMode && location.id == _singleModeLocation?.id) {
         marker.setCaption(NOverlayCaption(text: location.name, color: Colors.indigo, textSize: 14));
      }

      // Listener
      marker.setOnTapListener((overlay) {
        _showLocationBottomSheet(location);
      });

      overlaysToAdd.add(marker);
    }

    if (overlaysToAdd.isNotEmpty) {
      await _mapController!.addOverlayAll(overlaysToAdd);
    }

    // Update current tracking set
    _currentMarkerIds.clear();
    _currentMarkerIds.addAll(newIds);
  }

  /// 현재 위치로 카메라 이동
  void _moveToCurrentLocation() async {
    final locProv = context.read<LocationProvider>();
    
    if (!locProv.hasLocation) {
      await locProv.getCurrentLocation();
    }
    
    final position = locProv.currentPosition;
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 위치를 가져올 수 없습니다')),
        );
      }
      return;
    }

    setState(() {
      _currentPosition = position;
    });

    if (_mapController != null) {
      final cameraUpdate = _mapService.moveCameraToCurrentLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _mapController!.updateCamera(cameraUpdate);
    }
  }

  /// 알림 "보기" 진입: 내 위치 + 알림에서 찾은 맛집들이 모두 보이도록 bounds 맞춤 (알림 2곳이 지도에 보이도록)
  Future<void> _moveToCurrentLocationAndFitNearby(List<Location> nearby) async {
    final position = await _locationService.getCurrentPosition();
    if (position == null || _mapController == null) {
      if (mounted && position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 위치를 가져올 수 없습니다')),
        );
      }
      if (position != null) _moveToCurrentLocation();
      return;
    }

    setState(() {
      _currentPosition = position;
    });

    final points = <NLatLng>[
      NLatLng(position.latitude, position.longitude),
      ...nearby.map((loc) => NLatLng(loc.latitude, loc.longitude)),
    ];
    final cameraUpdate = _mapService.getCameraUpdateForMarkers(points);
    _mapController!.updateCamera(cameraUpdate);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _updateVisibleMarkers();
    });
  }

  /// 맛집 정보 바텀시트 표시
  void _showLocationBottomSheet(Location location) async {
    String? distanceText;
    if (_currentPosition != null) {
      final distance = _locationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        location.latitude,
        location.longitude,
      );
      distanceText = _locationService.formatDistance(distance);
    }

    // Reverse Geocoding으로 좌표를 주소로 변환
    String? reverseGeocodedAddress;
    try {
      reverseGeocodedAddress = await _mapsApiService.reverseGeocode(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (e) {
      print('Reverse Geocoding 실패: $e');
    }
    
    if (!mounted) return;

    final horizontalPadding = AppSpacing.bottomSheetPadding(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            horizontalPadding,
            horizontalPadding,
            horizontalPadding + 8,
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (location.contentTitle != null && location.contentTitle!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                location.contentTitle!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
            // Parse and display details from description (e.g. Episode info)
            if (location.description != null && location.description!.contains('\n')) ...[
               Builder(
                 builder: (context) {
                   final parts = location.description!.split('\n');
                   if (parts.length > 1) {
                     final details = parts.sublist(1).join('\n').trim();
                     if (details.isNotEmpty) {
                       return Padding(
                         padding: const EdgeInsets.only(top: 3.0),
                         child: Text(
                           details,
                           style: Theme.of(context).textTheme.bodySmall?.copyWith(
                             color: Colors.grey[700],
                             fontSize: 11,
                           ),
                           maxLines: 2,
                           overflow: TextOverflow.ellipsis,
                         ),
                       );
                     }
                   }
                   return const SizedBox.shrink();
                 }
               ),
            ],
            const SizedBox(height: 6),
            Text(
              location.address,
              style: TextStyle(color: Colors.grey[700], fontSize: 11),
            ),
            if (distanceText != null) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.location_on, size: 12, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    '현재 위치에서 $distanceText',
                    style: TextStyle(color: Colors.grey[700], fontSize: 11),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationDetailScreen(
                            locationId: location.id,
                            previewLocation: location,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('상세보기', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showNavigationOptions(location);
                    },
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('길찾기', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// 내비게이션 앱 선택 바텀시트
  void _showNavigationOptions(Location location) {
    final options = _navigationService.getNavigationOptions();
    final pad = AppSpacing.bottomSheetPadding(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + safeBottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '지도 앱 선택',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((option) => ListTile(
                    dense: true,
                    leading: Text(
                      option.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(
                      option.name,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final success = await _navigationService.navigate(
                        action: option.action,
                        destLat: location.latitude,
                        destLng: location.longitude,
                        destName: location.name,
                      );

                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${option.name} 실행에 실패했습니다'),
                          ),
                        );
                      }
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        centerTitle: true,
        title: Text(
          _isSingleViewMode ? _singleModeLocation?.name ?? '지도' : '맛집 지도',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isSingleViewMode) {
              // Exit single view mode on back
              setState(() {
                _isSingleViewMode = false;
                _singleModeLocation = null;
              });
              _updateVisibleMarkers();
            } else {
              // Navigate back to previous screen or home if no previous screen
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // If no previous screen, navigate to home tab
                final bottomNavProvider = context.read<BottomNavigationProvider>();
                bottomNavProvider.setIndex(0);
              }
            }
          },
        ),
        actions: [
          if (!_isSingleViewMode)
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (category) {
              setState(() {
                _selectedCategory = category == 'all' ? null : category;
              });
              // 필터 변경 시 즉시 업데이트
              _updateVisibleMarkers();
            },
            itemBuilder: (context) => [
              // ... menu items
              const PopupMenuItem(value: 'all', child: Text('전체')),
              const PopupMenuItem(value: 'cafe', child: Text('카페')),
              const PopupMenuItem(value: 'restaurant', child: Text('식당')),
              const PopupMenuItem(value: 'park', child: Text('공원')),
              const PopupMenuItem(value: 'building', child: Text('건물')),
              const PopupMenuItem(value: 'street', child: Text('거리')),
            ],
          ),
        ],
      ),
      body: Consumer<LocationDataProvider>(
        builder: (context, provider, child) {
          // "내 주변 맛집 보기" 또는 알림 "보기"로 진입했고 지도가 이미 준비된 경우
          if (provider.requestMoveToMyLocation && _mapController != null) {
            provider.clearMoveToMyLocationRequest();
            final nearbyList = provider.nearbyNotificationLocations;
            provider.clearNearbyNotificationLocations();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                if (nearbyList != null && nearbyList.isNotEmpty) {
                  _moveToCurrentLocationAndFitNearby(nearbyList);
                } else {
                  _moveToCurrentLocation();
                }
              }
            });
          }

          // ... loading/error logic
          if (provider.isLoading && provider.allLocations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.allLocations.isEmpty) {
             // ... error view
            return Center(child: Text(provider.error!)); 
          }

          return Stack(
            children: [
              // 네이버 지도
              NaverMap(
                options: _mapService.getDefaultMapOptions(),
                onMapReady: _onMapReady,
                onCameraIdle: _onCameraIdle,
              ),
              
              // Single View Mode Button: "Show Nearby"
              if (_isSingleViewMode)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        setState(() {
                          _isSingleViewMode = false;
                        });
                        // Update to show nearby markers (viewport filtering will kick in)
                        _updateVisibleMarkers();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('주변 맛집을 검색합니다'), duration: Duration(seconds: 1)),
                        );
                      },
                      label: const Text('주변 맛집 보기'),
                      icon: const Icon(Icons.manage_search),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              // 현재 위치 버튼 (only in normal mode or top right)
              if (!_isSingleViewMode) ...[
                // List View Button
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0, 
                  child: Center(
                    child: FloatingActionButton.extended(
                      heroTag: 'list_view_fab',
                      onPressed: _showListBottomSheet,
                      label: const Text('목록으로 보기'),
                      icon: const Icon(Icons.list),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                
                // Current Location Button
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    heroTag: 'my_location_fab',
                    onPressed: _moveToCurrentLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// 현재 보이는 마커 리스트 바텀시트
  void _showListBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.bottomSheetPadding(context),
                  vertical: AppSpacing.spacingS(context),
                ),
                child: Row(
                  children: [
                    Text(
                      '현재 지도에 보이는 맛집',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_visibleLocations.length}곳',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              
              // List
              Expanded(
                child: _visibleLocations.isEmpty
                    ? const Center(child: Text('보이는 맛집이 없습니다'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _visibleLocations.length,
                        itemBuilder: (context, index) {
                          final location = _visibleLocations[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: location.imageUrls.isNotEmpty
                                  ? Image.network(
                                      location.imageUrls.first,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.movie, size: 20, color: Colors.grey),
                                    ),
                            ),
                            title: Text(
                              location.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (location.contentTitle != null)
                                  Text(
                                    location.contentTitle!,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                Text(
                                  location.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () {
                                _showLocationBottomSheet(location);
                              },
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _mapController?.updateCamera(
                                _mapService.moveCameraTo(
                                  latitude: location.latitude,
                                  longitude: location.longitude,
                                  zoom: 16,
                                ),
                              );
                              // Trigger showing bottom sheet after move? 
                              // Optional: Future.delayed(...)
                              _showLocationBottomSheet(location);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
