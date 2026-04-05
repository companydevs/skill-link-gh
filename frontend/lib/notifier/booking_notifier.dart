import 'dart:developer';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skill_link_gh/data/repository/booking_repository.dart';
import 'package:skill_link_gh/domain/models/booking_model.dart';

/// State class for booking operations
class BookingState {
  final List<BookingModel> bookings;
  final BookingModel? currentBooking;
  final bool isLoading;
  final bool isCreatingBooking;
  final bool isVerifyingPayment;
  final String? error;
  final String? paymentUrl;
  final LocationData? currentLocation;

  const BookingState({
    this.bookings = const [],
    this.currentBooking,
    this.isLoading = false,
    this.isCreatingBooking = false,
    this.isVerifyingPayment = false,
    this.error,
    this.paymentUrl,
    this.currentLocation,
  });

  BookingState copyWith({
    List<BookingModel>? bookings,
    BookingModel? currentBooking,
    bool? isLoading,
    bool? isCreatingBooking,
    bool? isVerifyingPayment,
    String? error,
    String? paymentUrl,
    LocationData? currentLocation,
  }) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      currentBooking: currentBooking ?? this.currentBooking,
      isLoading: isLoading ?? this.isLoading,
      isCreatingBooking: isCreatingBooking ?? this.isCreatingBooking,
      isVerifyingPayment: isVerifyingPayment ?? this.isVerifyingPayment,
      error: error ?? this.error,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final BookingRepository repository;

  BookingNotifier(this.repository) : super(const BookingState());

  /// Create a new booking
  Future<Map<String, dynamic>?> createBooking({
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
    state = state.copyWith(isCreatingBooking: true, error: null);

    try {
      log('🔄 Creating booking...');

      final result = await repository.createBooking(
        clientId: clientId,
        artisanId: artisanId,
        serviceId: serviceId,
        serviceTitle: serviceTitle,
        serviceDescription: serviceDescription,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        duration: duration,
        totalAmount: totalAmount,
        clientLocation: clientLocation,
        specialRequests: specialRequests,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
      );

      if (result['success'] == true) {
        state = state.copyWith(
          isCreatingBooking: false,
          paymentUrl: result['paymentUrl'],
        );

        log('✅ Booking created successfully');
        return result;
      } else {
        throw Exception('Failed to create booking');
      }
    } catch (e) {
      log('❌ Error creating booking: $e');
      state = state.copyWith(isCreatingBooking: false, error: e.toString());
      return null;
    }
  }

  /// Verify payment
  Future<bool> verifyPayment(String reference) async {
    state = state.copyWith(isVerifyingPayment: true, error: null);

    try {
      log('🔄 Verifying payment: $reference');

      final result = await repository.verifyPayment(reference);

      if (result['success'] == true && result['paymentStatus'] == 'success') {
        state = state.copyWith(isVerifyingPayment: false, paymentUrl: null);

        // Refresh bookings in background — don't block or fail verification if this errors
        loadUserBookings('client').catchError((_) {});

        log('✅ Payment verified successfully');
        return true;
      } else {
        throw Exception('Payment verification failed');
      }
    } catch (e) {
      log('❌ Error verifying payment: $e');
      state = state.copyWith(isVerifyingPayment: false, error: e.toString());
      return false;
    }
  }

  /// Update booking status (for artisan)
  Future<bool> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    LocationData? location,
    String? estimatedArrival,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      log('🔄 Updating booking status: $bookingId -> ${status.name}');

      final result = await repository.updateBookingStatus(
        bookingId: bookingId,
        status: status,
        location: location,
        estimatedArrival: estimatedArrival,
      );

      if (result['success'] == true) {
        // Update the booking in the list
        final updatedBookings = state.bookings.map((booking) {
          if (booking.id == bookingId) {
            return booking.copyWith(
              status: status,
              artisanCurrentLocation: location,
            );
          }
          return booking;
        }).toList();

        // Update current booking if it matches
        BookingModel? updatedCurrentBooking = state.currentBooking;
        if (state.currentBooking?.id == bookingId) {
          updatedCurrentBooking = state.currentBooking!.copyWith(
            status: status,
            artisanCurrentLocation: location,
          );
        }

        state = state.copyWith(
          isLoading: false,
          bookings: updatedBookings,
          currentBooking: updatedCurrentBooking,
        );

        log('✅ Booking status updated successfully');
        return true;
      } else {
        throw Exception('Failed to update booking status');
      }
    } catch (e) {
      log('❌ Error updating booking status: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get booking details
  Future<void> getBookingDetails(String bookingId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      log('🔄 Getting booking details: $bookingId');

      final result = await repository.getBookingDetails(bookingId);

      if (result['success'] == true) {
        final bookingData = result['booking'];
        final booking = BookingModel.fromJson(bookingData, bookingData['id']);

        state = state.copyWith(isLoading: false, currentBooking: booking);

        log('✅ Booking details retrieved successfully');
      } else {
        throw Exception('Failed to get booking details');
      }
    } catch (e) {
      log('❌ Error getting booking details: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update artisan location
  Future<bool> updateArtisanLocation({
    required String bookingId,
    required LocationData location,
  }) async {
    try {
      log('🔄 Updating artisan location for booking: $bookingId');

      final result = await repository.updateArtisanLocation(
        bookingId: bookingId,
        location: location,
      );

      if (result['success'] == true) {
        // Update the booking in the list
        final updatedBookings = state.bookings.map((booking) {
          if (booking.id == bookingId) {
            return booking.copyWith(artisanCurrentLocation: location);
          }
          return booking;
        }).toList();

        // Update current booking if it matches
        BookingModel? updatedCurrentBooking = state.currentBooking;
        if (state.currentBooking?.id == bookingId) {
          updatedCurrentBooking = state.currentBooking!.copyWith(
            artisanCurrentLocation: location,
          );
        }

        state = state.copyWith(
          bookings: updatedBookings,
          currentBooking: updatedCurrentBooking,
        );

        log('✅ Artisan location updated successfully');
        return true;
      } else {
        throw Exception('Failed to update artisan location');
      }
    } catch (e) {
      log('❌ Error updating artisan location: $e');
      return false;
    }
  }

  /// Load user bookings
  Future<void> loadUserBookings(
    String userType, {
    BookingStatus? status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      log('🔄 Loading user bookings: $userType');

      final bookings = await repository.getUserBookings(
        userType: userType,
        status: status,
      );

      state = state.copyWith(isLoading: false, bookings: bookings);

      log('✅ Loaded ${bookings.length} bookings');
    } catch (e) {
      log('❌ Error loading user bookings: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get current location
  Future<void> getCurrentLocation() async {
    try {
      log('🔄 Getting current location...');

      final location = await repository.getCurrentLocation();

      state = state.copyWith(currentLocation: location);

      log('✅ Current location retrieved');
    } catch (e) {
      log('❌ Error getting current location: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get location from address
  Future<LocationData?> getLocationFromAddress(String address) async {
    try {
      log('🔄 Getting location from address: $address');

      final location = await repository.getLocationFromAddress(address);

      log('✅ Location from address retrieved');
      return location;
    } catch (e) {
      log('❌ Error getting location from address: $e');
      return null;
    }
  }

  /// Calculate distance between locations
  double calculateDistance(LocationData from, LocationData to) {
    return repository.calculateDistance(from, to);
  }

  /// Get estimated travel time
  Duration getEstimatedTravelTime(double distanceKm) {
    return repository.getEstimatedTravelTime(distanceKm);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear payment URL
  void clearPaymentUrl() {
    state = state.copyWith(paymentUrl: null);
  }

  /// Clear current booking
  void clearCurrentBooking() {
    state = state.copyWith(currentBooking: null);
  }
}
