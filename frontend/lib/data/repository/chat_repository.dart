import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;

  /// Returns a stable conversation ID for two users (sorted so it's always the same)
  String conversationId(String otherUid) {
    final ids = [currentUid, otherUid]..sort();
    return ids.join('_');
  }

  /// Ensure the conversation document exists with participant metadata
  Future<void> ensureConversation({
    required String otherUid,
    required String otherName,
    required String otherAvatar,
  }) async {
    final convId = conversationId(otherUid);
    final ref = _firestore.collection('conversations').doc(convId);
    final snap = await ref.get();

    // Fetch current user's own name and avatar from Firestore
    String myName = '';
    String myAvatar = '';
    try {
      final myDoc = await _firestore.collection('users').doc(currentUid).get();
      if (myDoc.exists) {
        final d = myDoc.data()!;
        myName =
            d['fullName'] as String? ??
            d['displayName'] as String? ??
            _auth.currentUser?.displayName ??
            '';
        myAvatar =
            d['profileImage'] as String? ??
            d['photoUrl'] as String? ??
            _auth.currentUser?.photoURL ??
            '';
      }
    } catch (_) {}

    if (!snap.exists) {
      await ref.set({
        'participants': [currentUid, otherUid],
        'participantNames': {currentUid: myName, otherUid: otherName},
        'participantAvatars': {currentUid: myAvatar, otherUid: otherAvatar},
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'unreadCount': {currentUid: 0, otherUid: 0},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Update names/avatars in case they were empty before
      final existingData = snap.data() as Map<String, dynamic>;
      final existingNames =
          existingData['participantNames'] as Map<String, dynamic>? ?? {};
      final existingAvatars =
          existingData['participantAvatars'] as Map<String, dynamic>? ?? {};

      final updates = <String, dynamic>{};

      // Fix empty current user name
      if ((existingNames[currentUid] as String? ?? '').isEmpty &&
          myName.isNotEmpty) {
        updates['participantNames.$currentUid'] = myName;
      }
      // Fix empty current user avatar
      if ((existingAvatars[currentUid] as String? ?? '').isEmpty &&
          myAvatar.isNotEmpty) {
        updates['participantAvatars.$currentUid'] = myAvatar;
      }
      // Fix empty other user name
      if ((existingNames[otherUid] as String? ?? '').isEmpty &&
          otherName.isNotEmpty) {
        updates['participantNames.$otherUid'] = otherName;
      }

      if (updates.isNotEmpty) {
        await ref.update(updates);
      }
    }
  }

  /// Real-time stream of messages for a conversation
  Stream<QuerySnapshot> messagesStream(String otherUid) {
    return _firestore
        .collection('conversations')
        .doc(conversationId(otherUid))
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Send a text message
  Future<void> sendMessage({
    required String otherUid,
    required String content,
    String type = 'text',
    Map<String, dynamic>? extra,
  }) async {
    final convId = conversationId(otherUid);
    final msgData = {
      'senderId': currentUid,
      'type': type,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      if (extra != null) ...extra,
    };

    final batch = _firestore.batch();

    // Add message
    final msgRef = _firestore
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .doc();
    batch.set(msgRef, msgData);

    // Update conversation metadata
    final convRef = _firestore.collection('conversations').doc(convId);
    batch.update(convRef, {
      'lastMessage': type == 'text' ? content : '[$type]',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': currentUid,
      'unreadCount.$otherUid': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Mark all messages in a conversation as read
  Future<void> markAsRead(String otherUid) async {
    final convId = conversationId(otherUid);
    await _firestore.collection('conversations').doc(convId).update({
      'unreadCount.$currentUid': 0,
    });
  }

  /// Stream of all conversations for the current user
  Stream<QuerySnapshot> conversationsStream() {
    // Use simple query without orderBy to avoid index/null issues,
    // then sort in the UI layer
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUid)
        .snapshots();
  }

  /// Set typing indicator
  Future<void> setTyping(String otherUid, bool isTyping) async {
    final convId = conversationId(otherUid);
    await _firestore.collection('conversations').doc(convId).update({
      'typing.$currentUid': isTyping,
    });
  }

  /// Stream to watch if the other user is typing
  Stream<DocumentSnapshot> typingStream(String otherUid) {
    return _firestore
        .collection('conversations')
        .doc(conversationId(otherUid))
        .snapshots();
  }

  /// Fetch the live profile photo URL for any user from the users collection.
  /// Checks `profileImage` first, then falls back to `photoUrl`.
  Future<String> getUserPhotoUrl(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return '';
      final data = doc.data()!;
      final profileImage = data['profileImage'] as String? ?? '';
      if (profileImage.isNotEmpty) return profileImage;
      final photoUrl = data['photoUrl'] as String? ?? '';
      if (photoUrl.isNotEmpty) return photoUrl;
      // Last resort: Firebase Auth photoURL (covers Google sign-in users)
      if (uid == currentUid) {
        return _auth.currentUser?.photoURL ?? '';
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  /// Stream of a user's profile photo URL so it stays in sync.
  Stream<String> userPhotoStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return '';
      final data = doc.data()!;
      final profileImage = data['profileImage'] as String? ?? '';
      if (profileImage.isNotEmpty) return profileImage;
      return data['photoUrl'] as String? ?? '';
    });
  }
}
