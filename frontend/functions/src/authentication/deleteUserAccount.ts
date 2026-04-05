/* eslint-disable linebreak-style */
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const deleteUserAccount = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError("unauthenticated",
      "You must be logged in to delete your account");
  }

  try {
    const userDocRef = admin.firestore().collection("users").doc(uid);
    const userSnap = await userDocRef.get();

    // Clean up related data if user document exists
    if (userSnap.exists) {
      const userData = userSnap.data();
      const email = userData?.email;

      // Delete email verification records (if any)
      if (email) {
        const verifQuery = await admin
          .firestore()
          .collection("email_verifications")
          .where("email", "==", email)
          .get();

        if (!verifQuery.empty) {
          const batch = admin.firestore().batch();
          verifQuery.docs.forEach((doc) => batch.delete(doc.ref));
          await batch.commit();
        }
      }

      // Delete user profile document
      await userDocRef.delete();
    }

    // Finally, delete the Firebase Auth user
    await admin.auth().deleteUser(uid);

    return {success: true, message: "Account deleted successfully"};
  } catch (error) {
    console.error("Delete account error:", error);
    throw new HttpsError("internal", "Failed to delete account");
  }
});
