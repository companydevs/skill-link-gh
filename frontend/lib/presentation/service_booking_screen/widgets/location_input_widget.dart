import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

const _mapsApiKey = 'AIzaSyCeGxqoYlPBqAXDX5JMp89wwJfmQEM-ZWc';

class LocationInputWidget extends StatefulWidget {
  final TextEditingController addressController;
  final LatLng? selectedLocation;
  final Function(LatLng) onLocationSelected;

  const LocationInputWidget({
    super.key,
    required this.addressController,
    required this.selectedLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationInputWidget> createState() => _LocationInputWidgetState();
}

class _LocationInputWidgetState extends State<LocationInputWidget> {
  bool _isLocating = false;
  LatLng? _pickedLatLng;

  @override
  void initState() {
    super.initState();
    _autoFillLocation();
  }

  Future<void> _autoFillLocation() async {
    if (_isLocating) return;
    if (mounted) setState(() => _isLocating = true);
    try {
      final svcOn = await Geolocator.isLocationServiceEnabled();
      dev.log('📍 Service: $svcOn', name: 'Location');
      if (!svcOn) return;
      var perm = await Geolocator.checkPermission();
      dev.log('📍 Perm: $perm', name: 'Location');
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        dev.log('📍 After request: $perm', name: 'Location');
      }

      if (perm == LocationPermission.deniedForever) {
        dev.log('❌ Permanently denied', name: 'Location');
        openAppSettings();
        return;
      }
      if (perm == LocationPermission.denied) {
        dev.log('❌ Denied', name: 'Location');
        return;
      }
      Position? pos = await Geolocator.getLastKnownPosition();
      dev.log('📍 Last known: $pos', name: 'Location');
      if (pos == null) {
        dev.log(
          '📍 Using forceLocationManager (TECNO fix)...',
          name: 'Location',
        );
        pos = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.low,
            forceLocationManager: true,
            timeLimit: const Duration(seconds: 15),
          ),
        );
        dev.log('📍 Got: ${pos.latitude}, ${pos.longitude}', name: 'Location');
      }
      final ll = LatLng(pos.latitude, pos.longitude);
      widget.onLocationSelected(ll);
      if (mounted) setState(() => _pickedLatLng = ll);
      if (mounted) {
        // Temporary label while geocoding — use Ghana Post GPS style
        widget.addressController.text = _toGhanaPostGps(ll);
      }
      final addr = await _geocode(ll);
      dev.log('📍 Geocode: $addr', name: 'Location');
      if (mounted && addr != null) {
        widget.addressController.text = addr;
        setState(() {});
      }
    } catch (e, st) {
      dev.log('❌ Error: $e', name: 'Location', error: e, stackTrace: st);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Converts lat/lng to Ghana Post GPS format: e.g. "GA-123-4567"
  /// Uses a simplified encoding — real Ghana Post GPS uses a proprietary grid.
  /// This gives a human-readable short code instead of raw coordinates.
  String _toGhanaPostGps(LatLng pos) {
    // Encode as a short alphanumeric code based on the coordinates
    final latCode = ((pos.latitude + 90) * 1000).round();
    final lngCode = ((pos.longitude + 180) * 1000).round();
    final prefix = _ghanaRegionPrefix(pos.latitude, pos.longitude);
    final part1 = (latCode % 1000).toString().padLeft(3, '0');
    final part2 = (lngCode % 10000).toString().padLeft(4, '0');
    return '$prefix-$part1-$part2';
  }

  String _ghanaRegionPrefix(double lat, double lng) {
    // Rough bounding boxes for Ghana regions
    if (lat >= 5.5 && lat <= 6.0 && lng >= -0.4 && lng <= 0.2)
      return 'GA'; // Greater Accra
    if (lat >= 6.0 && lat <= 7.0 && lng >= -1.5 && lng <= -0.5)
      return 'AH'; // Ashanti
    if (lat >= 5.0 && lat <= 5.5 && lng >= -2.0 && lng <= -1.0)
      return 'WE'; // Western
    if (lat >= 7.0 && lat <= 8.0 && lng >= -1.0 && lng <= 0.5)
      return 'BE'; // Bono East
    if (lat >= 9.0 && lat <= 11.0 && lng >= -2.5 && lng <= 0.0)
      return 'NR'; // Northern
    return 'GH'; // Generic Ghana
  }

  Future<String?> _geocode(LatLng pos) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      final resp = await dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '${pos.latitude},${pos.longitude}',
          'key': _mapsApiKey,
        },
      );
      dev.log('📍 Geocode status: ${resp.data?['status']}', name: 'Location');
      final results = resp.data?['results'] as List?;
      if (results != null && results.isNotEmpty) {
        return results.first['formatted_address'] as String?;
      }
    } catch (e) {
      dev.log('❌ Geocode error: $e', name: 'Location');
    }
    return null;
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _MapPickerScreen(
          initialLocation:
              _pickedLatLng ??
              widget.selectedLocation ??
              const LatLng(5.6037, -0.1870),
        ),
      ),
    );
    if (result != null && mounted) {
      widget.onLocationSelected(result);
      setState(() {
        _pickedLatLng = result;
        _isLocating = true;
      });
      widget.addressController.text = _toGhanaPostGps(result);
      final addr = await _geocode(result);
      if (mounted) {
        if (addr != null) widget.addressController.text = addr;
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation =
        _pickedLatLng != null || widget.selectedLocation != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Service Location',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_isLocating)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Detecting...',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              )
            else if (hasLocation)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Set',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
          ],
        ),
        SizedBox(height: 1.h),
        GestureDetector(
          onTap: _openMapPicker,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasLocation
                    ? theme.colorScheme.primary.withValues(alpha: 0.4)
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasLocation ? Icons.location_on : Icons.location_searching,
                  color: hasLocation
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _isLocating
                      ? Text(
                          'Getting your location...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : Text(
                          widget.addressController.text.isNotEmpty
                              ? widget.addressController.text
                              : 'Tap to set location',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: widget.addressController.text.isNotEmpty
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_location_alt_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  const _MapPickerScreen({required this.initialLocation});
  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  late LatLng _picked;
  GoogleMapController? _ctrl;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialLocation;
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.low,
          forceLocationManager: true,
          timeLimit: const Duration(seconds: 15),
        ),
      );
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() => _picked = ll);
      _ctrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 16));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Location'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _picked),
            child: Text(
              'Confirm',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) {
              _ctrl = c;
              Future.delayed(const Duration(milliseconds: 400), () {
                _ctrl?.animateCamera(
                  CameraUpdate.newLatLngZoom(widget.initialLocation, 15),
                );
              });
            },
            initialCameraPosition: CameraPosition(
              target: widget.initialLocation,
              zoom: 15,
            ),
            onTap: (pos) => setState(() => _picked = pos),
            markers: {
              Marker(
                markerId: const MarkerId('pick'),
                position: _picked,
                draggable: true,
                onDragEnd: (pos) => setState(() => _picked = pos),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Tap anywhere or drag the pin to set your location',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'map_my_loc',
              onPressed: _isLocating ? null : _goToMyLocation,
              backgroundColor: theme.colorScheme.surface,
              elevation: 4,
              child: _isLocating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(Icons.my_location, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
