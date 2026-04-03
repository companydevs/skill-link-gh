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
  final String? parentId;
  final int replyCount;
  final bool isExpanded;

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
    this.parentId,
    this.replyCount = 0,
    this.isExpanded = false,
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
      isLiked: false,
      replies: [],
      parentId: data['parentId'] as String?,
      replyCount: (data['replyCount'] ?? 0) as int,
      isExpanded: false,
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
      'parentId': parentId,
      'replyCount': replyCount,
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
    String? parentId,
    int? replyCount,
    bool? isExpanded,
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
      parentId: parentId ?? this.parentId,
      replyCount: replyCount ?? this.replyCount,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}
