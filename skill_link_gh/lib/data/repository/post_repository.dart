import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_link_gh/domain/models/post_model.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch posts with optional pagination
  Future<List<PostModel>> fetchPosts({
  DocumentSnapshot? startAfter,
  int limit = 10,
}) async {
  final user = _auth.currentUser;
  final uid = user?.uid;

  Query query = _firestore
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(limit);

  if (startAfter != null) query = query.startAfterDocument(startAfter);

  final snapshot = await query.get();

  return Future.wait(snapshot.docs.map((doc) async {
    bool isLiked = false;

    if (uid != null) {
      final likeDoc = await doc.reference
          .collection('likes')
          .doc(uid)
          .get();
      isLiked = likeDoc.exists;
    }

    final post = PostModel.fromFirestore(doc);
    return post.copyWith(isLiked: isLiked);
  }));
}


Future<void> toggleLike(String postId) async {
  final user = _auth.currentUser;
  if (user == null) return;

  final postRef = _firestore.collection('posts').doc(postId);
  final likeRef = postRef.collection('likes').doc(user.uid);

  await _firestore.runTransaction((tx) async {
    final likeSnap = await tx.get(likeRef);

    if (likeSnap.exists) {
      tx.delete(likeRef);
      tx.update(postRef, {
        'likes': FieldValue.increment(-1),
      });
    } else {
      tx.set(
        likeRef,
        {'likedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      tx.update(postRef, {
        'likes': FieldValue.increment(1),
      });
    }
  });
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


