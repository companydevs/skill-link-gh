import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../data/repository/artisan_repository.dart';
import '../../presentation/in_app_messaging/in_app_messaging.dart';
import '../../services/presence_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/map_view_widget.dart';

class SearchAndDiscoveryScreen extends StatefulWidget {
  const SearchAndDiscoveryScreen({super.key});
  @override
  State<SearchAndDiscoveryScreen> createState() =>
      _SearchAndDiscoveryScreenState();
}

class _SearchAndDiscoveryScreenState extends State<SearchAndDiscoveryScreen> {
  String? _selectedCategory;
  String _searchQuery = '';
  String _sortBy = 'distance';
  LatLng _currentLocation = const LatLng(5.6037, -0.1870);
  bool _locationReady = false;
  bool _isLoadingArtisans = false;
  List<Map<String, dynamic>> _artisans = [];
  final ArtisanRepository _repo = ArtisanRepository();
  final Map<String, dynamic> _filters = {
    'distance': 10.0,
    'minRating': 0.0,
    'availability': 'any',
    'verifiedOnly': false,
  };
  final List<String> _categories = [
    'All',
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Cleaning',
    'Painting',
    'Masonry',
    'Welding',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final s = await Permission.location.request();
      if (s.isGranted) {
        await _getLocation();
      } else {
        _markReady(_currentLocation);
      }
    } catch (_) {
      _markReady(_currentLocation);
    }
  }

  Future<void> _getLocation() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null &&
          DateTime.now().difference(last.timestamp).inMinutes < 5) {
        _markReady(LatLng(last.latitude, last.longitude));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 10));
      _markReady(LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      _markReady(_currentLocation);
    }
  }

  void _markReady(LatLng loc) {
    if (!mounted) return;
    setState(() {
      _currentLocation = loc;
      _locationReady = true;
    });
    _loadArtisans();
  }

  Future<void> _loadArtisans() async {
    if (!mounted) return;
    setState(() => _isLoadingArtisans = true);
    try {
      final list = await _repo.fetchArtisans(
        userLat: _currentLocation.latitude,
        userLng: _currentLocation.longitude,
      );
      if (mounted)
        setState(() {
          _artisans = list;
          _isLoadingArtisans = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoadingArtisans = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var f = List<Map<String, dynamic>>.from(_artisans);
    if (_searchQuery.isNotEmpty) {
      f = f.where((a) {
        final n = (a['name'] as String).toLowerCase();
        final s = (a['services'] as List).join(' ').toLowerCase();
        return n.contains(_searchQuery.toLowerCase()) ||
            s.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    if (_selectedCategory != null && _selectedCategory != 'All') {
      f = f
          .where(
            (a) => (a['services'] as List).any(
              (s) => (s as String).toLowerCase().contains(
                _selectedCategory!.toLowerCase(),
              ),
            ),
          )
          .toList();
    }
    f = f.where((a) {
      if ((a['distance'] as double) > (_filters['distance'] as double))
        return false;
      if ((a['rating'] as double) < (_filters['minRating'] as double))
        return false;
      if ((_filters['verifiedOnly'] as bool) && !(a['isVerified'] as bool))
        return false;
      if (_filters['availability'] != 'any' && !(a['isAvailable'] as bool))
        return false;
      return true;
    }).toList();
    if (_sortBy == 'rating')
      f.sort(
        (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
      );
    if (_sortBy == 'distance')
      f.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );
    return f;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: 80.h,
        child: FilterBottomSheetWidget(
          currentFilters: _filters,
          onApplyFilters: (f) => setState(() => _filters.addAll(f)),
        ),
      ),
    );
  }

  void _showSearchSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                onChanged: (q) => setState(() => _searchQuery = q),
                decoration: InputDecoration(
                  hintText: 'Search artisans or services...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((name) {
                  final sel =
                      _selectedCategory == name ||
                      (name == 'All' && _selectedCategory == null);
                  return GestureDetector(
                    onTap: () {
                      setState(
                        () => _selectedCategory = name == 'All' ? null : name,
                      );
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: sel
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showArtisanList() {
    final artisans = _filtered;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ArtisanListSheet(
        artisans: artisans,
        sortBy: _sortBy,
        onSortChanged: (s) => setState(() => _sortBy = s),
        onViewProfile: (a) => Navigator.pushNamed(
          context,
          '/artisan-profile-screen',
          arguments: a,
        ),
        onBookNow: (a) => Navigator.pushNamed(
          context,
          '/service-booking-screen',
          arguments: a,
        ),
        onMessage: (a) => Navigator.pushNamed(
          context,
          '/in-app-messaging-screen',
          arguments: ChatArgs(
            otherUserId: a['id'] as String,
            otherUserName: a['name'] as String,
            otherUserAvatar: a['profileImage'] as String? ?? '',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;
    final hasFilter = _searchQuery.isNotEmpty || _selectedCategory != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          if (_locationReady)
            Positioned.fill(
              child: MapViewWidget(
                artisans: filtered,
                currentLocation: _currentLocation,
                onArtisanSelected: (a) => Navigator.pushNamed(
                  context,
                  '/artisan-profile-screen',
                  arguments: a,
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.surface,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Finding artisans near you...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top-right buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 12,
            child: Column(
              children: [
                _MapBtn(icon: Icons.search, onTap: _showSearchSheet),
                const SizedBox(height: 8),
                _MapBtn(icon: Icons.tune, onTap: _showFilterSheet),
              ],
            ),
          ),

          // Active filter pill
          if (hasFilter)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 12,
              child: GestureDetector(
                onTap: () => setState(() {
                  _searchQuery = '';
                  _selectedCategory = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCategory ?? _searchQuery,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.close, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ),

          // Artisan count pill
          if (_locationReady && !_isLoadingArtisans)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 72,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _showArtisanList,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${filtered.length} artisan${filtered.length == 1 ? '' : 's'} nearby',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 2),
    );
  }
}

// â”€â”€ Floating map button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
      ),
    );
  }
}

// â”€â”€ Artisan list bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ArtisanListSheet extends StatelessWidget {
  final List<Map<String, dynamic>> artisans;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<Map<String, dynamic>> onViewProfile;
  final ValueChanged<Map<String, dynamic>> onBookNow;
  final ValueChanged<Map<String, dynamic>> onMessage;
  const _ArtisanListSheet({
    required this.artisans,
    required this.sortBy,
    required this.onSortChanged,
    required this.onViewProfile,
    required this.onBookNow,
    required this.onMessage,
  });

  void _sortSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            for (final s in [
              ('distance', 'Distance', Icons.location_on_outlined),
              ('rating', 'Rating', Icons.star_outline),
            ])
              ListTile(
                leading: Icon(
                  s.$3,
                  color: sortBy == s.$1
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(s.$2),
                trailing: sortBy == s.$1
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  onSortChanged(s.$1);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (ctx, ctrl) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '${artisans.length} artisan${artisans.length == 1 ? '' : 's'} nearby',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _sortSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sort,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sortBy == 'rating' ? 'Rating' : 'Distance',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: artisans.isEmpty
                  ? Center(
                      child: Text(
                        'No artisans found',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                      ),
                      itemCount: artisans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ArtisanCard(
                        artisan: artisans[i],
                        onViewProfile: () => onViewProfile(artisans[i]),
                        onBookNow: () => onBookNow(artisans[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Artisan card with real-time presence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ArtisanCard extends StatelessWidget {
  final Map<String, dynamic> artisan;
  final VoidCallback onViewProfile;
  final VoidCallback onBookNow;
  const _ArtisanCard({
    required this.artisan,
    required this.onViewProfile,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = artisan['id'] as String;
    final rating = (artisan['rating'] as num?)?.toDouble() ?? 0.0;
    final services = (artisan['services'] as List?)?.cast<String>() ?? [];
    final isVerified = artisan['isVerified'] as bool? ?? false;
    final durationMins = artisan['durationMinutes'] as int?;
    final distKm = (artisan['distance'] as num).toDouble();
    final mins = durationMins ?? (distKm * 3).round().clamp(1, 999);
    final distLabel = distKm > 0
        ? '${distKm.toStringAsFixed(1)} km · $mins min'
        : '$mins min away';
    final img = (artisan['profileImage'] as String?)?.isNotEmpty == true
        ? artisan['profileImage'] as String
        : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

    return GestureDetector(
      onTap: onViewProfile,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with real-time online dot
            StreamBuilder<Map<String, dynamic>>(
              stream: PresenceService.presenceStream(id),
              builder: (_, snap) {
                final isOnline = snap.data?['isOnline'] as bool? ?? false;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        img,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 52,
                          height: 52,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF9E9E9E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2.5,
                          ),
                          boxShadow: isOnline
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF22C55E,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          artisan['name'] as String? ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF4CAF50)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Verified',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF4CAF50),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Last seen text under name
                  StreamBuilder<Map<String, dynamic>>(
                    stream: PresenceService.presenceStream(id),
                    builder: (_, snap) {
                      final isOnline = snap.data?['isOnline'] as bool? ?? false;
                      final lastSeen = snap.data?['lastSeen'] as Timestamp?;
                      return Text(
                        isOnline
                            ? '🟢 Online'
                            : PresenceService.recentLastSeenLabel(lastSeen),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isOnline
                              ? const Color(0xFF22C55E)
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isOnline
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        distLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('·'),
                      ),
                      Flexible(
                        child: Text(
                          services.isNotEmpty ? services.first : 'Artisan',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('·'),
                      ),
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onViewProfile,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Profile',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onBookNow,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Book Now',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
