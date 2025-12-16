import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch posts with optional pagination
  Future<List<PostModel>> fetchPosts({DocumentSnapshot? startAfter, int limit = 10}) async {
    Query query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  /// Toggle like count on a post
  Future<void> toggleLike(String postId, bool isLiked) async {
    final docRef = _firestore.collection('posts').doc(postId);
    await docRef.update({'likes': FieldValue.increment(isLiked ? -1 : 1)});
  }

  /// Toggle save/unsave for the current user
  Future<void> toggleSave(String postId, bool isSaved) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final saveRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedPosts')
        .doc(postId);

    if (isSaved) {
      // If currently saved, remove
      await saveRef.delete();
    } else {
      // Otherwise, add with timestamp
      await saveRef.set({
        'postId': postId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Optional: Fetch saved posts for current user
  Future<List<String>> fetchSavedPostIds() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedPosts')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
