import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/main_repository.dart';
import '../datasources/main_remote_datasource.dart';
import '../models/user_profile_model.dart';

class MainRepositoryImpl implements MainRepository {
  final MainRemoteDataSource remoteDataSource;

  MainRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String?>> getUserProfileImage(String userId) async {
    try {
      final doc = await remoteDataSource.getUserData(userId);
      final profile = UserProfileModel.fromFirestore(doc);
      return Right(profile.profileImageUrl);
    } catch (e) {
      // ✅ Use ServerFailure instead of abstract Failure
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastLogin(String userId) async {
    try {
      await remoteDataSource.updateUserData(
        userId,
        {'lastLogin': FieldValue.serverTimestamp()},
      );
      return const Right(null);
    } catch (e) {
      // ✅ Use ServerFailure instead of abstract Failure
      return Left(ServerFailure(message: e.toString()));
    }
  }
}