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
    const isOtpVerified = userData?.isVerified ?? false;

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
