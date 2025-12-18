/* eslint-disable linebreak-style */
/* eslint-disable require-jsdoc */
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

interface DeleteCommentData {
  postId: string;
  commentId: string;
}

export const deleteComment = onCall(async (request) => {
  const auth = request.auth; // ✅ v2 replaces context.auth
  const data = request.data as DeleteCommentData;

  if (!auth?.uid) {
    throw new HttpsError("unauthenticated", "User must be logged in");
  }

  const uid = auth.uid;
  const {postId, commentId} = data;

  if (!postId || !commentId) {
    throw new HttpsError("invalid-argument",
      "Post ID and Comment ID are required");
  }

  const commentsRef = db.collection("posts").doc(postId).collection("comments");

  async function deleteRecursively(id: string) {
    const children = await commentsRef.where("parentId", "==", id).get();
    for (const child of children.docs) {
      await deleteRecursively(child.id);
    }

    const docSnap = await commentsRef.doc(id).get();
    if (!docSnap.exists) return;

    const docData = docSnap.data();
    if (docData?.userId !== uid) {
      throw new HttpsError("permission-denied",
        "You can only delete your own comments");
    }

    await commentsRef.doc(id).delete();
  }

  try {
    await deleteRecursively(commentId);
    return {success: true, message: "Comment and replies deleted"};
  } catch (err: any) {
    throw new HttpsError("unknown", err.message || "Failed to delete comment");
  }
});
