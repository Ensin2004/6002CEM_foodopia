// Implements repository operations for profile.

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/user_profile_model.dart';

/// Defines behavior for profile repository impl.
/// Implements the ProfileRepository interface using remote data source.
class ProfileRepositoryImpl implements ProfileRepository {
  /// Remote data source for profile operations.
  final ProfileRemoteDataSource remoteDataSource;

  /// Creates a profile repository impl instance.
  ProfileRepositoryImpl({required this.remoteDataSource});

  /// Loads data for the get user profile operation.
  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String uid) async {
    try {
      // Runs the guarded operation that can throw.
      final doc = await remoteDataSource.getUserProfile(uid);

      // Return not found failure if profile doesn't exist.
      if (!doc.exists) {
        return Left(NotFoundFailure(message: 'User profile not found'));
      }

      // Parse and return the profile.
      final profile = UserProfileModel.fromFirestore(doc);
      return Right(profile);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Runs the update user name operation.
  @override
  Future<Either<Failure, void>> updateUserName(String uid, String name) async {
    try {
      // Runs the guarded operation that can throw.
      await remoteDataSource.updateUserName(uid, name);
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Runs the update user gender operation.
  @override
  Future<Either<Failure, void>> updateUserGender(String uid, String gender) async {
    try {
      // Runs the guarded operation that can throw.
      await remoteDataSource.updateUserGender(uid, gender);
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Runs the update user age group operation.
  @override
  Future<Either<Failure, void>> updateUserAgeGroup(
      String uid,
      String ageGroupId,
      String ageGroupName,
      ) async {
    try {
      // Runs the guarded operation that can throw.
      await remoteDataSource.updateUserAgeGroup(uid, ageGroupId, ageGroupName);
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Runs the update profile image operation.
  @override
  Future<Either<Failure, void>> updateProfileImage(String uid, String imagePath) async {
    try {
      // Runs the guarded operation that can throw.
      // Create File from path.
      final imageFile = File(imagePath);

      // Upload image to remote service.
      final imageUrl = await remoteDataSource.uploadProfileImage(imageFile);

      // Update profile with new image URL.
      await remoteDataSource.updateProfileImage(uid, imageUrl);

      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }
}