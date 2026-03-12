import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  paymentPending,
  paymentFailed,
}

enum PaymentStatus { pending, success, failed, abandoned }

class LocationData {
  final String address;
  final double latitude;
  final double longitude;
  final String city;
  final String state;

  LocationData({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      city: json['city'] ?? '',
      state: json['state'] ?? '',
    );
  }
}

class PaymentData {
  final int transactionId;
  final double amount;
  final String paidAt;
  final String channel;
  final String currency;
  final double fees;
  final String gatewayResponse;
  final Map<String, dynamic> authorization;

  PaymentData({
    required this.transactionId,
    required this.amount,
    required this.paidAt,
    required this.channel,
    required this.currency,
    required this.fees,
    required this.gatewayResponse,
    required this.authorization,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      transactionId: json['transactionId'] ?? 0,
      amount: (json['amount'] ?? 0.0).toDouble(),
      paidAt: json['paidAt'] ?? '',
      channel: json['channel'] ?? '',
      currency: json['currency'] ?? '',
      fees: (json['fees'] ?? 0.0).toDouble(),
      gatewayResponse: json['gatewayResponse'] ?? '',
      authorization: json['authorization'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'amount': amount,
      'paidAt': paidAt,
      'channel': channel,
      'currency': currency,
      'fees': fees,
      'gatewayResponse': gatewayResponse,
      'authorization': authorization,
    };
  }
}

class BookingModel {
  final String id;
  final String clientId;
  final String artisanId;
  final String serviceId;
  final String serviceTitle;
  final String serviceDescription;
  final String scheduledDate;
  final String scheduledTime;
  final int duration;
  final double totalAmount;
  final LocationData clientLocation;
  final LocationData? artisanLocation;
  final String? specialRequests;
  final String contactPhone;
  final String contactEmail;
  final String bookingReference;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final double serviceFee;
  final double totalWithFees;
  final double distance;
  final String? paymentReference;
  final String? paymentUrl;
  final String? paymentAccessCode;
  final PaymentData? paymentData;
  final LocationData? artisanCurrentLocation;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.artisanId,
    required this.serviceId,
    required this.serviceTitle,
    required this.serviceDescription,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.duration,
    required this.totalAmount,
    required this.clientLocation,
    this.artisanLocation,
    this.specialRequests,
    required this.contactPhone,
    required this.contactEmail,
    required this.bookingReference,
    required this.status,
    required this.paymentStatus,
    required this.serviceFee,
    required this.totalWithFees,
    required this.distance,
    this.paymentReference,
    this.paymentUrl,
    this.paymentAccessCode,
    this.paymentData,
    this.artisanCurrentLocation,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json, String id) {
    return BookingModel(
      id: id,
      clientId: json['clientId'] ?? '',
      artisanId: json['artisanId'] ?? '',
      serviceId: json['serviceId'] ?? '',
      serviceTitle: json['serviceTitle'] ?? '',
      serviceDescription: json['serviceDescription'] ?? '',
      scheduledDate: json['scheduledDate'] ?? '',
      scheduledTime: json['scheduledTime'] ?? '',
      duration: json['duration'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      clientLocation: LocationData.fromJson(json['clientLocation'] ?? {}),
      artisanLocation: json['artisanLocation'] != null
          ? LocationData.fromJson(json['artisanLocation'])
          : null,
      specialRequests: json['specialRequests'],
      contactPhone: json['contactPhone'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      bookingReference: json['bookingReference'] ?? '',
      status: _parseBookingStatus(json['status']),
      paymentStatus: _parsePaymentStatus(json['paymentStatus']),
      serviceFee: (json['serviceFee'] ?? 0.0).toDouble(),
      totalWithFees: (json['totalWithFees'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      paymentReference: json['paymentReference'],
      paymentUrl: json['paymentUrl'],
      paymentAccessCode: json['paymentAccessCode'],
      paymentData: json['paymentData'] != null
          ? PaymentData.fromJson(json['paymentData'])
          : null,
      artisanCurrentLocation: json['artisanCurrentLocation'] != null
          ? LocationData.fromJson(json['artisanCurrentLocation'])
          : null,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'artisanLocation': artisanLocation?.toJson(),
      'specialRequests': specialRequests,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'bookingReference': bookingReference,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'serviceFee': serviceFee,
      'totalWithFees': totalWithFees,
      'distance': distance,
      'paymentReference': paymentReference,
      'paymentUrl': paymentUrl,
      'paymentAccessCode': paymentAccessCode,
      'paymentData': paymentData?.toJson(),
      'artisanCurrentLocation': artisanCurrentLocation?.toJson(),
    };
  }

  static BookingStatus _parseBookingStatus(String? status) {
    switch (status) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'payment_pending':
        return BookingStatus.paymentPending;
      case 'payment_failed':
        return BookingStatus.paymentFailed;
      default:
        return BookingStatus.pending;
    }
  }

  static PaymentStatus _parsePaymentStatus(String? status) {
    switch (status) {
      case 'pending':
        return PaymentStatus.pending;
      case 'success':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      case 'abandoned':
        return PaymentStatus.abandoned;
      default:
        return PaymentStatus.pending;
    }
  }

  BookingModel copyWith({
    String? id,
    String? clientId,
    String? artisanId,
    String? serviceId,
    String? serviceTitle,
    String? serviceDescription,
    String? scheduledDate,
    String? scheduledTime,
    int? duration,
    double? totalAmount,
    LocationData? clientLocation,
    LocationData? artisanLocation,
    String? specialRequests,
    String? contactPhone,
    String? contactEmail,
    String? bookingReference,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    double? serviceFee,
    double? totalWithFees,
    double? distance,
    String? paymentReference,
    String? paymentUrl,
    String? paymentAccessCode,
    PaymentData? paymentData,
    LocationData? artisanCurrentLocation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      artisanId: artisanId ?? this.artisanId,
      serviceId: serviceId ?? this.serviceId,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      duration: duration ?? this.duration,
      totalAmount: totalAmount ?? this.totalAmount,
      clientLocation: clientLocation ?? this.clientLocation,
      artisanLocation: artisanLocation ?? this.artisanLocation,
      specialRequests: specialRequests ?? this.specialRequests,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      bookingReference: bookingReference ?? this.bookingReference,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      serviceFee: serviceFee ?? this.serviceFee,
      totalWithFees: totalWithFees ?? this.totalWithFees,
      distance: distance ?? this.distance,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      paymentAccessCode: paymentAccessCode ?? this.paymentAccessCode,
      paymentData: paymentData ?? this.paymentData,
      artisanCurrentLocation:
          artisanCurrentLocation ?? this.artisanCurrentLocation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
