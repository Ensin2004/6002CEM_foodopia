import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';

/// Defines behavior for auth remote data source.
class AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _fcm;

  /// Creates a auth remote data source instance.
  AuthRemoteDataSource({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? fcm,
  }) : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _fcm = fcm ?? FirebaseMessaging.instance;

  // Keeps preferred 'login' naming
  Future<firebase_auth.UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Keeps preferred 'signup' naming
  Future<firebase_auth.UserCredential> signup({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Runs the send email verification operation.
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Handles the reload user operation.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  firebase_auth.User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Loads data for the get fcmtoken operation.
  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }

  Future<void> saveFcmToken(String uid) async {
    final token = await getFCMToken();
    if (token == null || token.isEmpty) return;
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Runs the save user to firestore operation.
  Future<void> saveUserToFirestore({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    await _firestore.collection('users').doc(uid).set(userData);
  }

  /// Runs the update user in firestore operation.
  Future<void> updateUserInFirestore({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    await _firestore.collection('users').doc(uid).update(userData);
  }

  /// Loads data for the get user from firestore operation.
  Future<DocumentSnapshot> getUserFromFirestore(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Loads configured age groups.
  Future<QuerySnapshot> getAgeGroups() async {
    return await _firestore
        .collection('app_config')
        .doc('age_groups')
        .collection('items')
        .orderBy('sortOrder')
        .get();
  }

  /// Handles the logout operation.
  Future<void> logout() async {
    await _auth.signOut();
  }
}
