import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

/// Loads the configured age groups used during signup and profile editing.
class GetAgeGroupsUseCase {
  final AuthRepository repository;

  GetAgeGroupsUseCase(this.repository);

  Future<Either<AuthFailure, List<Map<String, dynamic>>>> execute() async {
    return await repository.getAgeGroups();
  }
}
