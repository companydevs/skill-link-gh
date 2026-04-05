import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// Tracks online presence and last seen for the current user.
/// Call [init] once after login, [dispose] on logout.
class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._();
  factory PresenceService() => _instance;
  PresenceService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  Timer? _heartbeat;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _setOnline(true);
    // Heartbeat every 60s to keep lastSeen fresh
    _heartbeat = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_auth.currentUser != null) _setOnline(true);
    });
  }

  void dispose() {
    _heartbeat?.cancel();
    _setOnline(false);
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _setOnline(false);
        break;
    }
  }

  Future<void> _setOnline(bool online) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': online,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Returns a stream of the online status + lastSeen for any user.
  static Stream<Map<String, dynamic>> presenceStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snap) {
          final d = snap.data() ?? {};
          return {
            'isOnline': d['isOnline'] as bool? ?? false,
            'lastSeen': d['lastSeen'] as Timestamp?,
          };
        });
  }

  /// Formats lastSeen as a human-readable string.
  static String formatLastSeen(Timestamp? ts) {
    if (ts == null) return 'Offline';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return 'Long ago';
  }

  /// Returns a short label only if seen recently (within 24h).
  /// Otherwise returns 'Available' to avoid ugly "Last seen Long ago" text.
  static String recentLastSeenLabel(Timestamp? ts) {
    if (ts == null) return 'Available';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inSeconds < 60) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    return 'Available';
  }
}
