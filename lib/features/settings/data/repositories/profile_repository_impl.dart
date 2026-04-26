import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/user_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String uid) async {
    try {
      final doc = await remoteDataSource.getUserProfile(uid);
      if (!doc.exists) {
        return Left(NotFoundFailure(message: 'User profile not found'));
      }
      final profile = UserProfileModel.fromFirestore(doc);
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserName(String uid, String name) async {
    try {
      await remoteDataSource.updateUserName(uid, name);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserGender(String uid, String gender) async {
    try {
      await remoteDataSource.updateUserGender(uid, gender);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfileImage(String uid, String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final imageUrl = await remoteDataSource.uploadProfileImage(imageFile);
      await remoteDataSource.updateProfileImage(uid, imageUrl);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}