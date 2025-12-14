// functions/src/index.ts
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const registerUser = onCall(async (request) => {
  const {
    fullName,
    email,
    password,
    isArtisan,
    businessName,
    description,
    category,
  } = request.data as {
    fullName: string;
    email: string;
    password: string;
    isArtisan: boolean;
    businessName?: string;
    description?: string;
    category?: string;
  };

  // 🔐 Validation
  if (!fullName || !email || !password) {
    throw new HttpsError("invalid-argument", "Missing required fields");
  }

  if (password.length < 8) {
    throw new HttpsError(
      "invalid-argument",
      "Password must be at least 8 characters"
    );
  }

  try {
    // Check if user already exists
    let existingUser;
    try {
      existingUser = await admin.auth().getUserByEmail(email);
    } catch (err) {
      // user not found is fine
    }
    if (existingUser) {
      throw new HttpsError("already-exists", "Email is already registered");
    }

    // 🔐 Create Auth user
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: fullName,
    });

    // 📦 Firestore profile
    await admin
      .firestore()
      .collection("users")
      .doc(userRecord.uid)
      .set({
        uid: userRecord.uid,
        fullName,
        email,
        role: isArtisan ? "artisan" : "client",
        businessName: isArtisan ? businessName ?? null : null,
        description: isArtisan ? description ?? null : null,
        category: isArtisan ? category ?? null : null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return {
      success: true,
      uid: userRecord.uid,
    };
  } catch (error: unknown) {
    console.error("Register user error:", error);

    let message = "Registration failed";
    if (error instanceof Error) message = error.message;

    if (error instanceof HttpsError) throw error;

    throw new HttpsError("internal", message);
  }
});
