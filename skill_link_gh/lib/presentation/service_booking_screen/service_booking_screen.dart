import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_link_gh/domain/models/booking_model.dart';
import 'package:skill_link_gh/provider/booking_provider.dart';

import '../../core/app_export.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLocation();
      _loadServiceData();
    });
  }

  void _loadServiceData() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Args can come from:
    // 1. Post card → post.toJson() with artisanId, artisanName, artisanImage, priceRange
    // 2. Search/artisan card → artisan map with id, name, profileImage, rating, etc.
    // 3. Services section → no args

    Map<String, dynamic> artisan = {};
    Map<String, dynamic> service = {};

    if (args != null) {
      // From artisan card (search screen) — has 'name', 'profileImage', 'services'
      if (args.containsKey('name') || args.containsKey('fullName')) {
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
          'hourlyRate': args['hourlyRate'],
          'priceRange': args['priceRange'] ?? '',
        };
      }
      // From post card → post.toJson() has artisanId, artisanName, artisanImage, priceRange
      else if (args.containsKey('artisanId') ||
          args.containsKey('artisanName')) {
        artisan = {
          'id': args['artisanId'] ?? '',
          'name': args['artisanName'] ?? 'Artisan',
          'serviceType': args['category'] ?? '',
          'rating': args['rating'] ?? 0.0,
          'reviews': args['totalReviews'] ?? 0,
          'profileImage': args['artisanImage'] ?? '',
          'priceRange': args['priceRange'] ?? '',
        };
        service = {
          'id': args['id'] ?? '',
          'title': args['title'] ?? args['category'] ?? 'Service',
          'description': args['description'] ?? '',
          'basePrice': _parsePriceRange(args['priceRange'] as String?),
          'duration': 2,
        };
      }
      // Nested artisan/service keys
      else {
        artisan = Map<String, dynamic>.from(args['artisan'] as Map? ?? {});
        service = Map<String, dynamic>.from(args['service'] as Map? ?? {});
      }
    }

    setState(() {
      _artisanData = artisan.isNotEmpty ? artisan : null;
      _serviceData = service.isNotEmpty
          ? service
          : {
              'id': 'service_1',
              'title': artisan['serviceType'] ?? 'Service',
              'description': '',
              'basePrice':
                  _parseHourlyRate(artisan['hourlyRate']) ??
                  _parsePriceRange(artisan['priceRange'] as String?) ??
                  0.0,
              'duration': 2,
            };
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber != null) {
      _phoneController.text = user!.phoneNumber!;
    }
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

  // Mock saved cards
  final List<Map<String, dynamic>> _savedCards = [
    {"id": "card_1", "cardType": "Visa", "lastFourDigits": "4242"},
    {"id": "card_2", "cardType": "Mastercard", "lastFourDigits": "5555"},
  ];

  Map<String, dynamic> get _pricingData {
    // Get base price from artisan data or service data
    double basePrice = 0.0;
    if (_artisanData != null && _artisanData!['hourlyRate'] != null) {
      basePrice = (_artisanData!['hourlyRate'] as num).toDouble();
    } else if (_serviceData != null && _serviceData!['basePrice'] != null) {
      basePrice = (_serviceData!['basePrice'] as num).toDouble();
    } else {
      basePrice = 150.0; // Fallback
    }

    double complexityFee = _descriptionController.text.length > 100
        ? 30.0
        : 0.0;
    double travelFee = _selectedLocation != null ? 20.0 : 0.0;
    double platformFee = basePrice * 0.05; // 5% platform fee
    double total = basePrice + complexityFee + travelFee + platformFee;

    return {
      "basePrice": "GH₵ ${basePrice.toStringAsFixed(2)}",
      "complexityFee": "GH₵ ${complexityFee.toStringAsFixed(2)}",
      "travelFee": "GH₵ ${travelFee.toStringAsFixed(2)}",
      "platformFee": "GH₵ ${platformFee.toStringAsFixed(2)}",
      "totalPrice": "GH₵ ${total.toStringAsFixed(2)}",
    };
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

      // Calculate total amount
      final pricingData = _pricingData;
      final totalPriceString = pricingData['totalPrice'] as String;
      final totalAmount = double.parse(
        totalPriceString.replaceAll('GH₵ ', '').replaceAll(',', ''),
      );

      // Create booking
      final result = await ref
          .read(bookingNotifierProvider.notifier)
          .createBooking(
            clientId: user.uid,
            artisanId: user.uid, // Using same user as artisan for testing
            serviceId: _serviceData?['id'] ?? 'service_1',
            serviceTitle: _serviceData?['title'] ?? 'Service',
            serviceDescription: _descriptionController.text.trim(),
            scheduledDate: _selectedDate!.toIso8601String().split('T')[0],
            scheduledTime: _selectedTimeSlot!,
            duration: _serviceData?['duration'] ?? 2,
            totalAmount: totalAmount,
            clientLocation: _clientLocation!,
            specialRequests: _descriptionController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            contactEmail: user.email ?? '',
          );

      if (result != null && result['success'] == true) {
        if (mounted) {
          // Navigate to payment verification screen
          Navigator.pushReplacementNamed(
            context,
            '/payment-verification',
            arguments: {
              'paymentUrl': result['paymentUrl'],
              'bookingId': result['bookingId'],
              'reference': result['bookingReference'],
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
