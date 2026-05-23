import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/post_difficulty_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetPostDifficultyStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetPostDifficultyStatisticsUseCase(this._repository);

  Future<Either<Failure, PostDifficultyStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getPostDifficulty(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
