import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/rating.dart';
import '../../../domain/usecases/delete_rating_usecase.dart';
import '../../../domain/usecases/get_user_rating_usecase.dart';
import '../../../domain/usecases/save_rating_usecase.dart';
import '../../../domain/usecases/upload_rating_image_usecase.dart';

class RateUsViewModel extends ChangeNotifier {
  final GetUserRatingUseCase _getUserRatingUseCase;
  final SaveRatingUseCase _saveRatingUseCase;
  final DeleteRatingUseCase _deleteRatingUseCase;
  final UploadRatingImageUseCase _uploadRatingImageUseCase;
  final String _userId;

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  RatingEntity? _rating;
  int _selectedStars = 0;
  String _comment = '';
  String? _imageUrl;
  File? _selectedImageFile;
  bool _isEditing = false;

  RateUsViewModel({
    required String userId,
    required GetUserRatingUseCase getUserRatingUseCase,
    required SaveRatingUseCase saveRatingUseCase,
    required DeleteRatingUseCase deleteRatingUseCase,
    required UploadRatingImageUseCase uploadRatingImageUseCase,
  })  : _userId = userId,
        _getUserRatingUseCase = getUserRatingUseCase,
        _saveRatingUseCase = saveRatingUseCase,
        _deleteRatingUseCase = deleteRatingUseCase,
        _uploadRatingImageUseCase = uploadRatingImageUseCase {
    loadRating();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  RatingEntity? get rating => _rating;
  int get selectedStars => _selectedStars;
  String get comment => _comment;
  String? get imageUrl => _imageUrl;
  File? get selectedImageFile => _selectedImageFile;
  bool get hasSubmittedRating => _rating != null;
  bool get isEditing => _isEditing;
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

  // Pick image
  void pickImage(File imageFile) {
    _selectedImageFile = imageFile;
    notifyListeners();
  }

  // Remove selected image
  void removeSelectedImage() {
    _selectedImageFile = null;
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
    _selectedImageFile = null;
    notifyListeners();
  }

  // Save rating
  Future<bool> saveRating() async {
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
      imageFile: _selectedImageFile,
      existingImageUrl: _imageUrl,
    );

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    await loadRating();
    _selectedImageFile = null;
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
    _selectedImageFile = null;
    _isEditing = false;
    _isSaving = false;
    notifyListeners();
    return true;
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.message;
    }
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    return failure.message;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}