import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/faq_item.dart';

abstract class FaqRepository {
  Future<Either<Failure, List<FaqItem>>> getUserFaqItems();
  Future<Either<Failure, List<FaqItem>>> getAdminFaqItems();
  Future<Either<Failure, void>> addFaqItem(FaqItem item);
  Future<Either<Failure, void>> updateFaqItem(FaqItem item);
  Future<Either<Failure, void>> deleteFaqItem(String id);
  Future<Either<Failure, String>> uploadFaqImage(File imageFile);
}