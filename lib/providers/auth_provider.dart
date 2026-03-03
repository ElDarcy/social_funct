import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Initialize auth state
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      User? firebaseUser = _authService.getCurrentUser();
      if (firebaseUser != null) {
        _currentUser = await _authService.getCurrentUserData();
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserModel? user = await _authService.register(
        email: email,
        password: password,
        username: username,
      );

      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserModel? user = await _authService.login(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // Update profile
  Future<void> updateProfile({
    String? username,
    String? bio,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return;

    try {
      await _authService.updateProfile(
        userId: _currentUser!.id,
        username: username,
        bio: bio,
        profileImageUrl: profileImageUrl,
      );

      // Refresh user data
      _currentUser = await _authService.getCurrentUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}