import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../data/models/location.dart'; // Ensure Location type is available
import '../../core/constants/app_spacing.dart';
import '../../data/services/nearby_notification_service.dart';
import '../../data/services/preferences_service.dart';
import '../providers/bookmark_provider.dart';
import '../providers/bottom_navigation_provider.dart';
import '../providers/location_provider.dart'; // LocationDataProvider
import '../providers/location_provider_service.dart'; // LocationProvider (for currentPosition)
import '../widgets/location_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'location_list_screen.dart';
import 'location_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _sectorNearbyOnly = true; // Default to showing nearby 5km
  
  // Radius Filter
  double _selectedRadius = 5.0; // Default 5km

  bool _showTopButton = false;
  bool _nearCheckScheduled = false;
  bool _nearbyNotificationCheckScheduled = false;
  bool _appIntroExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _showTopButton = _scrollController.offset > 300;
        });
      }
    });
    // Load data when screen initializes
    Future.microtask(() async {
      context.read<LocationDataProvider>().loadContentTitles();
      context.read<LocationDataProvider>().loadPopularLocations();
      context.read<LocationDataProvider>().loadRecentLocations();
      
      // Auto-fetch location if permission is already granted
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
           final position = await Geolocator.getCurrentPosition(
             timeLimit: const Duration(seconds: 5),
           );
           if (mounted) {
             context.read<LocationProvider>().updateCurrentPosition(position);
           }
        }
      } catch (e) {
        debugPrint('Auto-location fetch failed: $e');
      }
    });
  }

  void _scheduleNearBookmarkCheck(BuildContext context) {
    if (_nearCheckScheduled) return;
    _nearCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () async {
        if (!context.mounted) return;
        final name = await context.read<BookmarkProvider>().checkIfNearBookmarkedLocations();
        if (name != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name 근처에 계시네요!'),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    });
  }

  void _scheduleNearbyNotificationCheck(BuildContext context) {
    if (NearbyNotificationService.requestCheckOnNextBuild) {
      NearbyNotificationService.requestCheckOnNextBuild = false;
      _nearbyNotificationCheckScheduled = false;
    }
    if (_nearbyNotificationCheckScheduled) return;
    _nearbyNotificationCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () async {
        if (!context.mounted) return;
        final provider = context.read<LocationDataProvider>();
        if (provider.allLocations.isEmpty) {
          await provider.loadAllLocations();
        }
        if (!context.mounted) return;
        await NearbyNotificationService.instance.checkAndNotify(
          context,
          allLocations: provider.allLocations,
          onTapShowOnMap: () {
            if (context.mounted) {
              context.read<LocationDataProvider>().requestMoveToMyLocationOnce();
              context.read<BottomNavigationProvider>().setIndex(1);
            }
          },
        );
      });
    });
  }

  void _onSectorTapped(BuildContext context, LocationDataProvider provider, String sector) {
    provider.setSector(sector);
    
    // Default to "View All" (World icon mode) for B&W Chef and Michelin
    if (sector == '흑백요리사' || sector == '미슐렝 코리아') {
      setState(() => _sectorNearbyOnly = false);
    }
    
    // 섹터별 값에 따른 mediaType 매핑
    String? mediaType;
    String displaySectorName = sector;
    
    if (sector == '흑백요리사') {
      mediaType = 'blackwhite';
    } else if (sector == '미슐렝 코리아') {
      mediaType = 'guide';
      displaySectorName = '미슐랭'; // UI 표시용
    } else if (sector == '예능 촬영 맛집') {
      mediaType = 'show';
      displaySectorName = '예능'; // UI 표시용
    }
    
    if (mediaType != null) {
      // 2km 반경 내 맛집 알림 (ignoreThrottle: true로 탭 할 때마다 체크 시도)
      NearbyNotificationService.instance.checkAndNotify(
        context,
        allLocations: provider.allLocations,
        overrideRadiusMeters: 2000,
        sectorName: displaySectorName,
        ignoreThrottle: true,
        onTapShowOnMap: () {
          if (context.mounted) {
            context.read<LocationDataProvider>().requestMoveToMyLocationOnce();
            context.read<BottomNavigationProvider>().setIndex(1);
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleNearBookmarkCheck(context);
    _scheduleNearbyNotificationCheck(context);
    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final fontSize = screenWidth < 360 ? 14.0 : screenWidth < 400 ? 16.0 : 17.0;
            return Text(
              '맛집지도',
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            );
          },
        ),
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _showTopButton
          ? FloatingActionButton.small(
              heroTag: 'scroll_top',
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
              tooltip: '맨 위로',
            )
          : null,
      body: Consumer<LocationDataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, '✨ 최근 추가'),
                  const ListSkeleton(
                    itemCount: 5,
                    isHorizontal: false,
                  ),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadPopularLocations();
                      provider.loadRecentLocations();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Top Sector Navigation - 항상 표시되도록 RefreshIndicator 밖으로 이동
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final navAreaWidth = screenWidth * 0.8;
                  final sideMargin = (screenWidth - navAreaWidth) / 2;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: sideMargin,
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              tooltip: '위치 새로고침',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📍 위치 정보를 갱신 중입니다...'), 
                                    duration: Duration(milliseconds: 800),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                try {
                                  final pos = await Geolocator.getCurrentPosition(
                                    timeLimit: const Duration(seconds: 5),
                                  );
                                  if (context.mounted) {
                                     context.read<LocationProvider>().updateCurrentPosition(pos);
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(
                                         content: Text('✅ 현재 위치가 갱신되었습니다!'),
                                         behavior: SnackBarBehavior.floating,
                                         duration: Duration(seconds: 1500),
                                       ),
                                     );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(
                                         content: Text('❌ 위치 정보 실패: $e'),
                                         behavior: SnackBarBehavior.floating,
                                       ),
                                     );
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          width: navAreaWidth,
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSectorButton(
                                  context,
                                  'HOME',
                                  'HOME',
                                  null,
                                  provider.selectedSector == null,
                                  () => provider.clearSectorFilter(),
                                  screenWidth,
                                ),
                              ),
                              Expanded(
                                child: _buildSectorButton(
                                  context,
                                  '흑백요리사',
                                  '흑백요리사',
                                  '흑백요리사',
                                  provider.selectedSector == '흑백요리사',
                                  () => _onSectorTapped(context, provider, '흑백요리사'),
                                  screenWidth,
                                ),
                              ),
                              Expanded(
                                child: _buildSectorButton(
                                  context,
                                  '미슐렝 코리아',
                                  '미슐랭',
                                  '미슐렝 코리아',
                                  provider.selectedSector == '미슐렝 코리아',
                                  () => _onSectorTapped(context, provider, '미슐렝 코리아'),
                                  screenWidth,
                                ),
                              ),
                              Expanded(
                                child: _buildSectorButton(
                                  context,
                                  '예능 촬영 맛집',
                                  '예능',
                                  '예능 촬영 맛집',
                                  provider.selectedSector == '예능 촬영 맛집',
                                  () => _onSectorTapped(context, provider, '예능 촬영 맛집'),
                                  screenWidth,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: sideMargin),
                      ],
                    ),
                  );
                },
              ),
              
              // 스크롤 가능한 하나의 영역: RefreshIndicator가 SingleChildScrollView를 직접 감쌈
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.loadPopularLocations();
                    await provider.loadRecentLocations();
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sub-Sector Navigation (맛집지도: 흑백요리사/미슐렝/예능 — 서브는 작품·프로그램별)
                        if (provider.selectedSector != null)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withOpacity(0.5),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final screenWidth = constraints.maxWidth;
                                final buttonAreaWidth = screenWidth * 0.8;
                                final sideMargin = (screenWidth - buttonAreaWidth) / 2;
                                return Row(
                                  children: [
                                    SizedBox(width: sideMargin),
                                    SizedBox(
                                      width: buttonAreaWidth,
                                      child: Row(
                                        children: _buildSubSectorButtons(context, provider),
                                      ),
                                    ),
                                    SizedBox(width: sideMargin),
                                  ],
                                );
                              },
                            ),
                          ),
                        // 콘텐츠 (기본: 인기/최근 추가 | 섹터: 리스트 또는 촬영현장 카드)
                        provider.selectedSector == null
                            ? _buildDefaultContent(context, provider)
                            : _buildSectorContent(context, provider),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectorButton(
    BuildContext context,
    String label,
    String displayText,
    String? value,
    bool isSelected,
    VoidCallback onTap,
    double screenWidth,
  ) {
    final fontSize = screenWidth < 360 ? 10.0 : screenWidth < 400 ? 11.0 : 12.0;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: EdgeInsets.symmetric(
          vertical: screenWidth < 360 ? 8.0 : 10.0,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF6BA3C7) 
                  : Theme.of(context).primaryColor)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF6BA3C7) 
                : Theme.of(context).primaryColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.4)
                  : Theme.of(context).shadowColor.withOpacity(0.15),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
              spreadRadius: isSelected ? 1 : 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.black87 : Colors.white) // Use dark text on light blue button in dark mode for contrast
                  : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE0E0E0) : Theme.of(context).textTheme.bodyMedium?.color),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ),
    );
  }

  /// 미슐렝 등급 선택 시 섹션 제목에 붙일 라벨 (3 STAR, 2 STAR, 1 STAR, 빕 구르망, Registered)
  static String _michelinTierSectionLabel(String subSector) {
    switch (subSector) {
      case '3 Star': return '3 STAR';
      case '2 Star': return '2 STAR';
      case '1 Star': return '1 STAR';
      case '빕구르망': return '빕 구르망';
      case '미슐렝': return 'Registered';
      default: return subSector;
    }
  }

  List<Widget> _buildSubSectorButtons(
    BuildContext context,
    LocationDataProvider provider,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 360 ? 9.0 : screenWidth < 400 ? 10.0 : 11.0;

    // 흑백요리사 선택 시: 시즌별 버튼 (시즌 참가업체, 시즌1, 시즌2, 시즌3)
    if (provider.selectedSector == '흑백요리사') {
      return LocationDataProvider.blackwhiteSubOptions.map((option) {
        final isSelected = provider.selectedSubSector == option;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => provider.setSubSector(option),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList();
    }

    // 미슐렝 코리아 선택 시: 등급별 버튼 (3 Star, 2 Star, 1 Star, 빕구르망, 미슐렝)
    if (provider.selectedSector == '미슐렝 코리아') {
      return LocationDataProvider.michelinSubOptions.map((grade) {
        final isSelected = provider.selectedSubSector == grade;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => provider.setSubSector(grade),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      grade,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList();
    }
    return [];
  }

  /// HOME 탭: 앱 안내 카드 + 내 주변 맛집 보기 버튼 + 최근 추가
  Widget _buildDefaultContent(
    BuildContext context,
    LocationDataProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.spacingM(context)),
        _buildAppIntroCard(context),
        SizedBox(height: AppSpacing.spacingL(context)),
        _buildNearbyMapButton(context),
        if (PreferencesService.instance.nearbyNotificationEnabled)
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.screenPaddingHorizontal(context),
              right: AppSpacing.screenPaddingHorizontal(context),
              top: AppSpacing.spacingS(context),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _onAlarmRecheck(context, provider),
                icon: Icon(Icons.notifications_none, size: 16, color: Theme.of(context).primaryColor),
                label: const Text('알림 다시보기'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
        SizedBox(height: AppSpacing.spacingL(context)),
        _buildSectionHeader(context, '✨ 최근 추가'),
        _buildVerticalLocationList(provider.recentLocations, showAll: false),
      ],
    );
  }

  Future<void> _onAlarmRecheck(BuildContext context, LocationDataProvider provider) async {
    if (provider.allLocations.isEmpty) {
      await provider.loadAllLocations();
    }
    if (!context.mounted) return;
    await NearbyNotificationService.instance.checkAndNotify(
      context,
      allLocations: provider.allLocations,
      forceShow: true,
      showEmptyMessage: true,
      onTapShowOnMap: () {
        if (context.mounted) {
          context.read<LocationDataProvider>().requestMoveToMyLocationOnce();
          context.read<BottomNavigationProvider>().setIndex(1);
        }
      },
    );
  }

  /// 내 주변 맛집 보기 — 지도 탭으로 이동
  Widget _buildNearbyMapButton(BuildContext context) {
    final screenH = AppSpacing.screenPaddingHorizontal(context);
    final cardP = AppSpacing.getCardPadding(context);
    final radius = AppSpacing.cardRadius(context);
    final btnIconSize = AppSpacing.buttonIconSize(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenH),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<LocationDataProvider>().requestMoveToMyLocationOnce();
            context.read<BottomNavigationProvider>().setIndex(1);
          },
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            width: double.infinity,
            padding: cardP,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.map,
                  size: btnIconSize * 1.2,
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF6BA3C7) : Theme.of(context).primaryColor,
                ),
                SizedBox(width: AppSpacing.spacingM(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '내 주변 맛집 보기',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF6BA3C7) : Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingXS(context)),
                      Text(
                        '지도에서 주변 맛집 위치를 확인하세요',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF6BA3C7) : Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 앱 안내 카드 — 마이페이지 카드 스타일 통일, 접기/펼치기
  Widget _buildAppIntroCard(BuildContext context) {
    const oneLiner = '흑백요리사, 미슐랭, 예능에 나온 맛집을 한곳에서.';
    final points = [
      '프로그램·가이드별로 맛집 보기',
      '지도에서 위치 확인 후 길찾기',
      '저장·방문 기록으로 나만의 맛집 리스트',
      '내 위치 반경 내 맛집이 있으면 알림 (설정에서 반경 조절 가능)',
    ];
    final screenH = AppSpacing.screenPaddingHorizontal(context);
    final cardP = AppSpacing.getCardPadding(context);
    final radius = AppSpacing.cardRadius(context);
    final iconBtnSize = AppSpacing.iconButtonMinSize(context);
    final btnIconSize = AppSpacing.buttonIconSize(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenH),
      child: Container(
        width: double.infinity,
        padding: cardP,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu, size: btnIconSize, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF6BA3C7) : Theme.of(context).primaryColor),
                SizedBox(width: AppSpacing.spacingS(context)),
                Text(
                  '맛집지도란?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _appIntroExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF6BA3C7) : Theme.of(context).primaryColor,
                  ),
                  onPressed: () => setState(() => _appIntroExpanded = !_appIntroExpanded),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: iconBtnSize, minHeight: iconBtnSize),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.spacingS(context)),
            Text(
              oneLiner,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            if (_appIntroExpanded) ...[
              SizedBox(height: AppSpacing.spacingM(context)),
              ...points.map((text) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.spacingS(context)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacingS(context)),
                    Expanded(
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              SizedBox(height: AppSpacing.spacingS(context)),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<LocationDataProvider>().requestMoveToMyLocationOnce();
                    context.read<BottomNavigationProvider>().setIndex(1);
                  },
                  icon: Icon(Icons.map, size: btnIconSize),
                  label: const Text('내 주변 맛집 보기'),
                  style: OutlinedButton.styleFrom(
                    padding: AppSpacing.getButtonPadding(context),
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectorContent(
    BuildContext context,
    LocationDataProvider provider,
  ) {
    final locProvider = context.read<LocationProvider>();

    // 1. 공통 필터링 로직 (내 주변 5km 여부) - 최적화 적용
    List<Location> getFilteredLocations(List<Location> source) {
      final pos = locProvider.currentPosition;
      
      // 위치 정보가 없으면 원본 반환 (거리 계산 불가)
      if (pos == null) return source;

      // 1. 거리 미리 계산 (Sort 내부에서 반복 계산 방지)
      final locationDistances = source.map((loc) {
        final dist = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, 
          loc.latitude, loc.longitude
        );
        return MapEntry(loc, dist);
      }).toList();

      List<MapEntry<Location, double>> filteredEntries;

      if (_sectorNearbyOnly) {
        // 5km 이내 필터링
        filteredEntries = locationDistances.where((entry) => entry.value <= 5000).toList();
      } else {
        // 전체 보기
        filteredEntries = locationDistances;
      }

      // 2. 거리순 정렬 (미리 계산된 값 비교)
      filteredEntries.sort((a, b) => a.value.compareTo(b.value));
      
      return filteredEntries.map((e) => e.key).toList();
    }

    // 2. 토글 위젯 빌더
    Widget buildToggle() {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingHorizontal(context),
          vertical: 8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // 위치 권한 없으면 요청 로직 등 필요할 수 있음
                    if (locProvider.currentPosition == null && !_sectorNearbyOnly) {
                       Geolocator.getCurrentPosition().then((pos) {
                         context.read<LocationProvider>().updateCurrentPosition(pos);
                         setState(() => _sectorNearbyOnly = true);
                       }).catchError((e) {
                         // 권한 거부 등
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("위치 정보를 가져올 수 없습니다")));
                       });
                    } else {
                       setState(() => _sectorNearbyOnly = true);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _sectorNearbyOnly ? Theme.of(context).primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _sectorNearbyOnly ? [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                      ] : [],
                    ),
                    child: Text(
                      '📍 내 주변 5km',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _sectorNearbyOnly ? Colors.white : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _sectorNearbyOnly = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_sectorNearbyOnly ? Theme.of(context).primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: !_sectorNearbyOnly ? [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                      ] : [],
                    ),
                    child: Text(
                      '🌏 전체 보기',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: !_sectorNearbyOnly ? Colors.white : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // ----------- 흑백요리사 -----------
    if (provider.selectedSector == '흑백요리사') {
      final sub = provider.selectedSubSector ?? '시즌1';
      final rawLocations = provider.sectorLocations;
      
      // 필터 적용
      final locations = getFilteredLocations(rawLocations);
      final count = locations.length;
      
      final sectionTitle = '흑백요리사 $sub 참가업체($count)';
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.spacingM(context)),
          _buildSectionHeader(context, sectionTitle),
          
          buildToggle(), // Toggle 추가 (흑백요리사)

          if (sub == '시즌3')
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingL(context)),
              child: const EmptyState(message: '업데이트 예정입니다.'),
            )
          else if (locations.isEmpty)
             Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text("조건에 맞는 맛집이 없습니다."),
                    if (_sectorNearbyOnly && locProvider.currentPosition != null)
                      TextButton(
                        onPressed: () => setState(() => _sectorNearbyOnly = false),
                        child: const Text("전체 보기로 전환"),
                      )
                  ],
                ),
             )
          else
            _buildVerticalLocationList(locations, showAll: true, horizontalPadding: _contentHorizontalMargin(context)),
        ],
      );
    }

    // ----------- 미슐렝 코리아 -----------
    if (provider.selectedSector == '미슐렝 코리아') {
      final rawLocations = provider.sectorLocations;
      final filteredLocations = getFilteredLocations(rawLocations);
      
      final tierLabel = _michelinTierSectionLabel(provider.selectedSubSector ?? '미슐렝');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.spacingM(context)),
          _buildSectionHeader(
            context,
            '미슐렝 레스토랑',
            titleSuffixRed: '$tierLabel (${filteredLocations.length}개)',
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showMichelinTierModal(context),
              tooltip: '미슐랭 등급 안내',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          
          buildToggle(), // Toggle 추가 (미슐랭)

          if (filteredLocations.isEmpty)
             Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text("조건에 맞는 맛집이 없습니다."),
                    if (_sectorNearbyOnly && locProvider.currentPosition != null)
                      TextButton(
                        onPressed: () => setState(() => _sectorNearbyOnly = false),
                        child: const Text("전체 보기로 전환"),
                      )
                  ],
                ),
             )
          else
            _buildVerticalLocationList(filteredLocations, showAll: true, horizontalPadding: _contentHorizontalMargin(context)),
        ],
      );
    }
    // 예능 촬영 맛집: 작품/프로그램별 카드 → 탭 시 맛집 리스트
    if (provider.selectedSector == '예능 촬영 맛집') {
      return _buildFilmingWorkList(context, provider);
    }

    final locations = provider.sectorLocations;
    if (locations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: EmptyState(
          message: '해당 섹터의 맛집이 없습니다',
        ),
      );
    }

    final sectionTitle = '${provider.selectedSector} ${provider.selectedSubSector ?? ""}'.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.spacingM(context)),
        _buildSectionHeader(context, sectionTitle),
        _buildVerticalLocationList(locations, showAll: true),
      ],
    );
  }

  /// 맛집지도: 섹터별 작품/프로그램 카드 리스트 + 탭 시 해당 맛집 리스트 아래 표시
  Widget _buildFilmingWorkList(
    BuildContext context,
    LocationDataProvider provider,
  ) {
    final works = provider.contentTitles;
    if (works.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.spacingL(context)),
        child: const EmptyState(
          message: '해당 분야의 맛집이 없습니다',
        ),
      );
    }

    final titleFontSize = AppSpacing.titleFontSize(context);
    final addressFontSize = titleFontSize * 0.8;
    final iconSize = AppSpacing.iconSizeS(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.spacingM(context)),
        _buildSectionHeader(
          context,
          '${provider.selectedSector} ${provider.selectedSubSector ?? ""}'.trim(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingHorizontal(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < works.length; i++) ...[
                _buildWorkCard(
                  context,
                  provider,
                  works[i],
                  titleFontSize,
                  addressFontSize,
                  iconSize,
                ),
                  if (provider.expandedContentTitle == works[i]) ...[
                    SizedBox(height: AppSpacing.spacingS(context)),
                    _buildKmdbWorkInfo(context, provider),
                    
                    // Filter Controls & Logic
                    Builder(
                      builder: (context) {
                        final locProvider = context.read<LocationProvider>();
                        final currentPos = locProvider.currentPosition;
                        List<Location> filteredList = []; // Default empty to prevent ANR
                        int totalCount = 0;
                        
                        if (currentPos != null) {
                           // 1. Start with full list
                           var sourceList = provider.locationsForExpandedWork;
                           
                           // 2. Apply Radius Filter
                           if (_selectedRadius != 99999) {
                             sourceList = sourceList.where((loc) {
                               final distMeters = Geolocator.distanceBetween(
                                 currentPos.latitude, currentPos.longitude, 
                                 loc.latitude, loc.longitude
                               );
                               return distMeters <= (_selectedRadius * 1000);
                             }).toList();
                           }
                           
                           // 3. Sort by distance
                           sourceList.sort((a, b) {
                             final distA = Geolocator.distanceBetween(
                               currentPos.latitude, currentPos.longitude, 
                               a.latitude, a.longitude
                             );
                             final distB = Geolocator.distanceBetween(
                               currentPos.latitude, currentPos.longitude, 
                               b.latitude, b.longitude
                             );
                             return distA.compareTo(distB);
                           });
                           
                           totalCount = sourceList.length;
                           // 4. Hard Limit for Preview (Max 15 items to prevent ANR)
                           filteredList = sourceList.take(15).toList();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Radius Dropdown
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (currentPos == null)
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          icon: const Icon(Icons.my_location, size: 16),
                                          label: const Text('내 위치를 찾아 주변 맛집 보기', style: TextStyle(fontWeight: FontWeight.bold)),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red, // Highlight action
                                          ),
                                          onPressed: () {
                                             Geolocator.getCurrentPosition().then((pos) {
                                               context.read<LocationProvider>().updateCurrentPosition(pos);
                                             });
                                          },
                                        ),
                                      ),
                                    ),
                                  if (currentPos != null) ...[
                                    Text('내 위치 기준 ', style: Theme.of(context).textTheme.bodySmall),
                                    DropdownButton<double>(
                                      value: _selectedRadius,
                                      isDense: true,
                                      underline: Container(),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                      items: [1.0, 3.0, 5.0, 10.0, 30.0, 99999.0].map((r) {
                                        String label;
                                        if (r == 99999.0) label = '전국';
                                        else label = '${r.toInt()}km';
                                        return DropdownMenuItem(value: r, child: Text(label));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedRadius = val);
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            // Content
                            if (currentPos == null)
                               Padding(
                                 padding: const EdgeInsets.all(20),
                                 child: Center(
                                   child: Column(
                                     children: [
                                       const Icon(Icons.location_off, size: 40, color: Colors.grey),
                                       const SizedBox(height: 10),
                                       Text(
                                         '위치 정보가 없어 맛집 목록을 불러올 수 없습니다.',
                                         style: Theme.of(context).textTheme.bodyMedium,
                                       ),
                                       const SizedBox(height: 4),
                                       Text(
                                         '상단의 [내 위치를 찾아 주변 맛집 보기]를 눌러주세요.',
                                         style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                       ),
                                     ],
                                   ),
                                 ),
                               )
                            else if (filteredList.isEmpty)
                               Padding(
                                 padding: const EdgeInsets.symmetric(vertical: 20),
                                 child: Center(
                                   child: Text(
                                     '${_selectedRadius.toInt()}km 반경 내에 맛집이 없습니다.',
                                     style: Theme.of(context).textTheme.bodySmall,
                                   ),
                                 ),
                               )
                            else ...[
                              _buildVerticalLocationList(
                                filteredList,
                                showAll: true,
                                horizontalPadding: 0,
                              ),
                              if (totalCount > filteredList.length)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Center(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // Navigate to full list screen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => LocationListScreen(
                                              title: works[i],
                                              contentTitle: works[i],
                                              maxDistance: _selectedRadius == 99999.0 ? null : _selectedRadius,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text('${totalCount - filteredList.length}개 더보기'),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkCard(
    BuildContext context,
    LocationDataProvider provider,
    String contentTitle,
    double titleFontSize,
    double addressFontSize,
    double iconSize,
  ) {
    final isExpanded = provider.expandedContentTitle == contentTitle;
    IconData iconData = Icons.restaurant;
    if (provider.selectedSector == '미슐렝 코리아') iconData = Icons.restaurant;
    if (provider.selectedSector == '예능 촬영 맛집') iconData = Icons.theater_comedy;
    if (provider.selectedSector == '흑백요리사') iconData = Icons.restaurant_menu;

    final boxSize = AppSpacing.iconBoxSize(context);
    final boxRadius = AppSpacing.iconBoxRadius(context);
    final cardRadius = AppSpacing.cardRadius(context);
    final cardP = AppSpacing.getCardPadding(context);
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingS(context)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(
            color: isExpanded
                ? Theme.of(context).primaryColor.withOpacity(0.5)
                : Colors.grey.withOpacity(0.2),
            width: isExpanded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => provider.expandWorkContentTitle(contentTitle),
            child: Padding(
              padding: cardP,
              child: Row(
                children: [
                  Container(
                    width: boxSize,
                    height: boxSize,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(boxRadius),
                    ),
                    child: Icon(iconData, size: boxSize * 0.5, color: Theme.of(context).primaryColor),
                  ),
                  SizedBox(width: AppSpacing.spacingM(context)),
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              contentTitle,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: titleFontSize,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (provider.contentTitleYears[contentTitle] != null) ...[
                            SizedBox(width: AppSpacing.spacingXS(context)),
                            Text(
                              '(${provider.contentTitleYears[contentTitle]})',
                              style: TextStyle(
                                fontSize: addressFontSize,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: AppSpacing.spacingXS(context)),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: iconSize, color: Colors.grey[600]),
                          SizedBox(width: AppSpacing.spacingXS(context)),
                          Text(
                            isExpanded
                                ? '맛집 접기'
                                : '맛집 ${provider.contentTitleCounts[contentTitle] ?? 0}개',
                            style: TextStyle(
                              fontSize: addressFontSize,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
          ),
        ),
      ),
    ),
    );
  }

  /// KMDb API로 가져온 작품 정보(감독, 연도, 줄거리) 표시
  Widget _buildKmdbWorkInfo(BuildContext context, LocationDataProvider provider) {
    if (provider.kmdbInfoLoading) {
      final iconS = AppSpacing.iconSizeM(context);
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingS(context)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: iconS,
              height: iconS,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSpacing.spacingS(context)),
            Text(
              '작품 정보 불러오는 중...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    final info = provider.kmdbInfoForExpandedWork;
    if (info == null || !info.hasAnyInfo) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 360 ? 11.0 : screenWidth < 400 ? 12.0 : 13.0;

    final cardP = AppSpacing.getCardPadding(context);
    final radius = AppSpacing.cardRadius(context);
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingS(context)),
      child: Container(
        padding: cardP,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '작품 정보 (KMDb)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize + 1,
                    ),
              ),
              SizedBox(height: AppSpacing.spacingS(context)),
              if (info.directorNm != null && info.directorNm!.isNotEmpty)
                _buildKmdbRow(context, '감독', info.directorNm!, fontSize),
              if (info.prodYear != null && info.prodYear!.isNotEmpty)
                _buildKmdbRow(context, '제작년도', info.prodYear!, fontSize),
              if (info.nation != null && info.nation!.isNotEmpty)
                _buildKmdbRow(context, '제작국가', info.nation!, fontSize),
              if (info.genre != null && info.genre!.isNotEmpty)
                _buildKmdbRow(context, '장르', info.genre!, fontSize),
              if (info.plot != null && info.plot!.isNotEmpty) ...[
                SizedBox(height: AppSpacing.spacingXS(context)),
                Text(
                  '줄거리',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize,
                      ),
                ),
                SizedBox(height: AppSpacing.spacingXS(context)),
                Text(
                  info.plot!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: fontSize - 1,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (info.kmdbUrl != null && info.kmdbUrl!.isNotEmpty) ...[
                SizedBox(height: AppSpacing.spacingS(context)),
                Text(
                  '출처: 한국영화데이터베이스(KMDb)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: fontSize - 2,
                      ),
                ),
              ],
            ],
        ),
      ),
    );
  }

  Widget _buildKmdbRow(BuildContext context, String label, String value, double fontSize) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingXS(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$label ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    color: Colors.grey[700],
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: fontSize,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// 메인 네비(HOME 등) 버튼 영역과 맞추기 위한 좌우 여백 (화면 폭의 10%)
  static double _contentHorizontalMargin(BuildContext context) {
    return MediaQuery.of(context).size.width * 0.1;
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
    /// 미슐렝 등급 라벨 등, 제목 뒤에 빨간색으로 붙일 텍스트
    String? titleSuffixRed,
    /// 제목 오른쪽에 표시할 위젯 (예: 정보 아이콘)
    Widget? trailing,
  }) {
    final horizontalPadding = _contentHorizontalMargin(context);
    final titleFontSize = AppSpacing.sectionHeaderFontSize(context);
    final buttonFontSize = AppSpacing.captionFontSize(context) + 1;
    final baseStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: titleFontSize,
    );
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.spacingS(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: titleSuffixRed != null && titleSuffixRed.isNotEmpty
                ? RichText(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    text: TextSpan(
                      style: baseStyle,
                      children: [
                        TextSpan(text: title),
                        TextSpan(
                          text: ' $titleSuffixRed',
                          style: (baseStyle ?? TextStyle()).copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                  )
                : Text(
                    title,
                    style: baseStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
          ),
          if (trailing != null) trailing,
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                '전체보기',
                style: TextStyle(fontSize: buttonFontSize),
              ),
              style: TextButton.styleFrom(
                padding: AppSpacing.getTextButtonPadding(context),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  /// 미슐랭 가이드 등급(티어) 설명 모달
  void _showMichelinTierModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF4D6), // 밝은 골드
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingHorizontal(context),
                vertical: AppSpacing.spacingM(context),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '미슐랭 가이드 등급 안내',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSpacing.sectionHeaderFontSize(context),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.all(AppSpacing.screenPaddingHorizontal(context)),
                children: [
                  _buildTierExplanationCard(
                    context,
                    tier: '3 STAR',
                    subtitle: '3스타 레스토랑',
                    description:
                        '뛰어난 요리로, 그 맛을 위해 특별히 여행할 가치가 있는 레스토랑입니다. '
                        '미슐랭 가이드가 부여하는 최고 등급으로, 세계적으로도 극소수만 선정됩니다.',
                  ),
                  _buildTierExplanationCard(
                    context,
                    tier: '2 STAR',
                    subtitle: '2스타 레스토랑',
                    description:
                        '훌륭한 요리를 선보이며, 맛을 위해 우회해서라도 방문할 가치가 있는 레스토랑입니다. '
                        '최고 수준의 요리 실력과 일관된 품질을 인정받은 곳입니다.',
                  ),
                  _buildTierExplanationCard(
                    context,
                    tier: '1 STAR',
                    subtitle: '1스타 레스토랑',
                    description:
                        '높은 수준의 요리를 제공하며, 그 지역을 방문할 때 꼭 들러볼 만한 레스토랑입니다. '
                        '양질의 식재료와 숙련된 요리 기술이 인정받은 곳입니다.',
                  ),
                  _buildTierExplanationCard(
                    context,
                    tier: '빕 구르망',
                    subtitle: 'Bib Gourmand',
                    description:
                        '좋은 품질의 요리를 합리적인 가격에 제공하는 레스토랑입니다. '
                        '미슐랭 심사위원이 정한 기준 가격 이하에서 훌륭한 맛을 선사하는 곳을 선정합니다.',
                  ),
                  _buildTierExplanationCard(
                    context,
                    tier: 'Registered',
                    subtitle: '미슐렝 셀렉티드 (등록 레스토랑)',
                    description:
                        '미슐랭 가이드 심사위원이 추천하는 레스토랑으로, '
                        '신선한 식재료와 숙련된 요리 실력을 바탕으로 한 맛을 선보입니다. '
                        '스타나 빕 구르망과는 별도로, 가이드에 등록된 주목할 만한 맛집입니다.',
                  ),
                  SizedBox(height: AppSpacing.spacingL(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierExplanationCard(
    BuildContext context, {
    required String tier,
    required String subtitle,
    required String description,
  }) {
    final theme = Theme.of(context);
    final bodySize = AppSpacing.captionFontSize(context) + 1;
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingM(context)),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacingS(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tier,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: bodySize + 2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: bodySize - 1,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
            SizedBox(height: AppSpacing.spacingS(context) * 0.5),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: bodySize,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalLocationList(List<dynamic> locations) {
    if (locations.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.spacingM(context)),
        child: const EmptyState(
          message: '맛집이 없습니다',
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardAreaWidth = screenWidth * 0.9;
        final sideMargin = (screenWidth - cardAreaWidth) / 2;
        final cardSpacing = AppSpacing.spacingS(context);
        final cardWidth = (cardAreaWidth - cardSpacing) / 2;
        final listHeight = AppSpacing.horizontalCardHeight(context);
        return SizedBox(
          height: listHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: sideMargin),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              final locProvider = context.read<LocationProvider>();
              String? distanceText;
              if (locProvider.currentPosition != null) {
                final distanceMeters = Geolocator.distanceBetween(
                  locProvider.currentPosition!.latitude,
                  locProvider.currentPosition!.longitude,
                  location.latitude,
                  location.longitude,
                );
                if (distanceMeters < 1000) {
                  distanceText = '${distanceMeters.toStringAsFixed(0)}m';
                } else {
                  distanceText = '${(distanceMeters / 1000).toStringAsFixed(1)}km';
                }
              }
              return Padding(
                padding: EdgeInsets.only(
                  right: index < locations.length - 1 ? cardSpacing : 0,
                ),
                child: SizedBox(
                  width: cardWidth,
                  child: LocationCard(
                    location: location,
                    distance: distanceText,
                    heroTagPrefix: 'popular',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationDetailScreen(
                            locationId: location.id,
                            previewLocation: location,
                            heroTag: 'popular_${location.id}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVerticalLocationList(List<dynamic> locations, {bool showAll = false, double? horizontalPadding}) {
    if (locations.isEmpty) {
      final hPad = horizontalPadding ?? AppSpacing.screenPaddingHorizontal(context);
      return Padding(
        padding: EdgeInsets.all(hPad),
        child: const EmptyState(
          message: '맛집이 없습니다',
        ),
      );
    }

    const int recentListMax = 30;
    final itemCount = showAll ? locations.length : (locations.length > recentListMax ? recentListMax : locations.length);
    final hPadding = horizontalPadding ?? AppSpacing.screenPaddingHorizontal(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final location = locations[index];
          final locProvider = context.read<LocationProvider>();
          String? distanceText;
          if (locProvider.currentPosition != null) {
            final distanceMeters = Geolocator.distanceBetween(
              locProvider.currentPosition!.latitude,
              locProvider.currentPosition!.longitude,
              location.latitude,
              location.longitude,
            );
            if (distanceMeters < 1000) {
              distanceText = '${distanceMeters.toStringAsFixed(0)}m';
            } else {
              distanceText = '${(distanceMeters / 1000).toStringAsFixed(1)}km';
            }
          }
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.spacingS(context)),
            child: LocationCard(
              location: location,
              distance: distanceText,
              isHorizontal: true,
              heroTagPrefix: 'recent',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationDetailScreen(
                      locationId: location.id,
                      previewLocation: location,
                      heroTag: 'recent_${location.id}',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
