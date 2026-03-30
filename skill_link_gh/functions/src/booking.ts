/* eslint-disable linebreak-style */
/* eslint-disable max-len */
/* eslint-disable linebreak-style */
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import axios from "axios";

// Initialize Firebase Admin if not already initialized
try {
  initializeApp();
} catch (error) {
  // App already initialized
}

const db = getFirestore();

// Paystack configuration
const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY ||
  "sk_test_your_secret_key";
const PAYSTACK_BASE_URL = "https://api.paystack.co";

// Booking status enum
enum BookingStatus {
  PENDING = "pending",
  CONFIRMED = "confirmed",
  IN_PROGRESS = "in_progress",
  COMPLETED = "completed",
  CANCELLED = "cancelled",
  PAYMENT_PENDING = "payment_pending",
  PAYMENT_FAILED = "payment_failed",
}

// Payment status enum
enum PaymentStatus {
  PENDING = "pending",
  SUCCESS = "success",
  FAILED = "failed",
  ABANDONED = "abandoned",
}

// Interfaces
interface BookingData {
  clientId: string;
  artisanId: string;
  serviceId: string;
  serviceTitle: string;
  serviceDescription: string;
  scheduledDate: string;
  scheduledTime: string;
  duration: number; // in hours
  totalAmount: number;
  clientLocation: {
    address: string;
    latitude: number;
    longitude: number;
    city: string;
    state: string;
  };
  artisanLocation?: {
    address: string;
    latitude: number;
    longitude: number;
    city: string;
    state: string;
  };
  specialRequests?: string;
  contactPhone: string;
  contactEmail: string;
}

interface PaystackInitializeResponse {
  status: boolean;
  message: string;
  data: {
    authorization_url: string;
    access_code: string;
    reference: string;
  };
}

interface PaystackVerifyResponse {
  status: boolean;
  message: string;
  data: {
    id: number;
    domain: string;
    status: string;
    reference: string;
    amount: number;
    message: string;
    gateway_response: string;
    paid_at: string;
    created_at: string;
    channel: string;
    currency: string;
    ip_address: string;
    metadata: Record<string, unknown>;
    log: Record<string, unknown>;
    fees: number;
    fees_split: Record<string, unknown>;
    authorization: {
      authorization_code: string;
      bin: string;
      last4: string;
      exp_month: string;
      exp_year: string;
      channel: string;
      card_type: string;
      bank: string;
      country_code: string;
      brand: string;
      reusable: boolean;
      signature: string;
      account_name: string;
    };
    customer: {
      id: number;
      first_name: string;
      last_name: string;
      email: string;
      customer_code: string;
      phone: string;
      metadata: Record<string, unknown>;
      risk_action: string;
      international_format_phone: string;
    };
    plan: Record<string, unknown>;
    split: Record<string, unknown>;
    order_id: Record<string, unknown>;
    paidAt: string;
    createdAt: string;
    requested_amount: number;
    pos_transaction_data: Record<string, unknown>;
    source: Record<string, unknown>;
    fees_breakdown: Record<string, unknown>;
  };
}


/**
 * Helper function to calculate distance between two coordinates
 * @param {number} lat1 - First latitude
 * @param {number} lon1 - First longitude
 * @param {number} lat2 - Second latitude
 * @param {number} lon2 - Second longitude
 * @return {number} Distance in kilometers
 */
function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Radius of the Earth in kilometers
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c; // Distance in kilometers
  return distance;
}

/**
 * Helper function to calculate service fee (platform commission)
 * @param {number} amount - The base amount
 * @return {number} The calculated service fee
 */
function calculateServiceFee(amount: number): number {
  const feePercentage = 0.05; // 5% platform fee
  return Math.round(amount * feePercentage);
}

/**
 * Helper function to generate booking reference
 * @return {string} Generated booking reference
 */
function generateBookingReference(): string {
  const timestamp = Date.now().toString();
  const random = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `BK${timestamp.slice(-6)}${random}`;
}

/**
 * Create a new booking
 */
export const createBooking = onCall(async (request) => {
  try {
    // Verify user authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const userId = request.auth.uid;
    const data = request.data as BookingData;

    // Validate required fields
    if (!data.clientId || !data.artisanId ||
        !data.serviceId || !data.totalAmount) {
      throw new HttpsError("invalid-argument", "Missing required booking data");
    }

    // Verify client is the authenticated user
    if (data.clientId !== userId) {
      throw new HttpsError(
        "permission-denied",
        "Client ID must match authenticated user"
      );
    }

    // Get artisan data (since everyone is an artisan, get from users collection)
    const artisanDoc = await db.collection("users").doc(data.artisanId).get();
    let artisanLocation = null;

    if (artisanDoc.exists) {
      const artisanData = artisanDoc.data();
      artisanLocation = artisanData?.location;
    } else {
      // If artisan not found in users, create a basic entry or use default location
      console.warn(`Artisan ${data.artisanId} not found, using client location as fallback`);
      artisanLocation = data.clientLocation;
    }

    // Calculate distance if both locations are available
    let distance = 0;
    if (artisanLocation && data.clientLocation) {
      distance = calculateDistance(
        data.clientLocation.latitude,
        data.clientLocation.longitude,
        artisanLocation.latitude,
        artisanLocation.longitude
      );
    }

    // Calculate fees
    const serviceFee = calculateServiceFee(data.totalAmount);
    const totalWithFees = data.totalAmount + serviceFee;

    // Generate booking reference
    const bookingReference = generateBookingReference();

    // Create booking document
    const bookingData = {
      ...data,
      bookingReference,
      status: BookingStatus.PAYMENT_PENDING,
      paymentStatus: PaymentStatus.PENDING,
      serviceFee,
      totalWithFees,
      distance,
      artisanLocation,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const bookingRef = await db.collection("bookings").add(bookingData);
    const bookingId = bookingRef.id;

    // Initialize Paystack payment
    if (!PAYSTACK_SECRET_KEY || PAYSTACK_SECRET_KEY === "sk_test_your_secret_key") {
      throw new HttpsError("failed-precondition",
        "Payment gateway not configured. Please contact support.");
    }

    const paymentData = {
      email: data.contactEmail,
      amount: totalWithFees * 100, // Paystack expects amount in kobo (cents)
      reference: bookingReference,
      callback_url: "https://your-app.com/payment-callback",
      metadata: {
        bookingId,
        clientId: data.clientId,
        artisanId: data.artisanId,
        serviceId: data.serviceId,
        custom_fields: [
          {
            display_name: "Booking ID",
            variable_name: "booking_id",
            value: bookingId,
          },
          {
            display_name: "Service",
            variable_name: "service",
            value: data.serviceTitle,
          },
        ],
      },
      channels: ["card", "bank", "ussd", "qr", "mobile_money", "bank_transfer"],
    };

    let paystackResponse;
    try {
      paystackResponse = await axios.post<PaystackInitializeResponse>(
        `${PAYSTACK_BASE_URL}/transaction/initialize`,
        paymentData,
        {
          headers: {
            "Authorization": `Bearer ${PAYSTACK_SECRET_KEY}`,
            "Content-Type": "application/json",
          },
        }
      );
    } catch (paystackError: any) {
      console.error("Paystack API error:", paystackError?.response?.data || paystackError?.message);
      throw new HttpsError("internal",
        `Payment gateway error: ${paystackError?.response?.data?.message || paystackError?.message || "Unknown"}`);
    }

    if (!paystackResponse.data.status) {
      console.error("Paystack returned false status:", paystackResponse.data);
      throw new HttpsError("internal", `Payment init failed: ${paystackResponse.data.message}`);
    }

    // Update booking with payment details
    await bookingRef.update({
      paymentReference: bookingReference,
      paymentUrl: paystackResponse.data.data.authorization_url,
      paymentAccessCode: paystackResponse.data.data.access_code,
      updatedAt: new Date(),
    });

    // Create notification for artisan
    await db.collection("notifications").add({
      userId: data.artisanId,
      type: "new_booking",
      title: "New Booking Request",
      message: `You have a new booking request for ${data.serviceTitle}`,
      bookingId,
      isRead: false,
      createdAt: new Date(),
    });

    return {
      success: true,
      bookingId,
      bookingReference,
      paymentUrl: paystackResponse.data.data.authorization_url,
      totalAmount: totalWithFees,
      serviceFee,
      distance: Math.round(distance * 100) / 100, // Round to 2 decimal places
    };
  } catch (error) {
    console.error("Error creating booking:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "Failed to create booking");
  }
});
/**
 * Verify payment and update booking status
 */
export const verifyPayment = onCall(async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {reference} = request.data;
    if (!reference) {
      throw new HttpsError("invalid-argument", "Payment reference is required");
    }

    // Verify payment with Paystack
    const paystackResponse = await axios.get<PaystackVerifyResponse>(
      `${PAYSTACK_BASE_URL}/transaction/verify/${reference}`,
      {
        headers: {
          "Authorization": `Bearer ${PAYSTACK_SECRET_KEY}`,
        },
      }
    );

    if (!paystackResponse.data.status) {
      throw new HttpsError("internal", "Payment verification failed");
    }

    const paymentData = paystackResponse.data.data;
    const bookingId = paymentData.metadata?.bookingId as string;

    if (!bookingId) {
      throw new HttpsError(
        "not-found",
        "Booking not found in payment metadata"
      );
    }

    // Update booking status
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw new HttpsError("not-found", "Booking not found");
    }

    const updateData: any = {
      paymentStatus: paymentData.status === "success" ?
        PaymentStatus.SUCCESS : PaymentStatus.FAILED,
      updatedAt: new Date(),
    };

    if (paymentData.status === "success") {
      updateData.status = BookingStatus.CONFIRMED;
      updateData.paidAt = new Date(paymentData.paid_at);
    } else {
      updateData.status = BookingStatus.PAYMENT_FAILED;
    }

    await bookingRef.update(updateData);

    // Create notification for artisan if payment successful
    if (paymentData.status === "success") {
      const bookingData = bookingDoc.data();
      await db.collection("notifications").add({
        userId: bookingData?.artisanId,
        type: "booking_confirmed",
        title: "Booking Confirmed",
        message: `Payment received for ${bookingData?.serviceTitle}`,
        bookingId,
        isRead: false,
        createdAt: new Date(),
      });
    }

    return {
      success: true,
      paymentStatus: paymentData.status,
      bookingStatus: updateData.status,
    };
  } catch (error) {
    console.error("Error verifying payment:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "Failed to verify payment");
  }
});

/**
 * Update booking status (for artisan)
 */
export const updateBookingStatus = onCall(async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {bookingId, status, location, estimatedArrival} = request.data;

    if (!bookingId || !status) {
      throw new HttpsError("invalid-argument",
        "Booking ID and status are required");
    }

    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw new HttpsError("not-found", "Booking not found");
    }

    const bookingData = bookingDoc.data();

    // Verify artisan is updating their own booking
    if (bookingData?.artisanId !== request.auth.uid) {
      throw new HttpsError("permission-denied",
        "Only the assigned artisan can update this booking");
    }

    const updateData: any = {
      status,
      updatedAt: new Date(),
    };

    if (location) {
      updateData.artisanCurrentLocation = location;
    }

    if (estimatedArrival) {
      updateData.estimatedArrival = estimatedArrival;
    }

    await bookingRef.update(updateData);

    // Create notification for client
    const statusMessages: Record<string, string> = {
      [BookingStatus.IN_PROGRESS]: "Your artisan is on the way!",
      [BookingStatus.COMPLETED]: "Your service has been completed",
      [BookingStatus.CANCELLED]: "Your booking has been cancelled",
    };

    if (statusMessages[status as BookingStatus]) {
      await db.collection("notifications").add({
        userId: bookingData?.clientId,
        type: "booking_update",
        title: "Booking Update",
        message: statusMessages[status as BookingStatus],
        bookingId,
        isRead: false,
        createdAt: new Date(),
      });
    }

    return {success: true};
  } catch (error) {
    console.error("Error updating booking status:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "Failed to update booking status");
  }
});

/**
 * Get booking details
 */
export const getBookingDetails = onCall(async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {bookingId} = request.data;
    if (!bookingId) {
      throw new HttpsError("invalid-argument", "Booking ID is required");
    }

    const bookingDoc = await db.collection("bookings").doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw new HttpsError("not-found", "Booking not found");
    }

    const bookingData = bookingDoc.data();

    // Verify user has access to this booking
    if (bookingData?.clientId !== request.auth.uid &&
        bookingData?.artisanId !== request.auth.uid) {
      throw new HttpsError("permission-denied", "Access denied");
    }

    return {
      success: true,
      booking: {
        id: bookingDoc.id,
        ...bookingData,
      },
    };
  } catch (error) {
    console.error("Error getting booking details:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "Failed to get booking details");
  }
});

/**
 * Update artisan location
 */
export const updateArtisanLocation = onCall(async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {bookingId, location} = request.data;
    if (!bookingId || !location) {
      throw new HttpsError("invalid-argument",
        "Booking ID and location are required");
    }

    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw new HttpsError("not-found", "Booking not found");
    }

    const bookingData = bookingDoc.data();

    // Verify artisan is updating their own booking
    if (bookingData?.artisanId !== request.auth.uid) {
      throw new HttpsError("permission-denied",
        "Only the assigned artisan can update location");
    }

    await bookingRef.update({
      artisanCurrentLocation: location,
      updatedAt: new Date(),
    });

    return {success: true};
  } catch (error) {
    console.error("Error updating artisan location:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "Failed to update artisan location");
  }
});

/**
 * Get user bookings
 */
export const getUserBookings = onCall(async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {userType, status, limit = 50} = request.data;
    if (!userType) {
      throw new HttpsError("invalid-argument", "User type is required");
    }

    const userId = request.auth.uid;
    const field = userType === "client" ? "clientId" : "artisanId";

    let query = db.collection("bookings")
      .where(field, "==", userId)
      .orderBy("createdAt", "desc")
      .limit(limit);

    if (status) {
      query = query.where("status", "==", status);
    }

    const snapshot = await query.get();
    const bookings = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return {
      success: true,
      bookings,
    };
  } catch (error) {
    console.error("Error getting user bookings:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "Failed to get user bookings");
  }
});
