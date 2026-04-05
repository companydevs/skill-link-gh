import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skill_link_gh/domain/models/booking_model.dart';
import 'package:skill_link_gh/presentation/in_app_messaging/in_app_messaging.dart';
import 'package:skill_link_gh/provider/booking_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:skill_link_gh/widgets/user_avatar_widget.dart';

import '../../widgets/custom_app_bar.dart';

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
  String? _bookingId;
  BookingModel? _booking;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoadingBooking = true;
  String _artisanName = 'Artisan';
  String _artisanAvatar = '';
  LatLng? _artisanStaticLocation;

  // Animated polyline
  late AnimationController _routeAnim;
  List<LatLng> _fullRoute = [];
