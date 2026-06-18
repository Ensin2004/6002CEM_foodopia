import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_setup_option.dart';
import '../../domain/entities/user_setup_preferences.dart';
import '../../domain/repositories/user_setup_repository.dart';
import '../datasources/user_setup_remote_datasource.dart';
import '../models/user_setup_preferences_model.dart';

/// Implementation of the user setup repository.
/// Coordinates data operations for user preferences and options.
class UserSetupRepositoryImpl implements UserSetupRepository {
  /// Remote data source for user setup operations.
  final UserSetupRemoteDataSource remoteDataSource;

  /// Creates a new user setup repository implementation instance.
  UserSetupRepositoryImpl({required this.remoteDataSource});

  /// Retrieves admin-configured options for a category.
  @override
  Future<Either<Failure, List<UserSetupOption>>> getAdminOptions(
      String categoryId,
      ) async {
    try {
      // Delegate to remote data source.
      return Right(await remoteDataSource.getAdminOptions(categoryId));
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Searches for foods matching a query.
  @override
  Future<Either<Failure, List<UserSetupOption>>> searchFoods(
      String query,
      ) async {
    try {
      // Delegate to remote data source.
      return Right(await remoteDataSource.searchFoods(query));
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Retrieves user preferences.
  @override
  Future<Either<Failure, UserSetupPreferences>> getPreferences(
      String uid,
      ) async {
    try {
      // Delegate to remote data source.
      return Right(await remoteDataSource.getPreferences(uid));
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Checks if user setup is completed.
  @override
  Future<Either<Failure, bool>> isSetupCompleted(String uid) async {
    try {
      // Delegate to remote data source.
      return Right(await remoteDataSource.isSetupCompleted(uid));
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Saves user preferences.
  @override
  Future<Either<Failure, void>> savePreferences({
    required String uid,
    required UserSetupPreferences preferences,
  }) async {
    try {
      // Convert entity to model and delegate to remote data source.
      await remoteDataSource.savePreferences(
        uid: uid,
        preferences: UserSetupPreferencesModel.fromEntity(preferences),
      );
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }
}