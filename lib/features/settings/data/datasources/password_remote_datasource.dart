import 'package:firebase_auth/firebase_auth.dart';

class PasswordRemoteDataSource {
  final FirebaseAuth _auth;

  PasswordRemoteDataSource({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final email = user.email;
    if (email == null) {
      throw Exception('User email not found');
    }

    // Re-authenticate user with current password
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update to new password
    await user.updatePassword(newPassword);
  }
}