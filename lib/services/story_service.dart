import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/story_model.dart';
import 'post_service.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PostService _postService = PostService();

  // =================== UPLOAD STORY ===================
  Future<void> uploadStory({
    required String userId,
    required String username,
    String? userProfileImage,
    required dynamic file,
  }) async {
    try {
      // 1. Upload image to Cloudinary (using existing post service utility)
      String imageUrl = await _postService.uploadImage(file, userId);

      // 2. Create Story document
      final storyId = _firestore.collection('stories').doc().id;
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(hours: 24));

      final story = StoryModel(
        id: storyId,
        userId: userId,
        username: username,
        userProfileImage: userProfileImage,
        imageUrl: imageUrl,
        createdAt: createdAt,
        expiresAt: expiresAt,
      );

      await _firestore.collection('stories').doc(storyId).set(story.toMap());
    } catch (e) {
      throw Exception('Failed to upload story: $e');
    }
  }

  // =================== GET STORIES FROM FOLLOWING ===================
  Stream<List<StoryModel>> getStories(List<String> followingIds) {
    if (followingIds.isEmpty) return Stream.value([]);

    // Firestore whereIn limit is 30
    final chunk = followingIds.length > 30 
        ? followingIds.sublist(0, 30) 
        : followingIds;

    return _firestore
        .collection('stories')
        .where('userId', whereIn: chunk)
        .where('expiresAt', isGreaterThan: DateTime.now())
        .snapshots()
        .map((snapshot) {
          final stories = snapshot.docs
              .map((doc) => StoryModel.fromDocument(doc))
              .toList();
          stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return stories;
        });
  }

  // =================== DELETE EXPIRED STORIES ===================
  // This would usually be a Cloud Function, but we can call it periodically
  Future<void> deleteExpiredStories() async {
    final snapshot = await _firestore
        .collection('stories')
        .where('expiresAt', isLessThan: DateTime.now())
        .get();
    
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
