import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? userProfileImage;
  final String content;
  final int likesCount;
  final List<String> likedBy;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.userProfileImage,
    required this.content,
    this.likesCount = 0,
    this.likedBy = const [],
    required this.createdAt,
  });

  factory CommentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userProfileImage: data['userProfileImage'],
      content: data['content'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'content': content,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'createdAt': createdAt,
    };
  }

  bool isLikedBy(String userId) => likedBy.contains(userId);
}