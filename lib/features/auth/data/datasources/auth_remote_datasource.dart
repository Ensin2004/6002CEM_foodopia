import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';

/// Defines behavior for auth remote data source.
class AuthRemoteDataSource {
  static const List<Map<String, String>> _defaultNotificationPreferences = [
    {
      'id': 'new_follower_notification',
      'title': 'New Follower Notification',
      'description': 'Get a notification for new follower',
    },
    {
      'id': 'new_rating_notification',
      'title': 'New Rating Notification',
      'description':
          'Receive a notification when your Recipe is being rated by user',
    },
    {
      'id': 'new_comment_notification',
      'title': 'New Comment Notification',
      'description': 'Receive a notification when your recipe has comment',
    },
    {
      'id': 'new_recipe_notification',
      'title': 'New Recipe Notification',
      'description': 'Receive a notification when followed creator posts',
    },
    {
      'id': 'new_reply_notification',
      'title': 'New Reply Notification',
      'description': 'Receive a notification when someone replies you',
    },
  ];

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
    await _removeFcmTokenFromOtherUsers(uid: uid, token: token);
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  Future<void> removeCurrentFcmToken() async {
    final uid = _auth.currentUser?.uid;
    final token = await getFCMToken();
    if (uid == null || uid.isEmpty || token == null || token.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Logout should still continue if token cleanup is blocked.
    }
  }

  Future<void> _removeFcmTokenFromOtherUsers({
    required String uid,
    required String token,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('fcmTokens', arrayContains: token)
          .get();
      final batch = _firestore.batch();
      var hasUpdates = false;

      for (final doc in snapshot.docs) {
        if (doc.id == uid) continue;
        batch.set(doc.reference, {
          'fcmTokens': FieldValue.arrayRemove([token]),
        }, SetOptions(merge: true));
        hasUpdates = true;
      }

      if (hasUpdates) {
        await batch.commit();
      }
    } on FirebaseException {
      // Best-effort cleanup for shared test devices.
    }
  }

  /// Runs the save user to firestore operation.
  Future<void> saveUserToFirestore({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    await _firestore.collection('users').doc(uid).set(userData);
    await ensureNotificationPreferences(uid);
  }

  Future<void> ensureNotificationPreferences(String uid) async {
    if (uid.isEmpty) return;

    final userRef = _firestore.collection('users').doc(uid);
    final collectionRef = userRef.collection('notification_preferences');
    final snapshot = await collectionRef.get();
    final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
    final existingMap = <String, bool>{};

    for (final doc in snapshot.docs) {
      final enabled = doc.data()['enabled'];
      if (enabled is bool) {
        existingMap[doc.id] = enabled;
      }
    }

    final batch = _firestore.batch();
    for (final preference in _defaultNotificationPreferences) {
      final id = preference['id'] ?? '';
      if (id.isEmpty) continue;

      final ref = collectionRef.doc(id);
      if (existingIds.contains(id)) {
        batch.set(ref, {
          'title': preference['title'] ?? id,
          'description': preference['description'] ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        batch.set(ref, {
          'title': preference['title'] ?? id,
          'description': preference['description'] ?? '',
          'enabled': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        existingMap[id] = true;
      }
    }

    batch.set(userRef, {
      'notificationPreferences': {
        for (final preference in _defaultNotificationPreferences)
          if ((preference['id'] ?? '').isNotEmpty)
            preference['id']!: existingMap[preference['id']] ?? true,
      },
    }, SetOptions(merge: true));
    await batch.commit();
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
    await removeCurrentFcmToken();
    await _auth.signOut();
  }
}
