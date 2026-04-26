import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/help_center_repository.dart';

class GetUserEmailUseCase {
  final HelpCenterRepository repository;

  GetUserEmailUseCase(this.repository);

  Future<Either<Failure, String>> execute(String uid) async {
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    return await repository.getUserEmail(uid);
  }
}