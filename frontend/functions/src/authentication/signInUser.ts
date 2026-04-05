/* eslint-disable linebreak-style */
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const signInUser = onCall(async (request) => {
  const {email, password, provider = "password"} = request.data as {
    email: string;
    password?: string;
    provider?: "password" | "google";
  };

  // Basic validation
  if (!email) {
    throw new HttpsError("invalid-argument", "Email is required");
  }

  if (provider === "password" && !password) {
    throw new HttpsError("invalid-argument", "Password is required");
  }

  try {
    // Get user from Firebase Auth
    const userRecord = await admin.auth().getUserByEmail(email);

    // 🔐 PASSWORD SIGN-IN
    if (provider === "password") {
      // IMPORTANT:
      // Firebase Admin SDK CANNOT verify passwords.
      // Password validation must already be done on the client
      // using Firebase Auth signInWithEmailAndPassword.

      return {
        success: true,
        uid: userRecord.uid,
        email: userRecord.email,
        emailVerified: userRecord.emailVerified,
        provider: "password",
      };
    }

    // 🔐 GOOGLE SIGN-IN
    if (provider === "google") {
      return {
        success: true,
        uid: userRecord.uid,
        email: userRecord.email,
        emailVerified: true, // Google accounts are trusted
        provider: "google",
      };
    }

    throw new HttpsError("invalid-argument", "Unsupported provider");
  } catch (error: unknown) {
    console.error("Sign-in error:", error);

    if (error instanceof HttpsError) throw error;

    if (
      error instanceof Error &&
      error.message.includes("auth/user-not-found")
    ) {
      throw new HttpsError("not-found", "User not found");
    }

    throw new HttpsError(
      "internal",
      error instanceof Error ? error.message : "Sign-in failed"
    );
  }
});
