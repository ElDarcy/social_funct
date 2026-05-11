import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import 'package:image_picker/image_picker.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _cloudName = 'dm8bztegh';
  static const String _uploadPreset = 'social_app_unsigned';

  // =================== CREATE POST ===================
  Future<PostModel> createPost({
    required String userId,
    required String caption,
    required List<String> mediaUrls,
    required PostType type,
  }) async {
    try {
      PostModel post = PostModel(
        id: _firestore.collection('posts').doc().id,
        userId: userId,
        caption: caption,
        mediaUrls: mediaUrls,
        type: type,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('posts').doc(post.id).set(post.toMap());

      await _firestore.collection('users').doc(userId).update({
        'postsCount': FieldValue.increment(1),
      });

      return post;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // =================== GET FEED POSTS (ALL PUBLIC) ===================
  // ✅ REMOVED orderBy temporarily to fix "infinite loading" / index issues
  Stream<List<PostModel>> getFeedPosts() {
    return _firestore
        .collection('posts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromDocument(doc))
          .toList();
    });
  }

  // =================== GET EXPLORE POSTS (NOT FOLLOWED) ===================
  Stream<List<PostModel>> getExplorePosts(String currentUserId, List<String> followingIds) {
    return _firestore
        .collection('posts')
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromDocument(doc))
          .where((post) => post.userId != currentUserId && !followingIds.contains(post.userId))
          .toList();
    });
  }

  // =================== GET FOLLOWING FEED (REAL-TIME) ===================
  Stream<List<PostModel>> getFollowingFeedPosts(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().asyncExpand((userDoc) {
      if (!userDoc.exists) return Stream.value([]);
      
      final data = userDoc.data();
      List<String> followingIds = List<String>.from(data?['following'] ?? []);
      
      if (!followingIds.contains(userId)) {
        followingIds.add(userId);
      }

      if (followingIds.isEmpty) return Stream.value([]);

      final chunk = followingIds.length > 30 
          ? followingIds.sublist(followingIds.length - 30) 
          : followingIds;

      return _firestore
          .collection('posts')
          .where('userId', whereIn: chunk)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PostModel.fromDocument(doc))
              .toList());
    });
  }

  // =================== GET USER POSTS ===================
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromDocument(doc)).toList();
    });
  }

  // =================== TOGGLE LIKE ===================
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        List<String> likedBy = List<String>.from(postDoc.get('likedBy') ?? []);
        int currentLikes = postDoc.get('likesCount') ?? 0;

        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          transaction.update(postRef, {
            'likedBy': likedBy,
            'likesCount': (currentLikes - 1).clamp(0, 999999),
          });
        } else {
          likedBy.add(userId);
          transaction.update(postRef, {
            'likedBy': likedBy,
            'likesCount': currentLikes + 1,
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // =================== TOGGLE SAVE ===================
  Future<void> toggleSave({
    required String postId,
    required String userId,
  }) async {
    try {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        List<String> savedBy = List<String>.from(postDoc.get('savedBy') ?? []);
        int currentSaves = postDoc.get('savesCount') ?? 0;

        if (savedBy.contains(userId)) {
          savedBy.remove(userId);
          transaction.update(postRef, {
            'savedBy': savedBy,
            'savesCount': (currentSaves - 1).clamp(0, 999999),
          });
        } else {
          savedBy.add(userId);
          transaction.update(postRef, {
            'savedBy': savedBy,
            'savesCount': currentSaves + 1,
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle save: $e');
    }
  }

  // =================== UPDATE POST ===================
  Future<void> updatePost({
    required String postId,
    required String caption,
  }) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'caption': caption,
      });
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  // =================== DELETE POST ===================
  Future<void> deletePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      await _firestore.collection('users').doc(userId).update({
        'postsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // =================== CLOUDINARY UPLOAD ===================
  Future<String> uploadImage(dynamic file, String userId) async {
    return await _uploadToCloudinary(file: file, resourceType: 'image', userId: userId);
  }

  Future<String> uploadVideo(dynamic file, String userId) async {
    return await _uploadToCloudinary(file: file, resourceType: 'video', userId: userId);
  }

  Future<String> _uploadToCloudinary({
    required dynamic file,
    required String resourceType,
    required String userId,
  }) async {
    final url = Uri.parse('');

    Uint8List bytes;
    if (kIsWeb) {
      bytes = await (file as XFile).readAsBytes();
    } else {
      bytes = await (file as File).readAsBytes();
    }

    final ext = resourceType == 'image' ? 'jpg' : 'mp4';
    final filename = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'social_app/$userId'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['secure_url'];
    } else {
      throw Exception('Upload failed: ${response.body}');
    }
  }
}
