/* eslint-disable linebreak-style */
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const resetPassword = onCall(
  {region: "us-central1"},
  async (request) => {
    const {email} = request.data as { email?: string };

    if (!email) {
      throw new HttpsError("invalid-argument", "Email is required");
    }

    // Validate email format
    const emailRegex = /^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$/;
    if (!emailRegex.test(email)) {
      throw new HttpsError("invalid-argument", "Invalid email address");
    }

    try {
      // Generate password reset link using Firebase's default flow
      const resetLink = await admin.auth().generatePasswordResetLink(email);

      // Optional: store reset request in Firestore for tracking
      await admin.firestore().collection("password_resets").add({
        email,
        link: resetLink,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {success: true, message: "Password reset email sent"};
    } catch (error: unknown) {
      console.error("Password reset error:", error);

      if (
        error instanceof Error &&
        error.message.includes("auth/user-not-found")
      ) {
        throw new HttpsError("not-found", "No user found with this email");
      }

      throw new HttpsError(
        "internal",
        error instanceof Error ? error.message : "Password reset failed"
      );
    }
  }
);
