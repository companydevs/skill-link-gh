/* eslint-disable linebreak-style */
/* eslint-disable func-call-spacing */
/* eslint-disable linebreak-style */
import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

interface CreateReelRequest {
  videoUrl: string;
  description: string;
  artisanName?: string;
  artisanAvatar?: string;
  artisanCategory?: string;
  artisanSemanticLabel?: string;
}

// ✅ Fix: explicitly wrap async function to satisfy TypeScript
export const createReel = onCall<CreateReelRequest>
(async (request: CallableRequest<CreateReelRequest>) => {
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError("unauthenticated",
      "You must be logged in to create a reel");
  }

  const uid = auth.uid;
  const data = request.data;

  if (!data.videoUrl?.trim() || !data.description?.trim()) {
    throw new HttpsError("invalid-argument",
      "Missing required fields: videoUrl or description");
  }

  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists) {
    throw new HttpsError("not-found", "User profile not found");
  }

  const user = userSnap.data();
  if (!user) {
    throw new HttpsError("not-found", "User data is undefined");
  }

  const role = (user.userType || user.role || "").toLowerCase();
  if (role !== "artisan") {
    throw new HttpsError("permission-denied", "Only artisans can create reels");
  }

  const reelData = {
    artisanId: uid,
    artisanName: data.artisanName || user.fullName || "",
    artisanAvatar: data.artisanAvatar || user.profileImage || null,
    artisanCategory: data.artisanCategory || user.category || "",
    artisanSemanticLabel: data.artisanSemanticLabel || "",
    videoUrl: data.videoUrl,
    description: data.description,
    likes: 0,
    comments: 0,
    shares: 0,
    isLiked: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const reelRef = await db.collection("reels").add(reelData);

  // Return directly (no Promise type issues)
  return {
    success: true,
    reelId: reelRef.id,
  };
});
