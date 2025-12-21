import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skill_link_gh/domain/models/reel_model.dart';

final reelsProvider = StateNotifierProvider<ReelsNotifier, List<Reel>>(
  (ref) => ReelsNotifier(),
);

class ReelsNotifier extends StateNotifier<List<Reel>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  ReelsNotifier() : super([]);

  /// Load initial reels from Firestore
  Future<void> loadInitialReels() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final snapshot = await _firestore
          .collection('reels')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final reels = snapshot.docs.map((doc) {
        return Reel.fromFirestore(doc);
      }).toList();

      state = reels;
    } catch (e) {
      log('Failed to load reels: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Add a new reel locally
  void addReel(Reel reel) {
    state = [reel, ...state];
  }

  /// Toggle like
  Future<void> toggleLike(String reelId) async {
    final index = state.indexWhere((r) => r.id == reelId);
    if (index == -1) return;

    final reel = state[index];
    final isLiked = !reel.isLiked;

    // Update locally
    state = [
      ...state.sublist(0, index),
      reel.copyWith(isLiked: isLiked, likes: isLiked ? reel.likes + 1 : reel.likes - 1),
      ...state.sublist(index + 1),
    ];

    try {
      final reelRef = _firestore.collection('reels').doc(reelId);
      final uid = "CURRENT_USER_UID"; // replace with FirebaseAuth.instance.currentUser?.uid

      final likeRef = reelRef.collection('likes').doc(uid);

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(likeRef);
        if (snap.exists) {
          tx.delete(likeRef);
          tx.update(reelRef, {'likes': FieldValue.increment(-1)});
        } else {
          tx.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
          tx.update(reelRef, {'likes': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      log('Failed to update like in Firestore: $e');
    }
  }
}
