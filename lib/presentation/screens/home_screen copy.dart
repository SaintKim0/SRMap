import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/services/nearby_notification_service.dart';
import '../../data/services/preferences_service.dart';
import '../providers/bookmark_provider.dart';
import '../providers/bottom_navigation_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/bottom_navigation_provider.dart';
import '../providers/location_provider.dart'; // Data Provider
import '../providers/location_provider_service.dart'; // Logic Provider
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
    Future.microtask(() {
      context.read<LocationDataProvider>().loadContentTitles();
      context.read<LocationDataProvider>().loadPopularLocations();
      context.read<LocationDataProvider>().loadRecentLocations();
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
              content: Text('$name Í∑ºÏ≤ò??Í≥ÑÏãú?§Ïöî!'),
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
              'ÎßõÏßëÏßÄ??,
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
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
              tooltip: 'Îß??ÑÎ°ú',
            )
          : null,
      body: Consumer<LocationDataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, '??ÏµúÍ∑º Ï∂îÍ?'),
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
                    child: const Text('?§Ïãú ?úÎèÑ'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Top Sector Navigation - ??ÉÅ ?úÏãú?òÎèÑÎ°?RefreshIndicator Î∞ñÏúºÎ°??¥Îèô
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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: sideMargin),
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
                                  '?ëÎ∞±?îÎ¶¨??,
                                  '?ëÎ∞±?îÎ¶¨??,
                                  '?ëÎ∞±?îÎ¶¨??,
                                  provider.selectedSector == '?ëÎ∞±?îÎ¶¨??,
                                  () => provider.setSector('?ëÎ∞±?îÎ¶¨??),
                                  screenWidth,
                                ),
                              ),
                              Expanded(
                                child: _buildSectorButton(
                                  context,
                                  'ÎØ∏Ïäê??ÏΩîÎ¶¨??,
                                  'ÎØ∏Ïäê??,
                                  'ÎØ∏Ïäê??ÏΩîÎ¶¨??,
                                  provider.selectedSector == 'ÎØ∏Ïäê??ÏΩîÎ¶¨??,
                                  () => provider.setSector('ÎØ∏Ïäê??ÏΩîÎ¶¨??),
                                  screenWidth,
                                ),
                              ),
                              Expanded(
                                child: _buildSectorButton(
                                  context,
                                  '?àÎä• Ï¥¨ÏòÅ?ÑÏû•',
                                  '?àÎä•',
                                  '?àÎä• Ï¥¨ÏòÅ?ÑÏû•',
                                  provider.selectedSector == '?àÎä• Ï¥¨ÏòÅ?ÑÏû•',
                                  () => provider.setSector('?àÎä• Ï¥¨ÏòÅ?ÑÏû•'),
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
              
              // ?§ÌÅ¨Î°?Í∞Ä?•Ìïú ?òÎÇò???ÅÏó≠: RefreshIndicatorÍ∞Ä SingleChildScrollViewÎ•?ÏßÅÏ†ë Í∞êÏåà
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
                        // Sub-Sector Navigation (ÎßõÏßëÏßÄ?? ?ëÎ∞±?îÎ¶¨??ÎØ∏Ïäê???àÎä• ???úÎ∏å???ëÌíà¬∑?ÑÎ°úÍ∑∏Îû®Î≥?
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
                        // ÏΩòÌÖêÏ∏?(Í∏∞Î≥∏: ?∏Í∏∞/ÏµúÍ∑º Ï∂îÍ? | ?πÌÑ∞: Î¶¨Ïä§???êÎäî Ï¥¨ÏòÅ?ÑÏû• Ïπ¥Îìú)
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
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).primaryColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.4)
                  : Colors.black.withOpacity(0.15),
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
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ),
    );
  }

  /// ÎØ∏Ïäê???±Í∏â ?†ÌÉù ???πÏÖò ?úÎ™©??Î∂ôÏùº ?ºÎ≤® (3 STAR, 2 STAR, 1 STAR, Îπ?Íµ¨Î•¥Îß? Registered)
  static String _michelinTierSectionLabel(String subSector) {
    switch (subSector) {
      case '3 Star': return '3 STAR';
      case '2 Star': return '2 STAR';
      case '1 Star': return '1 STAR';
      case 'ÎπïÍµ¨Î•¥Îßù': return 'Îπ?Íµ¨Î•¥Îß?;
      case 'ÎØ∏Ïäê??: return 'Registered';
      default: return subSector;
    }
  }

  List<Widget> _buildSubSectorButtons(
    BuildContext context,
    LocationDataProvider provider,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 360 ? 9.0 : screenWidth < 400 ? 10.0 : 11.0;

    // ?ëÎ∞±?îÎ¶¨???†ÌÉù ?? ?úÏ¶åÎ≥?Î≤ÑÌäº (?úÏ¶å Ï∞∏Í??ÖÏ≤¥, ?úÏ¶å1, ?úÏ¶å2, ?úÏ¶å3)
    if (provider.selectedSector == '?ëÎ∞±?îÎ¶¨??) {
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

    // ÎØ∏Ïäê??ÏΩîÎ¶¨???†ÌÉù ?? ?±Í∏âÎ≥?Î≤ÑÌäº (3 Star, 2 Star, 1 Star, ÎπïÍµ¨Î•¥Îßù, ÎØ∏Ïäê??
    if (provider.selectedSector == 'ÎØ∏Ïäê??ÏΩîÎ¶¨??) {
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

  /// HOME ?? ???àÎÇ¥ Ïπ¥Îìú + ??Ï£ºÎ? ÎßõÏßë Î≥¥Í∏∞ Î≤ÑÌäº + ÏµúÍ∑º Ï∂îÍ?
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
                label: const Text('?åÎ¶º ?§ÏãúÎ≥¥Í∏∞'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
        SizedBox(height: AppSpacing.spacingL(context)),
        _buildSectionHeader(context, '??ÏµúÍ∑º Ï∂îÍ?'),
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

  /// ??Ï£ºÎ? ÎßõÏßë Î≥¥Í∏∞ ??ÏßÄ????úºÎ°??¥Îèô
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
              color: Theme.of(context).primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: AppSpacing.spacingM(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '??Ï£ºÎ? ÎßõÏßë Î≥¥Í∏∞',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingXS(context)),
                      Text(
                        'ÏßÄ?ÑÏóê??Ï£ºÎ? ÎßõÏßë ?ÑÏπòÎ•??ïÏù∏?òÏÑ∏??,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ???àÎÇ¥ Ïπ¥Îìú ??ÎßàÏù¥?òÏù¥ÏßÄ Ïπ¥Îìú ?§Ì????µÏùº, ?ëÍ∏∞/?ºÏπòÍ∏?  Widget _buildAppIntroCard(BuildContext context) {
    const oneLiner = '?ëÎ∞±?îÎ¶¨?? ÎØ∏Ïäê?? ?àÎä•???òÏò® ÎßõÏßë???úÍ≥≥?êÏÑú.';
    final points = [
      '?ÑÎ°úÍ∑∏Îû®¬∑Í∞Ä?¥ÎìúÎ≥ÑÎ°ú ÎßõÏßë Î≥¥Í∏∞',
      'ÏßÄ?ÑÏóê???ÑÏπò ?ïÏù∏ ??Í∏∏Ï∞æÍ∏?,
      '?Ä?•¬∑Î∞©Î¨?Í∏∞Î°ù?ºÎ°ú ?òÎßå??ÎßõÏßë Î¶¨Ïä§??,
      '???ÑÏπò Î∞òÍ≤Ω ??ÎßõÏßë???àÏúºÎ©??åÎ¶º (?§Ï†ï?êÏÑú Î∞òÍ≤Ω Ï°∞Ï†à Í∞Ä??',
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
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
            Row(
              children: [
                Icon(Icons.restaurant_menu, size: btnIconSize, color: Theme.of(context).primaryColor),
                SizedBox(width: AppSpacing.spacingS(context)),
                Text(
                  'ÎßõÏßëÏßÄ?ÑÎ??',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _appIntroExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).primaryColor,
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
                      '??,
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
                  label: const Text('??Ï£ºÎ? ÎßõÏßë Î≥¥Í∏∞'),
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
    // ?ëÎ∞±?îÎ¶¨?? ?úÏ¶å1/?úÏ¶å2/?úÏ¶å3 Î≤ÑÌäº, ?úÎ™©??'?ëÎ∞±?îÎ¶¨???úÏ¶åN Ï∞∏Í??ÖÏ≤¥(?ÖÏ≤¥??' ?úÏãú
    if (provider.selectedSector == '?ëÎ∞±?îÎ¶¨??) {
      final sub = provider.selectedSubSector ?? '?úÏ¶å1';
      final locations = provider.sectorLocations;
      final count = locations.length;
      final sectionTitle = '?ëÎ∞±?îÎ¶¨??$sub Ï∞∏Í??ÖÏ≤¥($count)';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.spacingM(context)),
          _buildRadiusFilterButtons(context, provider),
          SizedBox(height: AppSpacing.spacingS(context)),
          _buildSectionHeader(context, sectionTitle),
          if (sub == '?úÏ¶å3')
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingL(context)),
              child: const EmptyState(message: '?ÖÎç∞?¥Ìä∏ ?àÏ†ï?ÖÎãà??'),
            )
          else
            _buildVerticalLocationList(locations, showAll: true, horizontalPadding: _contentHorizontalMargin(context)),
        ],
      );
    }
    // ÎØ∏Ïäê??ÏΩîÎ¶¨?? ?±Í∏â Î≤ÑÌäº???∞Îùº 'ÎØ∏Ïäê???àÏä§?†Îûë' ?§Ïóê ?±Í∏â ?ºÎ≤®(Îπ®Í∞Ñ?? ?úÏãú + ?±Í∏â ?àÎÇ¥ Î≤ÑÌäº
    if (provider.selectedSector == 'ÎØ∏Ïäê??ÏΩîÎ¶¨??) {
      final locations = provider.sectorLocations;
      final tierLabel = _michelinTierSectionLabel(provider.selectedSubSector ?? 'ÎØ∏Ïäê??);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.spacingM(context)),
          _buildRadiusFilterButtons(context, provider),
          SizedBox(height: AppSpacing.spacingS(context)),
          _buildSectionHeader(
            context,
            'ÎØ∏Ïäê???àÏä§?†Îûë',
            titleSuffixRed: tierLabel,
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showMichelinTierModal(context),
              tooltip: 'ÎØ∏Ïäê???±Í∏â ?àÎÇ¥',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          _buildVerticalLocationList(locations, showAll: true, horizontalPadding: _contentHorizontalMargin(context)),
        ],
      );
    }
    // ?àÎä• Ï¥¨ÏòÅ?ÑÏû•: ?ëÌíà/?ÑÎ°úÍ∑∏Îû®Î≥?Ïπ¥Îìú ??????ÎßõÏßë Î¶¨Ïä§??    if (provider.selectedSector == '?àÎä• Ï¥¨ÏòÅ?ÑÏû•') {
      return _buildFilmingWorkList(context, provider);
    }

    final locations = provider.sectorLocations;
    if (locations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: EmptyState(
          message: '?¥Îãπ ?πÌÑ∞??ÎßõÏßë???ÜÏäµ?àÎã§',
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

  /// ÎßõÏßëÏßÄ?? ?πÌÑ∞Î≥??ëÌíà/?ÑÎ°úÍ∑∏Îû® Ïπ¥Îìú Î¶¨Ïä§??+ ?????¥Îãπ ÎßõÏßë Î¶¨Ïä§???ÑÎûò ?úÏãú
  Widget _buildFilmingWorkList(
    BuildContext context,
    LocationDataProvider provider,
  ) {
    final works = provider.contentTitles;
    if (works.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.spacingL(context)),
        child: const EmptyState(
          message: '?¥Îãπ Î∂ÑÏïº??ÎßõÏßë???ÜÏäµ?àÎã§',
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
                  SizedBox(height: AppSpacing.spacingS(context)),
                  _buildVerticalLocationList(
                    provider.locationsForExpandedWork.where((loc) {
                      final locationService = context.read<LocationProvider>();
                      if (!locationService.hasLocation) return true;
                      final dist = locationService.calculateDistanceToLocation(loc.latitude, loc.longitude);
                      return dist != null && dist <= 5.0; // 5km filter
                    }).toList(),
                    showAll: true,
                    horizontalPadding: 0,
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
    if (provider.selectedSector == 'ÎØ∏Ïäê??ÏΩîÎ¶¨??) iconData = Icons.restaurant;
    if (provider.selectedSector == '?àÎä• Ï¥¨ÏòÅ?ÑÏû•') iconData = Icons.theater_comedy;
    if (provider.selectedSector == '?ëÎ∞±?îÎ¶¨??) iconData = Icons.restaurant_menu;

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
                                ? 'ÎßõÏßë ?ëÍ∏∞'
                                : 'ÎßõÏßë ${provider.contentTitleCounts[contentTitle] ?? 0}Í∞?,
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

  /// KMDb APIÎ°?Í∞Ä?∏Ïò® ?ëÌíà ?ïÎ≥¥(Í∞êÎèÖ, ?∞ÎèÑ, Ï§ÑÍ±∞Î¶? ?úÏãú
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
              '?ëÌíà ?ïÎ≥¥ Î∂àÎü¨?§Îäî Ï§?..',
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
                '?ëÌíà ?ïÎ≥¥ (KMDb)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize + 1,
                    ),
              ),
              SizedBox(height: AppSpacing.spacingS(context)),
              if (info.directorNm != null && info.directorNm!.isNotEmpty)
                _buildKmdbRow(context, 'Í∞êÎèÖ', info.directorNm!, fontSize),
              if (info.prodYear != null && info.prodYear!.isNotEmpty)
                _buildKmdbRow(context, '?úÏûë?ÑÎèÑ', info.prodYear!, fontSize),
              if (info.nation != null && info.nation!.isNotEmpty)
                _buildKmdbRow(context, '?úÏûëÍµ??', info.nation!, fontSize),
              if (info.genre != null && info.genre!.isNotEmpty)
                _buildKmdbRow(context, '?•Î•¥', info.genre!, fontSize),
              if (info.plot != null && info.plot!.isNotEmpty) ...[
                SizedBox(height: AppSpacing.spacingXS(context)),
                Text(
                  'Ï§ÑÍ±∞Î¶?,
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
                  'Ï∂úÏ≤ò: ?úÍµ≠?ÅÌôî?∞Ïù¥?∞Î≤†?¥Ïä§(KMDb)',
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

  /// Î©îÏù∏ ?§ÎπÑ(HOME ?? Î≤ÑÌäº ?ÅÏó≠Í≥?ÎßûÏ∂îÍ∏??ÑÌïú Ï¢åÏö∞ ?¨Î∞± (?îÎ©¥ ??ùò 10%)
  static double _contentHorizontalMargin(BuildContext context) {
    return MediaQuery.of(context).size.width * 0.1;
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
    /// ÎØ∏Ïäê???±Í∏â ?ºÎ≤® ?? ?úÎ™© ?§Ïóê Îπ®Í∞Ñ?âÏúºÎ°?Î∂ôÏùº ?çÏä§??    String? titleSuffixRed,
    /// ?úÎ™© ?§Î•∏Ï™ΩÏóê ?úÏãú???ÑÏ†Ø (?? ?ïÎ≥¥ ?ÑÏù¥ÏΩ?
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
                '?ÑÏ≤¥Î≥¥Í∏∞',
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

  /// ÎØ∏Ïäê??Í∞Ä?¥Îìú ?±Í∏â(?∞Ïñ¥) ?§Î™Ö Î™®Îã¨
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
              color: const Color(0xFFFFF4D6), // Î∞ùÏ? Í≥®Îìú
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingHorizontal(context),
                vertical: AppSpacing.spacingM(context),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ÎØ∏Ïäê??Í∞Ä?¥Îìú ?±Í∏â ?àÎÇ¥',
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
                    subtitle: '3?§Ì? ?àÏä§?†Îûë',
                    description:
                        '?∞Ïñ¥???îÎ¶¨Î°? Í∑?ÎßõÏùÑ ?ÑÌï¥ ?πÎ≥Ñ???¨Ìñâ??Í∞ÄÏπòÍ? ?àÎäî ?àÏä§?†Îûë?ÖÎãà?? '
                        'ÎØ∏Ïäê??Í∞Ä?¥ÎìúÍ∞Ä Î∂Ä?¨Ìïò??ÏµúÍ≥† ?±Í∏â?ºÎ°ú, ?∏Í≥Ñ?ÅÏúºÎ°úÎèÑ Í∑πÏÜå?òÎßå ?†Ï†ï?©Îãà??',
                  ),
                  _buildTierExplanationCard(
                    context,
                    tier: '2 STAR',
                    subtitle: '2?§Ì? ?àÏä§?†Îûë',
                    description:
                        '?åÎ????îÎ¶¨Î•??†Î≥¥?¥Î©∞, ÎßõÏùÑ ?ÑÌï¥ ?∞Ìöå?¥ÏÑú?ºÎèÑ Î∞©Î¨∏??Í∞ÄÏπòÍ? ?àÎäî ?àÏä§?†Îûë?ÖÎãà?? '
                        'ÏµúÍ≥† ?òÏ????îÎ¶¨ ?§Î†•Í≥??ºÍ????àÏßà???∏Ï†ïÎ∞õÏ? Í≥≥ÏûÖ?àÎã§.',
                  ),
                  _buildTierExplanationCard(
                    context,
                    tier: '1 STAR',
                    subtitle: '1?§Ì? ?àÏä§?†Îûë',
                    description:
                        '?íÏ? ?òÏ????îÎ¶¨Î•??úÍ≥µ?òÎ©∞, Í∑?ÏßÄ??ùÑ Î∞©Î¨∏????Íº??§Îü¨Î≥?ÎßåÌïú ?àÏä§?†Îûë?ÖÎãà?? '
                        '?ëÏßà???ùÏû¨Î£åÏ? ?ôÎ†®???îÎ¶¨ Í∏∞Ïà†???∏Ï†ïÎ∞õÏ? Í≥≥ÏûÖ?àÎã§.',
                  ),
                  _buildTierExplanationCard(
                    context,
                    tier: 'Îπ?Íµ¨Î•¥Îß?,
                    subtitle: 'Bib Gourmand',
                    description:
                        'Ï¢ãÏ? ?àÏßà???îÎ¶¨Î•??©Î¶¨?ÅÏù∏ Í∞ÄÍ≤©Ïóê ?úÍ≥µ?òÎäî ?àÏä§?†Îûë?ÖÎãà?? '
                        'ÎØ∏Ïäê???¨ÏÇ¨?ÑÏõê???ïÌïú Í∏∞Ï? Í∞ÄÍ≤??¥Ìïò?êÏÑú ?åÎ???ÎßõÏùÑ ?†ÏÇ¨?òÎäî Í≥≥ÏùÑ ?†Ï†ï?©Îãà??',
                  ),
                  _buildTierExplanationCard(
                    context,
                    tier: 'Registered',
                    subtitle: 'ÎØ∏Ïäê???Ä?âÌã∞??(?±Î°ù ?àÏä§?†Îûë)',
                    description:
                        'ÎØ∏Ïäê??Í∞Ä?¥Îìú ?¨ÏÇ¨?ÑÏõê??Ï∂îÏ≤ú?òÎäî ?àÏä§?†Îûë?ºÎ°ú, '
                        '?†ÏÑ†???ùÏû¨Î£åÏ? ?ôÎ†®???îÎ¶¨ ?§Î†•??Î∞îÌÉï?ºÎ°ú ??ÎßõÏùÑ ?†Î≥¥?ÖÎãà?? '
                        '?§Ì???Îπ?Íµ¨Î•¥ÎßùÍ≥º??Î≥ÑÎèÑÎ°? Í∞Ä?¥Îìú???±Î°ù??Ï£ºÎ™©??ÎßåÌïú ÎßõÏßë?ÖÎãà??',
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
          message: 'Ï¥¨ÏòÅÏßÄÍ∞Ä ?ÜÏäµ?àÎã§',
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
              return Padding(
                padding: EdgeInsets.only(
                  right: index < locations.length - 1 ? cardSpacing : 0,
                ),
                child: SizedBox(
                  width: cardWidth,
                  child: LocationCard(
                    location: location,
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
          message: 'Ï¥¨ÏòÅÏßÄÍ∞Ä ?ÜÏäµ?àÎã§',
        ),
      );
    }

    const int recentListMax = 30;
    final itemCount = showAll ? locations.length : (locations.length > recentListMax ? recentListMax : locations.length);
    final hPadding = horizontalPadding ?? AppSpacing.screenPaddingHorizontal(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(itemCount, (index) {
          final location = locations[index];
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.spacingS(context)),
            child: LocationCard(
              location: location,
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
        }),
      ),
    );
  }

  Widget _buildRadiusFilterButtons(BuildContext context, LocationDataProvider provider) {
    final locProv = context.read<LocationProvider>();
    final showNearby = provider.showNearbyOnly;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _contentHorizontalMargin(context)),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (!showNearby) {
                    provider.toggleNearbyFilter();
                    // Apply radius filter with current location
                    if (locProv.hasLocation) {
                      final pos = locProv.currentPosition!;
                      provider.applyRadiusFilter(pos.latitude, pos.longitude);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: showNearby ? Theme.of(context).primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: showNearby ? Colors.white : Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '??Ï£ºÎ? 5km',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: showNearby ? Colors.white : Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (showNearby) {
                    provider.toggleNearbyFilter();
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: !showNearby ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.public,
                        size: 16,
                        color: !showNearby ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '?ÑÏ≤¥ Î≥¥Í∏∞',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !showNearby ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
}

