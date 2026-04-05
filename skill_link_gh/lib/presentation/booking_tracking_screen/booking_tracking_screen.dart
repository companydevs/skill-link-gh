import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skill_link_gh/domain/models/booking_model.dart';
import 'package:skill_link_gh/presentation/in_app_messaging/in_app_messaging.dart';
import 'package:skill_link_gh/provider/wallet_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:skill_link_gh/widgets/user_avatar_widget.dart';
import 'widgets/client_qr_screen.dart';
import 'widgets/artisan_qr_scanner_screen.dart';

const _kMapsKey = 'AIzaSyCeGxqoYlPBqAXDX5JMp89wwJfmQEM-ZWc';
const _kDefaultAvatar =
    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

class BookingTrackingScreen extends ConsumerStatefulWidget {
  const BookingTrackingScreen({super.key});
  @override
  ConsumerState<BookingTrackingScreen> createState() =>
      _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends ConsumerState<BookingTrackingScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Timer? _locationUpdateTimer;
  Timer? _expiryCheckTimer;
  String? _bookingId;
  BookingModel? _booking;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoadingBooking = true;
  String _artisanName = 'Artisan';
  String _artisanAvatar = '';
  String _clientName = 'Client';
  String _clientAvatar = '';
  LatLng? _artisanStaticLocation;
  double _distanceKm = 0.0;
  bool _isArtisan = false;
  String _resolvedAddress = '';
  late AnimationController _routeAnim;
  List<LatLng> _fullRoute = [];

  @override
  void initState() {
    super.initState();
    _routeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(_onRouteAnimTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookingData());
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _expiryCheckTimer?.cancel();
    _routeAnim.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onRouteAnimTick() {
    if (_fullRoute.isEmpty) return;
    final count = (_fullRoute.length * _routeAnim.value).round().clamp(
      2,
      _fullRoute.length,
    );
    final visible = _fullRoute.sublist(0, count);
    if (mounted) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('shadow'),
            points: visible,
            color: Colors.black.withValues(alpha: 0.18),
            width: 12,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
          Polyline(
            polylineId: const PolylineId('route'),
            points: visible,
            color: const Color(0xFF1A73E8),
            width: 7,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };
      });
    }
  }

  Future<List<LatLng>> _fetchRoute(LatLng origin, LatLng dest) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${dest.latitude},${dest.longitude}&key=$_kMapsKey',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 8));
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return [];
      return _decodePolyline(
        routes[0]['overview_polyline']['points'] as String,
      );
    } catch (_) {
      return [];
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final result = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result0 = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result0 |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
      shift = 0;
      result0 = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result0 |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
      result.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return result;
  }

  Future<void> _loadBookingData() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _bookingId = args?['bookingId'] as String?;
    if (_bookingId == null) {
      setState(() => _isLoadingBooking = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(_bookingId)
          .get();
      if (!doc.exists || !mounted) return;
      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] = doc.id;
      final booking = BookingModel.fromJson(data, doc.id);
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      _isArtisan = currentUid == booking.artisanId;

      final artisanDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(booking.artisanId)
          .get();
      if (artisanDoc.exists) {
        final ad = artisanDoc.data()!;
        _artisanName = ad['fullName'] as String? ?? 'Artisan';
        _artisanAvatar =
            ad['profileImage'] as String? ?? ad['photoUrl'] as String? ?? '';
        final lat = (ad['latitude'] as num?)?.toDouble();
        final lng = (ad['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null)
          _artisanStaticLocation = LatLng(lat, lng);
      }

      final clientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(booking.clientId)
          .get();
      if (clientDoc.exists) {
        final cd = clientDoc.data()!;
        _clientName = cd['fullName'] as String? ?? 'Client';
        _clientAvatar =
            cd['profileImage'] as String? ?? cd['photoUrl'] as String? ?? '';
      }

      final cl = booking.clientLocation;

      // ── Artisan location: stored coords → device GPS → near client ──
      if (_artisanStaticLocation == null) {
        // Try device GPS if current user IS the artisan
        if (_isArtisan) {
          try {
            final perm = await Geolocator.checkPermission();
            if (perm == LocationPermission.whileInUse ||
                perm == LocationPermission.always) {
              Position? pos = await Geolocator.getLastKnownPosition();
              pos ??= await Geolocator.getCurrentPosition(
                locationSettings: AndroidSettings(
                  accuracy: LocationAccuracy.low,
                  forceLocationManager: true,
                  timeLimit: const Duration(seconds: 8),
                ),
              );
              _artisanStaticLocation = LatLng(pos.latitude, pos.longitude);
            }
          } catch (_) {}
        }
        // Final fallback: place artisan marker near client location
        if (_artisanStaticLocation == null && cl.latitude != 0) {
          _artisanStaticLocation = LatLng(
            cl.latitude + 0.01,
            cl.longitude + 0.01,
          );
        }
      }

      // ── Distance calculation ─────────────────────────────────────────
      if (_artisanStaticLocation != null && cl.latitude != 0) {
        final artLoc = _artisanStaticLocation!;
        final dLat = (cl.latitude - artLoc.latitude) * math.pi / 180;
        final dLng = (cl.longitude - artLoc.longitude) * math.pi / 180;
        final a =
            math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(artLoc.latitude * math.pi / 180) *
                math.cos(cl.latitude * math.pi / 180) *
                math.sin(dLng / 2) *
                math.sin(dLng / 2);
        _distanceKm = double.parse(
          (6371 * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)))
              .toStringAsFixed(1),
        );
      }

      if (mounted)
        setState(() {
          _booking = booking;
          _isLoadingBooking = false;
        });

      // Resolve address — reverse-geocode if stored as raw coords or Ghana Post GPS code
      _resolveClientAddress(booking.clientLocation);

      if (_artisanStaticLocation != null && cl.latitude != 0) {
        final clientLatLng = LatLng(cl.latitude, cl.longitude);
        final route = await _fetchRoute(_artisanStaticLocation!, clientLatLng);
        if (route.isNotEmpty && mounted) {
          _fullRoute = route;
          _routeAnim.forward(from: 0);
        }
        await _buildMarkers(clientLatLng);
      } else if (cl.latitude != 0) {
        // At minimum show the client marker
        final clientLatLng = LatLng(cl.latitude, cl.longitude);
        await _buildMarkers(clientLatLng);
      }

      _startExpiryCheck(booking);
      _locationUpdateTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _refreshArtisanLocation(),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoadingBooking = false);
    }
  }

  void _startExpiryCheck(BookingModel booking) {
    if (booking.status != BookingStatus.pending) return;
    DateTime? scheduledDate;
    try {
      scheduledDate = DateTime.parse(booking.scheduledDate);
    } catch (_) {
      return;
    }
    _checkAndRefundIfExpired(booking, scheduledDate);
    _expiryCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAndRefundIfExpired(booking, scheduledDate!),
    );
  }

  Future<void> _checkAndRefundIfExpired(
    BookingModel booking,
    DateTime scheduledDate,
  ) async {
    final now = DateTime.now();
    final endOfDay = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      23,
      59,
      59,
    );
    if (now.isAfter(endOfDay)) {
      _expiryCheckTimer?.cancel();
      final success = await ref
          .read(walletNotifierProvider.notifier)
          .refundExpiredBooking(
            bookingId: booking.id,
            clientId: booking.clientId,
            amount: booking.totalWithFees,
          );
      if (success && mounted) {
        AppToast.show(
          context,
          message:
              'Booking expired. GH₵ ${booking.totalWithFees.toStringAsFixed(2)} refunded to your wallet.',
          type: ToastType.success,
        );
        setState(
          () => _booking = booking.copyWith(status: BookingStatus.cancelled),
        );
      }
    }
  }

  Future<void> _refreshArtisanLocation() async {
    if (_booking == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(_bookingId)
          .get();
      if (!doc.exists || !mounted) return;
      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] = doc.id;
      if (mounted)
        setState(() => _booking = BookingModel.fromJson(data, doc.id));
    } catch (_) {}
  }

  Future<void> _buildMarkers(LatLng clientLatLng) async {
    final markers = <Marker>{};

    // Client marker — always shown
    final clientMarker = await _buildAvatarMarker(
      id: 'client',
      latLng: clientLatLng,
      imageUrl: _clientAvatar,
      label: '$_clientName (Client)',
    );
    markers.add(clientMarker);

    // Artisan marker — only if we have a location
    if (_artisanStaticLocation != null) {
      final artisanMarker = await _buildAvatarMarker(
        id: 'artisan',
        latLng: _artisanStaticLocation!,
        imageUrl: _artisanAvatar,
        label: '$_artisanName (Artisan)',
      );
      markers.add(artisanMarker);
    }

    if (mounted) setState(() => _markers = markers);

    if (_artisanStaticLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              math.min(
                    clientLatLng.latitude,
                    _artisanStaticLocation!.latitude,
                  ) -
                  0.01,
              math.min(
                    clientLatLng.longitude,
                    _artisanStaticLocation!.longitude,
                  ) -
                  0.01,
            ),
            northeast: LatLng(
              math.max(
                    clientLatLng.latitude,
                    _artisanStaticLocation!.latitude,
                  ) +
                  0.01,
              math.max(
                    clientLatLng.longitude,
                    _artisanStaticLocation!.longitude,
                  ) +
                  0.01,
            ),
          ),
          60,
        ),
      );
    } else {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(clientLatLng, 15),
      );
    }
  }

  Future<Marker> _buildAvatarMarker({
    required String id,
    required LatLng latLng,
    required String imageUrl,
    required String label,
  }) async {
    const int size = 56; // smaller, like search screen cards
    final bool isClient = id == 'client';
    final Color ringColor = isClient
        ? const Color(0xFF10B981)
        : const Color(0xFF1A73E8);

    BitmapDescriptor icon;
    try {
      final resp = await http
          .get(Uri.parse(imageUrl.isNotEmpty ? imageUrl : _kDefaultAvatar))
          .timeout(const Duration(seconds: 5));
      final codec = await ui.instantiateImageCodec(
        Uint8List.fromList(resp.bodyBytes),
        targetWidth: size,
        targetHeight: size,
      );
      final frame = await codec.getNextFrame();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..isAntiAlias = true;

      // Draw colored ring
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2,
        Paint()..color = ringColor,
      );
      // Clip inner circle for avatar
      canvas.clipPath(
        Path()..addOval(Rect.fromLTWH(3, 3, size - 6.0, size - 6.0)),
      );
      canvas.drawImageRect(
        frame.image,
        Rect.fromLTWH(
          0,
          0,
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        ),
        Rect.fromLTWH(3, 3, size - 6.0, size - 6.0),
        paint,
      );
      final img = await recorder.endRecording().toImage(size, size);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      icon = BitmapDescriptor.bytes(
        bytes!.buffer.asUint8List(),
        width: size.toDouble(),
        height: size.toDouble(),
      );
    } catch (_) {
      icon = BitmapDescriptor.defaultMarkerWithHue(
        isClient ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue,
      );
    }
    return Marker(
      markerId: MarkerId(id),
      position: latLng,
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(title: label),
    );
  }

  /// Reverse-geocodes the client location if the stored address is raw coords.
  /// Falls back to Ghana Post GPS format if the API fails.
  Future<void> _resolveClientAddress(LocationData cl) async {
    // If address is already a proper human-readable string, use it
    final raw = cl.address.trim();
    final isRawCoords =
        raw.startsWith('Lat:') ||
        RegExp(r'^-?\d+\.\d+,\s*-?\d+\.\d+$').hasMatch(raw);

    if (!isRawCoords && raw.isNotEmpty) {
      if (mounted) setState(() => _resolvedAddress = raw);
      return;
    }

    // Try reverse-geocoding via Google Maps API
    if (cl.latitude != 0 && cl.longitude != 0) {
      try {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${cl.latitude},${cl.longitude}&key=$_kMapsKey',
        );
        final resp = await http.get(url).timeout(const Duration(seconds: 6));
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final addr = results.first['formatted_address'] as String?;
          if (addr != null && addr.isNotEmpty && mounted) {
            setState(() => _resolvedAddress = addr);
            return;
          }
        }
      } catch (_) {}

      // Fallback: Ghana Post GPS style
      if (mounted) {
        setState(
          () => _resolvedAddress = _toGhanaPostGps(cl.latitude, cl.longitude),
        );
      }
    }
  }

  /// Encodes coordinates as a Ghana Post GPS-style short code
  String _toGhanaPostGps(double lat, double lng) {
    final prefix = _ghanaRegionPrefix(lat, lng);
    final part1 = ((lat + 90) * 1000).round() % 1000;
    final part2 = ((lng + 180) * 1000).round() % 10000;
    return '$prefix-${part1.toString().padLeft(3, '0')}-${part2.toString().padLeft(4, '0')}';
  }

  String _ghanaRegionPrefix(double lat, double lng) {
    if (lat >= 5.5 && lat <= 6.0 && lng >= -0.4 && lng <= 0.2) return 'GA';
    if (lat >= 6.0 && lat <= 7.0 && lng >= -1.5 && lng <= -0.5) return 'AH';
    if (lat >= 5.0 && lat <= 5.5 && lng >= -2.0 && lng <= -1.0) return 'WE';
    if (lat >= 7.0 && lat <= 8.0 && lng >= -1.0 && lng <= 0.5) return 'BE';
    if (lat >= 9.0 && lat <= 11.0 && lng >= -2.5 && lng <= 0.0) return 'NR';
    return 'GH';
  }

  void _showClientQr() {
    if (_booking == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientQrScreen(
          bookingId: _booking!.id,
          clientId: _booking!.clientId,
          amount: _booking!.totalWithFees,
        ),
      ),
    );
  }

  Future<void> _openArtisanScanner() async {
    if (_booking == null) return;
    final released = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanQrScannerScreen(
          expectedBookingId: _booking!.id,
          artisanId: _booking!.artisanId,
        ),
      ),
    );
    if (released == true && mounted)
      setState(
        () => _booking = _booking!.copyWith(status: BookingStatus.completed),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoadingBooking) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Booking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Booking')),
        body: const Center(child: Text('Booking not found')),
      );
    }
    final booking = _booking!;
    final cl = booking.clientLocation;
    final clientLatLng = cl.latitude != 0
        ? LatLng(cl.latitude, cl.longitude)
        : const LatLng(5.6037, -0.1870);
    final statusLabel = _statusLabel(booking.status);
    final statusColor = _statusColor(theme, booking.status);
    final isCompleted = booking.status == BookingStatus.completed;
    final isCancelled = booking.status == BookingStatus.cancelled;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Track Booking'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, color: statusColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        booking.serviceTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCancelled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Refunded',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: booking.scheduledDate,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.access_time_outlined,
                  label: booking.scheduledTime,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.straighten_outlined,
                  label: '${_distanceKm.toStringAsFixed(1)} km',
                  theme: theme,
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 28.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: GoogleMap(
                  onMapCreated: (c) => _mapController = c,
                  initialCameraPosition: CameraPosition(
                    target: clientLatLng,
                    zoom: 13,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Expanded(
                  child: _ProfileTile(
                    label: 'Artisan',
                    name: _artisanName,
                    avatar: _artisanAvatar,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProfileTile(
                    label: 'Client',
                    name: _clientName,
                    avatar: _clientAvatar,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          if (cl.address.isNotEmpty || _resolvedAddress.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _resolvedAddress.isNotEmpty
                            ? _resolvedAddress
                            : cl.address,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/in-app-messaging-screen',
                          arguments: ChatArgs(
                            otherUserId: _isArtisan
                                ? booking.clientId
                                : booking.artisanId,
                            otherUserName: _isArtisan
                                ? _clientName
                                : _artisanName,
                            otherUserAvatar: _isArtisan
                                ? _clientAvatar
                                : _artisanAvatar,
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Message'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse('tel:${booking.contactPhone}');
                          if (await canLaunchUrl(uri)) launchUrl(uri);
                        },
                        icon: const Icon(Icons.call_outlined, size: 18),
                        label: const Text('Call'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Get Directions button — opens Google Maps to client location
                if (cl.latitude != 0)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(
                          'https://www.google.com/maps/dir/?api=1'
                          '&destination=${cl.latitude},${cl.longitude}'
                          '&travelmode=driving',
                        );
                        if (await canLaunchUrl(uri)) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.directions_outlined, size: 18),
                      label: const Text('Get Directions to Client'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A73E8),
                        side: const BorderSide(color: Color(0xFF1A73E8)),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (!isCompleted && !isCancelled)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isArtisan
                          ? _openArtisanScanner
                          : _showClientQr,
                      icon: Icon(
                        _isArtisan ? Icons.qr_code_scanner : Icons.qr_code,
                        size: 20,
                      ),
                      label: Text(
                        _isArtisan
                            ? 'Scan Client QR to Release Payment'
                            : 'Show QR Code for Payment',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (isCompleted)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Released — Job Complete',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return 'Waiting for Artisan';
      case BookingStatus.confirmed:
        return 'Booking Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled — Refunded';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(ThemeData theme, BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed:
        return theme.colorScheme.primary;
      case BookingStatus.inProgress:
        return Colors.orange;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return theme.colorScheme.error;
      default:
        return const Color(0xFFFFC107);
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String label;
  final String name;
  final String avatar;
  final ThemeData theme;
  const _ProfileTile({
    required this.label,
    required this.name,
    required this.avatar,
    required this.theme,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          UserAvatarWidget(
            imageUrl: avatar.isNotEmpty ? avatar : null,
            name: name,
            size: 40,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
