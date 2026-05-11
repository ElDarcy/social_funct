import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../models/post_model.dart';

class PostProvider with ChangeNotifier {
  final PostService _postService = PostService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get feed posts
  Stream<List<PostModel>> getFeedPosts() {
    return _postService.getFeedPosts();
  }

  // Get following feed
  Stream<List<PostModel>> getFollowingFeedPosts(String userId) {
    return _postService.getFollowingFeedPosts(userId);
  }

  // Get explore posts
  Stream<List<PostModel>> getExplorePosts(String userId, List<String> followingIds) {
    return _postService.getExplorePosts(userId, followingIds);
  }

  // Get user posts
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _postService.getUserPosts(userId);
  }

  // Create post
  Future<bool> createPost({
    required String userId,
    required String caption,
    required List<String> mediaUrls,
    required PostType type,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _postService.createPost(
        userId: userId,
        caption: caption,
        mediaUrls: mediaUrls,
        type: type,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ ADDED BACK: Missing upload methods
  Future<String> uploadImage(dynamic file, String userId) async {
    return await _postService.uploadImage(file, userId);
  }

  Future<String> uploadVideo(dynamic file, String userId) async {
    return await _postService.uploadVideo(file, userId);
  }

  Future<void> toggleLike({required String postId, required String userId}) async {
    try {
      await _postService.toggleLike(postId: postId, userId: userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleSave({required String postId, required String userId}) async {
    try {
      await _postService.toggleSave(postId: postId, userId: userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePost(String postId, String caption) async {
    try {
      await _postService.updatePost(postId: postId, caption: caption);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId, String userId) async {
    try {
      await _postService.deletePost(postId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
