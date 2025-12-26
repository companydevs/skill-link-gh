import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String reelId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final DateTime timestamp;
  final int likes;
  final bool isLiked;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.reelId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timestamp,
    this.likes = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Comment(
      id: doc.id,
      reelId: data['reelId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userAvatar: data['userAvatar'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: (data['likes'] ?? 0) as int,
      isLiked: false, // This will be set by the repository
      replies: [], // Replies will be loaded separately
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reelId': reelId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
    };
  }

  Comment copyWith({
    String? id,
    String? reelId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? text,
    DateTime? timestamp,
    int? likes,
    bool? isLiked,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      reelId: reelId ?? this.reelId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      replies: replies ?? this.replies,
    );
  }
}
