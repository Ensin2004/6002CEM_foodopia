import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/about_content.dart';
import '../../domain/repositories/about_repository.dart';
import '../datasources/about_remote_datasource.dart';
import '../models/about_content_model.dart';

class AboutRepositoryImpl implements AboutRepository {
  final AboutRemoteDataSource remoteDataSource;

  AboutRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AboutContent>> getAboutContent(String documentId) async {
    try {
      final doc = await remoteDataSource.getAboutContent(documentId);

      if (!doc.exists) {
        // Return empty content instead of error, let UI handle creation
        return Right(AboutContentModel(
          id: documentId,
          title: _getTitleFromId(documentId),
          content: '',
          updatedAt: null,
        ));
      }

      final content = AboutContentModel.fromFirestore(doc);
      return Right(content);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  String _getTitleFromId(String id) {
    switch (id) {
      case 'about_us':
        return 'About Us';
      case 'terms_and_conditions':
        return 'Terms & Conditions';
      case 'privacy_policy':
        return 'Privacy Policy';
      default:
        return id;
    }
  }

  @override
  Future<Either<Failure, void>> saveAboutContent(String documentId, String content) async {
    try {
      await remoteDataSource.saveAboutContent(documentId, content);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}