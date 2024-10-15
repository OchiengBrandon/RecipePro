import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<String?> getCurrentUsername() async {
    User? user = currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      return userDoc['username'] as String?;
    }
    return null; // Return null if no user is logged in
  }

  Future<void> updateProfile(
      String username, String name, String phone, String bio) async {
    User? user = currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'username': username,
        'name': name,
        'phone': phone,
        'bio': bio,
      });
    } else {
      throw Exception('User not logged in');
    }
  }

  Future<void> sendPasswordResetEmail() async {
    User? user = currentUser;
    if (user != null) {
      await _auth.sendPasswordResetEmail(email: user.email!);
    } else {
      throw Exception('User not logged in');
    }
  }
}
