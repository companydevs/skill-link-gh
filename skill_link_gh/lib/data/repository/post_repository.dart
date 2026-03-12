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

    return Future.wait(
      snapshot.docs.map((doc) async {
        bool isLiked = false;
        List<LikedByUser> likedBy = [];

        if (uid != null) {
          final likeDoc = await doc.reference
              .collection('likes')
              .doc(uid)
              .get();
          isLiked = likeDoc.exists;
        }

        // Fetch recent likers (up to 3)
        final likesSnapshot = await doc.reference
            .collection('likes')
            .orderBy('likedAt', descending: true)
            .limit(3)
            .get();

        // Get user details from the likes documents (already stored there)
        for (var likeDoc in likesSnapshot.docs) {
          try {
            final likeData = likeDoc.data() as Map<String, dynamic>?;

            // Use stored data from like document if available
            if (likeData != null &&
                likeData['userName'] != null &&
                likeData['userName'].toString().isNotEmpty) {
              likedBy.add(
                LikedByUser(
                  userId: likeDoc.id,
                  userName: likeData['userName'] ?? '',
                  userImage: likeData['userImage'] ?? '',
                ),
              );
            } else {
              // Fallback: fetch from users collection if not stored in like doc
              final userDoc = await _firestore
                  .collection('users')
                  .doc(likeDoc.id)
                  .get();

              if (userDoc.exists) {
                final userData = userDoc.data() as Map<String, dynamic>;
                final userName = userData['name'] ?? userData['username'] ?? '';

                if (userName.isNotEmpty) {
                  likedBy.add(
                    LikedByUser(
                      userId: likeDoc.id,
                      userName: userName,
                      userImage:
                          userData['profileImage'] ??
                          userData['photoUrl'] ??
                          '',
                    ),
                  );
                }
              }
            }
          } catch (e) {
            // Skip if user not found
            continue;
          }
        }

        final post = PostModel.fromFirestore(doc);
        return post.copyWith(isLiked: isLiked, likedBy: likedBy);
      }),
    );
  }

  Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(user.uid);

    // Fetch current user data
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    // Get user name from various possible fields
    final userName =
        userData?['name'] ??
        userData?['username'] ??
        userData?['displayName'] ??
        user.displayName ??
        '';

    final userImage =
        userData?['profileImage'] ??
        userData?['photoUrl'] ??
        user.photoURL ??
        '';

    await _firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);

      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {'likes': FieldValue.increment(-1)});
      } else {
        tx.set(likeRef, {
          'likedAt': FieldValue.serverTimestamp(),
          'userName': userName,
          'userImage': userImage,
        }, SetOptions(merge: true));
        tx.update(postRef, {'likes': FieldValue.increment(1)});
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
