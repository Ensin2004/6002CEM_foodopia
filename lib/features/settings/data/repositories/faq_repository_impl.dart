// Implements repository operations for faq.

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/faq_item.dart';
import '../../domain/repositories/faq_repository.dart';
import '../datasources/faq_remote_datasource.dart';
import '../models/faq_item_model.dart';

/// Defines behavior for faq repository impl.
/// Implements the FaqRepository interface using remote data source.
class FaqRepositoryImpl implements FaqRepository {
  /// Remote data source for FAQ operations.
  final FaqRemoteDataSource remoteDataSource;

  /// Creates a faq repository impl instance.
  FaqRepositoryImpl({required this.remoteDataSource});

  /// Loads data for the get user faq items operation.
  @override
  Future<Either<Failure, List<FaqItem>>> getUserFaqItems() async {
    try {
      // Runs the guarded operation that can throw.
      final snapshot = await remoteDataSource.getUserFaqItems();

      // Map Firestore documents to domain entities.
      final items = snapshot.docs
          .map((doc) => FaqItemModel.fromFirestore(doc) as FaqItem)
          .toList();

      return Right(items);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Streams real-time updates for user FAQ items.
  @override
  Stream<Either<Failure, List<FaqItem>>> watchUserFaqItems() async* {
    try {
      // Listen to Firestore snapshots.
      await for (final snapshot in remoteDataSource.watchUserFaqItems()) {
        // Map documents to domain entities.
        final items = snapshot.docs
            .map((doc) => FaqItemModel.fromFirestore(doc) as FaqItem)
            .toList();

        yield Right(items);
      }
    } catch (error) {
      // Map any exception to a server failure.
      yield Left(ServerFailure(message: error.toString()));
    }
  }

  /// Loads data for the get admin faq items operation.
  @override
  Future<Either<Failure, List<FaqItem>>> getAdminFaqItems() async {
    try {
      // Runs the guarded operation that can throw.
      final snapshot = await remoteDataSource.getAdminFaqItems();

      // Map Firestore documents to domain entities.
      final items = snapshot.docs
          .map((doc) => FaqItemModel.fromFirestore(doc) as FaqItem)
          .toList();

      return Right(items);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Streams real-time updates for admin FAQ items.
  @override
  Stream<Either<Failure, List<FaqItem>>> watchAdminFaqItems() async* {
    try {
      // Listen to Firestore snapshots.
      await for (final snapshot in remoteDataSource.watchAdminFaqItems()) {
        // Map documents to domain entities.
        final items = snapshot.docs
            .map((doc) => FaqItemModel.fromFirestore(doc) as FaqItem)
            .toList();

        yield Right(items);
      }
    } catch (error) {
      // Map any exception to a server failure.
      yield Left(ServerFailure(message: error.toString()));
    }
  }

  /// Handles the add faq item operation.
  @override
  Future<Either<Failure, void>> addFaqItem(FaqItem item) async {
    try {
      // Runs the guarded operation that can throw.
      // Convert domain entity to model for Firestore.
      final model = FaqItemModel(
        id: item.id,
        question: item.question,
        answer: item.answer,
        questionImageUrl: item.questionImageUrl,
        answerImageUrl: item.answerImageUrl,
        createdAt: item.createdAt,
      );

      await remoteDataSource.addFaqItem(model.toJson());
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Runs the update faq item operation.
  @override
  Future<Either<Failure, void>> updateFaqItem(FaqItem item) async {
    try {
      // Runs the guarded operation that can throw.
      // Convert domain entity to model for Firestore.
      final model = FaqItemModel(
        id: item.id,
        question: item.question,
        answer: item.answer,
        questionImageUrl: item.questionImageUrl,
        answerImageUrl: item.answerImageUrl,
        createdAt: item.createdAt,
      );

      await remoteDataSource.updateFaqItem(item.id, model.toUpdateJson());
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Runs the delete faq item operation.
  @override
  Future<Either<Failure, void>> deleteFaqItem(String id) async {
    try {
      // Runs the guarded operation that can throw.
      await remoteDataSource.deleteFaqItem(id);
      return const Right(null);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Runs the upload faq image operation.
  @override
  Future<Either<Failure, String>> uploadFaqImage(File imageFile) async {
    try {
      // Runs the guarded operation that can throw.
      final imageUrl = await remoteDataSource.uploadFaqImage(imageFile);
      return Right(imageUrl);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }
}