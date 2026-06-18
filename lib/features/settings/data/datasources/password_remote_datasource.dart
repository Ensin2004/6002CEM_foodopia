import 'package:firebase_auth/firebase_auth.dart';

/// Defines behavior for password remote data source.
/// Handles password change operations with Firebase Authentication.
class PasswordRemoteDataSource {
  /// FirebaseAuth instance used for authentication operations.
  final FirebaseAuth _auth;

  /// Creates a password remote data source instance.
  PasswordRemoteDataSource({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  /// Runs the change password operation.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Get the current authenticated user.
    final user = _auth.currentUser;

    // Check if user is logged in.
    if (user == null) {
      /// Handles the exception operation.
      throw Exception('User not logged in');
    }

    // Get the user's email.
    final email = user.email;
    if (email == null) {
      /// Handles the exception operation.
      throw Exception('User email not found');
    }

    // Re-authenticate user with current password.
    // This is required before changing the password.
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update to new password.
    await user.updatePassword(newPassword);
  }
}