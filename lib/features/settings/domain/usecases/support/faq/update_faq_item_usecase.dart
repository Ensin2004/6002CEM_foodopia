// Executes the update faq item use case.

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../entities/faq_item.dart';
import '../../../repositories/faq_repository.dart';

/// Runs the update faq item use case operation.
/// Handles updating an existing FAQ item with validation.
class UpdateFaqItemUseCase {
  /// Repository instance for data operations.
  final FaqRepository repository;

  /// Runs the update faq item use case operation.
  UpdateFaqItemUseCase(this.repository);

  /// Validates input and delegates the update faq item request to the repository.
  ///
  /// [id] is the ID of the FAQ item to update.
  /// [question] is the updated question text.
  /// [answer] is the updated answer text.
  /// [existingQuestionImageUrl] is the existing question image URL.
  /// [existingAnswerImageUrl] is the existing answer image URL.
  /// [newQuestionImageFile] is an optional new image for the question.
  /// [newAnswerImageFile] is an optional new image for the answer.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String id,
    required String question,
    required String answer,
    String? existingQuestionImageUrl,
    String? existingAnswerImageUrl,
    File? newQuestionImageFile,
    File? newAnswerImageFile,
  }) async {
    // Validate the ID.
    if (id.isEmpty) {
      return Left(ValidationFailure(message: 'ID cannot be empty'));
    }

    // Validate the question.
    if (question.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Question cannot be empty'));
    }

    // Validate the answer.
    if (answer.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Answer cannot be empty'));
    }

    // Create the updated FAQ item.
    final item = FaqItem(
      id: id,
      question: question.trim(),
      answer: answer.trim(),
      questionImageUrl: existingQuestionImageUrl,
      answerImageUrl: existingAnswerImageUrl,
      createdAt: DateTime.now(),
    );

    // Delegate to repository to update the item.
    return await repository.updateFaqItem(item);
  }
}