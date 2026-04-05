/* eslint-disable linebreak-style */
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

type CreatePostPayload = {
  serviceCategory: string;
  description: string;
  pricing: string;
  images: { url: string; label?: string }[];
};

export const createPost = onCall(async (request) => {
  const auth = request.auth;

  // 🔐 Auth check
  if (!auth) {
    throw new HttpsError("unauthenticated",
      "You must be logged in to create a post");
  }

  const uid = auth.uid;
  const data = request.data as CreatePostPayload;

  // 🧪 Validation
  if (!data.serviceCategory?.trim() ||
      !data.description?.trim() ||
      !data.pricing?.trim()) {
    throw new HttpsError("invalid-argument", "Missing required post fields");
  }

  if (!Array.isArray(data.images)) {
    throw new HttpsError("invalid-argument", "Images must be an array");
  }

  if (data.images.length === 0) {
    throw new HttpsError("invalid-argument", "At least one image is required");
  }

  if (data.images.length > 5) {
    throw new HttpsError("invalid-argument", "Maximum of 5 images allowed");
  }

  // 🔎 Fetch user profile
  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists) {
    throw new HttpsError("not-found", "User profile not found");
  }

  const user = userSnap.data();
  if (!user) {
    throw new HttpsError("not-found", "User data is undefined");
  }

  // ✅ Check artisan role (supports 'userType' or 'role' field)
  const role = (user.userType ?? user.role ?? "").toLowerCase();
  if (role !== "artisan") {
    throw new HttpsError("permission-denied", "Only artisans can create posts");
  }

  // 🧱 Build post document
  const postData = {
    artisanId: uid,
    artisanName: user.fullName ?? "",
    artisanImage: user.profileImage ?? null,

    serviceCategory: data.serviceCategory,
    description: data.description,
    pricing: data.pricing,

    postImages: data.images.map((img) => ({
      url: img.url,
      label: img.label ?? "",
    })),

    likes: 0,
    comments: 0,

    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // 💾 Save post
  const postRef = await db.collection("posts").add(postData);

  return {
    success: true,
    postId: postRef.id,
  };
});
