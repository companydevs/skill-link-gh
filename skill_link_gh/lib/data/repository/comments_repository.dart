import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_link_gh/domain/models/comment_model.dart';

class CommentsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch comments for a specific reel
  Future<List<Comment>> fetchComments(String reelId) async {
    try {
      print("🔍 Fetching comments for reel: $reelId");

      final snapshot = await _firestore
          .collection('reels')
          .doc(reelId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .get();

      print("📊 Found ${snapshot.docs.length} comments");

      final currentUserId = _auth.currentUser?.uid;
      final comments = <Comment>[];

      for (var doc in snapshot.docs) {
        // Check if current user has liked this comment
        bool isLiked = false;
        if (currentUserId != null) {
          final likeDoc = await doc.reference
              .collection('likes')
              .doc(currentUserId)
              .get();
          isLiked = likeDoc.exists;
        }

        final comment = Comment.fromFirestore(doc).copyWith(isLiked: isLiked);
        comments.add(comment);
      }

      return comments;
    } catch (e) {
      print('❌ Error fetching comments: $e');
      rethrow;
    }
  }

  /// Add a new comment to a reel
  Future<void> addComment(String reelId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    try {
      print("💬 Adding comment to reel: $reelId");

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final comment = Comment(
        id: '', // Will be set by Firestore
        reelId: reelId,
        userId: user.uid,
        userName:
            userData['fullName'] ?? userData['displayName'] ?? 'Anonymous',
        userAvatar: userData['profileImage'] ?? '',
        text: text,
        timestamp: DateTime.now(),
      );

      // Add comment to Firestore
      await _firestore
          .collection('reels')
          .doc(reelId)
          .collection('comments')
          .add(comment.toFirestore());

      // Update comment count on reel
      await _firestore.collection('reels').doc(reelId).update({
        'comments': FieldValue.increment(1),
      });

      print("✅ Comment added successfully");
    } catch (e) {
      print('❌ Error adding comment: $e');
      rethrow;
    }
  }

  /// Toggle like on a comment
  Future<void> toggleCommentLike(
    String reelId,
    String commentId,
    bool currentIsLiked,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final commentRef = _firestore
        .collection('reels')
        .doc(reelId)
        .collection('comments')
        .doc(commentId);
    final likeRef = commentRef.collection('likes').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final likeSnap = await transaction.get(likeRef);

      if (likeSnap.exists) {
        // Unlike
        transaction.delete(likeRef);
        transaction.update(commentRef, {'likes': FieldValue.increment(-1)});
      } else {
        // Like
        transaction.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
        transaction.update(commentRef, {'likes': FieldValue.increment(1)});
      }
    });
  }

  /// Delete a comment (only by the author)
  Future<void> deleteComment(
    String reelId,
    String commentId,
    String authorId,
  ) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId != authorId) {
      throw Exception("Not authorized to delete this comment");
    }

    try {
      await _firestore
          .collection('reels')
          .doc(reelId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Update comment count on reel
      await _firestore.collection('reels').doc(reelId).update({
        'comments': FieldValue.increment(-1),
      });

      print("🗑️ Comment deleted successfully");
    } catch (e) {
      print('❌ Error deleting comment: $e');
      rethrow;
    }
  }
}
