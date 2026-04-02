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
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didUpdateWidget(MapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artisans != widget.artisans) {
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
        final offsetLat = (rng.nextDouble() - 0.5) * 0.04;
        final offsetLng = (rng.nextDouble() - 0.5) * 0.04;
        lat = widget.currentLocation.latitude + offsetLat;
        lng = widget.currentLocation.longitude + offsetLng;
        artisan['_lat'] = lat;
        artisan['_lng'] = lng;
      } else {
        artisan['_lat'] = lat;
        artisan['_lng'] = lng;
      }

      final isSelected =
          _selectedArtisan != null && _selectedArtisan!['id'] == artisan['id'];

      final imageUrl = (artisan['profileImage'] as String?)?.isNotEmpty == true
          ? artisan['profileImage'] as String
          : kDefaultMaleAvatarUrl;

      final icon = await _buildCircularMarkerIcon(imageUrl, isSelected);

      markers.add(
        Marker(
          markerId: MarkerId(artisan['id'].toString()),
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
    setState(() {
      _selectedArtisan = artisan;
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            widget.currentLocation,
            LatLng(
              (artisan['_lat'] as double?) ??
                  (artisan['latitude'] as num).toDouble(),
              (artisan['_lng'] as double?) ??
                  (artisan['longitude'] as num).toDouble(),
            ),
          ],
          color: const Color(0xFF4CAF50),
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(8)],
        ),
      };
    });
    _buildMarkers();
  }

  Future<BitmapDescriptor> _buildCircularMarkerIcon(
    String imageUrl,
    bool isSelected,
  ) async {
    const int imgSize = 56;
    const double borderWidth = 3;
    const double pinTail = 10;
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

      // Shadow
      canvas.drawCircle(
        Offset(cx, circleRadius),
        circleRadius + 1,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Border circle
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

      // Pin tail
      final tailPath = Path()
        ..moveTo(cx - 8, circleRadius * 2 - 4)
        ..lineTo(cx + 8, circleRadius * 2 - 4)
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

  String _distanceLabel(double km) {
    final minutes = (km * 3).round().clamp(1, 999);
    return '$minutes min${minutes == 1 ? '' : 's'} away';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Map (55% of screen) ──────────────────────────────────────────
        SizedBox(
          height: 55.h,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.currentLocation,
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _mapController = c,
            onTap: (_) {
              setState(() {
                _selectedArtisan = null;
                _polylines = {};
              });
              _buildMarkers();
            },
          ),
        ),

        // ── List section ─────────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'These are the available artisans',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.tune,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ],
                ),
              ),

              // Artisan cards
              Expanded(
                child: widget.artisans.isEmpty
                    ? Center(
                        child: Text(
                          'No artisans found nearby',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: _listScrollController,
                        padding: EdgeInsets.symmetric(horizontal: 4.w).copyWith(
                          bottom: MediaQuery.of(context).padding.bottom + 1.h,
                        ),
                        itemCount: widget.artisans.length,
                        separatorBuilder: (_, __) => SizedBox(height: 1.2.h),
                        itemBuilder: (context, index) {
                          final artisan = widget.artisans[index];
                          final isSelected =
                              _selectedArtisan != null &&
                              _selectedArtisan!['id'] == artisan['id'];
                          return _ArtisanMapCard(
                            artisan: artisan,
                            isSelected: isSelected,
                            distanceLabel: _distanceLabel(
                              (artisan['distance'] as num).toDouble(),
                            ),
                            onTap: () {
                              _selectArtisan(artisan);
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(
                                    (artisan['_lat'] as double?) ??
                                        (artisan['latitude'] as num).toDouble(),
                                    (artisan['_lng'] as double?) ??
                                        (artisan['longitude'] as num)
                                            .toDouble(),
                                  ),
                                ),
                              );
                            },
                            onBookNow: () => Navigator.pushNamed(
                              context,
                              '/service-booking-screen',
                              arguments: artisan,
                            ),
                            onViewProfile: () =>
                                widget.onArtisanSelected(artisan),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _listScrollController.dispose();
    super.dispose();
  }
}

// ── Artisan card for map list ─────────────────────────────────────────────────
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
    final rating = (artisan['rating'] as num?)?.toDouble() ?? 0.0;
    final services = (artisan['services'] as List?)?.cast<String>() ?? [];
    final imageUrl = (artisan['profileImage'] as String?)?.isNotEmpty == true
        ? artisan['profileImage'] as String
        : kDefaultMaleAvatarUrl;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 14.w,
                  height: 14.w,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 14.w,
                    height: 14.w,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            artisan['name'] as String,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF4CAF50),
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
                    SizedBox(height: 0.5.h),

                    // Distance · experience · rating
                    Row(
                      children: [
                        Text(
                          distanceLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        _dot(theme),
                        Text(
                          services.isNotEmpty ? services.first : 'Artisan',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        _dot(theme),
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        SizedBox(width: 0.5.w),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),

                    // Book / View row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onViewProfile,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 0.6.h),
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
                              padding: EdgeInsets.symmetric(vertical: 0.6.h),
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
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      '·',
      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
    ),
  );
}
