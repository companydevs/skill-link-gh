/**
 * Firestore trigger: when a user's fullName or profileImage changes,
 * fan-out the update to all their posts, reels, and comments.
 *
 * This keeps denormalized author data fresh without any client-side work.
 */

import * as admin from "firebase-admin";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

export const syncUserProfile = onDocumentUpdated(
  "users/{uid}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!before || !after) return;

    const uid = event.params.uid;

    const nameChanged = before.fullName !== after.fullName;
    const imageChanged = before.profileImage !== after.profileImage;

    // Nothing relevant changed — bail early
    if (!nameChanged && !imageChanged) return;

    const newName: string = after.fullName ?? before.fullName ?? "";
    const newImage: string = after.profileImage ?? before.profileImage ?? "";

    const batch = db.batch();
    let opCount = 0;

    // Helper: flush batch every 490 writes (Firestore limit is 500)
    const maybeCommit = async () => {
      if (opCount >= 490) {
        await batch.commit();
        opCount = 0;
      }
    };

    // ── Posts ────────────────────────────────────────────────────────────
    const postsSnap = await db
      .collection("posts")
      .where("artisanId", "==", uid)
      .get();

    for (const doc of postsSnap.docs) {
      const update: Record<string, string> = {};
      if (nameChanged) update.artisanName = newName;
      if (imageChanged) update.artisanImage = newImage;
      batch.update(doc.ref, update);
      opCount++;
      await maybeCommit();
    }

    // ── Reels ────────────────────────────────────────────────────────────
    const reelsSnap = await db
      .collection("reels")
      .where("artisanId", "==", uid)
      .get();

    for (const doc of reelsSnap.docs) {
      const update: Record<string, string> = {};
      if (nameChanged) update.artisanName = newName;
      if (imageChanged) update.artisanAvatar = newImage;
      batch.update(doc.ref, update);
      opCount++;
      await maybeCommit();
    }

    // ── Comments on reels ────────────────────────────────────────────────
    // Comments are stored as a subcollection under each reel
    const allReelsSnap = await db.collection("reels").get();
    for (const reelDoc of allReelsSnap.docs) {
      const commentsSnap = await reelDoc.ref
        .collection("comments")
        .where("userId", "==", uid)
        .get();

      for (const doc of commentsSnap.docs) {
        const update: Record<string, string> = {};
        if (nameChanged) update.userName = newName;
        if (imageChanged) update.userAvatar = newImage;
        batch.update(doc.ref, update);
        opCount++;
        await maybeCommit();
      }
    }

    // ── Comments on posts (if stored as subcollection) ───────────────────
    const allPostsSnap = await db.collection("posts").get();
    for (const postDoc of allPostsSnap.docs) {
      const commentsSnap = await postDoc.ref
        .collection("comments")
        .where("userId", "==", uid)
        .get();

      for (const doc of commentsSnap.docs) {
        const update: Record<string, string> = {};
        if (nameChanged) update.userName = newName;
        if (imageChanged) update.userAvatar = newImage;
        batch.update(doc.ref, update);
        opCount++;
        await maybeCommit();
      }
    }

    // ── Top-level comments collection (if used) ──────────────────────────
    const topLevelCommentsSnap = await db
      .collection("comments")
      .where("userId", "==", uid)
      .get();

    for (const doc of topLevelCommentsSnap.docs) {
      const update: Record<string, string> = {};
      if (nameChanged) update.userName = newName;
      if (imageChanged) update.userAvatar = newImage;
      batch.update(doc.ref, update);
      opCount++;
      await maybeCommit();
    }

    // Final commit
    if (opCount > 0) {
      await batch.commit();
    }

    console.log(
      `✅ syncUserProfile: uid=${uid} | posts=${postsSnap.size} | reels=${reelsSnap.size} | nameChanged=${nameChanged} | imageChanged=${imageChanged}`
    );
  }
);
