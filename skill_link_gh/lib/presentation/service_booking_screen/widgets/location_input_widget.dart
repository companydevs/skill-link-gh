import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../widgets/custom_icon_widget.dart';

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
    if (widget.addressController.text.isEmpty) {
      _autoFillLocation();
    }
  }

  Future<void> _autoFillLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Please enable location services');
        return;
      }

      final status = await Permission.location.request();
      if (status.isPermanentlyDenied) {
        _showSnack('Location permission denied. Open settings to allow.');
        openAppSettings();
        return;
      }
      if (!status.isGranted) {
        _showSnack('Location permission required');
        return;
      }

      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      widget.onLocationSelected(latLng);
      if (mounted) setState(() => _pickedLatLng = latLng);
      await _reverseGeocode(latLng);
    } catch (e) {
      _showSnack('Could not detect location. Enter address manually.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Uses Google Maps Geocoding API (same key as Maps SDK) — works reliably on all Android devices
  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final dio = Dio();
      final response = await dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '${pos.latitude},${pos.longitude}',
          'key': _mapsApiKey,
        },
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      final results = response.data?['results'] as List?;
      if (results != null && results.isNotEmpty) {
        final address = results.first['formatted_address'] as String? ?? '';
        if (address.isNotEmpty && mounted) {
          widget.addressController.text = address;
          return;
        }
      }
    } catch (_) {}
    // Fallback — show coordinates so the field isn't empty
    if (mounted) {
      widget.addressController.text =
          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      await _reverseGeocode(result);
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation =
        _pickedLatLng != null || widget.selectedLocation != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Service Location',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (hasLocation)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.my_location,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Located',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.addressController,
            decoration: InputDecoration(
              hintText: _isLocating
                  ? 'Getting your location...'
                  : 'Your service address',
              prefixIcon: _isLocating
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: CustomIconWidget(
                        iconName: 'location_on',
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLocating ? null : _autoFillLocation,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 16),
                  label: Text(_isLocating ? 'Locating...' : 'Use My Location'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Pick on Map'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Full-screen map picker ────────────────────────────────────────────────────

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
      final status = await Permission.location.request();
      if (!status.isGranted) return;
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _picked = latLng);
      _ctrl?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
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
        title: const Text('Pick Location'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _picked),
            child: Text(
              'Confirm',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tap the map or drag the pin to set your location',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'map_my_location',
              onPressed: _isLocating ? null : _goToMyLocation,
              backgroundColor: theme.colorScheme.surface,
              child: _isLocating
                  ? SizedBox(
                      width: 18,
                      height: 18,
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
