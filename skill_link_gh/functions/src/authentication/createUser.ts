import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const registerUser = onCall(async (request) => {
  const {
    fullName,
    email,
    phone,
    password,
    isArtisan,
    businessName,
    description,
    category,
    provider = "password",
  } = request.data as {
    fullName: string;
    email: string;
    phone: string;
    password: string;
    isArtisan: boolean;
    businessName?: string;
    description?: string;
    category?: string;
    provider?: "password" | "google";
  };

  // Validation
  if (!fullName || !email || (!password && provider === "password")) {
    throw new HttpsError("invalid-argument", "Missing required fields");
  }

  if (provider === "password" && password.length < 8) {
    throw new HttpsError(
      "invalid-argument",
      "Password must be at least 8 characters"
    );
  }

  try {
    // Check if user already exists
    try {
      await admin.auth().getUserByEmail(email);
      throw new HttpsError("already-exists", "Email is already registered");
    } catch (_) {/* empty */}

    // Create Auth user if password signup
    let userRecord;
    if (provider === "password") {
      userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: fullName,
        emailVerified: false, // explicitly false
      });
    }

    const role = isArtisan ? "artisan" : "client";

    // Firestore profile
    await admin.firestore()
      .collection("users")
      .doc(userRecord?.uid ?? email)
      .set({
        uid: userRecord?.uid ?? email,
        fullName,
        email,
        phone,
        role,
        provider,
        businessName: role === "artisan" ? businessName ?? null : null,
        description: role === "artisan" ? description ?? null : null,
        category: role === "artisan" ? category ?? null : null,
        isVerified: provider === "google" ? true :
          userRecord?.emailVerified ?? false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });


    return {
      success: true,
      uid: userRecord?.uid ?? email,
      isVerified: provider === "google" ? true :
        userRecord?.emailVerified ?? false,
    };
  } catch (error: unknown) {
    console.error("Register user error:", error);

    if (error instanceof HttpsError) throw error;

    throw new HttpsError(
      "internal",
      error instanceof Error ? error.message : "Registration failed"
    );
  }
});
