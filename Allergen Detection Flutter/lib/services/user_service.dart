import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Create (Add User)
  Future<void> saveUserData(UserModel user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(user.userId)
          .set(user.toMap());
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  // Read (Get User)
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    }
  }

  // Update (Update User)
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(user.userId)
          .update(user.toMap());
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  // Delete (Delete User)
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Admin: Get all users as a stream
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }
}
