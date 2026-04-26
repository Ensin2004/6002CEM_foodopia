import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/faq_item.dart';
import '../../domain/repositories/faq_repository.dart';
import '../datasources/faq_remote_datasource.dart';
import '../models/faq_item_model.dart';

class FaqRepositoryImpl implements FaqRepository {
  final FaqRemoteDataSource remoteDataSource;

  FaqRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<FaqItem>>> getUserFaqItems() async {
    try {
      final snapshot = await remoteDataSource.getUserFaqItems();
      final items = snapshot.docs
          .map((doc) => FaqItemModel.fromFirestore(doc) as FaqItem)
          .toList();
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FaqItem>>> getAdminFaqItems() async {
    try {
      final snapshot = await remoteDataSource.getAdminFaqItems();
      final items = snapshot.docs
          .map((doc) => FaqItemModel.fromFirestore(doc) as FaqItem)
          .toList();
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addFaqItem(FaqItem item) async {
    try {
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
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFaqItem(FaqItem item) async {
    try {
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
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFaqItem(String id) async {
    try {
      await remoteDataSource.deleteFaqItem(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadFaqImage(File imageFile) async {
    try {
      final imageUrl = await remoteDataSource.uploadFaqImage(imageFile);
      return Right(imageUrl);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}