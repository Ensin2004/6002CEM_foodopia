import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/rating.dart';
import '../../../domain/usecases/support/rating/delete_rating_usecase.dart';
import '../../../domain/usecases/support/rating/get_user_rating_usecase.dart';
import '../../../domain/usecases/support/rating/save_rating_usecase.dart';

/// Defines behavior for rate us view model.
class RateUsViewModel extends ChangeNotifier {
  final GetUserRatingUseCase _getUserRatingUseCase;
  final SaveRatingUseCase _saveRatingUseCase;
  final DeleteRatingUseCase _deleteRatingUseCase;
  final String _userId;

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  RatingEntity? _rating;
  int _selectedStars = 0;
  String _comment = '';
  String? _imageUrl;
  bool _isEditing = false;

  /// Creates a rate us view model instance.
  RateUsViewModel({
    required String userId,
    required GetUserRatingUseCase getUserRatingUseCase,
    required SaveRatingUseCase saveRatingUseCase,
    required DeleteRatingUseCase deleteRatingUseCase,
  }) : _userId = userId,
       _getUserRatingUseCase = getUserRatingUseCase,
       _saveRatingUseCase = saveRatingUseCase,
       _deleteRatingUseCase = deleteRatingUseCase {
    /// Loads data for the load rating operation.
    loadRating();
  }

  // Getters
  bool get isLoading => _isLoading;

  /// Handles the is saving operation.
  bool get isSaving => _isSaving;

  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;

  /// Handles the rating operation.
  RatingEntity? get rating => _rating;

  /// Handles the selected stars operation.
  int get selectedStars => _selectedStars;

  /// Handles the comment operation.
  String get comment => _comment;

  /// Handles the image url operation.
  String? get imageUrl => _imageUrl;

  /// Handles the has submitted rating operation.
  bool get hasSubmittedRating => _rating != null;

  /// Handles the is editing operation.
  bool get isEditing => _isEditing;

  /// Handles the is submit disabled operation.
  bool get isSubmitDisabled => _selectedStars == 0 || _isSaving;

  // Load existing rating
  Future<void> loadRating() async {
    _isLoading = true;
    notifyListeners();

    final result = await _getUserRatingUseCase.execute(_userId);

    if (result.isLeft()) {
      final failure = result.left!;
      if (failure is NotFoundFailure) {
        _rating = null;
        _selectedStars = 0;
        _comment = '';
        _imageUrl = null;
      } else {
        _errorMessage = _getErrorMessage(failure);
      }
    } else {
      _rating = result.right;
      _selectedStars = _rating!.stars;
      _comment = _rating!.comment;
      _imageUrl = _rating!.imageUrl;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update stars
  void setStars(int stars) {
    _selectedStars = stars;
    notifyListeners();
  }

  // Update comment
  void setComment(String comment) {
    _comment = comment;
    notifyListeners();
  }

  // Remove stored image
  void removeStoredImage() {
    _imageUrl = null;
    notifyListeners();
  }

  // Start editing
  void startEditing() {
    _isEditing = true;
    notifyListeners();
  }

  // Cancel editing
  void cancelEditing() {
    _isEditing = false;
    _selectedStars = _rating?.stars ?? 0;
    _comment = _rating?.comment ?? '';
    notifyListeners();
  }

  // Save rating
  Future<bool> saveRating({File? imageFile}) async {
    if (_selectedStars == 0) {
      _errorMessage = 'Please select at least 1 star';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    notifyListeners();

    final result = await _saveRatingUseCase.execute(
      userId: _userId,
      stars: _selectedStars,
      comment: _comment,
      imageFile: imageFile,
      existingImageUrl: null,
    );

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    /// Loads data for the load rating operation.
    await loadRating();
    _isEditing = false;
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // Delete rating
  Future<bool> deleteRating() async {
    _isSaving = true;
    notifyListeners();

    final result = await _deleteRatingUseCase.execute(_userId);

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    _rating = null;
    _selectedStars = 0;
    _comment = '';
    _imageUrl = null;
    _isEditing = false;
    _isSaving = false;
    notifyListeners();
    return true;
  }

  /// Handles the get error message operation.
  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.message;
    }
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    return failure.message;
  }

  /// Handles the clear error operation.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
