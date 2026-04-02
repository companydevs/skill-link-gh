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

/// Map view widget displaying artisan locations with circular profile image markers
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
  Map<String, dynamic>? _selectedArtisan;

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

      // No stored location — scatter around current location so they show on map
      if (lat == null || lng == null) {
        final offsetLat = (rng.nextDouble() - 0.5) * 0.04;
        final offsetLng = (rng.nextDouble() - 0.5) * 0.04;
        lat = widget.currentLocation.latitude + offsetLat;
        lng = widget.currentLocation.longitude + offsetLng;
      }

      final imageUrl = (artisan['profileImage'] as String?)?.isNotEmpty == true
          ? artisan['profileImage'] as String
          : kDefaultMaleAvatarUrl;

      final icon = await _buildCircularMarkerIcon(imageUrl);

      markers.add(
        Marker(
          markerId: MarkerId(artisan['id'].toString()),
          position: LatLng(lat, lng),
          icon: icon,
          anchor: const Offset(0.5, 1.0),
          onTap: () => setState(() => _selectedArtisan = artisan),
        ),
      );
    }

    // Current location marker
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: widget.currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    if (mounted) setState(() => _markers = markers);
  }

  /// Renders a circular avatar with a white border + pin tail as a BitmapDescriptor
  Future<BitmapDescriptor> _buildCircularMarkerIcon(String imageUrl) async {
    const int size = 80;
    const int imgSize = 60;
    const double borderWidth = 3;
    const double pinTail = 10;

    try {
      // Fetch image bytes
      Uint8List? imageBytes;
      try {
        final response = await http
            .get(Uri.parse(imageUrl))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) imageBytes = response.bodyBytes;
      } catch (_) {}

      // Fall back to default if fetch failed
      if (imageBytes == null) {
        try {
          final response = await http
              .get(Uri.parse(kDefaultMaleAvatarUrl))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) imageBytes = response.bodyBytes;
        } catch (_) {}
      }

      if (imageBytes == null) return BitmapDescriptor.defaultMarker;

      // Decode image
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: imgSize,
        targetHeight: imgSize,
      );
      final frame = await codec.getNextFrame();
      final srcImage = frame.image;

      // Draw onto canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const double cx = size / 2;
      const double circleTop = 0;
      const double circleRadius = imgSize / 2 + borderWidth;

      // White border circle
      canvas.drawCircle(
        const Offset(cx, circleTop + circleRadius),
        circleRadius,
        Paint()..color = Colors.white,
      );

      // Clip to circle and draw image
      final clipPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(cx, circleTop + circleRadius),
            radius: imgSize / 2,
          ),
        );
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
          circleTop,
          imgSize.toDouble(),
          imgSize.toDouble(),
        ),
        Paint(),
      );

      // Pin tail triangle (drawn outside clip — need new layer)
      final recorder2 = ui.PictureRecorder();
      final canvas2 = Canvas(recorder2);

      // Redraw white border
      canvas2.drawCircle(
        const Offset(cx, circleTop + circleRadius),
        circleRadius,
        Paint()..color = Colors.white,
      );

      // Clip and draw image again
      canvas2.save();
      canvas2.clipPath(clipPath);
      canvas2.drawImageRect(
        srcImage,
        Rect.fromLTWH(
          0,
          0,
          srcImage.width.toDouble(),
          srcImage.height.toDouble(),
        ),
        Rect.fromLTWH(
          cx - imgSize / 2,
          circleTop,
          imgSize.toDouble(),
          imgSize.toDouble(),
        ),
        Paint(),
      );
      canvas2.restore();

      // Pin tail
      final tailPath = Path()
        ..moveTo(cx - 10, circleTop + circleRadius * 2 - 4)
        ..lineTo(cx + 10, circleTop + circleRadius * 2 - 4)
        ..lineTo(cx, circleTop + circleRadius * 2 + pinTail)
        ..close();
      canvas2.drawPath(tailPath, Paint()..color = Colors.white);

      final picture2 = recorder2.endRecording();
      final img = await picture2.toImage(
        size,
        (circleRadius * 2 + pinTail).ceil(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return BitmapDescriptor.defaultMarker;

      return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
    } catch (_) {
      return BitmapDescriptor.defaultMarker;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.currentLocation,
            zoom: 13,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) => _mapController = controller,
          onTap: (_) => setState(() => _selectedArtisan = null),
        ),
        if (_selectedArtisan != null)
          Positioned(
            bottom: 2.h,
            left: 4.w,
            right: 4.w,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl:
                                (_selectedArtisan!['profileImage'] as String?)
                                        ?.isNotEmpty ==
                                    true
                                ? _selectedArtisan!['profileImage'] as String
                                : kDefaultMaleAvatarUrl,
                            width: 15.w,
                            height: 15.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedArtisan!['name'] as String,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                (_selectedArtisan!['services'] as List).join(
                                  ', ',
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.5.h),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    '${_selectedArtisan!['rating']}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Icon(
                                    Icons.location_on,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 14,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    '${_selectedArtisan!['distance']} km',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _selectedArtisan = null),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                widget.onArtisanSelected(_selectedArtisan!),
                            child: const Text('View Profile'),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/service-booking-screen',
                              arguments: _selectedArtisan,
                            ),
                            child: const Text('Book Now'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
