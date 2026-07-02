import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/library_repository.dart';
// Use case for updating the current user's profile information
// This class encapsulates the business logic for updating profile details
class UpdateLibraryProfileUseCase {
  final LibraryRepository repository;

  const UpdateLibraryProfileUseCase(this.repository);
// Executes the use case to update the user's profile
  Future<Either<Failure, void>> execute({
    required String name,
    required String bio,
    File? imageFile,
  }) {
    // Validate the name is not empty or just space
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
