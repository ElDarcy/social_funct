import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isPrivate;
  final DateTime createdAt;
  final List<String> following;
  final List<String> followers;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isPrivate = false,
    required this.createdAt,
    this.following = const [],
    this.followers = const [],
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      bio: data['bio'],
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      isPrivate: data['isPrivate'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'isPrivate': isPrivate,
      'createdAt': createdAt,
      'following': following,   // ✅
      'followers': followers,   // ✅
    };
  }

  UserModel copyWith({
    String? username,
    String? email,
    String? profileImageUrl,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isPrivate,
    List<String>? following,
    List<String>? followers,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt,
      following: following ?? this.following,
      followers: followers ?? this.followers,
    );
  }

  // ✅ Helper methods
  bool isFollowing(String userId) => following.contains(userId);
  bool isFollowedBy(String userId) => followers.contains(userId);
}