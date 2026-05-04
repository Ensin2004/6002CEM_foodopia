// Implements repository operations for main.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/main_repository.dart';
import '../datasources/main_remote_datasource.dart';
import '../models/user_profile_model.dart';

/// Connects main feature requests to the remote Firestore data source.
class MainRepositoryImpl implements MainRepository {
  final MainRemoteDataSource remoteDataSource;

  /// Creates a repository with the required remote data source dependency.
  MainRepositoryImpl({required this.remoteDataSource});

  /// Loads the profile image URL for a user account.
  @override
  Future<Either<Failure, String?>> getUserProfileImage(String userId) async {
    try {
      // Fetches the user document from the remote data source.
      final doc = await remoteDataSource.getUserData(userId);

      // Converts the Firestore document into a profile model.
      final profile = UserProfileModel.fromFirestore(doc);

      // Returns only the nullable profile image URL to the caller.
      return Right(profile.profileImageUrl);
    } catch (e) {
      // Converts remote errors into a concrete failure type.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Stores a fresh server timestamp as the latest login time.
  @override
  Future<Either<Failure, void>> updateLastLogin(String userId) async {
    try {
      // Sends a partial update so existing user fields remain unchanged.
      await remoteDataSource.updateUserData(
        userId,
        {'lastLogin': FieldValue.serverTimestamp()},
      );

      // Indicates a successful update without returning extra data.
      return const Right(null);
    } catch (e) {
      // Converts remote errors into a concrete failure type.
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
