import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/library_repository.dart';

class UpdateLibraryProfileUseCase {
  final LibraryRepository repository;

  const UpdateLibraryProfileUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String name,
    required String bio,
    File? imageFile,
  }) {
    if (name.trim().isEmpty) {
      return Future.value(
        Left(ValidationFailure(message: 'Please enter your name.')),
      );
    }

    return repository.updateProfile(
      name: name.trim(),
      bio: bio.trim(),
      imageFile: imageFile,
    );
  }
}
