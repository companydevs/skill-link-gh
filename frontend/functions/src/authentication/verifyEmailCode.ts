/* eslint-disable linebreak-style */
import {onCall, HttpsError} from "firebase-functions/v2/https";
import admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

export const verifyEmailCode = onCall(
  {region: "us-central1"},
  async (request) => {
    const {email, code} = request.data;

    if (!email || !code) {
      throw new HttpsError("invalid-argument", "Email and code are required");
    }

    // 1️⃣ Fetch OTP
    const snapshot = await firestore
      .collection("email_verifications")
      .where("email", "==", email)
      .where("used", "==", false)
      .orderBy("createdAt", "desc")
      .limit(1)
      .get();

    if (snapshot.empty) {
      throw new HttpsError("not-found", "No verification code found");
    }

    const doc = snapshot.docs[0];
    const data = doc.data();

    // 2️⃣ Expiry
    if (admin.firestore.Timestamp.now().
      toMillis() > data.expiresAt.toMillis()) {
      throw new HttpsError("deadline-exceeded", "Verification code expired");
    }

    // 3️⃣ Code match
    if (data.code !== code) {
      throw new HttpsError("permission-denied", "Incorrect verification code");
    }

    // 4️⃣ Mark OTP used
    await doc.ref.update({used: true, status: "verified"});

    // 5️⃣ Auth user lookup (safe)
    let uid: string;
    try {
      const user = await admin.auth().getUserByEmail(email);
      uid = user.uid;

      if (!user.emailVerified) {
        await admin.auth().updateUser(uid, {emailVerified: true});
      }
    } catch {
      throw new HttpsError("not-found", "User not found in authentication");
    }

    // 6️⃣ Update Firestore user
    await firestore.collection("users").doc(uid).update({
      isVerified: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {success: true};
  }
);
