import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String artisanId;
  final String artisanName;
  final String artisanImage;
  final String serviceCategory;
  final String description;
  final String pricing;
  final List<PostImage> postImages;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isSaved;
  final int commentsCount; // Add this

  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.artisanId,
    required this.artisanName,
    required this.artisanImage,
    required this.serviceCategory,
    required this.description,
    required this.pricing,
    required this.postImages,
    required this.likes,
    required this.comments,
    this.isLiked = false,
    this.isSaved = false,
    this.commentsCount = 0, // default 0

    required this.createdAt,
  });

  /// Create PostModel from Firestore document
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      artisanId: data['artisanId'] ?? '',
      artisanName: data['artisanName'] ?? '',
      artisanImage: data['artisanImage'] ?? '',
      serviceCategory: data['serviceCategory'] ?? '',
      description: data['description'] ?? '',
      pricing: data['pricing'] ?? '',
      postImages:
          (data['postImages'] as List<dynamic>?)
              ?.map((e) => PostImage.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      commentsCount: (data['commentsCount'] ?? 0).toInt(),

      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert PostModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artisanId': artisanId,
      'artisanName': artisanName,
      'artisanImage': artisanImage,
      'serviceCategory': serviceCategory,
      'description': description,
      'pricing': pricing,
      'postImages': postImages.map((e) => e.toJson()).toList(),
      'likes': likes,
      'comments': comments,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'commentsCount': commentsCount, // include in JSON
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields (useful for toggling like/save)
  PostModel copyWith({
    String? id,
    String? artisanId,
    String? artisanName,
    String? artisanImage,
    String? serviceCategory,
    String? description,
    String? pricing,
    List<PostImage>? postImages,
    int? likes,
    int? comments,
    bool? isLiked,
    bool? isSaved,
    int? commentsCount,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      artisanId: artisanId ?? this.artisanId,
      artisanName: artisanName ?? this.artisanName,
      artisanImage: artisanImage ?? this.artisanImage,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      description: description ?? this.description,
      pricing: pricing ?? this.pricing,
      postImages: postImages ?? this.postImages,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PostImage {
  final String url;
  final String label;

  PostImage({required this.url, this.label = ''});

  /// Create PostImage from Map
  factory PostImage.fromMap(Map<String, dynamic> map) {
    return PostImage(url: map['url'] ?? '', label: map['label'] ?? '');
  }

  /// Convert PostImage to JSON
  Map<String, dynamic> toJson() {
    return {'url': url, 'label': label};
  }
}
