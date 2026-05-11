import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String userId;
  final String username;
  final String? userProfileImage;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewers;

  StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfileImage,
    required this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    this.viewers = const [],
  });

  factory StoryModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userProfileImage: data['userProfileImage'],
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      viewers: List<String>.from(data['viewers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'viewers': viewers,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
