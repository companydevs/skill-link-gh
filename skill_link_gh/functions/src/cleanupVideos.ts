import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {CallableRequest} from "firebase-functions/v2/https";

/**
 * Delete 4K videos from Firestore and Storage
 * Call this function manually to clean up problematic videos
 */
export const cleanup4KVideos = functions.https.onCall(async (request: CallableRequest) => {
  // Require authentication
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be authenticated to run cleanup"
    );
  }

  const db = admin.firestore();
  const storage = admin.storage();

  try {
    console.log("🔍 Starting 4K video cleanup...");

    // Get all reels
    const reelsSnapshot = await db.collection("reels").get();

    const deletedReels: string[] = [];
    const deletedVideos: string[] = [];
    const errors: string[] = [];

    for (const doc of reelsSnapshot.docs) {
      const reelData = doc.data();
      const videoUrl = reelData.videoUrl;

      if (!videoUrl) {
        console.log(`⚠️ Reel ${doc.id} has no video URL, skipping`);
        continue;
      }

      try {
        // Extract file path from Firebase Storage URL
        const urlMatch = videoUrl.match(/\/o\/(.+?)\?/);
        if (!urlMatch) {
          console.log(`⚠️ Could not parse URL for reel ${doc.id}`);
          continue;
        }

        const filePath = decodeURIComponent(urlMatch[1]);

        // Get video metadata from Storage
        const file = storage.bucket().file(filePath);
        const [metadata] = await file.getMetadata();

        // Check if it's a large video (likely 4K)
        // 4K videos are typically > 10MB even for short clips
        const sizeInMB = Number(metadata.size || 0) / (1024 * 1024);

        if (sizeInMB > 10) {
          console.log(`🗑️ Deleting large video (${sizeInMB.toFixed(2)}MB): ${doc.id}`);

          // Delete from Storage
          await file.delete();
          deletedVideos.push(filePath);

          // Delete from Firestore
          await doc.ref.delete();
          deletedReels.push(doc.id);

          console.log(`✅ Deleted reel ${doc.id}`);
        } else {
          console.log(`✓ Keeping reel ${doc.id} (${sizeInMB.toFixed(2)}MB)`);
        }
      } catch (error: any) {
        console.error(`❌ Error processing reel ${doc.id}:`, error);
        errors.push(`${doc.id}: ${error.message}`);
      }
    }

    console.log("✅ Cleanup complete!");

    return {
      success: true,
      deletedReels: deletedReels.length,
      deletedVideos: deletedVideos.length,
      errors: errors.length,
      details: {
        reels: deletedReels,
        videos: deletedVideos,
        errors: errors,
      },
    };
  } catch (error: any) {
    console.error("❌ Cleanup failed:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * List all videos with their sizes (for inspection)
 */
export const listVideoSizes = functions.https.onCall(async (request: CallableRequest) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be authenticated"
    );
  }

  const db = admin.firestore();
  const storage = admin.storage();

  try {
    const reelsSnapshot = await db.collection("reels").get();
    const videoInfo: any[] = [];

    for (const doc of reelsSnapshot.docs) {
      const reelData = doc.data();
      const videoUrl = reelData.videoUrl;

      if (!videoUrl) continue;

      try {
        const urlMatch = videoUrl.match(/\/o\/(.+?)\?/);
        if (!urlMatch) continue;

        const filePath = decodeURIComponent(urlMatch[1]);
        const file = storage.bucket().file(filePath);
        const [metadata] = await file.getMetadata();

        const sizeInMB = Number(metadata.size || 0) / (1024 * 1024);

        videoInfo.push({
          reelId: doc.id,
          artisanName: reelData.artisanName,
          sizeMB: parseFloat(sizeInMB.toFixed(2)),
          filePath: filePath,
          is4K: sizeInMB > 10,
        });
      } catch (error) {
        console.error(`Error getting metadata for ${doc.id}:`, error);
      }
    }

    // Sort by size descending
    videoInfo.sort((a, b) => b.sizeMB - a.sizeMB);

    return {
      success: true,
      totalVideos: videoInfo.length,
      videos: videoInfo,
      total4K: videoInfo.filter((v) => v.is4K).length,
    };
  } catch (error: any) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});
