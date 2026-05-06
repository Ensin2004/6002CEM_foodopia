import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_setup_option.dart';
import '../../domain/entities/user_setup_preferences.dart';
import '../../domain/repositories/user_setup_repository.dart';
import '../datasources/user_setup_remote_datasource.dart';
import '../models/user_setup_preferences_model.dart';

class UserSetupRepositoryImpl implements UserSetupRepository {
  final UserSetupRemoteDataSource remoteDataSource;

  UserSetupRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<UserSetupOption>>> getAdminOptions(
    String categoryId,
  ) async {
    try {
      return Right(await remoteDataSource.getAdminOptions(categoryId));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserSetupOption>>> searchFoods(
    String query,
  ) async {
    try {
      return Right(await remoteDataSource.searchFoods(query));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserSetupPreferences>> getPreferences(
    String uid,
  ) async {
    try {
      return Right(await remoteDataSource.getPreferences(uid));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isSetupCompleted(String uid) async {
    try {
      return Right(await remoteDataSource.isSetupCompleted(uid));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> savePreferences({
    required String uid,
    required UserSetupPreferences preferences,
  }) async {
    try {
      await remoteDataSource.savePreferences(
        uid: uid,
        preferences: UserSetupPreferencesModel.fromEntity(preferences),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
