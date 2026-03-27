import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/artisan_card_widget.dart';
import './widgets/category_chips_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/map_view_widget.dart';
import './widgets/search_bar_widget.dart';

class SearchAndDiscoveryScreen extends StatefulWidget {
  const SearchAndDiscoveryScreen({super.key});

  @override
  State<SearchAndDiscoveryScreen> createState() =>
      _SearchAndDiscoveryScreenState();
}

class _SearchAndDiscoveryScreenState extends State<SearchAndDiscoveryScreen> {
  bool _isMapView = false;
  String? _selectedCategory;
  String _searchQuery = '';
  String _sortBy = 'distance';
  LatLng _currentLocation = const LatLng(5.6037, -0.1870);
  bool _isLoadingLocation = true;

  final Map<String, dynamic> _filters = {
    'distance': 10.0,
    'minPrice': 0.0,
    'maxPrice': 1000.0,
    'minRating': 0.0,
    'availability': 'any',
    'verifiedOnly': false,
  };

  final List<String> _recentSearches = [
    'Plumber near me',
    'Electrician',
    'Carpenter',
    'House cleaning',
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': 'apps'},
    {'name': 'Plumbing', 'icon': 'plumbing'},
    {'name': 'Electrical', 'icon': 'electrical_services'},
    {'name': 'Carpentry', 'icon': 'carpenter'},
    {'name': 'Cleaning', 'icon': 'cleaning_services'},
    {'name': 'Painting', 'icon': 'format_paint'},
    {'name': 'Masonry', 'icon': 'construction'},
    {'name': 'Welding', 'icon': 'hardware'},
  ];

  final List<Map<String, dynamic>> _mockArtisans = [
    {
      'id': 1,
      'name': 'Kwame Mensah',
      'profileImage':
          'https://img.rocket.new/generatedImages/rocket_gen_img_103ed5b0c-1763301455344.png',
      'semanticLabel':
          'Professional headshot of African man with short black hair wearing blue work shirt',
      'services': ['Plumbing', 'Pipe Fitting'],
      'rating': 4.8,
      'distance': 1.2,
      'isAvailable': true,
      'isVerified': true,
      'latitude': 5.6137,
      'longitude': -0.1770,
      'priceRange': 'GHS 50-200',
    },
    {
      'id': 2,
      'name': 'Ama Osei',
      'profileImage':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1a0ea65bb-1763296441079.png',
      'semanticLabel':
          'Professional headshot of African woman with braided hair wearing yellow work uniform',
      'services': ['Electrical', 'Wiring'],
      'rating': 4.9,
      'distance': 2.5,
      'isAvailable': true,
      'isVerified': true,
      'latitude': 5.5937,
      'longitude': -0.1970,
      'priceRange': 'GHS 80-300',
    },
    {
      'id': 3,
      'name': 'Kofi Asante',
      'profileImage':
          'https://img.rocket.new/generatedImages/rocket_gen_img_19b49695f-1763293153611.png',
      'semanticLabel':
          'Professional headshot of African man with short hair wearing green work shirt',
      'services': ['Carpentry', 'Furniture'],
      'rating': 4.7,
      'distance': 3.8,
      'isAvailable': false,
      'isVerified': true,
      'latitude': 5.6237,
      'longitude': -0.1670,
      'priceRange': 'GHS 100-500',
    },
    {
      'id': 4,
      'name': 'Akosua Boateng',
      'profileImage':
          'https://img.rocket.new/generatedImages/rocket_gen_img_13661fd1e-1763300454485.png',
      'semanticLabel':
          'Professional headshot of African woman with short hair wearing pink cleaning uniform',
      'services': ['Cleaning', 'Deep Cleaning'],
      'rating': 4.6,
      'distance': 4.2,
      'isAvailable': true,
      'isVerified': false,
      'latitude': 5.5837,
      'longitude': -0.2070,
      'priceRange': 'GHS 40-150',
    },
    {
      'id': 5,
      'name': 'Yaw Owusu',
      'profileImage':
          'https://img.rocket.new/generatedImages/rocket_gen_img_153041a11-1763292325606.png',
      'semanticLabel':
          'Professional headshot of African man with beard wearing orange work shirt',
      'services': ['Painting', 'Interior Design'],
      'rating': 4.5,
      'distance': 5.1,
      'isAvailable': true,
      'isVerified': true,
      'latitude': 5.6337,
      'longitude': -0.1570,
      'priceRange': 'GHS 60-250',
    },
  ];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      if (status.isGranted) {
        await _getCurrentLocation();
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Try last known position first — instant, no GPS wait
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() {
          _currentLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
          _isLoadingLocation = false;
        });
        return;
      }

      // Fall back to current position with a 8s timeout
      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 8),
            ),
          ).timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Location timeout'),
          );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      // Fall back to default location (Accra) silently
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredArtisans {
    var filtered = List<Map<String, dynamic>>.from(_mockArtisans);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((artisan) {
        final name = (artisan['name'] as String).toLowerCase();
        final services = (artisan['services'] as List).join(' ').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || services.contains(query);
      }).toList();
    }

    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered.where((artisan) {
        return (artisan['services'] as List).any(
          (service) => (service as String).toLowerCase().contains(
            _selectedCategory!.toLowerCase(),
          ),
        );
      }).toList();
    }

    filtered = filtered.where((artisan) {
      final distance = artisan['distance'] as double;
      final rating = artisan['rating'] as double;
      final isVerified = artisan['isVerified'] as bool;

      if (distance > (_filters['distance'] as double)) return false;
      if (rating < (_filters['minRating'] as double)) return false;
      if ((_filters['verifiedOnly'] as bool) && !isVerified) return false;

      if (_filters['availability'] == 'today' ||
          _filters['availability'] == 'week') {
        if (!(artisan['isAvailable'] as bool)) return false;
      }

      return true;
    }).toList();

    switch (_sortBy) {
      case 'rating':
        filtered.sort(
          (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
        );
        break;
      case 'distance':
        filtered.sort(
          (a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double),
        );
        break;
      case 'price':
        break;
      case 'availability':
        filtered.sort((a, b) {
          final aAvailable = a['isAvailable'] as bool;
          final bAvailable = b['isAvailable'] as bool;
          return aAvailable == bAvailable ? 0 : (aAvailable ? -1 : 1);
        });
        break;
    }

    return filtered;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: 80.h,
        child: FilterBottomSheetWidget(
          currentFilters: _filters,
          onApplyFilters: (filters) {
            setState(() {
              _filters.addAll(filters);
            });
          },
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 12.w,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Sort By',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'location_on',
                color: _sortBy == 'distance'
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              title: Text('Distance'),
              trailing: _sortBy == 'distance'
                  ? CustomIconWidget(
                      iconName: 'check',
                      color: theme.colorScheme.primary,
                      size: 24,
                    )
                  : null,
              onTap: () {
                setState(() {
                  _sortBy = 'distance';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'star',
                color: _sortBy == 'rating'
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              title: Text('Rating'),
              trailing: _sortBy == 'rating'
                  ? CustomIconWidget(
                      iconName: 'check',
                      color: theme.colorScheme.primary,
                      size: 24,
                    )
                  : null,
              onTap: () {
                setState(() {
                  _sortBy = 'rating';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'attach_money',
                color: _sortBy == 'price'
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              title: Text('Price'),
              trailing: _sortBy == 'price'
                  ? CustomIconWidget(
                      iconName: 'check',
                      color: theme.colorScheme.primary,
                      size: 24,
                    )
                  : null,
              onTap: () {
                setState(() {
                  _sortBy = 'price';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'schedule',
                color: _sortBy == 'availability'
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              title: Text('Availability'),
              trailing: _sortBy == 'availability'
                  ? CustomIconWidget(
                      iconName: 'check',
                      color: theme.colorScheme.primary,
                      size: 24,
                    )
                  : null,
              onTap: () {
                setState(() {
                  _sortBy = 'availability';
                });
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _handleVoiceSearch() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voice search feature coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredArtisans = _filteredArtisans;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Search & Discover',
        variant: AppBarVariant.standard,
        actions: [
          AppBarAction(
            icon: Icons.notifications_outlined,
            onPressed: () {},
            badgeCount: 3,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              color: theme.colorScheme.surface,
              child: Column(
                children: [
                  SearchBarWidget(
                    onSearchChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                    onSearchSubmitted: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                    onVoiceSearch: _handleVoiceSearch,
                    recentSearches: _recentSearches,
                    onRecentSearchTap: (search) {
                      setState(() {
                        _searchQuery = search;
                      });
                    },
                  ),
                  SizedBox(height: 2.h),
                  CategoryChipsWidget(
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategory = category == 'All' ? null : category;
                      });
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${filteredArtisans.length} artisans found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showSortBottomSheet,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: CustomIconWidget(
                      iconName: 'sort',
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    label: Text('Sort'),
                  ),
                  SizedBox(width: 1.w),
                  TextButton.icon(
                    onPressed: _showFilterBottomSheet,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: CustomIconWidget(
                      iconName: 'filter_list',
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    label: Text('Filter'),
                  ),
                  IconButton(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    constraints: const BoxConstraints(),
                    icon: CustomIconWidget(
                      iconName: _isMapView ? 'list' : 'map',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _isMapView = !_isMapView;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingLocation
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 2.h),
                          Text(
                            'Getting your location...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _isMapView
                  ? MapViewWidget(
                      artisans: filteredArtisans,
                      currentLocation: _currentLocation,
                      onArtisanSelected: (artisan) {
                        Navigator.pushNamed(
                          context,
                          '/artisan-profile-screen',
                          arguments: artisan,
                        );
                      },
                    )
                  : filteredArtisans.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'search_off',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 64,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'No artisans found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Try adjusting your filters or search in a different area',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 3.h),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = null;
                                  _filters['distance'] = 10.0;
                                  _filters['minPrice'] = 0.0;
                                  _filters['maxPrice'] = 1000.0;
                                  _filters['minRating'] = 0.0;
                                  _filters['availability'] = 'any';
                                  _filters['verifiedOnly'] = false;
                                });
                              },
                              child: Text('Reset Filters'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        top: 1.h,
                        bottom: MediaQuery.of(context).padding.bottom + 2.h,
                      ),
                      itemCount: filteredArtisans.length,
                      itemBuilder: (context, index) {
                        final artisan = filteredArtisans[index];
                        return ArtisanCardWidget(
                          artisan: artisan,
                          onViewProfile: () {
                            Navigator.pushNamed(
                              context,
                              '/artisan-profile-screen',
                              arguments: artisan,
                            );
                          },
                          onMessage: () {
                            Navigator.pushNamed(context, '/posts-homepage');
                          },
                          onBookNow: () {
                            Navigator.pushNamed(
                              context,
                              '/service-booking-screen',
                              arguments: artisan,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(currentIndex: 2),
    );
  }
}
