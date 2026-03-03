import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register new user
  Future<UserModel?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Create user with email and password
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user model
      UserModel user = UserModel(
        id: credential.user!.uid,
        username: username,
        email: email,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore.collection('users').doc(user.id).set(user.toMap());

      return user;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // Login user
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromDocument(userDoc);
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get current user data
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

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return UserModel.fromDocument(userDoc);
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  // Update user profile
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
      print('Update profile error: $e');
      rethrow;
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    QuerySnapshot query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return query.docs.isEmpty;
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}