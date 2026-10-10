import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  // Expose services if needed for direct access (e.g. for updatePassword)
  AuthService get authService => _authService;

  User? _firebaseUser;
  UserModel? _currentUserModel;

  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUserModel => _currentUserModel;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) {
      _firebaseUser = user;
      notifyListeners();
      if (user != null) {
        _fetchUserModel(user.uid);
      } else {
        _currentUserModel = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserModel(String uid) async {
    try {
      print('AuthProvider: Fetching user model for uid: $uid');
      final userModel = await _userService.getUserData(uid);
      if (userModel != null) {
        _currentUserModel = userModel;
        print('AuthProvider: User model fetched successfully - role: ${userModel.role}');
      } else {
        print('AuthProvider: User document not found in Firestore');
        _currentUserModel = null;
      }
      notifyListeners();
    } catch (e) {
      print("Error fetching user model in provider: $e");
      _currentUserModel = null;
      notifyListeners();
    }
  }

  // Expose Auth Services
  Future<UserCredential> signIn(String email, String password) async {
    final result = await _authService.signIn(email: email, password: password);
    // Fetch user model from Firestore after successful login
    if (result.user != null) {
      await _fetchUserModel(result.user!.uid);
    }
    return result;
  }

  Future<UserCredential> signUp(String email, String password) async {
    final result = await _authService.signUp(email: email, password: password);
    // Note: User model will be fetched by auth state listener
    return result;
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  // Expose User Services
  Future<void> saveUser(UserModel user) async {
    await _userService.saveUserData(user);
    _currentUserModel = user;
    notifyListeners();
  }
}
