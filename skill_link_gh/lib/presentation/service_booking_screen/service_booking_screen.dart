import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_link_gh/domain/models/booking_model.dart';
import 'package:skill_link_gh/provider/booking_provider.dart';

import '../../core/app_export.dart';
import '../../services/transport_fare_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/artisan_summary_widget.dart';
import './widgets/calendar_widget.dart';
import './widgets/location_input_widget.dart';
import './widgets/payment_method_widget.dart';
import './widgets/pricing_summary_widget.dart';
import './widgets/service_details_widget.dart';
import './widgets/time_slot_picker_widget.dart';

/// Service Booking Screen for scheduling appointments with artisans
class ServiceBookingScreen extends ConsumerStatefulWidget {
  const ServiceBookingScreen({super.key});

  @override
  ConsumerState<ServiceBookingScreen> createState() =>
      _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends ConsumerState<ServiceBookingScreen> {
  int _currentStep = 0;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  int _numberOfDays = 1; // for daily-rate bookings
  bool _isContractBooking =
      false; // true = from post (fixed price), false = from profile (daily rate)
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<XFile> _selectedImages = [];
  LatLng? _selectedLocation;
  LocationData? _clientLocation;
  String? _selectedPaymentMethod;
  bool _termsAccepted = false;
  bool _isProcessing = false;

  // Service data (passed from arguments or default)
  Map<String, dynamic>? _serviceData;
  Map<String, dynamic>? _artisanData;

  @override
  void initState() {
    super.initState();
    // Rebuild when description changes so Continue button enables/disables
    _descriptionController.addListener(() => setState(() {}));
    _addressController.addListener(() => setState(() {}));
    _selectedPaymentMethod = 'wallet'; // default to wallet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLocation();
      _loadServiceData();
    });
  }

  void _loadServiceData() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    Map<String, dynamic> artisan = {};
    Map<String, dynamic> service = {};

    if (args != null) {
      if (args.containsKey('name') || args.containsKey('fullName')) {
        // From artisan/search card
        artisan = {
          'id': args['id'] ?? args['uid'] ?? '',
          'name': args['name'] ?? args['fullName'] ?? 'Artisan',
          'serviceType':
              (args['services'] as List?)?.join(', ') ??
              (args['serviceCategories'] as List?)?.join(', ') ??
              '',
          'rating': args['rating'] ?? 0.0,
          'reviews': args['totalReviews'] ?? 0,
          'profileImage': args['profileImage'] ?? '',
          'dailyRate': args['dailyRate'],
          'priceRange': args['priceRange'] ?? '',
        };
      } else if (args.containsKey('artisanId') ||
          args.containsKey('artisanName')) {
        // From post card — 'pricing' field holds "GHS 1500 - 3800"
        final pricing =
            args['pricing'] as String? ?? args['priceRange'] as String? ?? '';
        artisan = {
          'id': args['artisanId'] ?? '',
          'name': args['artisanName'] ?? 'Artisan',
          'serviceType': args['serviceCategory'] ?? args['category'] ?? '',
          'rating': args['rating'] ?? 0.0,
          'reviews': args['totalReviews'] ?? 0,
          'profileImage': args['artisanImage'] ?? '',
          'priceRange': pricing,
        };
        service = {
          'id': args['id'] ?? '',
          'title': args['serviceCategory'] ?? args['category'] ?? 'Service',
          'description': args['description'] ?? '',
          'basePrice': _parsePriceRange(pricing),
          'duration': 2,
        };
      } else {
        artisan = Map<String, dynamic>.from(args['artisan'] as Map? ?? {});
        service = Map<String, dynamic>.from(args['service'] as Map? ?? {});
      }
    }

    setState(() {
      // Contract booking = came from a post (has artisanId/artisanName keys)
      // Daily rate booking = came from profile/search (has name/fullName keys)
      _isContractBooking =
          args != null &&
          (args.containsKey('artisanId') || args.containsKey('artisanName'));

      _artisanData = artisan.isNotEmpty ? artisan : null;
      _serviceData = service.isNotEmpty
          ? service
          : {
              'id': 'service_1',
              'title': artisan['serviceType'] ?? 'Service',
              'description': '',
              'basePrice':
                  _parseHourlyRate(artisan['dailyRate']) ??
                  _parsePriceRange(artisan['priceRange'] as String?),
              'duration': 2,
            };
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber != null) {
      _phoneController.text = user!.phoneNumber!;
    }

    // Fetch full artisan profile from Firestore for real schedule + hourly rate
    final artisanId = artisan['id'] as String? ?? '';
    if (artisanId.isNotEmpty) {
      _fetchArtisanProfile(artisanId);
      // Check for existing active booking with this artisan
      _checkExistingBooking(artisanId);
    } else {
      _buildDefaultTimeSlots();
    }
  }

  Future<void> _checkExistingBooking(String artisanId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('clientId', isEqualTo: uid)
          .where('artisanId', isEqualTo: artisanId)
          .get();

      // Find any active booking (not cancelled/completed/failed)
      final active = snapshot.docs.where((doc) {
        final status = doc.data()['status'] as String? ?? '';
        return status == 'confirmed' ||
            status == 'payment_pending' ||
            status == 'in_progress';
      }).toList();

      if (active.isNotEmpty && mounted) {
        final bookingId = active.first.id;
        // Show dialog and redirect
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Active Booking Found'),
            content: const Text(
              'You already have an active booking with this artisan. '
              'Would you like to view it?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close booking screen
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pushReplacementNamed(
                    context,
                    '/booking-tracking-screen',
                    arguments: {'bookingId': bookingId},
                  );
                },
                child: const Text('View Booking'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      // Silent — don't block booking if check fails
    }
  }

  Future<void> _fetchArtisanProfile(String artisanId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(artisanId)
          .get();
      if (!doc.exists || !mounted) return;

      final data = doc.data()!;
      setState(() {
        // Update hourly rate from real profile
        if (data['dailyRate'] != null) {
          _artisanData = {
            ..._artisanData ?? {},
            'dailyRate': data['dailyRate'],
          };
          // Update service base price too
          _serviceData = {
            ..._serviceData ?? {},
            'basePrice':
                (_parseHourlyRate(data['dailyRate']) ??
                _serviceData?['basePrice']),
          };
        }

        // Build time slots from artisan's working hours
        final workingHours = data['workingHours'] as Map<String, dynamic>?;
        final startStr = workingHours?['start'] as String? ?? '09:00';
        final endStr = workingHours?['end'] as String? ?? '17:00';
        _availableTimeSlots = _generateTimeSlots(startStr, endStr);

        // Build unavailable dates from availability days
        final availability = data['availability'] as Map<String, dynamic>?;
        if (availability != null) {
          _unavailableDates = _getUnavailableDates(availability);
        }
      });
    } catch (_) {
      _buildDefaultTimeSlots();
    }
  }

  void _buildDefaultTimeSlots() {
    setState(() {
      _availableTimeSlots = _generateTimeSlots('09:00', '17:00');
    });
  }

  /// Generate 2-hour slots between start and end time
  List<String> _generateTimeSlots(String start, String end) {
    final slots = <String>[];
    try {
      final startParts = start.split(':');
      final endParts = end.split(':');
      int hour = int.parse(startParts[0]);
      final endHour = int.parse(endParts[0]);

      while (hour < endHour) {
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        slots.add('${displayHour.toString().padLeft(2, '0')}:00 $period');
        hour += 2;
      }
    } catch (_) {
      return ['09:00 AM', '11:00 AM', '01:00 PM', '03:00 PM', '05:00 PM'];
    }
    return slots.isEmpty
        ? ['09:00 AM', '11:00 AM', '01:00 PM', '03:00 PM', '05:00 PM']
        : slots;
  }

  /// Returns dates in the next 90 days that are NOT in the artisan's available days
  List<DateTime> _getUnavailableDates(Map<String, dynamic> availability) {
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final unavailable = <DateTime>[];
    final now = DateTime.now();
    for (int i = 0; i <= 90; i++) {
      final date = now.add(Duration(days: i));
      // weekday: 1=Mon, 7=Sun
      final dayName = dayNames[date.weekday - 1];
      final isAvailable = availability[dayName] as bool? ?? false;
      if (!isAvailable) unavailable.add(date);
    }
    return unavailable;
  }

  double? _parseHourlyRate(dynamic rate) {
    if (rate == null) return null;
    if (rate is num) return rate.toDouble();
    if (rate is String) return double.tryParse(rate);
    return null;
  }

  double? _parsePriceRange(String? range) {
    if (range == null || range.isEmpty) return null;
    // e.g. "GHS 50-200" → take the lower bound
    final digits = RegExp(r'\d+').allMatches(range);
    if (digits.isNotEmpty) {
      return double.tryParse(digits.first.group(0)!);
    }
    return null;
  }

  Future<void> _loadCurrentLocation() async {
    try {
      await ref.read(bookingNotifierProvider.notifier).getCurrentLocation();
      final currentLocation = ref.read(bookingNotifierProvider).currentLocation;
      if (currentLocation != null) {
        setState(() {
          _clientLocation = currentLocation;
          _addressController.text = currentLocation.address;
        });
      }
    } catch (e) {
      // Handle location error silently, but log it
      print('Location error: $e');
    }
  }

  // Mock unavailable dates
  List<DateTime> _unavailableDates = [];

  // Time slots generated from artisan's working hours
  List<String> _availableTimeSlots = [];

  // Mock saved cards — kept for API compat but wallet is primary
  final List<Map<String, dynamic>> _savedCards = [];

  Map<String, dynamic> get _pricingData {
    // Trotro round-trip fare based on artisan distance
    final distKm = (_artisanData?['distance'] as num?)?.toDouble() ?? 0.0;
    final transportFare = TransportFareService.roundTripFare(distKm);
    final transportLabel = 'GH₵ ${transportFare.toStringAsFixed(2)}';

    if (_isContractBooking) {
      final raw = (_serviceData?['basePrice'] as num?)?.toDouble() ?? 0.0;
      final contractPrice = (raw.isNaN || raw.isInfinite) ? 0.0 : raw;
      final platformFee = contractPrice * 0.05;
      final total = contractPrice + transportFare + platformFee;
      return {
        "basePrice": contractPrice == 0.0
            ? 'Not set'
            : 'GH₵ ${contractPrice.toStringAsFixed(2)}',
        "complexityFee": null,
        "travelFee": transportLabel,
        "platformFee": "GH₵ ${platformFee.toStringAsFixed(2)}",
        "totalPrice": contractPrice == 0.0
            ? 'TBD'
            : "GH₵ ${total.toStringAsFixed(2)}",
        "isContract": true,
      };
    } else {
      double rawRate = 0.0;
      if (_artisanData?['dailyRate'] != null) {
        rawRate = _parseHourlyRate(_artisanData!['dailyRate']) ?? 0.0;
      } else if (_serviceData?['basePrice'] != null) {
        rawRate = (_serviceData!['basePrice'] as num?)?.toDouble() ?? 0.0;
      }
      final dailyRate = (rawRate.isNaN || rawRate.isInfinite) ? 0.0 : rawRate;
      final subtotal = dailyRate * _numberOfDays;
      final platformFee = subtotal * 0.05;
      final total = subtotal + transportFare + platformFee;
      final dayLabel = '$_numberOfDays day${_numberOfDays > 1 ? 's' : ''}';
      return {
        "basePrice": dailyRate == 0.0
            ? 'Not set'
            : 'GH₵ ${dailyRate.toStringAsFixed(2)} × $dayLabel',
        "complexityFee": null,
        "travelFee": transportLabel,
        "platformFee": "GH₵ ${platformFee.toStringAsFixed(2)}",
        "totalPrice": dailyRate == 0.0
            ? 'TBD'
            : "GH₵ ${total.toStringAsFixed(2)}",
        "isContract": false,
        "numberOfDays": _numberOfDays,
      };
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null;
    });
  }

  void _onTimeSlotSelected(String timeSlot) {
    setState(() => _selectedTimeSlot = timeSlot);
  }

  void _onImagesSelected(List<XFile> images) {
    setState(() => _selectedImages = images);
  }

  void _onLocationSelected(LatLng location) {
    setState(() => _selectedLocation = location);
  }

  void _onPaymentMethodSelected(String paymentMethodId) {
    setState(() => _selectedPaymentMethod = paymentMethodId);
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _selectedDate != null && _selectedTimeSlot != null;
      case 1:
        return _descriptionController.text.isNotEmpty &&
            _addressController.text.isNotEmpty;
      case 2:
        return _selectedPaymentMethod != null &&
            _termsAccepted &&
            (_clientLocation != null || _addressController.text.isNotEmpty);
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceedToNextStep()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        _confirmBooking();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _confirmBooking() async {
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Ensure we have client location
      if (_clientLocation == null) {
        // Try to get location one more time
        await _loadCurrentLocation();

        // If still null, create a default location from address
        if (_clientLocation == null) {
          if (_addressController.text.isNotEmpty) {
            final locationFromAddress = await ref
                .read(bookingNotifierProvider.notifier)
                .getLocationFromAddress(_addressController.text);

            if (locationFromAddress != null) {
              setState(() => _clientLocation = locationFromAddress);
            } else {
              throw Exception(
                'Unable to determine location. Please ensure location services are enabled or enter a valid address.',
              );
            }
          } else {
            throw Exception(
              'Location is required. Please enable location services or enter your address.',
            );
          }
        }
      }

      // Calculate total amount — handle TBD case
      final pricingData = _pricingData;
      final totalPriceString = pricingData['totalPrice'] as String;
      if (totalPriceString == 'TBD') {
        throw Exception(
          'Price not set. Please contact the artisan to confirm pricing.',
        );
      }
      // Extract numeric value robustly — strip all non-numeric chars except dot
      final numericString = totalPriceString.replaceAll(RegExp(r'[^\d.]'), '');
      final totalAmount = double.tryParse(numericString);
      if (totalAmount == null ||
          totalAmount.isNaN ||
          totalAmount.isInfinite ||
          totalAmount <= 0) {
        throw Exception(
          'Invalid price "$totalPriceString". Please go back and try again.',
        );
      }

      // Use real artisan ID from loaded data
      final artisanId = _artisanData?['id'] as String? ?? '';
      if (artisanId.isEmpty) {
        throw Exception(
          'Artisan information missing. Please go back and try again.',
        );
      }

      // Create booking
      final result = await ref
          .read(bookingNotifierProvider.notifier)
          .createBooking(
            clientId: user.uid,
            artisanId: artisanId,
            serviceId: _serviceData?['id'] ?? 'service_1',
            serviceTitle: _serviceData?['title'] ?? 'Service',
            serviceDescription: _descriptionController.text.trim(),
            scheduledDate: _selectedDate!.toIso8601String().split('T')[0],
            scheduledTime: _selectedTimeSlot!,
            duration: _isContractBooking ? 1 : _numberOfDays,
            totalAmount: totalAmount,
            clientLocation: _clientLocation!,
            specialRequests: _descriptionController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            contactEmail: user.email ?? '',
          );

      if (result != null && result['success'] == true) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/payment-verification',
            arguments: {
              'paymentUrl': result['paymentUrl'],
              'bookingId': result['bookingId'],
              'reference': result['bookingReference'],
              'email': FirebaseAuth.instance.currentUser?.email ?? '',
            },
          );
        }
      } else {
        throw Exception(
          'Failed to create booking: ${result?['error'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating booking: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Book Service',
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Processing your booking...',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ArtisanSummaryWidget(artisanData: _artisanData ?? {}),
                        const SizedBox(height: 24),
                        _buildStepContent(),
                      ],
                    ),
                  ),
                ),
                _buildBottomActions(),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    final theme = Theme.of(context);
    final steps = ['Date & Time', 'Details', 'Payment'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          steps.length,
          (index) => Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: index <= _currentStep
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: index < _currentStep
                              ? CustomIconWidget(
                                  iconName: 'check',
                                  color: theme.colorScheme.onPrimary,
                                  size: 16,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: index <= _currentStep
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: index <= _currentStep
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: index == _currentStep
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      color: index < _currentStep
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contract badge
            if (_isContractBooking) ...[
              _buildContractBadge(),
              const SizedBox(height: 16),
            ],
            CalendarWidget(
              selectedDate: _selectedDate,
              onDateSelected: _onDateSelected,
              unavailableDates: _unavailableDates,
            ),
            const SizedBox(height: 24),
            if (_selectedDate != null)
              TimeSlotPickerWidget(
                selectedTimeSlot: _selectedTimeSlot,
                onTimeSlotSelected: _onTimeSlotSelected,
                availableTimeSlots: _availableTimeSlots,
              ),
            // Days selector — only for daily rate bookings
            if (!_isContractBooking && _selectedDate != null) ...[
              const SizedBox(height: 24),
              _buildDaysSelector(),
            ],
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceDetailsWidget(
              descriptionController: _descriptionController,
              selectedImages: _selectedImages,
              onImagesSelected: _onImagesSelected,
            ),
            const SizedBox(height: 16),
            LocationInputWidget(
              addressController: _addressController,
              selectedLocation: _selectedLocation,
              onLocationSelected: _onLocationSelected,
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PricingSummaryWidget(pricingData: _pricingData),
            const SizedBox(height: 16),
            PaymentMethodWidget(
              selectedPaymentMethod: _selectedPaymentMethod,
              onPaymentMethodSelected: _onPaymentMethodSelected,
              savedCards: _savedCards,
              totalAmount:
                  double.tryParse(
                    (_pricingData['totalPrice'] as String? ?? '').replaceAll(
                      RegExp(r'[^\d.]'),
                      '',
                    ),
                  ) ??
                  0.0,
            ),
            const SizedBox(height: 16),
            _buildTermsCheckbox(),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTermsCheckbox() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _termsAccepted,
            onChanged: (value) {
              setState(() => _termsAccepted = value ?? false);
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'I agree to the Terms of Service and Privacy Policy. I understand that payment will be processed upon booking confirmation.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractBadge() {
    final theme = Theme.of(context);
    final priceRange = _artisanData?['priceRange'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contract Booking',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Fixed price${priceRange.isNotEmpty ? ': $priceRange' : ''} — covers the full job regardless of days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSelector() {
    final theme = Theme.of(context);
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
          Text(
            'Number of Days',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How many days do you need the artisan?',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _numberOfDays > 1
                    ? () => setState(() => _numberOfDays--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: theme.colorScheme.primary,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_numberOfDays day${_numberOfDays > 1 ? 's' : ''}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _numberOfDays < 30
                    ? () => setState(() => _numberOfDays++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep > 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _canProceedToNextStep() ? _nextStep : null,
                child: Text(_currentStep < 2 ? 'Continue' : 'Confirm Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
