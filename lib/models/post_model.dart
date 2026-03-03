import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

enum PostType { image, video, carousel }

class PostModel {
  final String id;
  final String userId;
  final String caption;
  final List<String> mediaUrls;
  final PostType type;
  final int likesCount;
  final int commentsCount;
  final int savesCount;
  final List<String> likedBy;
  final List<String> savedBy;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.caption,
    required this.mediaUrls,
    this.type = PostType.image,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.savesCount = 0,
    this.likedBy = const [],
    this.savedBy = const [],
    required this.createdAt,
  });

  factory PostModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      caption: data['caption'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      type: PostType.values[data['type'] ?? 0],
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      savesCount: data['savesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      savedBy: List<String>.from(data['savedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'caption': caption,
      'mediaUrls': mediaUrls,
      'type': type.index,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'savesCount': savesCount,
      'likedBy': likedBy,
      'savedBy': savedBy,
      'createdAt': createdAt,
    };
  }

  bool isLikedBy(String userId) => likedBy.contains(userId);
  bool isSavedBy(String userId) => savedBy.contains(userId);
}