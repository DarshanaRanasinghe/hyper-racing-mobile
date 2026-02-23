import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUserProfile({
    required String uid,
    required String username,
    required String email,
    String? photoUrl,
  }) async {
    await _db.collection('users').doc(uid).set({
      'username': username.trim(),
      'email': email.trim(),
      'photoUrl': (photoUrl ?? '').trim(),
      'online': false,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Stream<QuerySnapshot> usersStream() {
    // assumes username exists
    return _db.collection('users').orderBy('username').snapshots();
  }

  Stream<DocumentSnapshot> userDocStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<void> setPresence({required String uid, required bool online}) async {
    await _db.collection('users').doc(uid).set({
      'online': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
