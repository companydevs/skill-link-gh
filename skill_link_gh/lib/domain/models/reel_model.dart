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

  /// Safe copyWith
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

  /// Updated factory to handle both 'createdAt' and 'timestamp' fields
  /// Makes it robust when collection is empty or fields are missing
  factory Reel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    // If document has no data (shouldn't happen, but safe guard)
    if (data == null) {
      return Reel(
        id: doc.id,
        videoUrl: '',
        artisanName: 'Unknown Artisan',
        artisanAvatar: '',
        artisanCategory: 'General',
        artisanSemanticLabel: '',
        description: 'No description available',
        likes: 0,
        comments: 0,
        shares: 0,
        isLiked: false,
        timestamp: DateTime.now(),
      );
    }

    // Safely extract timestamp (supports both field names from your code evolution)
    DateTime parsedTimestamp;
    final timestampField = data['createdAt'] ?? data['timestamp'];
    if (timestampField is Timestamp) {
      parsedTimestamp = timestampField.toDate();
    } else {
      parsedTimestamp = DateTime.now(); // fallback
    }

    return Reel(
      id: doc.id,
      videoUrl: data['videoUrl'] as String? ?? '',
      artisanName: data['artisanName'] as String? ?? 'Unknown Artisan',
      artisanAvatar: data['artisanAvatar'] as String? ?? '',
      artisanCategory: data['artisanCategory'] as String? ?? 'General',
      artisanSemanticLabel: data['artisanSemanticLabel'] as String? ?? '',
      description: data['description'] as String? ?? 'Check out this amazing work!',
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      comments: (data['comments'] as num?)?.toInt() ?? 0,
      shares: (data['shares'] as num?)?.toInt() ?? 0,
      isLiked: false, // This will be set correctly in repository fetch
      timestamp: parsedTimestamp,
    );
  }

  /// For future use if needed (e.g., caching)
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
      'createdAt': Timestamp.fromDate(timestamp), // Use consistent field name
    };
  }

  @override
  String toString() {
    return 'Reel(id: $id, artisan: $artisanName, likes: $likes, description: $description)';
  }
}