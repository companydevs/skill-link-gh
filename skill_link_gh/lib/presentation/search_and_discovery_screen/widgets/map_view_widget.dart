import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

const _kMapsKey = 'AIzaSyCeGxqoYlPBqAXDX5JMp89wwJfmQEM-ZWc';
const _kDefaultAvatar =
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

class _MapViewWidgetState extends State<MapViewWidget>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final Map<String, Map<String, BitmapDescriptor>> _iconCache = {};

  // Uber-style animated polyline
  List<LatLng> _fullRoute = [];
  late AnimationController _routeAnim;
  Timer? _routeTimer;

  @override
  void initState() {
    super.initState();
    _routeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _routeAnim.addListener(_onRouteAnimTick);
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

  @override
  void dispose() {
    _routeTimer?.cancel();
    _routeAnim.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Animated polyline draw ─────────────────────────────────────────────────

  void _onRouteAnimTick() {
    if (_fullRoute.isEmpty) return;
    final progress = _routeAnim.value;
    final count = (_fullRoute.length * progress).round().clamp(
      2,
      _fullRoute.length,
    );
    final visible = _fullRoute.sublist(0, count);
    if (mounted) {
      setState(() {
        _polylines = {
          // Shadow for depth
          Polyline(
            polylineId: const PolylineId('route_shadow'),
            points: visible,
            color: Colors.black.withValues(alpha: 0.18),
            width: 12,
            jointType: JointType.round,
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
            geodesic: false,
          ),
          Polyline(
            polylineId: const PolylineId('route'),
            points: visible,
            color: const Color(0xFF1A73E8),
            width: 7,
            jointType: JointType.round,
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
            geodesic: false,
          ),
        };
      });
    }
  }

  void _animateRoute(List<LatLng> points) {
    _fullRoute = points;
    _routeAnim.reset();
    _routeAnim.forward();
  }

  // ── Markers ────────────────────────────────────────────────────────────────

  Future<void> _buildMarkers() async {
    final rng = math.Random();
    final Set<Marker> markers = {};

    for (final artisan in widget.artisans) {
      var lat = (artisan['latitude'] as num?)?.toDouble();
      var lng = (artisan['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        if (artisan['_lat'] != null) {
          lat = artisan['_lat'] as double;
          lng = artisan['_lng'] as double;
        } else {
          lat =
              widget.currentLocation.latitude + (rng.nextDouble() - 0.5) * 0.04;
          lng =
              widget.currentLocation.longitude +
              (rng.nextDouble() - 0.5) * 0.04;
          artisan['_lat'] = lat;
          artisan['_lng'] = lng;
        }
      } else {
        artisan['_lat'] = lat;
        artisan['_lng'] = lng;
      }

      final id = artisan['id'].toString();
      final imageUrl = (artisan['profileImage'] as String?)?.isNotEmpty == true
          ? artisan['profileImage'] as String
          : _kDefaultAvatar;

      if (_iconCache[id] == null) {
        final normal = await _buildMarkerIcon(imageUrl, false);
        final selected = await _buildMarkerIcon(imageUrl, true);
        _iconCache[id] = {'normal': normal, 'selected': selected};
      }

      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
          icon: _iconCache[id]!['normal']!,
          anchor: const Offset(0.5, 1.0),
          onTap: () => _onMarkerTap(artisan),
        ),
      );
    }

    if (mounted) setState(() => _markers = markers);
  }

  void _swapIcon(String selectedId) {
    final updated = _markers.map((m) {
      final cache = _iconCache[m.markerId.value];
      if (cache == null) return m;
      return m.copyWith(
        iconParam: m.markerId.value == selectedId
            ? cache['selected']
            : cache['normal'],
      );
    }).toSet();
    if (mounted) setState(() => _markers = updated);
  }

  Future<void> _onMarkerTap(Map<String, dynamic> artisan) async {
    final lat = artisan['_lat'] as double? ?? widget.currentLocation.latitude;
    final lng = artisan['_lng'] as double? ?? widget.currentLocation.longitude;
    final dest = LatLng(lat, lng);

    _swapIcon(artisan['id'].toString());

    // Fit both points in view
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            math.min(widget.currentLocation.latitude, lat) - 0.005,
            math.min(widget.currentLocation.longitude, lng) - 0.005,
          ),
          northeast: LatLng(
            math.max(widget.currentLocation.latitude, lat) + 0.005,
            math.max(widget.currentLocation.longitude, lng) + 0.005,
          ),
        ),
        80,
      ),
    );

    // Clear old route immediately
    setState(() => _polylines = {});

    final points = await _fetchRoutePoints(widget.currentLocation, dest);
    _animateRoute(points);
  }

  // ── Directions API ─────────────────────────────────────────────────────────

  Future<List<LatLng>> _fetchRoutePoints(LatLng origin, LatLng dest) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${dest.latitude},${dest.longitude}'
        '&mode=driving'
        '&key=$_kMapsKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return _curvedFallback(origin, dest);
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return _curvedFallback(origin, dest);
      final encoded =
          data['routes'][0]['overview_polyline']['points'] as String;
      return _decodePolyline(encoded);
    } catch (_) {
      return _curvedFallback(origin, dest);
    }
  }

  /// Generates a smooth curved arc between two points as a fallback.
  List<LatLng> _curvedFallback(LatLng a, LatLng b) {
    const steps = 40;
    final midLat = (a.latitude + b.latitude) / 2;
    final midLng = (a.longitude + b.longitude) / 2;
    // Perpendicular offset for the curve
    final dLat = b.latitude - a.latitude;
    final dLng = b.longitude - a.longitude;
    final curvature = 0.3;
    final ctrlLat = midLat - dLng * curvature;
    final ctrlLng = midLng + dLat * curvature;

    return List.generate(steps + 1, (i) {
      final t = i / steps;
      final lat =
          (1 - t) * (1 - t) * a.latitude +
          2 * (1 - t) * t * ctrlLat +
          t * t * b.latitude;
      final lng =
          (1 - t) * (1 - t) * a.longitude +
          2 * (1 - t) * t * ctrlLng +
          t * t * b.longitude;
      return LatLng(lat, lng);
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  // ── Circular avatar marker ─────────────────────────────────────────────────

  Future<BitmapDescriptor> _buildMarkerIcon(
    String imageUrl,
    bool selected,
  ) async {
    const int imgSize = 60;
    const double border = 3.5;
    const double tail = 14;
    final double r = imgSize / 2 + border;
    final int w = (r * 2).ceil();
    final int h = (r * 2 + tail).ceil();

    try {
      Uint8List? bytes;
      try {
        final res = await http
            .get(Uri.parse(imageUrl))
            .timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) bytes = res.bodyBytes;
      } catch (_) {}
      if (bytes == null) {
        try {
          final res = await http
              .get(Uri.parse(_kDefaultAvatar))
              .timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) bytes = res.bodyBytes;
        } catch (_) {}
      }
      if (bytes == null) return BitmapDescriptor.defaultMarker;

      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: imgSize,
        targetHeight: imgSize,
      );
      final frame = await codec.getNextFrame();
      final src = frame.image;

      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      final cx = w / 2.0;
      final borderColor = selected ? const Color(0xFF1A73E8) : Colors.white;

      // Drop shadow
      canvas.drawCircle(
        Offset(cx, r + 2),
        r,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Border
      canvas.drawCircle(Offset(cx, r), r, Paint()..color = borderColor);

      // Image
      final clip = Path()
        ..addOval(Rect.fromCircle(center: Offset(cx, r), radius: imgSize / 2));
      canvas.save();
      canvas.clipPath(clip);
      canvas.drawImageRect(
        src,
        Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
        Rect.fromLTWH(
          cx - imgSize / 2,
          border,
          imgSize.toDouble(),
          imgSize.toDouble(),
        ),
        Paint(),
      );
      canvas.restore();

      // Pin tail
      final tailPath = Path()
        ..moveTo(cx - 8, r * 2 - 4)
        ..lineTo(cx + 8, r * 2 - 4)
        ..lineTo(cx, r * 2 + tail)
        ..close();
      canvas.drawPath(tailPath, Paint()..color = borderColor);

      final img = await rec.endRecording().toImage(w, h);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null) return BitmapDescriptor.defaultMarker;
      return BitmapDescriptor.bytes(bd.buffer.asUint8List());
    } catch (_) {
      return BitmapDescriptor.defaultMarker;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.currentLocation,
        zoom: 14,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      onMapCreated: (c) => _mapController = c,
      onTap: (_) {
        _routeAnim.reset();
        setState(() {
          _polylines = {};
          _fullRoute = [];
        });
        _swapIcon('');
      },
    );
  }
}
