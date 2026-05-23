import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_profile.dart';
import '../repositories/library_repository.dart';

class GetLibraryProfileUseCase {
  final LibraryRepository repository;

  const GetLibraryProfileUseCase(this.repository);

  Future<Either<Failure, LibraryProfile>> execute() {
    return repository.getProfile();
  }
}
