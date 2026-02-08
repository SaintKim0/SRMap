import 'package:flutter/material.dart';
import '../../data/models/location.dart';
import '../../data/services/map_service.dart';

class LocationCard extends StatelessWidget {
  final Location location;
  final bool isHorizontal;
  final VoidCallback onTap;
  final String? heroTagPrefix;
  final String? distance;

  const LocationCard({
    super.key,
    required this.location,
    required this.onTap,
    this.isHorizontal = false,
    this.heroTagPrefix,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return _buildHorizontalCard(context);
    }
    return _buildVerticalCard(context);
  }

  Widget _buildVerticalCard(BuildContext context) {
    return Card(
      elevation: 8,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      shadowColor: Theme.of(context).shadowColor.withOpacity(0.25),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildHeroImage(),
            ),
            // Content
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final titleFontSize = screenWidth < 360 ? 13.0 : screenWidth < 400 ? 14.0 : 15.0;
                final addressFontSize = screenWidth < 360 ? 10.0 : screenWidth < 400 ? 11.0 : 12.0;
                final statFontSize = screenWidth < 360 ? 10.0 : screenWidth < 400 ? 11.0 : 12.0;
                final distanceFontSize = screenWidth < 360 ? 10.0 : screenWidth < 400 ? 11.0 : 12.0;
                final iconSize = screenWidth < 360 ? 12.0 : screenWidth < 400 ? 13.0 : 14.0;
                final padding = screenWidth < 360 ? 8.0 : 10.0;
                
                return Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              location.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: titleFontSize,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_getSectorLabel() != null) ...[
                            const SizedBox(width: 4),
                            _buildSectorTag(context, _getSectorLabel()!, _getSectorColorForContext(context)!, titleFontSize * 0.7),
                          ],
                        ],
                      ),
                      SizedBox(height: screenWidth < 360 ? 3.0 : 4.0),
                      if (location.chefName != null && location.mediaType?.toLowerCase() == 'blackwhite') ...[
                        Row(
                          children: [
                            Icon(Icons.person, size: iconSize, color: Theme.of(context).iconTheme.color),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '세프: ${location.chefName}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  fontSize: addressFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenWidth < 360 ? 2.0 : 3.0),
                      ],
                      Row(
                        children: [
                          Icon(Icons.location_on, size: iconSize, color: Theme.of(context).iconTheme.color),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location.address,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontSize: addressFontSize,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth < 360 ? 6.0 : 8.0),
                      Row(
                        children: [
                          _buildStat(context, Icons.remove_red_eye, '${location.viewCount}', statFontSize, iconSize),
                          SizedBox(width: screenWidth < 360 ? 10.0 : 12.0),
                          _buildStat(context, Icons.bookmark, '${location.bookmarkCount}', statFontSize, iconSize),
                          if (distance != null) ...[
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth < 360 ? 6.0 : 8.0,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                distance!,
                                style: TextStyle(
                                  fontSize: distanceFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return Card(
      elevation: 8,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      shadowColor: Theme.of(context).shadowColor.withOpacity(0.25),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Image
            SizedBox(
              width: 88, // 기존 110의 80% = 88
              height: 88, // 기존 110의 80% = 88
              child: _buildHeroImage(),
            ),
            // Content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  // 섹션 헤더 크기 기준 (titleFontSize from _buildSectionHeader)
                  final sectionTitleFontSize = screenWidth < 360 ? 13.0 : screenWidth < 400 ? 14.0 : 15.0;
                  // 장소명 = 섹션 헤더 크기의 80%
                  final titleFontSize = sectionTitleFontSize * 0.8;
                  // 주소 = 장소명 크기의 80%
                  final addressFontSize = titleFontSize * 0.8;
                  final statFontSize = screenWidth < 360 ? 9.0 : screenWidth < 400 ? 10.0 : 11.0;
                  final iconSize = screenWidth < 360 ? 10.0 : screenWidth < 400 ? 11.0 : 12.0;
                  final padding = screenWidth < 360 ? 6.0 : 8.0;
                  
                  return Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                location.name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: titleFontSize,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (_getSectorLabel() != null)
                                  _buildSectorTag(context, _getSectorLabel()!, _getSectorColorForContext(context)!, titleFontSize * 0.7),
                                if (distance != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    distance!,
                                    style: TextStyle(
                                      fontSize: titleFontSize * 0.7,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: screenWidth < 360 ? 3.0 : 4.0),
                        if (location.chefName != null && location.mediaType?.toLowerCase() == 'blackwhite') ...[
                          Row(
                            children: [
                              Icon(Icons.person, size: iconSize, color: Theme.of(context).iconTheme.color),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '세프: ${location.chefName}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                    fontSize: addressFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenWidth < 360 ? 2.0 : 3.0),
                        ],
                        Text(
                          location.address,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: addressFontSize,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenWidth < 360 ? 6.0 : 8.0),
                        Row(
                          children: [
                            _buildStat(context, Icons.remove_red_eye, '${location.viewCount}', statFontSize, iconSize),
                            SizedBox(width: screenWidth < 360 ? 10.0 : 12.0),
                            _buildStat(context, Icons.bookmark, '${location.bookmarkCount}', statFontSize, iconSize),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String text, [double? fontSize, double? iconSize]) {
    final screenWidth = MediaQuery.of(context).size.width;
    final finalFontSize = fontSize ?? (screenWidth < 360 ? 10.0 : screenWidth < 400 ? 11.0 : 12.0);
    final finalIconSize = iconSize ?? (screenWidth < 360 ? 12.0 : screenWidth < 400 ? 13.0 : 14.0);
    
    return Row(
      children: [
        Icon(
          icon,
          size: finalIconSize,
          color: Theme.of(context).iconTheme.color,
        ),
        SizedBox(width: screenWidth < 360 ? 3.0 : 4.0),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: finalFontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage() {
    return Hero(
      tag: heroTagPrefix != null 
          ? '${heroTagPrefix}_${location.id}' 
          : location.id,
      child: Builder(
        builder: (context) => _buildTypography(context),
      ),
    );
  }

  Widget _buildTypography(BuildContext context) {
    final category = location.category.toLowerCase();
    final mediaType = location.mediaType?.toLowerCase();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallCard = isHorizontal;

    // 1. Determine Base Category Icon & Gradient
    IconData icon;
    Color iconColor;
    List<Color> gradientColors;

    if (category.contains('restaurant') || category.contains('식당') || category.contains('레스토랑')) {
      icon = Icons.restaurant;
      iconColor = const Color(0xFF8B4513);
      gradientColors = [const Color(0xFFE8D8A8), const Color(0xFFD4A574)];
    } else if (category.contains('cafe') || category.contains('카페')) {
      icon = Icons.local_cafe;
      iconColor = const Color(0xFF5A5754);
      gradientColors = [const Color(0xFFB8B5B0), const Color(0xFF9B8FA8)];
    } else if (category.contains('park') || category.contains('공원')) {
      icon = Icons.park;
      iconColor = const Color(0xFF2D5016);
      gradientColors = [const Color(0xFFB8D4B8), const Color(0xFF9BC49B)];
    } else if (category.contains('building') || category.contains('건물')) {
      icon = Icons.business;
      iconColor = Colors.white;
      gradientColors = [const Color(0xFF6BA3C7), const Color(0xFF3A4A5C)];
    } else if (category.contains('street') || category.contains('거리')) {
      icon = Icons.streetview;
      iconColor = Colors.white;
      gradientColors = [const Color(0xFF9B8FA8), const Color(0xFFB8A5C7)];
    } else if (category.contains('shop') || category.contains('상점') || category.contains('매장')) {
      icon = Icons.shopping_bag;
      iconColor = const Color(0xFF8B4513);
      gradientColors = [const Color(0xFFE8D8A8), const Color(0xFFD4A574)];
    } else if (category.contains('hotel') || category.contains('호텔') || category.contains('숙소')) {
      icon = Icons.hotel;
      iconColor = Colors.white;
      gradientColors = [const Color(0xFF3A4A5C), const Color(0xFF6BA3C7)];
    } else {
      icon = Icons.place;
      iconColor = Colors.white;
      gradientColors = [const Color(0xFF3A4A5C), const Color(0xFF6BA3C7)];
    }

    final baseIconSize = isSmallCard
        ? (screenWidth < 360 ? 36.0 : screenWidth < 400 ? 40.0 : 44.0)
        : (screenWidth < 360 ? 56.0 : screenWidth < 400 ? 64.0 : 72.0);

    // 2. Determine Sector Marker Overlay (if any)
    String? markerAsset;
    Color? sectorColor;
    if (mediaType != null) {
      markerAsset = MapService.instance.getMarkerAssetForLocation(location);
      
      // Map marker asset to sector color for fallback icons
      if (mediaType == 'blackwhite') {
        sectorColor = const Color(0xFF2C2C2C);
      } else if (mediaType == 'guide') {
        sectorColor = const Color(0xFFB71C1C);
      } else if (mediaType == 'show' || mediaType == 'artist') {
        sectorColor = const Color(0xFF6A1B9A);
      }
    }

    return Stack(
      children: [
        // Base: Gradient + Category Icon
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: baseIconSize,
              color: iconColor,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        
        // Overlay: Sector Marker in Bottom Right
        if (markerAsset != null)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: isSmallCard ? 24 : 32,
              height: isSmallCard ? 24 : 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  markerAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => Icon(
                    Icons.place, 
                    color: sectorColor ?? Colors.red, 
                    size: isSmallCard ? 16 : 24
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectorTag(BuildContext context, String label, Color color, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String? _getSectorLabel() {
    final mediaType = location.mediaType?.toLowerCase();
    
    if (mediaType == 'guide') {
      return location.michelinTier;
    } else if (mediaType == 'blackwhite') {
      final title = location.contentTitle ?? '';
      if (title.contains('시즌1')) return '시즌 1';
      if (title.contains('시즌2')) return '시즌 2';
      return '흑백요리사';
    } else if (mediaType == 'show' || mediaType == 'artist') {
      return location.contentTitle;
    }
    return null;
  }

  Color _getSectorColor() {
    final mediaType = location.mediaType?.toLowerCase();
    if (mediaType == 'guide') return const Color(0xFFB71C1C); // Michelin Red
    if (mediaType == 'blackwhite') {
        // In dark mode, dark grey is invisible. Use White or Light Grey.
        // We can't access context here easily without changing signature.
        // But we can check if we want to return a fixed color that works on both or distinct?
        // Let's use a color that works on both or rely on the caller to adjust opacity.
        // Actually, 0xFF2C2C2C is very dark. 
        // Let's return a slightly lighter grey that might work, or we should pass context.
        return const Color(0xFF424242); // Slightly lighter grey, but still might be dark on dark bg.
    } 
    if (mediaType == 'show' || mediaType == 'artist') return const Color(0xFF6A1B9A); // TV Purple
    return Colors.grey;
  }

  Color _getSectorColorForContext(BuildContext context) {
      final mediaType = location.mediaType?.toLowerCase();
      final isDark = Theme.of(context).brightness == Brightness.dark;
      if (mediaType == 'blackwhite') {
          return isDark ? Colors.white70 : const Color(0xFF2C2C2C);
      }
      return _getSectorColor();
  }
}
