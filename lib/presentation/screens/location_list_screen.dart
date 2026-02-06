import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../providers/location_provider_service.dart'; // Logic/State provider
import '../providers/location_provider.dart' as data_provider; // Alias if needed for data provider casting
// Wait, looking at the file, 'location_provider.dart' seems to be the logic one? 
// And 'location_data_provider.dart' is likely the data one but it was imported as 'location_provider.dart' as data_provider?
// Let's check imports again.
// Line 4: import '../providers/location_provider.dart' as data_provider;
// But the file content I saw earlier had:
// 4: import '../providers/location_provider.dart' as data_provider;
// But typically LocationDataProvider is in location_provider.dart or location_data_provider.dart?
// Let's look at list_dir of providers again. 
// "location_provider.dart" size 13935
// "location_provider_service.dart" size 2491
// There is no "location_data_provider.dart" in the list_dir output!
// Wait, I saw "import '../providers/location_provider.dart' as data_provider;" in the file view.
// And usage: "context.read<data_provider.LocationDataProvider>()".
// This implies LocationDataProvider class is INSIDE location_provider.dart?
// Or maybe I misread the file content.
// Let's check location_provider.dart content to be sure.
import '../widgets/location_card.dart';
import '../widgets/empty_state.dart';
import '../../data/models/location.dart';
import '../providers/location_provider.dart';
import 'location_detail_screen.dart';

enum ViewMode { list, grid }
enum SortOption { distance, popularity, recent }

class LocationListScreen extends StatefulWidget {
  final String? initialCategory;
  final String? mediaType;
  final String? contentTitle;
  final String? title;
  final double? maxDistance;

  const LocationListScreen({
    super.key,
    this.initialCategory,
    this.mediaType,
    this.contentTitle,
    this.title,
    this.maxDistance, // Added
  });



  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  ViewMode _viewMode = ViewMode.list;
  SortOption _sortOption = SortOption.popularity;
  String? _selectedCategory;
  List<Location> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<data_provider.LocationDataProvider>().loadAllLocations();
    });
  }

  void _applyFiltersAndSort(List<Location> locations) async {
    var filtered = List<Location>.from(locations);

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered
          .where((loc) => loc.category == _selectedCategory)
          .toList();
    }

    // Apply Media Type filter
    if (widget.mediaType != null) {
      filtered = filtered
          .where((loc) => loc.mediaType == widget.mediaType)
          .toList();
    }

    // Apply Content Title filter
    if (widget.contentTitle != null) {
      filtered = filtered
          .where((loc) => loc.contentTitle == widget.contentTitle)
          .toList();
    }

    // Apply Distance filter (NEW)
    if (widget.maxDistance != null) {
      final locationProvider = context.read<data_provider.LocationDataProvider>();
      // Use LocationProvider to calculate distance. 
      // Note: We need the LocationProvider (service) not the data provider for calculation
      // logic if it's there, but LocationDataProvider might have helper or we use LocationProvider.
      // Let's assume we can get LocationProvider (logic) from context.
      final locProvider = context.read<LocationProvider>();
      
      if (locProvider.hasLocation) {
        filtered = filtered.where((loc) {
          final dist = locProvider.calculateDistanceToLocation(loc.latitude, loc.longitude);
          if (dist == null) return false;
          return dist <= widget.maxDistance!;
        }).toList();
      }
    }

    // Apply sorting
    switch (_sortOption) {
      case SortOption.popularity:
        filtered.sort((a, b) =>
            (b.viewCount + b.bookmarkCount * 2)
                .compareTo(a.viewCount + a.bookmarkCount * 2));
        break;
      case SortOption.recent:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.distance:
        // Get current location from provider
        final locationProvider = context.read<LocationProvider>();
        if (locationProvider.hasLocation) {
          filtered.sort((a, b) {
            final distA = locationProvider.calculateDistanceToLocation(
              a.latitude,
              a.longitude,
            ) ?? double.infinity;
            final distB = locationProvider.calculateDistanceToLocation(
              b.latitude,
              b.longitude,
            ) ?? double.infinity;
            return distA.compareTo(distB);
          });
        }
        break;
    }

    setState(() {
      _filteredLocations = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? '맛집 목록'),
        actions: [
          IconButton(
            icon: Icon(_viewMode == ViewMode.list ? Icons.grid_view : Icons.view_list),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list;
              });
            },
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (option) {
              setState(() {
                _sortOption = option;
              });
              _applyFiltersAndSort(context.read<data_provider.LocationDataProvider>().allLocations);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.popularity,
                child: Text('인기순'),
              ),
              const PopupMenuItem(
                value: SortOption.recent,
                child: Text('최신순'),
              ),
              const PopupMenuItem(
                value: SortOption.distance,
                child: Text('거리순'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Consumer<data_provider.LocationDataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadAllLocations(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          // Apply filters when data changes
          if (_filteredLocations.isEmpty && provider.allLocations.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _applyFiltersAndSort(provider.allLocations);
            });
          }

          final locations = _filteredLocations.isEmpty 
              ? provider.allLocations 
              : _filteredLocations;

          if (locations.isEmpty) {
            return const EmptyState(
              message: '맛집이 없습니다',
              icon: Icons.location_off,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadAllLocations();
              _applyFiltersAndSort(provider.allLocations);
            },
            child: _viewMode == ViewMode.list
                ? _buildListView(locations)
                : _buildGridView(locations),
          );
        },
      ),
    );
  }

  Widget _buildListView(List<Location> locations) {
    return Consumer<LocationProvider>(
      builder: (context, locationService, child) {
        final screenH = AppSpacing.screenPaddingHorizontal(context);
        return ListView.builder(
          padding: EdgeInsets.all(screenH),
          itemCount: locations.length,
          itemBuilder: (context, index) {
            final distance = locationService.formatDistanceToLocation(
              locations[index].latitude,
              locations[index].longitude,
            );
            
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.spacingS(context)),
              child: LocationCard(
                location: locations[index],
                isHorizontal: true,
                distance: distance,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationDetailScreen(
                        locationId: locations[index].id,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridView(List<Location> locations) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        return LocationCard(
          location: locations[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocationDetailScreen(
                  locationId: locations[index].id,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.all(AppSpacing.spacingL(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '필터',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedCategory = null;
                        });
                        setState(() {
                          _selectedCategory = null;
                        });
                        _applyFiltersAndSort(
                          context.read<data_provider.LocationDataProvider>().allLocations,
                        );
                      },
                      child: const Text('초기화'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '카테고리',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(
                      '카페',
                      'cafe',
                      setModalState,
                    ),
                    _buildFilterChip(
                      '식당',
                      'restaurant',
                      setModalState,
                    ),
                    _buildFilterChip(
                      '공원',
                      'park',
                      setModalState,
                    ),
                    _buildFilterChip(
                      '건물',
                      'building',
                      setModalState,
                    ),
                    _buildFilterChip(
                      '거리',
                      'street',
                      setModalState,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFiltersAndSort(
                        context.read<data_provider.LocationDataProvider>().allLocations,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('적용'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String category,
    StateSetter setModalState,
  ) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _selectedCategory = selected ? category : null;
        });
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
    );
  }
}
