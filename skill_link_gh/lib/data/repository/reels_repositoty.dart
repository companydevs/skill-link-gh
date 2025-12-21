import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_link_gh/domain/models/reel_model.dart';

class ReelsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch reels with optional pagination
  Future<List<Reel>> fetchReels({
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    final user = _auth.currentUser;
    final uid = user?.uid;

    Query query = _firestore
        .collection('reels')
        .orderBy('timestamp', descending: true)
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

      final reel = Reel.fromFirestore(doc);
      return reel.copyWith(isLiked: isLiked);
    }));
  }

  /// Toggle like
  Future<void> toggleLike(String reelId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final reelRef = _firestore.collection('reels').doc(reelId);
    final likeRef = reelRef.collection('likes').doc(user.uid);

    await _firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);

      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(reelRef, {'likes': FieldValue.increment(-1)});
      } else {
        tx.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
        tx.update(reelRef, {'likes': FieldValue.increment(1)});
      }
    });
  }

  /// Optional: Add new reel
  Future<void> addReel(Reel reel) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final reelData = reel.toFirestore();
    await _firestore.collection('reels').add(reelData);
  }
}
