import 'package:flutter/material.dart';
import '../services/story_service.dart';
import '../models/story_model.dart';

class StoryProvider with ChangeNotifier {
  final StoryService _storyService = StoryService();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Upload story
  Future<bool> uploadStory({
    required String userId,
    required String username,
    String? userProfileImage,
    required dynamic file,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _storyService.uploadStory(
        userId: userId,
        username: username,
        userProfileImage: userProfileImage,
        file: file,
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

  // Get stories
  Stream<List<StoryModel>> getStories(List<String> followingIds) {
    return _storyService.getStories(followingIds);
  }

  // Periodic cleanup (can be called on app start)
  Future<void> cleanupStories() async {
    await _storyService.deleteExpiredStories();
  }
}
