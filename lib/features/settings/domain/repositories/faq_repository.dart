// Declares repository contracts for faq.

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/faq_item.dart';

/// Defines behavior for faq repository.
abstract class FaqRepository {
  /// Loads data for the get user faq items operation.
  Future<Either<Failure, List<FaqItem>>> getUserFaqItems();
  Stream<Either<Failure, List<FaqItem>>> watchUserFaqItems();

  /// Loads data for the get admin faq items operation.
  Future<Either<Failure, List<FaqItem>>> getAdminFaqItems();
  Stream<Either<Failure, List<FaqItem>>> watchAdminFaqItems();

  /// Handles the add faq item operation.
  Future<Either<Failure, void>> addFaqItem(FaqItem item);

  /// Runs the update faq item operation.
  Future<Either<Failure, void>> updateFaqItem(FaqItem item);

  /// Runs the delete faq item operation.
  Future<Either<Failure, void>> deleteFaqItem(String id);

  /// Runs the upload faq image operation.
  Future<Either<Failure, String>> uploadFaqImage(File imageFile);
}
