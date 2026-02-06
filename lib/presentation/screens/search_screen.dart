import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../providers/location_provider.dart';
import '../widgets/location_card.dart';
import '../widgets/empty_state.dart';

import '../widgets/distance_slider.dart';
import '../widgets/sector_search_filter.dart';
import '../../data/models/location.dart';
import 'dart:async';
import '../../data/services/preferences_service.dart';
import 'location_detail_screen.dart';
import '../widgets/fade_in_up.dart';
import '../providers/location_provider_service.dart'; // For distance calculation
import '../../data/services/naver_geocoding_service.dart';
import '../../data/services/naver_local_search_service.dart';
import 'package:geolocator/geolocator.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PreferencesService _prefs = PreferencesService.instance;
  List<Location> _searchResults = [];
  bool _isSearching = false;
  List<String> _recentSearches = [];
  bool _hasLoadedData = false;
  int _totalMatchCount = 0; // Count before distance filtering

  String? _selectedCategory;
  double? _selectedDistance;
  List<Map<String, dynamic>> _selectedSectorFilters = [];
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  Position? _referencePosition; // For address-based search

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      _loadRecentSearches();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    setState(() {
      _recentSearches = _prefs.getRecentSearches();
    });
  }

  Future<void> _performSearch(String query, {bool saveToRecent = false}) async {
    if (query.trim().isEmpty && 
        _selectedCategory == null && 
        _selectedSectorFilters.isEmpty && 
        _selectedDistance == null) {
      if (_searchResults.isNotEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() {
      _isSearching = true;
    });

    Position? resolvedPos;
    if (query.isNotEmpty) {
      // Try to resolve query to coordinates
      resolvedPos = await NaverGeocodingService.fetchGeocode(query);
      if (resolvedPos == null) {
        final address = await NaverLocalSearchService.searchPlaceAddress(query);
        if (address != null) {
          resolvedPos = await NaverGeocodingService.fetchGeocode(address);
        }
      }
      
      if (saveToRecent) {
        await _prefs.addRecentSearch(query);
        _loadRecentSearches();
      }
    }

    setState(() {
      _referencePosition = resolvedPos;
    });

    // Perform search
    // If we have a reference position from geocoding, we search ALL locations 
    // to find nearby ones regardless of whether the query string matches their name.
    final searchQuery = (resolvedPos != null) ? "" : query;
    var results = await context.read<LocationDataProvider>().searchLocations(
      searchQuery, 
      category: _selectedCategory
    );

    // Filter by sector if selected (Logical OR across all selected sectors)
    if (_selectedSectorFilters.isNotEmpty) {
      results = results.where((loc) {
        return _selectedSectorFilters.any((filter) {
          final type = filter['type'];
          final value = filter['value'];
          
          if (type == 'bw') {
            // 흑백요리사
            if (loc.mediaType?.toLowerCase() != 'blackwhite') return false;
            if (value == 'season1') return (loc.contentTitle ?? '').contains('시즌1');
            if (value == 'season2') return (loc.contentTitle ?? '').contains('시즌2');
          } else if (type == 'show') {
            // 예능출연 맛집
            return loc.mediaType?.toLowerCase() == 'show';
          } else if (type == 'michelin') {
            // 미슐랭
            if (loc.mediaType?.toLowerCase() != 'guide') return false;
            if (value == 'michelin') return (loc.michelinTier ?? '').toLowerCase() == 'michelin';
            if (value == '1star') return (loc.michelinTier ?? '').toLowerCase() == '1star';
            if (value == '2star') return (loc.michelinTier ?? '').toLowerCase() == '2star';
            if (value == '3star') return (loc.michelinTier ?? '').toLowerCase() == '3star';
            if (value == 'bib') return (loc.michelinTier ?? '').toLowerCase() == 'bib';
          }
          return false;
        });
      }).toList();
    }

    // Sort by distance if we have a reference position (Geographic Search priority)
    if (_referencePosition != null) {
      final dataProvider = context.read<LocationDataProvider>();
      results.sort((a, b) {
        final distA = dataProvider.calculateDistanceBetween(
          _referencePosition!.latitude, 
          _referencePosition!.longitude, 
          a.latitude, 
          a.longitude
        );
        final distB = dataProvider.calculateDistanceBetween(
          _referencePosition!.latitude, 
          _referencePosition!.longitude, 
          b.latitude, 
          b.longitude
        );
        return distA.compareTo(distB);
      });
    }

    // Update total match count (before distance filter)
    _totalMatchCount = results.length;

    // Filter by distance if selected
    List<Location> filteredResults = results;
    if (_selectedDistance != null) {
      final locProvService = context.read<LocationProvider>(); // Loc provider service
      final dataProvider = context.read<LocationDataProvider>();
      
      // Use resolved position if available, otherwise fallback to current location
      double? refLat;
      double? refLng;

      if (_referencePosition != null) {
        refLat = _referencePosition!.latitude;
        refLng = _referencePosition!.longitude;
      } else if (locProvService.hasLocation) {
        refLat = locProvService.currentPosition!.latitude;
        refLng = locProvService.currentPosition!.longitude;
      }

      if (refLat != null && refLng != null) {
        filteredResults = results.where((loc) {
          final dist = dataProvider.calculateDistanceBetween(refLat!, refLng!, loc.latitude, loc.longitude);
          return dist <= _selectedDistance!;
        }).toList();
      }
    }

    setState(() {
      _searchResults = filteredResults;
      _isSearching = false;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query, saveToRecent: false);
    });
    setState(() {}); // Update clear button and potentially other UI
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _performSearch(_searchController.text, saveToRecent: false);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _selectedCategory = null;
      _selectedDistance = null;
      _selectedSectorFilters = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: '지역 검색',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: _clearSearch,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : null,
            ),
            onSubmitted: (val) => _performSearch(val, saveToRecent: true),
            onChanged: _onSearchChanged,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text, saveToRecent: true),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(210),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                      label: const Text('필터 초기화', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              SectorSearchFilter(
                selectedFilters: _selectedSectorFilters,
                onFiltersChanged: (filters) {
                  setState(() {
                    _selectedSectorFilters = filters;
                  });
                  _performSearch(_searchController.text, saveToRecent: false);
                },
              ),
              DistanceSlider(
                selectedDistance: _selectedDistance,
                onDistanceSelected: (val) {
                  setState(() {
                    _selectedDistance = val;
                  });
                  _performSearch(_searchController.text, saveToRecent: false);
                },
                totalCount: _totalMatchCount,
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isNotEmpty
              ? _buildSearchResults()
              : _buildInitialView(),
    );
  }

  Widget _buildInitialView() {
    final screenH = AppSpacing.screenPaddingHorizontal(context);
    final spacingS = AppSpacing.spacingS(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '최근 검색어',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () async {
                    await _prefs.clearRecentSearches();
                    _loadRecentSearches();
                  },
                  child: const Text('전체 삭제'),
                ),
              ],
            ),
            SizedBox(height: spacingS),
            Wrap(
              spacing: spacingS,
              runSpacing: spacingS,
              children: _recentSearches.map((search) {
                return ActionChip(
                  label: Text(search),
                  avatar: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.text = search;
                    _performSearch(search, saveToRecent: true);
                  },
                );
              }).toList().cast<Widget>(),
            ),
            SizedBox(height: AppSpacing.spacingL(context)),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return EmptyState(
        message: '검색 결과가 없습니다',
        icon: Icons.search_off,
        action: ElevatedButton(
          onPressed: _clearSearch,
          child: const Text('다시 검색'),
        ),
      );
    }

    final screenH = AppSpacing.screenPaddingHorizontal(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(screenH),
          child: Text(
            '검색 결과 (${_searchResults.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: screenH),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final location = _searchResults[index];
              final locProvService = context.read<LocationProvider>();
              final dataProvider = context.read<LocationDataProvider>();
              String? distanceStr;
              
              // Reference point for distance display
              double? refLat;
              double? refLng;

              if (_referencePosition != null) {
                refLat = _referencePosition!.latitude;
                refLng = _referencePosition!.longitude;
              } else if (locProvService.hasLocation) {
                refLat = locProvService.currentPosition!.latitude;
                refLng = locProvService.currentPosition!.longitude;
              }

              if (refLat != null && refLng != null) {
                final dist = dataProvider.calculateDistanceBetween(refLat, refLng, location.latitude, location.longitude);
                if (dist < 1.0) {
                  distanceStr = '${(dist * 1000).toInt()}m';
                } else {
                  distanceStr = '${dist.toStringAsFixed(1)}km';
                }
              }

              return FadeInUp(
                delay: Duration(milliseconds: index * 50),
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.spacingS(context)),
                  child: LocationCard(
                    location: location,
                    isHorizontal: true,
                    distance: distanceStr,
                    onTap: () {
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
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
