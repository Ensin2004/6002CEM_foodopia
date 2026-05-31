import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/about_content.dart';
import '../../domain/repositories/about_repository.dart';
import '../datasources/about_remote_datasource.dart';
import '../models/about_content_model.dart';

/// Defines behavior for about repository impl.
class AboutRepositoryImpl implements AboutRepository {
  final AboutRemoteDataSource remoteDataSource;

  /// Creates a about repository impl instance.
  AboutRepositoryImpl({required this.remoteDataSource});

  /// Loads data for the get about content operation.
  @override
  Future<Either<Failure, AboutContent>> getAboutContent(
    String documentId,
  ) async {
    try {
      // Runs the guarded operation that can throw.
      final doc = await remoteDataSource.getAboutContent(documentId);

      if (!doc.exists) {
        // Return empty content instead of error, let UI handle creation
        return Right(
          AboutContentModel(
            id: documentId,
            title: _getTitleFromId(documentId),
            content: '',
            updatedAt: null,
          ),
        );
      }

      final content = AboutContentModel.fromFirestore(doc);
      return Right(content);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, AboutContent>> watchAboutContent(
    String documentId,
  ) async* {
    try {
      await for (final doc in remoteDataSource.watchAboutContent(documentId)) {
        if (!doc.exists) {
          yield Right(
            AboutContentModel(
              id: documentId,
              title: _getTitleFromId(documentId),
              content: '',
              updatedAt: null,
            ),
          );
          continue;
        }
        yield Right(AboutContentModel.fromFirestore(doc));
      }
    } catch (error) {
      yield Left(ServerFailure(message: error.toString()));
    }
  }

  /// Handles the get title from id operation.
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

  /// Runs the save about content operation.
  @override
  Future<Either<Failure, void>> saveAboutContent(
    String documentId,
    String content,
  ) async {
    try {
      // Runs the guarded operation that can throw.
      await remoteDataSource.saveAboutContent(documentId, content);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAboutContent(String documentId) async {
    try {
      await remoteDataSource.deleteAboutContent(documentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
