import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:skill_link_gh/domain/models/booking_model.dart';

class BookingRepository {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String clientId,
    required String artisanId,
    required String serviceId,
    required String serviceTitle,
    required String serviceDescription,
    required String scheduledDate,
    required String scheduledTime,
    required int duration,
    required double totalAmount,
    required LocationData clientLocation,
    String? specialRequests,
    required String contactPhone,
    required String contactEmail,
  }) async {
    try {
      log('🔄 Creating booking...');

      final callable = _functions.httpsCallable('createBooking');
      final result = await callable.call({
        'clientId': clientId,
        'artisanId': artisanId,
        'serviceId': serviceId,
        'serviceTitle': serviceTitle,
        'serviceDescription': serviceDescription,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'duration': duration,
        'totalAmount': totalAmount,
        'clientLocation': clientLocation.toJson(),
        'specialRequests': specialRequests,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
      });

      log('✅ Booking created successfully');
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      log('❌ Error creating booking: $e');
      rethrow;
    }
  }

  /// Verify payment with Paystack
  Future<Map<String, dynamic>> verifyPayment(String reference) async {
    try {
      log('🔄 Verifying payment: $reference');

      final callable = _functions.httpsCallable('verifyPayment');
      final result = await callable.call({'reference': reference});

      log('✅ Payment verified successfully');
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      log('❌ Error verifying payment: $e');
      rethrow;
    }
  }

  /// Update booking status (for artisan)
  Future<Map<String, dynamic>> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    LocationData? location,
    String? estimatedArrival,
  }) async {
    try {
      log('🔄 Updating booking status: $bookingId -> ${status.name}');

      final callable = _functions.httpsCallable('updateBookingStatus');
      final result = await callable.call({
        'bookingId': bookingId,
        'status': status.name,
        if (location != null) 'location': location.toJson(),
        if (estimatedArrival != null) 'estimatedArrival': estimatedArrival,
      });

      log('✅ Booking status updated successfully');
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      log('❌ Error updating booking status: $e');
      rethrow;
    }
  }

  /// Get booking details with tracking info
  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    try {
      log('🔄 Getting booking details: $bookingId');

      final callable = _functions.httpsCallable('getBookingDetails');
      final result = await callable.call({'bookingId': bookingId});

      log('✅ Booking details retrieved successfully');
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      log('❌ Error getting booking details: $e');
      rethrow;
    }
  }

  /// Update artisan location for real-time tracking
  Future<Map<String, dynamic>> updateArtisanLocation({
    required String bookingId,
    required LocationData location,
  }) async {
    try {
      log('🔄 Updating artisan location for booking: $bookingId');

      final callable = _functions.httpsCallable('updateArtisanLocation');
      final result = await callable.call({
        'bookingId': bookingId,
        'location': location.toJson(),
      });

      log('✅ Artisan location updated successfully');
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      log('❌ Error updating artisan location: $e');
      rethrow;
    }
  }

  /// Get user bookings — reads directly from Firestore (no Cloud Function needed)
  Future<List<BookingModel>> getUserBookings({
    required String userType, // 'client' or 'artisan'
    BookingStatus? status,
    int? limit,
  }) async {
    try {
      log('🔄 Getting user bookings: $userType');

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];

      final field = userType == 'client' ? 'clientId' : 'artisanId';

      Query query = FirebaseFirestore.instance
          .collection('bookings')
          .where(field, isEqualTo: uid)
          .limit(limit ?? 50);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      final bookings = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return BookingModel.fromJson(data, doc.id);
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      log('✅ Retrieved ${bookings.length} bookings');
      return bookings;
    } catch (e) {
      log('❌ Error getting user bookings: $e');
      rethrow;
    }
  }

  /// Get current location
  Future<LocationData> getCurrentLocation() async {
    try {
      log('🔄 Getting current location...');

      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position with updated settings
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      // Get address from coordinates with error handling
      String address = 'Unknown location';
      String city = '';
      String state = '';

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          address = [
            place.street,
            place.locality,
            place.administrativeArea,
          ].whereType<String>().where((part) => part.isNotEmpty).join(', ');

          if (address.isEmpty) {
            address =
                'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
          }

          city = place.locality ?? '';
          state = place.administrativeArea ?? '';
        }
      } catch (geocodingError) {
        log('⚠️ Geocoding failed, using coordinates: $geocodingError');
        address =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      }

      final locationData = LocationData(
        address: address,
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        state: state,
      );

      log('✅ Current location retrieved: ${locationData.address}');
      return locationData;
    } catch (e) {
      log('❌ Error getting current location: $e');
      rethrow;
    }
  }

  /// Get location from address
  Future<LocationData?> getLocationFromAddress(String address) async {
    try {
      log('🔄 Getting location from address: $address');

      List<Location> locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        return null;
      }

      Location location = locations.first;

      // Get detailed address information with error handling
      String fullAddress = address; // Fallback to input address
      String city = '';
      String state = '';

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          List<String> addressParts = [
            place.street,
            place.locality,
            place.administrativeArea,
          ].whereType<String>().where((part) => part.isNotEmpty).toList();

          if (addressParts.isNotEmpty) {
            fullAddress = addressParts.join(', ');
          }

          city = place.locality ?? '';
          state = place.administrativeArea ?? '';
        }
      } catch (geocodingError) {
        log(
          '⚠️ Reverse geocoding failed, using original address: $geocodingError',
        );
      }

      final locationData = LocationData(
        address: fullAddress,
        latitude: location.latitude,
        longitude: location.longitude,
        city: city,
        state: state,
      );

      log('✅ Location from address retrieved: ${locationData.address}');
      return locationData;
    } catch (e) {
      log('❌ Error getting location from address: $e');
      return null;
    }
  }

  /// Calculate distance between two locations
  double calculateDistance(LocationData from, LocationData to) {
    return Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ) /
        1000; // Convert to kilometers
  }

  /// Get estimated travel time (simplified calculation)
  Duration getEstimatedTravelTime(double distanceKm) {
    // Assume average speed of 30 km/h in urban areas
    const averageSpeedKmh = 30.0;
    final hours = distanceKm / averageSpeedKmh;
    return Duration(minutes: (hours * 60).round());
  }
}
