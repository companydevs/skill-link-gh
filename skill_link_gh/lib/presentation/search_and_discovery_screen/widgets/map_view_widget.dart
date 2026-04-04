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

class _MapViewWidgetState extends State<MapViewWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Icon cache: artisanId -> {normal, selected}
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

  // ── Marker building ────────────────────────────────────────────────────────

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

  // ── Marker tap → fetch road route ─────────────────────────────────────────

  Future<void> _onMarkerTap(Map<String, dynamic> artisan) async {
    final lat = artisan['_lat'] as double? ?? widget.currentLocation.latitude;
    final lng = artisan['_lng'] as double? ?? widget.currentLocation.longitude;
    final dest = LatLng(lat, lng);

    _swapIcon(artisan['id'].toString());
    _mapController?.animateCamera(CameraUpdate.newLatLng(dest));

    // Fetch road route from Directions API
    final points = await _fetchRoutePoints(widget.currentLocation, dest);

    if (mounted) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: const Color(0xFF4CAF50),
            width: 4,
            jointType: JointType.round,
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
          ),
        };
      });
    }
  }

  /// Calls Google Directions API and decodes the polyline into LatLng points.
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
      if (response.statusCode != 200) return _straightLine(origin, dest);

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return _straightLine(origin, dest);

      final encoded =
          data['routes'][0]['overview_polyline']['points'] as String;
      return _decodePolyline(encoded);
    } catch (_) {
      return _straightLine(origin, dest);
    }
  }

  List<LatLng> _straightLine(LatLng a, LatLng b) => [a, b];

  /// Google's polyline encoding decoder
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0, lng = 0;

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
    const int imgSize = 56;
    const double border = 3;
    const double tail = 12;
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
      final borderColor = selected ? const Color(0xFF4CAF50) : Colors.white;

      canvas.drawCircle(Offset(cx, r), r, Paint()..color = borderColor);

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

      final tail_ = Path()
        ..moveTo(cx - 7, r * 2 - 3)
        ..lineTo(cx + 7, r * 2 - 3)
        ..lineTo(cx, r * 2 + tail)
        ..close();
      canvas.drawPath(tail_, Paint()..color = borderColor);

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
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (c) => _mapController = c,
      onTap: (_) {
        setState(() => _polylines = {});
        _swapIcon('');
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
