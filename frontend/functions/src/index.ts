import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Send notification when a new message is sent
 */
export const onNewMessage = functions.firestore
  .document("conversations/{conversationId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const {conversationId} = context.params;

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
        return null;
      }

      const conversation = conversationDoc.data()!;
      const participants = conversation.participants as string[];
      const senderId = message.senderId;

      // Find recipient (the other participant)
      const recipientId = participants.find((id) => id !== senderId);
      if (!recipientId) {
        console.log("❌ Recipient not found");
        return null;
      }

      // Get recipient's FCM token
      const recipientDoc = await admin
        .firestore()
        .collection("users")
        .doc(recipientId)
        .get();

      if (!recipientDoc.exists) {
        console.log("❌ Recipient user not found");
        return null;
      }

      const recipient = recipientDoc.data()!;
      const fcmToken = recipient.fcmToken;

      if (!fcmToken) {
        console.log("⚠️ Recipient has no FCM token");
        return null;
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

      return null;
    } catch (error) {
      console.error("❌ Error sending chat notification:", error);
      return null;
    }
  });

/**
 * Send notification when payment is made
 */
export const onPaymentMade = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const {bookingId} = context.params;

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
        return null;
      } catch (error) {
        console.error("❌ Error sending payment notification:", error);
        return null;
      }
    }

    return null;
  });

/**
 * Send notification when new booking is created
 */
export const onNewBooking = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snapshot, context) => {
    const booking = snapshot.data();
    const {bookingId} = context.params;

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
      return null;
    } catch (error) {
      console.error("❌ Error sending booking notification:", error);
      return null;
    }
  });

/**
 * Send notification when booking status changes
 */
export const onBookingStatusChange = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const {bookingId} = context.params;

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
          return null;
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
        return null;
      } catch (error) {
        console.error("❌ Error sending status notification:", error);
        return null;
      }
    }

    return null;
  });

/**
 * Send notification when escrow is released
 */
export const onEscrowRelease = functions.firestore
  .document("escrow/{escrowId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const {escrowId} = context.params;

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
        return null;
      } catch (error) {
        console.error("❌ Error sending escrow notification:", error);
        return null;
      }
    }

    return null;
  });

/**
 * Send notification when review is received
 */
export const onNewReview = functions.firestore
  .document("reviews/{reviewId}")
  .onCreate(async (snapshot, context) => {
    const review = snapshot.data();
    const {reviewId} = context.params;

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
      return null;
    } catch (error) {
      console.error("❌ Error sending review notification:", error);
      return null;
    }
  });

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
    // Get user's FCM token
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();

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
    console.log("✅ Notification sent to:", userId);
  } catch (error) {
    console.error("❌ Error sending notification:", error);
    throw error;
  }
}

