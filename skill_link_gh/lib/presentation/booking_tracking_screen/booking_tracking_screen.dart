import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skill_link_gh/domain/models/booking_model.dart';
import 'package:skill_link_gh/presentation/in_app_messaging/in_app_messaging.dart';
import 'package:skill_link_gh/provider/booking_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:skill_link_gh/widgets/user_avatar_widget.dart';

import '../../widgets/custom_app_bar.dart';

class BookingTrackingScreen extends ConsumerStatefulWidget {
  const BookingTrackingScreen({super.key});

  @override
  ConsumerState<BookingTrackingScreen> createState() =>
      _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends ConsumerState<BookingTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _locationUpdateTimer;
  String? _bookingId;
  BookingModel? _booking;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _artisanName = 'Artisan';
  String _artisanAvatar = '';
  LatLng? _artisanStaticLocation; // from artisan's profile

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookingData();
    });
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _loadBookingData() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _bookingId = args['bookingId'] ?? args['paymentReference'];
      if (_bookingId != null) {
        _loadBookingDetails();
        _startLocationUpdates();
      }
    }
  }

  Future<void> _loadBookingDetails() async {
    if (_bookingId == null) return;

    try {
      // Read directly from Firestore — faster and doesn't need the Cloud Function
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(_bookingId!)
          .get();

      if (!doc.exists || !mounted) {
        // Try via Cloud Function as fallback
        await ref
            .read(bookingNotifierProvider.notifier)
            .getBookingDetails(_bookingId!);
        final currentBooking = ref.read(bookingNotifierProvider).currentBooking;
        if (currentBooking != null && mounted) {
          setState(() => _booking = currentBooking);
          await _loadArtisanProfile(currentBooking.artisanId);
          _updateMapMarkers();
        }
        return;
      }

      final data = doc.data()!;
      final booking = BookingModel.fromJson({...data, 'id': doc.id}, doc.id);
      if (mounted) {
        setState(() => _booking = booking);
        await _loadArtisanProfile(booking.artisanId);
        _updateMapMarkers();
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to load booking: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _loadArtisanProfile(String artisanId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(artisanId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _artisanName = doc.data()?['fullName'] as String? ?? 'Artisan';
          _artisanAvatar = doc.data()?['profileImage'] as String? ?? '';
          // Use artisan's stored location if no live location yet
          final lat = (doc.data()?['latitude'] as num?)?.toDouble();
          final lng = (doc.data()?['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            _artisanStaticLocation = LatLng(lat, lng);
          }
        });
      }
    } catch (_) {}
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_bookingId != null) {
        _loadBookingDetails();
      }
    });
  }

  void _updateMapMarkers() {
    if (_booking == null) return;

    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // Client location marker
    final clientLoc = _booking!.clientLocation;
    if (clientLoc != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('client'),
          position: LatLng(clientLoc.latitude, clientLoc.longitude),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: clientLoc.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Artisan location — prefer live, fall back to profile location
    final liveLoc = _booking!.artisanCurrentLocation;
    final artisanLatLng = liveLoc != null
        ? LatLng(liveLoc.latitude, liveLoc.longitude)
        : _artisanStaticLocation;

    if (artisanLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('artisan'),
          position: artisanLatLng,
          infoWindow: InfoWindow(
            title: _artisanName,
            snippet: liveLoc != null ? liveLoc.address : 'Artisan location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );

      // Polyline from artisan → client
      if (clientLoc != null) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [
              artisanLatLng,
              LatLng(clientLoc.latitude, clientLoc.longitude),
            ],
            color: Theme.of(context).colorScheme.primary,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    if (_mapController != null && markers.length > 1) {
      _fitMapToMarkers();
    } else if (_mapController != null && markers.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(markers.first.position, 14),
      );
    }
  }

  void _fitMapToMarkers() async {
    if (_mapController == null || _markers.isEmpty) return;

    final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      minLat = minLat < pos.latitude ? minLat : pos.latitude;
      maxLat = maxLat > pos.latitude ? maxLat : pos.latitude;
      minLng = minLng < pos.longitude ? minLng : pos.longitude;
      maxLng = maxLng > pos.longitude ? maxLng : pos.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _callArtisan() async {
    if (_booking?.contactPhone != null) {
      final uri = Uri.parse('tel:${_booking!.contactPhone}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _messageArtisan() async {
    if (_booking == null || !mounted) return;
    // Fetch artisan profile for name/avatar
    String artisanName = 'Artisan';
    String artisanAvatar = '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_booking!.artisanId)
          .get();
      if (doc.exists) {
        artisanName = doc.data()?['fullName'] as String? ?? 'Artisan';
        artisanAvatar = doc.data()?['profileImage'] as String? ?? '';
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/in-app-messaging-screen',
      arguments: ChatArgs(
        otherUserId: _booking!.artisanId,
        otherUserName: artisanName,
        otherUserAvatar: artisanAvatar,
      ),
    );
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Booking Confirmed';
      case BookingStatus.inProgress:
        return 'Service In Progress';
      case BookingStatus.completed:
        return 'Service Completed';
      case BookingStatus.cancelled:
        return 'Booking Cancelled';
      default:
        return 'Pending';
    }
  }

  Color _getStatusColor(BookingStatus status, ThemeData theme) {
    switch (status) {
      case BookingStatus.confirmed:
        return theme.colorScheme.primary;
      case BookingStatus.inProgress:
        return Colors.orange;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingState = ref.watch(bookingNotifierProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'Track Booking'),
      body: bookingState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
          ? _buildErrorState(theme)
          : Column(
              children: [
                _buildStatusHeader(theme),
                Expanded(child: _buildMapView(theme)),
                _buildBottomSheet(theme),
              ],
            ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          SizedBox(height: 2.h),
          Text('Booking not found', style: theme.textTheme.titleLarge),
          SizedBox(height: 1.h),
          Text(
            'Unable to load booking details',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    _booking!.status,
                    theme,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _booking!.status == BookingStatus.completed
                      ? Icons.check_circle
                      : _booking!.status == BookingStatus.inProgress
                      ? Icons.build
                      : Icons.schedule,
                  color: _getStatusColor(_booking!.status, theme),
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(_booking!.status),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(_booking!.status, theme),
                      ),
                    ),
                    Text(
                      _booking!.serviceTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  theme,
                  'Date',
                  _booking!.scheduledDate,
                  Icons.calendar_today,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildInfoCard(
                  theme,
                  'Time',
                  _booking!.scheduledTime,
                  Icons.access_time,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildInfoCard(
                  theme,
                  'Distance',
                  '${_booking!.distance.toStringAsFixed(1)} km',
                  Icons.location_on,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(ThemeData theme) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        _updateMapMarkers();
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _booking!.clientLocation!.latitude,
          _booking!.clientLocation!.longitude,
        ),
        zoom: 14.0,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildBottomSheet(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            _buildArtisanInfo(theme),
            SizedBox(height: 2.h),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildArtisanInfo(ThemeData theme) {
    return Row(
      children: [
        UserAvatarWidget(
          imageUrl: null, // You can get this from booking details
          name: 'Artisan', // You can get this from booking details
          size: 50,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Artisan', // You can get actual name from booking details
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _booking!.serviceTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (_booking!.artisanCurrentLocation != null)
                Text(
                  'Distance: ${_booking!.distance.toStringAsFixed(1)} km away',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _callArtisan,
            icon: const Icon(Icons.phone),
            label: const Text('Call'),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _messageArtisan,
            icon: const Icon(Icons.message),
            label: const Text('Message'),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to booking details
              Navigator.pushNamed(
                context,
                '/booking-details-screen',
                arguments: {'bookingId': _booking!.id},
              );
            },
            icon: const Icon(Icons.info),
            label: const Text('Details'),
          ),
        ),
      ],
    );
  }
}
