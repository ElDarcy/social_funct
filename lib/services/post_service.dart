import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post_model.dart';
import 'package:image_picker/image_picker.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new post
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

      // Update user's post count
      await _firestore.collection('users').doc(userId).update({
        'postsCount': FieldValue.increment(1),
      });

      return post;
    } catch (e) {
      print('Create post error: $e');
      rethrow;
    }
  }

  // Get all posts for feed
  Stream<List<PostModel>> getFeedPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromDocument(doc)).toList();
    });
  }

  // Get posts by user
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromDocument(doc)).toList();
    });
  }

  // Like/Unlike post
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      DocumentSnapshot postDoc = await postRef.get();

      if (postDoc.exists) {
        PostModel post = PostModel.fromDocument(postDoc);
        bool isLiked = post.likedBy.contains(userId);

        if (isLiked) {
          await postRef.update({
            'likesCount': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([userId]),
          });
        } else {
          await postRef.update({
            'likesCount': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([userId]),
          });
        }
      }
    } catch (e) {
      print('Toggle like error: $e');
      rethrow;
    }
  }

  // Save/Unsave post
  Future<void> toggleSave({
    required String postId,
    required String userId,
  }) async {
    try {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      DocumentSnapshot postDoc = await postRef.get();

      if (postDoc.exists) {
        PostModel post = PostModel.fromDocument(postDoc);
        bool isSaved = post.savedBy.contains(userId);

        if (isSaved) {
          await postRef.update({
            'savesCount': FieldValue.increment(-1),
            'savedBy': FieldValue.arrayRemove([userId]),
          });
        } else {
          await postRef.update({
            'savesCount': FieldValue.increment(1),
            'savedBy': FieldValue.arrayUnion([userId]),
          });
        }
      }
    } catch (e) {
      print('Toggle save error: $e');
      rethrow;
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      print('Delete post error: $e');
      rethrow;
    }
  }

  Future<String> uploadImage(dynamic file, String userId) async {
    try {
      String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child('posts/$userId/$fileName');

      if (kIsWeb) {
        // Web: file should be XFile
        if (file is XFile) {
          Uint8List bytes = await file.readAsBytes();
          await ref.putData(bytes);
        } else {
          throw Exception('Invalid file type for web. Expected XFile.');
        }
      } else {
        // Mobile: file should be File
        if (file is File) {
          await ref.putFile(file);
        } else {
          throw Exception('Invalid file type for mobile. Expected File.');
        }
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print('Upload image error: $e');
      rethrow;
    }
  }


  // Upload video (mobile & web)
  Future<String> uploadVideo(dynamic file, String userId) async {
    try {
      String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      Reference ref = _storage.ref().child('videos/$userId/$fileName');

      if (kIsWeb) {
        if (file is XFile) {
          Uint8List bytes = await file.readAsBytes();
          await ref.putData(bytes);
        } else {
          throw Exception('Invalid file type for web. Expected XFile.');
        }
      } else {
        if (file is File) {
          await ref.putFile(file);
        } else {
          throw Exception('Invalid file type for mobile. Expected File.');
        }
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print('Upload video error: $e');
      rethrow;
    }
  }

  // Get single post
  Future<PostModel?> getPost(String postId) async {
    try {
      DocumentSnapshot postDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();

      if (postDoc.exists) {
        return PostModel.fromDocument(postDoc);
      }
      return null;
    } catch (e) {
      print('Get post error: $e');
      return null;
    }
  }
}