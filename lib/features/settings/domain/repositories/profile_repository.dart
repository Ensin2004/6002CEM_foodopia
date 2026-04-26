import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getUserProfile(String uid);
  Future<Either<Failure, void>> updateUserName(String uid, String name);
  Future<Either<Failure, void>> updateUserGender(String uid, String gender);
  Future<Either<Failure, void>> updateProfileImage(String uid, String imageUrl);
}