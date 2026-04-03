import 'package:cloud_firestore/cloud_firestore.dart';

class LocalComment {
  final String id;
  final String? parentId;
  final String userId;
  final String userName;
  final String userAvatar;
  final bool isVerified;
  final String commentText;
  final int replies;
  final int level;
  final DateTime createdAt;
  List<String> likes;
  bool isExpanded;

  LocalComment({
    required this.id,
    this.parentId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.isVerified,
    required this.commentText,
    required this.likes,
    required this.replies,
    required this.level,
    required this.createdAt,
    this.isExpanded = true,
  });

  factory LocalComment.fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocalComment(
      id: data['id'],
      parentId: data['parentId'],
      userId: data['userId'] ?? '',
      userName: data['userName'],
      userAvatar: data['userAvatar'],
      isVerified: data['isVerified'] ?? false,
      commentText: data['commentText'],
      likes: List<String>.from(data['likes'] ?? []),
      replies: data['replies'] ?? 0,
      level: data['level'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isExpanded: true,
    );
  }

  LocalComment copyWith({
    int? level,
    int? replies,
    List<String>? likes,
    bool? isExpanded,
    String? userAvatar,
    String? userName,
  }) {
    return LocalComment(
      id: id,
      parentId: parentId,
      userId: userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      isVerified: isVerified,
      commentText: commentText,
      likes: likes ?? this.likes,
      replies: replies ?? this.replies,
      level: level ?? this.level,
      createdAt: createdAt,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'isVerified': isVerified,
      'commentText': commentText,
      'likes': likes,
      'replies': replies,
      'level': level,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
