import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../widgets/custom_icon_widget.dart';

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
    // Auto-fill location on load if address is empty
    if (widget.addressController.text.isEmpty) {
      _autoFillLocation();
    }
  }

  Future<void> _autoFillLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;

      // Try last known first (instant)
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      widget.onLocationSelected(latLng);
      setState(() => _pickedLatLng = latLng);

      // Reverse geocode to get address string
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          final p = placemarks.first;
          final parts = [
            p.street,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
          widget.addressController.text = parts.isNotEmpty
              ? parts
              : '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        }
      } catch (_) {
        widget.addressController.text =
            '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      }
    } catch (_) {
      // Silent — user can still type manually
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _openMapPicker() async {
    final result = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapPickerSheet(
        initialLocation:
            _pickedLatLng ??
            widget.selectedLocation ??
            const LatLng(5.6037, -0.1870),
      ),
    );

    if (result != null && mounted) {
      widget.onLocationSelected(result);
      setState(() => _pickedLatLng = result);

      // Reverse geocode the picked point
      try {
        final placemarks = await placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          final p = placemarks.first;
          final parts = [
            p.street,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
          widget.addressController.text = parts.isNotEmpty
              ? parts
              : '${result.latitude}, ${result.longitude}';
        }
      } catch (_) {
        widget.addressController.text =
            '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
      }
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

          // Address text field
          TextField(
            controller: widget.addressController,
            decoration: InputDecoration(
              hintText: _isLocating
                  ? 'Getting your location...'
                  : 'Your service address',
              prefixIcon: _isLocating
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
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

          // Action buttons row
          Row(
            children: [
              // Re-detect my location
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLocating ? null : _autoFillLocation,
                  icon: _isLocating
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : const Icon(Icons.my_location, size: 16),
                  label: Text(_isLocating ? 'Locating...' : 'My Location'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Pick on map
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

/// Full-screen map bottom sheet for picking a location
class _MapPickerSheet extends StatefulWidget {
  final LatLng initialLocation;
  const _MapPickerSheet({required this.initialLocation});

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  late LatLng _picked;
  GoogleMapController? _ctrl;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Pick Location',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context, _picked),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (c) => _ctrl = c,
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
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
                // Center crosshair hint
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Text(
                      'Tap or drag pin to set location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        shadows: [Shadow(blurRadius: 4)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
