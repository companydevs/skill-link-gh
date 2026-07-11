/* eslint-disable linebreak-style */
// functions/src/checkUserStatus.ts
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

export const checkUserStatus = onCall(async (request) => {
  const {uid} = request.data as { uid?: string };

  if (!uid) {
    throw new HttpsError("invalid-argument", "User ID is required");
  }

  try {
    const userRecord = await admin.auth().getUser(uid);

    // Check if email verified
    const emailVerified = userRecord.emailVerified;

    // Optional: check OTP status from Firestore
    const userDoc = await firestore.collection("users").doc(uid).get();
    const userData = userDoc.data();

    // isOtpVerified = true for Google/OAuth users (they skip OTP)
    // isOtpVerified = true for email users who completed OTP step
    const provider = userData?.provider ?? "password";
    const isGoogleUser = provider === "google" ||
      userRecord.providerData.some((p) => p.providerId === "google.com");
    const isOtpVerified = isGoogleUser
      ? true
      : (userData?.isOtpVerified ?? userData?.otpVerified ?? false);

    return {
      success: true,
      emailVerified,
      isOtpVerified,
    };
  } catch (error) {
    throw new HttpsError(
      "not-found",
      "User not found",
      error instanceof Error ? error.message : undefined
    );
  }
});
