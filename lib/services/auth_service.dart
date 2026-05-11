import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =================== REGISTER ===================
  Future<UserModel?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel user = UserModel(
        id: credential.user!.uid,
        username: username,
        email: email,
        createdAt: DateTime.now(),
        following: [],
        followers: [],
      );

      await _firestore.collection('users').doc(user.id).set(user.toMap());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // =================== LOGIN ===================
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromDocument(userDoc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // =================== LOGOUT ===================
  Future<void> logout() async {
    await _auth.signOut();
  }

  // =================== GET CURRENT USER ===================
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // =================== GET CURRENT USER DATA ===================
  Future<UserModel?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      return UserModel.fromDocument(userDoc);
    }
    return null;
  }

  // =================== UPDATE PROFILE ===================
  Future<void> updateProfile({
    required String userId,
    String? username,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (username != null) updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // =================== FOLLOW USER ===================
  Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      // Gumamit ng batch para siguradong parehong ma-uupdate o hindi
      WriteBatch batch = _firestore.batch();

      DocumentReference currentUserRef = _firestore.collection('users').doc(currentUserId);
      DocumentReference targetUserRef = _firestore.collection('users').doc(targetUserId);

      // Update current user: dagdag sa following list
      batch.update(currentUserRef, {
        'following': FieldValue.arrayUnion([targetUserId]),
        'followingCount': FieldValue.increment(1),
      });

      // Update target user: dagdag sa followers list
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayUnion([currentUserId]),
        'followersCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Follow error: $e');
      rethrow;
    }
  }

  // =================== UNFOLLOW USER ===================
  Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();

      DocumentReference currentUserRef = _firestore.collection('users').doc(currentUserId);
      DocumentReference targetUserRef = _firestore.collection('users').doc(targetUserId);

      batch.update(currentUserRef, {
        'following': FieldValue.arrayRemove([targetUserId]),
        'followingCount': FieldValue.increment(-1),
      });

      batch.update(targetUserRef, {
        'followers': FieldValue.arrayRemove([currentUserId]),
        'followersCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      print('Unfollow error: $e');
      rethrow;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
