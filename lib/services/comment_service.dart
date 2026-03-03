import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add comment
  Future<CommentModel> addComment({
    required String postId,
    required String userId,
    required String username,
    required String? userProfileImage,
    required String content,
  }) async {
    try {
      CommentModel comment = CommentModel(
        id: _firestore.collection('comments').doc().id,
        postId: postId,
        userId: userId,
        username: username,
        userProfileImage: userProfileImage,
        content: content,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('comments').doc(comment.id).set(comment.toMap());

      // Update post's comment count
      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      return comment;
    } catch (e) {
      print('Add comment error: $e');
      rethrow;
    }
  }

  // Get comments for a post
  Stream<List<CommentModel>> getPostComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommentModel.fromDocument(doc)).toList();
    });
  }

  // Delete comment
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();

      // Update post's comment count
      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Delete comment error: $e');
      rethrow;
    }
  }

  // Like/Unlike comment
  Future<void> toggleCommentLike({
    required String commentId,
    required String userId,
  }) async {
    try {
      DocumentReference commentRef = _firestore.collection('comments').doc(commentId);
      DocumentSnapshot commentDoc = await commentRef.get();

      if (commentDoc.exists) {
        CommentModel comment = CommentModel.fromDocument(commentDoc);
        bool isLiked = comment.likedBy.contains(userId);

        if (isLiked) {
          await commentRef.update({
            'likesCount': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([userId]),
          });
        } else {
          await commentRef.update({
            'likesCount': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([userId]),
          });
        }
      }
    } catch (e) {
      print('Toggle comment like error: $e');
      rethrow;
    }
  }
}