// Executes the add faq item use case.

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../entities/faq_item.dart';
import '../../../repositories/faq_repository.dart';

/// Defines behavior for add faq item use case.
/// Handles adding a new FAQ item with validation.
class AddFaqItemUseCase {
  /// Repository instance for data operations.
  final FaqRepository repository;

  /// Creates a add faq item use case instance.
  AddFaqItemUseCase(this.repository);

  /// Validates input and delegates the add faq item request to the repository.
  ///
  /// [question] is the FAQ question text.
  /// [answer] is the FAQ answer text.
  /// [questionImageFile] is an optional image for the question.
  /// [answerImageFile] is an optional image for the answer.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String question,
    required String answer,
    File? questionImageFile,
    File? answerImageFile,
  }) async {
    // Validate the question.
    if (question.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Question cannot be empty'));
    }

    // Validate the answer.
    if (answer.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Answer cannot be empty'));
    }

    // Create the FAQ item.
    final item = FaqItem(
      id: '', // Will be set by Firestore
      question: question.trim(),
      answer: answer.trim(),
      createdAt: DateTime.now(),
    );

    // Delegate to repository to add the item.
    return await repository.addFaqItem(item);
  }
}