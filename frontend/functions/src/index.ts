// ============================================================================
// EXISTING FUNCTIONS - DO NOT REMOVE
// ============================================================================

// Authentication functions
export {registerUser} from "./authentication/createUser";
export {signInUser} from "./authentication/signInUser";
export {verifyEmailCode} from "./authentication/verifyEmailCode";
export {resendVerificationCode} from "./authentication/email_verification";
export {resetPassword} from "./authentication/resetPassword";
export {checkUserStatus} from "./authentication/checkUserStatus";
export {deleteUserAccount} from "./authentication/deleteUserAccount";

// Booking functions
export {
  createBooking,
  getBookingDetails,
  getUserBookings,
  updateBookingStatus,
  verifyPayment,
  updateArtisanLocation,
} from "./booking";

// Post functions
export {createPost} from "./posts/createPost";
export {deleteComment} from "./posts/deleteComment";

// Reel functions
export {createReel} from "./reels/createReel";

// Wallet functions
export {
  initiateWalletTopUp,
  verifyWalletTopUp,
  payWithWallet,
} from "./wallet";

// Utility functions
export {getDistanceMatrix} from "./distanceMatrix";
export {syncUserProfile} from "./syncUserProfile";
export {cleanup4KVideos, listVideoSizes} from "./cleanupVideos";

// ============================================================================
// NEW NOTIFICATION FUNCTIONS
// ============================================================================

import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

// Initialize admin only if not already initialized
// (booking.ts and other files may have already initialized it)
try {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
} catch (e) {
  // Already initialized, ignore
}

/**
 * Send notification when a new message is sent
 */
export const onNewMessage = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    const conversationId = event.params.conversationId;

    if (!message) {
      console.log("❌ No message data");
      return;
    }

    console.log("📬 New message in conversation:", conversationId);

    try {
      // Get conversation to find recipient
      const conversationDoc = await admin
        .firestore()
        .collection("conversations")
        .doc(conversationId)
        .get();

      if (!conversationDoc.exists) {
        console.log("❌ Conversation not found");
        return;
      }

      const conversation = conversationDoc.data()!;
      const participants = conversation.participants as string[];
      const senderId = message.senderId;

      // Find recipient (the other participant)
      const recipientId = participants.find((id) => id !== senderId);
      if (!recipientId) {
        console.log("❌ Recipient not found");
        return;
      }

      // Get recipient's FCM token
      const recipientDoc = await admin
        .firestore()
        .collection("users")
        .doc(recipientId)
        .get();

      if (!recipientDoc.exists) {
        console.log("❌ Recipient user not found");
        return;
      }

      const recipient = recipientDoc.data()!;
      const fcmToken = recipient.fcmToken;

      if (!fcmToken) {
        console.log("⚠️ Recipient has no FCM token");
        return;
      }

      // Get sender's name
      const senderDoc = await admin
        .firestore()
        .collection("users")
        .doc(senderId)
        .get();

      const senderName = senderDoc.exists ?
        (senderDoc.data()!.fullName || senderDoc.data()!.displayName || "Someone") :
        "Someone";

      // Prepare notification
      const messageContent = message.type === "text" ?
        message.content :
        `[${message.type}]`;

      // Save notification to Firestore
      await admin.firestore().collection("notifications").add({
        userId: recipientId,
        title: senderName,
        message: messageContent,
        type: "chat",
        data: {
          conversationId: conversationId,
          senderId: senderId,
          senderName: senderName,
          otherUserId: senderId,
          otherUserName: senderName,
          otherUserAvatar: senderDoc.data()?.profileImage || "",
        },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("✅ Notification saved to Firestore");

      const payload: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: senderName,
          body: messageContent,
        },
        data: {
          type: "chat",
          conversationId: conversationId,
          senderId: senderId,
          senderName: senderName,
          otherUserId: senderId,
          otherUserName: senderName,
          otherUserAvatar: senderDoc.data()?.profileImage || "",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "chat_messages",
            priority: "high",
            sound: "default",
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      // Send notification
      await admin.messaging().send(payload);
      console.log("✅ Chat notification sent to:", recipientId);

      return;
    } catch (error) {
      console.error("❌ Error sending chat notification:", error);
      return;
    }
  }
);

/**
 * Send notification when payment is made
 */
export const onPaymentMade = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) {
      console.log("❌ No booking data");
      return;
    }

    // Check if payment status changed to paid
    if (before.paymentStatus !== "paid" && after.paymentStatus === "paid") {
      console.log("💰 Payment made for booking:", bookingId);

      try {
        const artisanId = after.artisanId;
        const customerId = after.customerId;
        const amount = after.totalAmount || after.price || 0;

        // Send notification to artisan
        await sendNotificationToUser(
          artisanId,
          "Payment Received! 💰",
          `You received GH₵ ${amount} from ${after.customerName || "a client"}`,
          {
            type: "payment",
            bookingId: bookingId,
            amount: amount.toString(),
            customerId: customerId,
          },
          "payments"
        );

        // Send notification to client
        await sendNotificationToUser(
          customerId,
          "Payment Successful ✅",
          `Your payment of GH₵ ${amount} to ${after.artisanName || "artisan"} was successful`,
          {
            type: "payment",
            bookingId: bookingId,
            amount: amount.toString(),
            artisanId: artisanId,
          },
          "payments"
        );

        console.log("✅ Payment notifications sent");
        return;
      } catch (error) {
        console.error("❌ Error sending payment notification:", error);
        return;
      }
    }

    return;
  }
);

/**
 * Send notification when new booking is created
 */
export const onNewBooking = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const booking = event.data?.data();
    const bookingId = event.params.bookingId;

    if (!booking) {
      console.log("❌ No booking data");
      return;
    }

    console.log("📅 New booking created:", bookingId);

    try {
      const artisanId = booking.artisanId;
      const customerName = booking.customerName || "A client";
      const service = booking.serviceName || booking.service || "a service";

      // Send notification to artisan
      await sendNotificationToUser(
        artisanId,
        "New Booking Request! 🔔",
        `${customerName} wants to book ${service}`,
        {
          type: "booking",
          bookingId: bookingId,
          customerId: booking.customerId,
          action: "new",
        },
        "bookings"
      );

      console.log("✅ New booking notification sent to artisan");
      return;
    } catch (error) {
      console.error("❌ Error sending booking notification:", error);
      return;
    }
  }
);

/**
 * Send notification when booking status changes
 */
export const onBookingStatusChange = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) {
      console.log("❌ No booking data");
      return;
    }

    // Check if status changed
    if (before.status !== after.status) {
      console.log(`📊 Booking status changed: ${before.status} → ${after.status}`);

      try {
        const customerId = after.customerId;
        const artisanName = after.artisanName || "Artisan";
        const status = after.status;

        let title = "";
        let body = "";

        switch (status) {
        case "accepted":
          title = "Booking Accepted ✅";
          body = `${artisanName} accepted your booking request`;
          break;
        case "rejected":
          title = "Booking Declined ❌";
          body = `${artisanName} declined your booking request`;
          break;
        case "in_progress":
          title = "Service Started 🚀";
          body = `${artisanName} has started working on your service`;
          break;
        case "completed":
          title = "Service Completed ✅";
          body = `${artisanName} completed your service. Please leave a review!`;
          break;
        case "cancelled":
          title = "Booking Cancelled ❌";
          body = `Your booking with ${artisanName} was cancelled`;
          break;
        default:
          return;
        }

        // Send notification to customer
        await sendNotificationToUser(
          customerId,
          title,
          body,
          {
            type: "booking",
            bookingId: bookingId,
            artisanId: after.artisanId,
            status: status,
          },
          "bookings"
        );

        console.log("✅ Booking status notification sent");
        return;
      } catch (error) {
        console.error("❌ Error sending status notification:", error);
        return;
      }
    }

    return;
  }
);

/**
 * Send notification when escrow is released
 */
export const onEscrowRelease = onDocumentUpdated(
  "escrow/{escrowId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const escrowId = event.params.escrowId;

    if (!before || !after) {
      console.log("❌ No escrow data");
      return;
    }

    // Check if escrow was released
    if (before.status !== "released" && after.status === "released") {
      console.log("💸 Escrow released:", escrowId);

      try {
        const artisanId = after.artisanId;
        const amount = after.amount || 0;

        // Send notification to artisan
        await sendNotificationToUser(
          artisanId,
          "Funds Released! 💸",
          `GH₵ ${amount} has been released to your account`,
          {
            type: "payment",
            escrowId: escrowId,
            amount: amount.toString(),
          },
          "payments"
        );

        console.log("✅ Escrow release notification sent");
        return;
      } catch (error) {
        console.error("❌ Error sending escrow notification:", error);
        return;
      }
    }

    return;
  }
);

/**
 * Trigger when admin approves or rejects a verification request.
 * Sends push notification to artisan immediately.
 */
export const onVerificationDecision = onDocumentUpdated(
  "verifications/{userId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const userId = event.params.userId;

    if (!before || !after) return;

    // Only fire when status changes
    if (before.status === after.status) return;

    const newStatus = after.status as string;
    if (newStatus !== "approved" && newStatus !== "rejected") return;

    console.log(`🔐 Verification ${newStatus} for user: ${userId}`);

    const isApproved = newStatus === "approved";
    const adminNote = after.adminNote as string || "";

    const title = isApproved
      ? "🎉 You're Verified!"
      : "Verification Update";

    const body = isApproved
      ? "Congratulations! Your identity has been verified. You now have a verified badge on your profile."
      : `Your verification was not approved. ${adminNote ? "Reason: " + adminNote : "Please resubmit with clearer documents."}`;

    try {
      await sendNotificationToUser(
        userId,
        title,
        body,
        {
          type: "verification",
          status: newStatus,
          adminNote: adminNote,
        },
        "general"
      );
      console.log(`✅ Verification notification sent to: ${userId}`);
    } catch (error) {
      console.error("❌ Error sending verification notification:", error);
    }
  }
);

/**
 * Send notification when review is received
 */
export const onNewReview = onDocumentCreated(
  "reviews/{reviewId}",
  async (event) => {
    const review = event.data?.data();
    const reviewId = event.params.reviewId;

    if (!review) {
      console.log("❌ No review data");
      return;
    }

    console.log("⭐ New review created:", reviewId);

    try {
      const artisanId = review.artisanId;
      const customerName = review.customerName || "A client";
      const rating = review.rating || 0;

      // Send notification to artisan
      await sendNotificationToUser(
        artisanId,
        "New Review! ⭐",
        `${customerName} gave you ${rating} stars`,
        {
          type: "review",
          reviewId: reviewId,
          rating: rating.toString(),
        },
        "general"
      );

      console.log("✅ Review notification sent");
      return;
    } catch (error) {
      console.error("❌ Error sending review notification:", error);
      return;
    }
  }
);

/**
 * Helper function to send notification to a user
 */
async function sendNotificationToUser(
  userId: string,
  title: string,
  body: string,
  data: Record<string, string>,
  channelId: string = "general"
): Promise<void> {
  try {
    const db = admin.firestore();

    // Save notification to Firestore
    await db.collection("notifications").add({
      userId: userId,
      title: title,
      message: body,
      type: data.type || "general",
      data: data,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("✅ Notification saved to Firestore for:", userId);

    // Get user's FCM token
    const userDoc = await db.collection("users").doc(userId).get();

    if (!userDoc.exists) {
      console.log("❌ User not found:", userId);
      return;
    }

    const user = userDoc.data()!;
    const fcmToken = user.fcmToken;

    if (!fcmToken) {
      console.log("⚠️ User has no FCM token:", userId);
      return;
    }

    // Prepare notification payload
    const payload: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: data,
      android: {
        priority: "high",
        notification: {
          channelId: channelId,
          priority: channelId === "payments" ? "max" : "high",
          sound: "default",
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    // Send notification
    await admin.messaging().send(payload);
    console.log("✅ Push notification sent to:", userId);
  } catch (error) {
    console.error("❌ Error sending notification:", error);
    throw error;
  }
}

