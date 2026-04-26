import 'package:flutter/material.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/rating.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/usecases/get_all_ratings_usecase.dart';
import '../../../domain/usecases/get_user_profile_usecase.dart';

class AdminRateUsViewModel extends ChangeNotifier {
  final GetAllRatingsUseCase _getAllRatingsUseCase;
  final GetUserProfileUseCase _getUserProfileUseCase;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  List<RatingEntity> _ratings = [];
  List<RatingEntity> _filteredRatings = [];
  final Map<String, UserProfile> _userProfiles = {};  // ✅ Use UserProfile directly

  // Filter and sort state
  int _starFilter = 0;
  String _sortOption = 'newest';
  String _searchTerm = '';

  AdminRateUsViewModel({
    required GetAllRatingsUseCase getAllRatingsUseCase,
    required GetUserProfileUseCase getUserProfileUseCase,
  })  : _getAllRatingsUseCase = getAllRatingsUseCase,
        _getUserProfileUseCase = getUserProfileUseCase {
    loadRatings();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RatingEntity> get filteredRatings => _filteredRatings;
  String get sortOption => _sortOption;
  int get starFilter => _starFilter;

  // Rating statistics
  Map<String, dynamic> get ratingStats {
    if (_ratings.isEmpty) {
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }

    final totalRatings = _ratings.length;
    final ratingSum = _ratings.fold<int>(0, (sum, rating) => sum + rating.stars);
    final averageRating = ratingSum / totalRatings;

    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final rating in _ratings) {
      distribution[rating.stars] = distribution[rating.stars]! + 1;
    }

    return {
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'distribution': distribution,
    };
  }

  // Load all ratings
  Future<void> loadRatings() async {
    _isLoading = true;
    notifyListeners();

    final result = await _getAllRatingsUseCase.execute();

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _ratings = [];
    } else {
      _ratings = result.right!;
      await _loadUserProfiles();
    }

    _applyFiltersAndSort();
    _isLoading = false;
    notifyListeners();
  }

  // Load user profiles for all ratings
  Future<void> _loadUserProfiles() async {
    final uniqueUserIds = _ratings.map((r) => r.userId).toSet();
    for (final userId in uniqueUserIds) {
      if (!_userProfiles.containsKey(userId)) {
        final result = await _getUserProfileUseCase.execute(userId);
        if (result.isRight()) {
          final profile = result.right;
          if (profile != null) {
            _userProfiles[userId] = profile;  // ✅ Store UserProfile directly
          }
        }
      }
    }
  }

  // Get user profile by ID - returns UserProfile? instead of Map
  UserProfile? getUserProfile(String userId) {
    return _userProfiles[userId];
  }

  // Apply filters and sorting
  void _applyFiltersAndSort() {
    var filtered = List<RatingEntity>.from(_ratings);

    // Apply star filter
    if (_starFilter > 0) {
      filtered = filtered.where((r) => r.stars == _starFilter).toList();
    }

    // Apply search filter
    if (_searchTerm.isNotEmpty) {
      filtered = filtered.where((r) {
        final profile = _userProfiles[r.userId];
        final name = profile?.name?.toLowerCase() ?? '';
        final email = profile?.email.toLowerCase() ?? '';
        final searchLower = _searchTerm.toLowerCase();
        return name.contains(searchLower) || email.contains(searchLower);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortOption) {
        case 'oldest':
          return a.updatedAt.compareTo(b.updatedAt);
        case '5to1':
          return b.stars.compareTo(a.stars);
        case '1to5':
          return a.stars.compareTo(b.stars);
        default: // 'newest'
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    _filteredRatings = filtered;
    notifyListeners();
  }

  // Set star filter
  void setStarFilter(int stars) {
    _starFilter = stars;
    _applyFiltersAndSort();
  }

  // Set sort option
  void setSortOption(String option) {
    _sortOption = option;
    _applyFiltersAndSort();
  }

  // Set search term
  void setSearchTerm(String term) {
    _searchTerm = term;
    _applyFiltersAndSort();
  }

  String _getErrorMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    return failure.message;
  }
}