import 'package:cloud_firestore/cloud_firestore.dart';

class Reel {
  final String id;
  final String videoUrl;
  final String artisanName;
  final String artisanAvatar;
  final String artisanCategory;
  final String artisanSemanticLabel;
  final String description;
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;
  final DateTime timestamp;

  Reel({
    required this.id,
    required this.videoUrl,
    required this.artisanName,
    required this.artisanAvatar,
    required this.artisanCategory,
    required this.artisanSemanticLabel,
    required this.description,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.isLiked,
    required this.timestamp,
  });

  Reel copyWith({
    String? id,
    String? videoUrl,
    String? artisanName,
    String? artisanAvatar,
    String? artisanCategory,
    String? artisanSemanticLabel,
    String? description,
    int? likes,
    int? comments,
    int? shares,
    bool? isLiked,
    DateTime? timestamp,
  }) {
    return Reel(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      artisanName: artisanName ?? this.artisanName,
      artisanAvatar: artisanAvatar ?? this.artisanAvatar,
      artisanCategory: artisanCategory ?? this.artisanCategory,
      artisanSemanticLabel: artisanSemanticLabel ?? this.artisanSemanticLabel,
      description: description ?? this.description,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory Reel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reel(
      id: doc.id,
      videoUrl: data['videoUrl'] ?? '',
      artisanName: data['artisanName'] ?? '',
      artisanAvatar: data['artisanAvatar'] ?? '',
      artisanCategory: data['artisanCategory'] ?? '',
      artisanSemanticLabel: data['artisanSemanticLabel'] ?? '',
      description: data['description'] ?? '',
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      shares: data['shares'] ?? 0,
      isLiked: false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'videoUrl': videoUrl,
      'artisanName': artisanName,
      'artisanAvatar': artisanAvatar,
      'artisanCategory': artisanCategory,
      'artisanSemanticLabel': artisanSemanticLabel,
      'description': description,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'timestamp': timestamp,
    };
  }
}
