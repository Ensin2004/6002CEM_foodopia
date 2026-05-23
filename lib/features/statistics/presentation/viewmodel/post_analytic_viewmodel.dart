import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/post_analytic_statistics.dart';
import '../../domain/usecases/get_post_analytic_statistics_usecase.dart';

class PostAnalyticViewModel extends ChangeNotifier {
  final GetPostAnalyticStatisticsUseCase _getStatisticsUseCase;

  PostAnalyticStatistics? _statistics;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedPageIndex = 0;
  int? _expandedCategoryIndex;
  PostAnalyticSortOrder _sortOrder = PostAnalyticSortOrder.highestRating;

  PostAnalyticViewModel({
    required GetPostAnalyticStatisticsUseCase getStatisticsUseCase,
  }) : _getStatisticsUseCase = getStatisticsUseCase {
    Future.microtask(loadStatistics);
  }

  PostAnalyticStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int get selectedPageIndex => _selectedPageIndex;
  int? get expandedCategoryIndex => _expandedCategoryIndex;
  PostAnalyticSortOrder get sortOrder => _sortOrder;

  String get secondarySummaryTitle {
    return _selectedPageIndex == 0 ? 'Average' : 'Highest Rating';
  }

  String get secondarySummaryValue {
    final statistics = _statistics;
    if (statistics == null) return '0';
    if (_selectedPageIndex == 0) {
      return statistics.averageRating.toStringAsFixed(1);
    }

    final highestRating = statistics.categories.fold<double>(
      0,
      (highest, category) =>
          category.averageRating > highest ? category.averageRating : highest,
    );
    return highestRating.toStringAsFixed(1);
  }

  List<PostRatingItem> get sortedPosts => _sortPosts(_statistics?.posts ?? []);

  List<PostRatingCategory> get sortedCategories {
    final categories = [...?_statistics?.categories];
    categories.sort((left, right) {
      switch (_sortOrder) {
        case PostAnalyticSortOrder.highestRating:
          return right.averageRating.compareTo(left.averageRating);
        case PostAnalyticSortOrder.lowestRating:
          return left.averageRating.compareTo(right.averageRating);
        case PostAnalyticSortOrder.mostRating:
          return right.ratedDishCount.compareTo(left.ratedDishCount);
        case PostAnalyticSortOrder.leastRating:
          return left.ratedDishCount.compareTo(right.ratedDishCount);
      }
    });
    return categories;
  }

  Future<void> loadStatistics() async {
    _isLoading = _statistics == null;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getStatisticsUseCase.execute(
      startDate: _startDate,
      endDate: _endDate,
    );
    if (_isDisposed) return;

    result.ifRight((statistics) {
      _statistics = statistics;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  void selectPage(int index) {
    if (_selectedPageIndex == index) return;
    _selectedPageIndex = index;
    _sortOrder = PostAnalyticSortOrder.highestRating;
    _notifyIfActive();
  }

  void setSortOrder(PostAnalyticSortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    _notifyIfActive();
  }

  void toggleCategory(int index) {
    _expandedCategoryIndex = _expandedCategoryIndex == index ? null : index;
    _notifyIfActive();
  }

  List<PostRatingItem> _sortPosts(List<PostRatingItem> posts) {
    final sorted = [...posts];
    sorted.sort((left, right) {
      switch (_sortOrder) {
        case PostAnalyticSortOrder.highestRating:
          return right.rating.compareTo(left.rating);
        case PostAnalyticSortOrder.lowestRating:
          return left.rating.compareTo(right.rating);
        case PostAnalyticSortOrder.mostRating:
          return right.ratingCount.compareTo(left.ratingCount);
        case PostAnalyticSortOrder.leastRating:
          return left.ratingCount.compareTo(right.ratingCount);
      }
    });
    return sorted;
  }

  Future<void> selectDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _startDate = startDate;
    _endDate = endDate;
    await loadStatistics();
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
