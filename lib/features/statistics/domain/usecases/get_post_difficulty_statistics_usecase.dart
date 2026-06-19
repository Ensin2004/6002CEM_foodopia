// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/post_difficulty_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetPostDifficultyStatisticsUseCase for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class GetPostDifficultyStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetPostDifficultyStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
