// Declares repository contracts for profile.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

/// Defines behavior for profile repository.
abstract class ProfileRepository {
  /// Loads data for the get user profile operation.
  Future<Either<Failure, UserProfile>> getUserProfile(String uid);
  /// Runs the update user name operation.
  Future<Either<Failure, void>> updateUserName(String uid, String name);
  /// Runs the update user gender operation.
  Future<Either<Failure, void>> updateUserGender(String uid, String gender);
  /// Runs the update profile image operation.
  Future<Either<Failure, void>> updateProfileImage(String uid, String imageUrl);
}
