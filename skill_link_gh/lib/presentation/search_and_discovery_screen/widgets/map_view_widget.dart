import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';

const kDefaultMaleAvatarUrl =
    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

class MapViewWidget extends StatefulWidget {
  final List<Map<String, dynamic>> artisans;
  final LatLng currentLocation;
  final Function(Map<String, dynamic>) onArtisanSelected;

  const MapViewWidget({
    super.key,
    required this.artisans,
    required this.currentLocation,
    required this.onArtisanSelected,
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Map<String, dynamic>? _selectedArtisan;

  // Cache: artisanId -> {normal: BitmapDescriptor, selected: BitmapDescriptor}
  final Map<String, Map<String, BitmapDescriptor>> _iconCache = {};

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didUpdateWidget(MapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artisans != widget.artisans) {
      _iconCache.clear();
      _buildMarkers();
    }
  }

  Future<void> _buildMarkers() async {
    final Set<Marker> markers = {};
    final rng = math.Random();

    for (final artisan in widget.artisans) {
      var lat = (artisan['latitude'] as num?)?.toDouble();
      var lng = (artisan['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        // Reuse previously assigned offset so markers don't jump on rebuild
        if (artisan['_lat'] != null) {
          lat = artisan['_lat'] as double;
          lng = artisan['_lng'] as double;
        } else {
          final offsetLat = (rng.nextDouble() - 0.5) * 0.04;
          final offsetLng = (rng.nextDouble() - 0.5) * 0.04;
          lat = widget.currentLocation.latitude + offsetLat;
          lng = widget.currentLocation.longitude + offsetLng;
          artisan['_lat'] = lat;
          artisan['_lng'] = lng;
        }
      } else {
        artisan['_lat'] = lat;
        artisan['_lng'] = lng;
      }

      final id = artisan['id'].toString();
      final isSelected =
          _selectedArtisan != null && _selectedArtisan!['id'] == artisan['id'];
      final imageUrl = (artisan['profileImage'] as String?)?.isNotEmpty == true
          ? artisan['profileImage'] as String
          : kDefaultMaleAvatarUrl;

      // Build icon only if not cached
      if (_iconCache[id] == null) {
        final normal = await _buildCircularMarkerIcon(imageUrl, false);
        final selected = await _buildCircularMarkerIcon(imageUrl, true);
        _iconCache[id] = {'normal': normal, 'selected': selected};
      }

      final icon = isSelected
          ? _iconCache[id]!['selected']!
          : _iconCache[id]!['normal']!;

      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
          icon: icon,
          anchor: const Offset(0.5, 1.0),
          onTap: () => _selectArtisan(artisan),
        ),
      );
    }

    if (mounted) setState(() => _markers = markers);
  }

  void _selectArtisan(Map<String, dynamic> artisan) {
    final lat =
        (artisan['_lat'] as double?) ??
        (artisan['latitude'] as num?)?.toDouble() ??
        widget.currentLocation.latitude;
    final lng =
        (artisan['_lng'] as double?) ??
        (artisan['longitude'] as num?)?.toDouble() ??
        widget.currentLocation.longitude;

    setState(() {
      _selectedArtisan = artisan;
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [widget.currentLocation, LatLng(lat, lng)],
          color: const Color(0xFF4CAF50),
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(8)],
        ),
      };
    });

    // Only swap marker icons — no full rebuild needed
    _swapMarkerIcon(artisan['id'].toString());

    _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
  }

  /// Swaps just the selected/normal icon without re-fetching images
  void _swapMarkerIcon(String selectedId) {
    final updated = _markers.map((m) {
      final cache = _iconCache[m.markerId.value];
      if (cache == null) return m;
      final isSelected = m.markerId.value == selectedId;
      return m.copyWith(
        iconParam: isSelected ? cache['selected'] : cache['normal'],
      );
    }).toSet();
    if (mounted) setState(() => _markers = updated);
  }

  Future<BitmapDescriptor> _buildCircularMarkerIcon(
    String imageUrl,
    bool isSelected,
  ) async {
    const int imgSize = 56;
    const double borderWidth = 3;
    const double pinTail = 12;
    final double circleRadius = imgSize / 2 + borderWidth;
    final int canvasW = (circleRadius * 2).ceil();
    final int canvasH = (circleRadius * 2 + pinTail).ceil();

    try {
      Uint8List? imageBytes;
      try {
        final response = await http
            .get(Uri.parse(imageUrl))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) imageBytes = response.bodyBytes;
      } catch (_) {}

      if (imageBytes == null) {
        try {
          final response = await http
              .get(Uri.parse(kDefaultMaleAvatarUrl))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) imageBytes = response.bodyBytes;
        } catch (_) {}
      }

      if (imageBytes == null) return BitmapDescriptor.defaultMarker;

      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: imgSize,
        targetHeight: imgSize,
      );
      final frame = await codec.getNextFrame();
      final srcImage = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final double cx = canvasW / 2;
      final borderColor = isSelected ? const Color(0xFF4CAF50) : Colors.white;

      // Sharp border circle (no blur/shadow)
      canvas.drawCircle(
        Offset(cx, circleRadius),
        circleRadius,
        Paint()..color = borderColor,
      );

      // Clip and draw image
      final clipPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(cx, circleRadius),
            radius: imgSize / 2,
          ),
        );
      canvas.save();
      canvas.clipPath(clipPath);
      canvas.drawImageRect(
        srcImage,
        Rect.fromLTWH(
          0,
          0,
          srcImage.width.toDouble(),
          srcImage.height.toDouble(),
        ),
        Rect.fromLTWH(
          cx - imgSize / 2,
          borderWidth,
          imgSize.toDouble(),
          imgSize.toDouble(),
        ),
        Paint(),
      );
      canvas.restore();

      // Sharp pin tail
      final tailPath = Path()
        ..moveTo(cx - 7, circleRadius * 2 - 3)
        ..lineTo(cx + 7, circleRadius * 2 - 3)
        ..lineTo(cx, circleRadius * 2 + pinTail)
        ..close();
      canvas.drawPath(tailPath, Paint()..color = borderColor);

      final picture = recorder.endRecording();
      final img = await picture.toImage(canvasW, canvasH);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return BitmapDescriptor.defaultMarker;

      return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    } catch (_) {
      return BitmapDescriptor.defaultMarker;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.currentLocation,
            zoom: 14,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (c) => _mapController = c,
          onTap: (_) {
            setState(() {
              _selectedArtisan = null;
              _polylines = {};
            });
            _swapMarkerIcon('');
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// ── Artisan card ──────────────────────────────────────────────────────────────
class _ArtisanMapCard extends StatelessWidget {
  final Map<String, dynamic> artisan;
  final bool isSelected;
  final String distanceLabel;
  final VoidCallback onTap;
  final VoidCallback onBookNow;
  final VoidCallback onViewProfile;

  const _ArtisanMapCard({
    required this.artisan,
    required this.isSelected,
    required this.distanceLabel,
    required this.onTap,
    required this.onBookNow,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerified = artisan['isVerified'] as bool? ?? false;
    final isAvailable = artisan['isAvailable'] as bool? ?? false;
    final rating = (artisan['rating'] as num?)?.toDouble() ?? 0.0;
    final services = (artisan['services'] as List?)?.cast<String>() ?? [];
    final imageUrl = (artisan['profileImage'] as String?)?.isNotEmpty == true
        ? artisan['profileImage'] as String
        : kDefaultMaleAvatarUrl;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4CAF50)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar + online dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 13.w,
                      height: 13.w,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 13.w,
                        height: 13.w,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  if (isAvailable)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 3.w),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name + badge
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
                          SizedBox(width: 1.w),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF4CAF50),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Recommended',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Distance · service · rating
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            distanceLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _dot(theme),
                        Flexible(
                          child: Text(
                            services.isNotEmpty ? services.first : 'Artisan',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _dot(theme),
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
                    const SizedBox(height: 6),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onViewProfile,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide(
                                color: theme.colorScheme.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'View Profile',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
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
      ),
    );
  }

  Widget _dot(ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Text(
      '·',
      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
    ),
  );
}
