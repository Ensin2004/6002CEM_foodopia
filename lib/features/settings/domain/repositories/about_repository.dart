import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/about_content.dart';

abstract class AboutRepository {
  Future<Either<Failure, AboutContent>> getAboutContent(String documentId);
  Future<Either<Failure, void>> saveAboutContent(String documentId, String content); // Changed from update to save
}