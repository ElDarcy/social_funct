import 'dart:io';
import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../models/post_model.dart';

class PostProvider with ChangeNotifier {
  final PostService _postService = PostService();

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get feed posts
  Stream<List<PostModel>> getFeedPosts() {
    return _postService.getFeedPosts().map((posts) {
      _posts = posts;
      notifyListeners();
      return posts;
    });
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

  // Toggle like
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      await _postService.toggleLike(postId: postId, userId: userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Toggle save
  Future<void> toggleSave({
    required String postId,
    required String userId,
  }) async {
    try {
      await _postService.toggleSave(postId: postId, userId: userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Upload image
  Future<String> uploadImage(File imageFile, String userId) async {
    return await _postService.uploadImage(imageFile, userId);
  }

  // Upload video
  Future<String> uploadVideo(File videoFile, String userId) async {
    return await _postService.uploadVideo(videoFile, userId);
  }
}