import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/models/location.dart';
import '../providers/location_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/visited_provider.dart';
import '../providers/recent_viewed_provider.dart';
import '../providers/bottom_navigation_provider.dart';
import '../../data/services/navigation_service.dart';
import '../../data/services/image_service.dart';
import '../../data/services/preferences_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationDetailScreen extends StatefulWidget {
  final String locationId;
  final Location? previewLocation;
  final String? heroTag;

  const LocationDetailScreen({
    super.key,
    required this.locationId,
    this.previewLocation,
    this.heroTag,
  });

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  Location? _location;
  int _currentImageIndex = 0;
  List<String> _fetchedImages = [];
  /// 로드 실패한 URL은 갤러리에서 제거
  final Set<String> _failedImageUrls = {};
  /// "이 장소와 맞지 않음"으로 사용자가 숨긴 URL (장소별, prefs에서 로드)
  Set<String> _rejectedImageUrls = {};
  bool _isLoadingImages = false;
  final _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    if (widget.previewLocation != null) {
      _location = widget.previewLocation;
      _loadImagesIfNeeded();
    }
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final location = await context
        .read<LocationDataProvider>()
        .getLocationById(widget.locationId);
    
    if (location != null && mounted) {
      setState(() {
        _location = location;
        _rejectedImageUrls = PreferencesService.instance.getRejectedImageUrls(location.id).toSet();
      });
      // Increment view count
      context.read<LocationDataProvider>().incrementViewCount(widget.locationId);
      // 최근 본 촬영지에 추가
      context.read<RecentViewedProvider>().addRecentViewed(widget.locationId);
      // 이미지가 없으면 공공 API에서 가져오기
      _loadImagesIfNeeded();
    }
  }

  /// 이미지가 없을 경우 공공 API에서 이미지 가져오기
  Future<void> _loadImagesIfNeeded() async {
    if (_location == null) return;
    
    // 이미 이미지가 있으면 스킵
    if (_location!.imageUrls.isNotEmpty) return;
    
    if (mounted) {
      setState(() {
        _isLoadingImages = true;
      });
    }

    try {
      final images = await _imageService.searchImagesForLocation(
        locationName: _location!.name,
        address: _location!.address,
        locationId: _location!.id,
        maxResults: 20,
      );

      if (mounted && images.isNotEmpty) {
        setState(() {
          _fetchedImages = images;
          _isLoadingImages = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      print('이미지 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingImages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_location == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    // ... existing Scaffold code ...
    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildRelatedContentSection(),
                _buildAddressSection(),
                _buildDetailInfoSection(),
                const SizedBox(height: 80), // Space for bottom buttons
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageGallery(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // TODO: Implement share
          },
        ),
      ],
    );
  }

  void _openFullScreenImage(BuildContext context, List<String> urls, int initialIndex) {
    if (urls.isEmpty || _location == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => _FullScreenImageView(
          imageUrls: urls,
          initialIndex: initialIndex.clamp(0, urls.length - 1),
          locationId: _location!.id,
          onRejectedImage: (url) async {
            await PreferencesService.instance.addRejectedImageUrl(_location!.id, url);
            if (mounted) setState(() => _rejectedImageUrls.add(url));
          },
        ),
      ),
    );
  }

  void _onImageLoadFailed(String url) {
    if (!_failedImageUrls.contains(url) && mounted) {
      final allImages = [..._location!.imageUrls, ..._fetchedImages];
      final currentUrl = allImages.length > _currentImageIndex
          ? allImages[_currentImageIndex]
          : null;
      setState(() {
        _failedImageUrls.add(url);
        final displayed = allImages.where((u) => !_failedImageUrls.contains(u)).toList();
        if (currentUrl != null && !_failedImageUrls.contains(currentUrl)) {
          final newIndex = displayed.indexOf(currentUrl);
          _currentImageIndex = newIndex >= 0 ? newIndex : 0;
        } else {
          _currentImageIndex = _currentImageIndex >= displayed.length
              ? displayed.length > 0 ? displayed.length - 1 : 0
              : _currentImageIndex.clamp(0, displayed.length - 1);
        }
      });
    }
  }

  Widget _buildImageGallery() {
    final allImages = [
      ..._location!.imageUrls,
      ..._fetchedImages,
    ];
    final displayedImages = allImages
        .where((u) => !_failedImageUrls.contains(u) && !_rejectedImageUrls.contains(u))
        .toList();

    if (displayedImages.isEmpty) {
      if (_isLoadingImages) {
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      final placeholderUrl = _getPlaceholderUrl(_location?.mediaType);
      return Stack(
        children: [
          SizedBox.expand(
            child: CachedNetworkImage(
              imageUrl: placeholderUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_outlined, size: 48, color: Colors.white.withOpacity(0.9)),
                const SizedBox(height: 12),
                const Text(
                  '이미지 준비 중',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: displayedImages.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final imageUrl = displayedImages[index];
            Widget imageWidget;
            
            if (imageUrl.startsWith('http')) {
              imageWidget = CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) {
                  if (url != null && url.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _onImageLoadFailed(url));
                  }
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image, size: 64, color: Colors.grey),
                    ),
                  );
                },
              );
            } else {
              imageWidget = Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _onImageLoadFailed(imageUrl));
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image, size: 64, color: Colors.grey),
                    ),
                  );
                },
              );
            }
            
            Widget child = index == 0
                ? Hero(
                    tag: widget.heroTag ?? 'location_img_${_location!.id}',
                    child: imageWidget,
                  )
                : imageWidget;
            return GestureDetector(
              onTap: () => _openFullScreenImage(context, displayedImages, index),
              child: child,
            );
          },
        ),
        if (displayedImages.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: displayedImages.length <= 10
                  ? List.generate(
                      displayedImages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    )
                  : [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${displayedImages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    final screenH = AppSpacing.screenPaddingHorizontal(context);
    final iconS = AppSpacing.iconSizeM(context);
    return Padding(
      padding: EdgeInsets.all(screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _location!.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppSpacing.spacingS(context)),
          Row(
            children: [
              Icon(Icons.category, size: iconS, color: Colors.grey[600]),
              SizedBox(width: AppSpacing.spacingXS(context)),
              Text(
                _getCategoryName(_location!.category),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(width: AppSpacing.spacingM(context)),
              Icon(Icons.remove_red_eye, size: iconS, color: Colors.grey[600]),
              SizedBox(width: AppSpacing.spacingXS(context)),
              Text(
                '${_location!.viewCount}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(width: AppSpacing.spacingS(context)),
              Icon(Icons.bookmark, size: iconS, color: Colors.grey[600]),
              SizedBox(width: AppSpacing.spacingXS(context)),
              Text(
                '${_location!.bookmarkCount}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      margin: AppSpacing.getCardMargin(context),
      child: Padding(
        padding: AppSpacing.getCardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _location!.address,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 앱 내 지도 보기 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Set focused location for map
                  context.read<LocationDataProvider>().setFocusedLocation(_location);
                  
                  // Switch to map tab
                  context.read<BottomNavigationProvider>().setIndex(1);
                  
                  // Close detail screen and return to main screen (clearing navigation stack)
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: Icon(Icons.map, size: AppSpacing.iconSizeS(context)),
                label: const Text('앱 지도에서 보기', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 외부 지도 앱 연결
            Text(
              '외부 지도 앱에서 보기',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildExternalMapButton(
                    '네이버맵',
                    Icons.map_outlined,
                    const Color(0xFF03C75A), // 네이버 진한 녹색
                    Colors.white, // 흰색 텍스트
                    _openNaverMap,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildExternalMapButton(
                    '카카오맵',
                    Icons.navigation,
                    Colors.yellow.shade700, // 노란색 배경
                    const Color(0xFF03C75A), // 진한 녹색 텍스트
                    _openKakaoMap,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildExternalMapButton(
                    '구글맵',
                    Icons.map,
                    const Color(0xFF4285F4), // 구글 짙은 파란색
                    Colors.white, // 흰색 텍스트
                    _openGoogleMap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalMapButton(
    String label,
    IconData icon,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    const double fontSize = 11;
    const EdgeInsets btnPadding = EdgeInsets.symmetric(vertical: 6, horizontal: 8);
    final iconSize = AppSpacing.iconSizeS(context) * 0.9;
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize, color: textColor),
        label: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: btnPadding,
          minimumSize: Size.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 1,
        ),
      ),
    );
  }

  /// 네이버맵 열기 — 1순위 장소명+시·군, 안 되면 2순위 상세주소
  Future<void> _openNaverMap() async {
    final address = _location!.address.trim();
    final queryByAddress = address.isNotEmpty ? address : null;
    final cityDistrict = _extractCityDistrict(address);
    final queryByNameDistrict = cityDistrict.isNotEmpty
        ? '${_location!.name} $cityDistrict'
        : _location!.name;
    final searchQuery = queryByNameDistrict;

    final naverMapSearchUrl = Uri(
      scheme: 'nmap',
      host: 'search',
      queryParameters: {'query': searchQuery},
    );
    final naverMapWebUrl = Uri.parse('https://map.naver.com/v5/search/${Uri.encodeComponent(searchQuery)}');

    try {
      if (await canLaunchUrl(naverMapSearchUrl)) {
        await launchUrl(naverMapSearchUrl, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(naverMapWebUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (queryByAddress != null && queryByAddress != searchQuery) {
        try {
          final fallbackUrl = Uri(
            scheme: 'nmap',
            host: 'search',
            queryParameters: {'query': queryByAddress},
          );
          if (await canLaunchUrl(fallbackUrl)) {
            await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
            return;
          }
          await launchUrl(
            Uri.parse('https://map.naver.com/v5/search/${Uri.encodeComponent(queryByAddress)}'),
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          await launchUrl(naverMapWebUrl, mode: LaunchMode.externalApplication);
        }
      } else {
        await launchUrl(naverMapWebUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// 주소에서 시/군/구 추출
  String _extractCityDistrict(String address) {
    // 주소에서 시/군/구 추출
    // 예: "충청남도 홍성군 홍성읍..." -> "홍성군"
    // 예: "서울특별시 강남구..." -> "강남구"
    // 예: "경기도 수원시 영통구..." -> "수원시 영통구"
    
    final parts = address.split(' ');
    if (parts.isEmpty) return '';
    
    // 첫 번째 부분이 도/시인 경우
    if (parts[0].endsWith('도') || parts[0].endsWith('시')) {
      // 두 번째 부분이 시/군/구인 경우
      if (parts.length > 1 && (parts[1].endsWith('시') || 
                                parts[1].endsWith('군') || 
                                parts[1].endsWith('구'))) {
        // 세 번째 부분도 구인 경우 (예: "경기도 수원시 영통구")
        if (parts.length > 2 && parts[2].endsWith('구')) {
          return '${parts[1]} ${parts[2]}';
        }
        return parts[1];
      }
      // 첫 번째 부분만 반환 (예: "서울특별시")
      return parts[0];
    }
    
    // 첫 번째 부분이 시/군/구인 경우
    if (parts[0].endsWith('시') || parts[0].endsWith('군') || parts[0].endsWith('구')) {
      return parts[0];
    }
    
    // 두 번째 부분이 시/군/구인 경우
    if (parts.length > 1 && (parts[1].endsWith('시') || 
                              parts[1].endsWith('군') || 
                              parts[1].endsWith('구'))) {
      return parts[1];
    }
    
    // 추출 실패 시 빈 문자열 반환
    return '';
  }

  /// 카카오맵 열기 — 1순위 장소명+시·군, 안 되면 2순위 상세주소
  Future<void> _openKakaoMap() async {
    final lat = _location!.latitude;
    final lng = _location!.longitude;
    final address = _location!.address.trim();
    final queryByAddress = address.isNotEmpty ? address : null;
    final cityDistrict = _extractCityDistrict(address);
    final queryByNameDistrict = cityDistrict.isNotEmpty
        ? '${_location!.name} $cityDistrict'
        : _location!.name;
    final searchQuery = queryByNameDistrict;

    final kakaoMapSearchUrl = Uri(
      scheme: 'kakaomap',
      host: 'search',
      queryParameters: {'q': searchQuery},
    );
    final kakaoMapPlaceUrl = Uri(
      scheme: 'kakaomap',
      host: 'place',
      queryParameters: {
        'name': _location!.name,
        'x': lng.toString(),
        'y': lat.toString(),
      },
    );
    final kakaoMapWebUrl = Uri.parse('https://map.kakao.com/link/search/${Uri.encodeComponent(searchQuery)}');

    try {
      if (await canLaunchUrl(kakaoMapSearchUrl)) {
        await launchUrl(kakaoMapSearchUrl, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(kakaoMapPlaceUrl)) {
        await launchUrl(kakaoMapPlaceUrl, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(kakaoMapWebUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (queryByAddress != null && queryByAddress != searchQuery) {
        try {
          final fallbackSearchUrl = Uri(
            scheme: 'kakaomap',
            host: 'search',
            queryParameters: {'q': queryByAddress},
          );
          if (await canLaunchUrl(fallbackSearchUrl)) {
            await launchUrl(fallbackSearchUrl, mode: LaunchMode.externalApplication);
            return;
          }
          await launchUrl(
            Uri.parse('https://map.kakao.com/link/search/${Uri.encodeComponent(queryByAddress)}'),
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          await launchUrl(kakaoMapWebUrl, mode: LaunchMode.externalApplication);
        }
      } else {
        await launchUrl(kakaoMapWebUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// 구글맵 열기 — 1순위 장소명+시·군, 안 되면 2순위 상세주소
  Future<void> _openGoogleMap() async {
    final lat = _location!.latitude;
    final lng = _location!.longitude;
    final address = _location!.address.trim();
    final queryByAddress = address.isNotEmpty ? address : null;
    final cityDistrict = _extractCityDistrict(address);
    final queryByNameDistrict = cityDistrict.isNotEmpty
        ? '${_location!.name} $cityDistrict'
        : _location!.name;
    final searchQuery = queryByNameDistrict;
    
    // 구글맵 URL (1순위: 장소명+시·군)
    // Uri 생성자를 사용하여 자동 인코딩 처리
    final googleMapSearchUrl = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/search/',
      queryParameters: {
        'api': '1',
        'query': searchQuery,
      },
    );
    
    // 앱용 URL (geo 스킴)
    final googleMapAppUrl = Uri(
      scheme: 'geo',
      path: '$lat,$lng',
      queryParameters: {'q': searchQuery},
    );
    
    // 좌표만 사용 (폴백)
    final googleMapCoordUrl = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/search/',
      queryParameters: {
        'api': '1',
        'query': '$lat,$lng',
      },
    );
    
    try {
      if (await canLaunchUrl(googleMapSearchUrl)) {
        await launchUrl(googleMapSearchUrl, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(googleMapAppUrl)) {
        await launchUrl(googleMapAppUrl, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(googleMapCoordUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (queryByAddress != null && queryByAddress != searchQuery) {
        try {
          final fallbackSearchUrl = Uri(
            scheme: 'https',
            host: 'www.google.com',
            path: '/maps/search/',
            queryParameters: {'api': '1', 'query': queryByAddress},
          );
          final fallbackAppUrl = Uri(
            scheme: 'geo',
            path: '$lat,$lng',
            queryParameters: {'q': queryByAddress},
          );
          if (await canLaunchUrl(fallbackSearchUrl)) {
            await launchUrl(fallbackSearchUrl, mode: LaunchMode.externalApplication);
            return;
          }
          if (await canLaunchUrl(fallbackAppUrl)) {
            await launchUrl(fallbackAppUrl, mode: LaunchMode.externalApplication);
            return;
          }
        } catch (_) {}
      }
      await launchUrl(googleMapCoordUrl, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildRelatedContentSection() {
    final isRestaurantInfo = _location!.mediaType == 'blackwhite' || _location!.mediaType == 'guide';
    final sectionTitle = isRestaurantInfo ? '레스토랑 정보' : '촬영 정보';
    final emptyMessage = isRestaurantInfo ? '레스토랑 정보를 불러올 수 없습니다.' : '촬영 정보를 불러올 수 없습니다.';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.movie, color: Colors.purple, size: AppSpacing.iconSizeS(context)),
                const SizedBox(width: 8),
                Text(
                  sectionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _location!.description ?? emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfoSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue, size: 18),
                const SizedBox(width: 6),
                Text(
                  '상세 정보',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_location!.phoneNumber != null) ...[
              _buildInfoRow(
                Icons.phone,
                '전화번호',
                _location!.phoneNumber!,
                onTap: () => _launchPhone(_location!.phoneNumber!),
              ),
              const Divider(),
            ],
            if (_location!.website != null) ...[
              _buildInfoRow(
                Icons.language,
                '웹사이트',
                _location!.website!,
                onTap: () => _launchUrl(_location!.website!),
              ),
              const Divider(),
            ],
            if (_location!.openingHours != null) ...[
              _buildInfoRow(
                Icons.access_time,
                '영업시간',
                _location!.openingHours!,
              ),
              const Divider(),
            ],
            if (_location!.parking != null) ...[
              _buildInfoRow(
                Icons.local_parking,
                '주차',
                _location!.parking!,
              ),
              const Divider(),
            ],
            if (_location!.transportation != null) ...[
              _buildInfoRow(
                Icons.directions_transit,
                '대중교통',
                _location!.transportation!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  static const EdgeInsets _compactButtonPadding = EdgeInsets.symmetric(vertical: 5, horizontal: 6);

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ElevatedButton.icon(
                  onPressed: () => _launchMaps(),
                  icon: Icon(Icons.directions, size: AppSpacing.buttonIconSize(context) * 0.85),
                  label: const Text('길찾기', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    padding: _compactButtonPadding,
                    minimumSize: Size.zero,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Consumer<BookmarkProvider>(
                  builder: (context, provider, child) {
                    final isBookmarked = provider.isBookmarked(_location!.id);
                    return OutlinedButton.icon(
                      onPressed: () {
                        provider.toggleBookmark(_location!.id).then((success) {
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isBookmarked ? '저장이 해제되었습니다' : '저장되었습니다',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        });
                      },
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        size: AppSpacing.buttonIconSize(context) * 0.85,
                        color: isBookmarked ? Theme.of(context).primaryColor : null,
                      ),
                      label: Text(
                        isBookmarked ? '저장됨' : '저장',
                        style: const TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: _compactButtonPadding,
                        minimumSize: Size.zero,
                        side: isBookmarked ? BorderSide(color: Theme.of(context).primaryColor) : null,
                        foregroundColor: isBookmarked ? Theme.of(context).primaryColor : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Consumer<VisitedProvider>(
                  builder: (context, provider, child) {
                    final isVisited = provider.isVisited(_location!.id);
                    return OutlinedButton.icon(
                      onPressed: () {
                        provider.toggleVisited(_location!.id).then((success) {
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isVisited ? '방문 기록이 해제되었습니다' : '다녀온 곳에 추가되었습니다',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        });
                      },
                      icon: Icon(
                        isVisited ? Icons.check_circle : Icons.check_circle_outline,
                        size: AppSpacing.buttonIconSize(context) * 0.85,
                        color: isVisited ? Theme.of(context).primaryColor : null,
                      ),
                      label: Text(
                        isVisited ? '다녀왔어요' : '다녀온 곳',
                        style: const TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: _compactButtonPadding,
                        minimumSize: Size.zero,
                        side: isVisited ? BorderSide(color: Theme.of(context).primaryColor) : null,
                        foregroundColor: isVisited ? Theme.of(context).primaryColor : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'cafe':
        return '카페';
      case 'restaurant':
        return '식당';
      case 'park':
        return '공원';
      case 'building':
        return '건물';
      case 'street':
        return '거리';
      default:
        return category;
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchMaps() {
    final navigationService = NavigationService.instance;
    final options = navigationService.getNavigationOptions();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
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
                    final success = await navigationService.navigate(
                      action: option.action,
                      destLat: _location!.latitude,
                      destLng: _location!.longitude,
                      destName: _location!.name,
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

  String _getPlaceholderUrl(String? mediaType) {
    switch (mediaType?.toLowerCase()) {
      case 'blackwhite':
        // Professional kitchen / Intense atmosphere (Unsplash)
        return 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&q=80&w=1200';
      case 'guide':
        // Luxury fine dining interior (Unsplash)
        return 'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&q=80&w=1200';
      case 'show':
      case 'artist':
        // Authentic local traditional K-dining (Unsplash) - Working from previous session
        return 'https://images.unsplash.com/photo-1590301157890-4810ed352733?auto=format&fit=crop&q=80&w=1200';
      default:
        // Generic elegant restaurant (Unsplash)
        return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=1200';
    }
  }

}

/// 갤러리 이미지 탭 시 전체 화면 확대 보기 (핀치 줌, 좌우 스와이프)
class _FullScreenImageView extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String locationId;
  final void Function(String url) onRejectedImage;

  const _FullScreenImageView({
    required this.imageUrls,
    required this.initialIndex,
    required this.locationId,
    required this.onRejectedImage,
  });

  @override
  State<_FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<_FullScreenImageView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _reportWrongImage() {
    if (_currentIndex >= 0 && _currentIndex < widget.imageUrls.length) {
      final url = widget.imageUrls[_currentIndex];
      widget.onRejectedImage(url);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            onPressed: _reportWrongImage,
            icon: const Icon(Icons.report_outlined, size: 18, color: Colors.white70),
            label: const Text('이 장소와 맞지 않음', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final url = widget.imageUrls[index];
          Widget image;
          if (url.startsWith('http')) {
            image = CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white54)),
              errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.white54)),
            );
          } else {
            image = Image.asset(url, fit: BoxFit.contain);
          }
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(child: image),
          );
        },
      ),
    );
  }
}
