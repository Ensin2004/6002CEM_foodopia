import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/usecases/get_user_profile_usecase.dart';
import '../../../domain/usecases/update_profile_image_usecase.dart';
import '../../../domain/usecases/update_user_gender_usecase.dart';
import '../../../domain/usecases/update_user_name_usecase.dart';

class EditProfileViewModel extends ChangeNotifier {
  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateUserNameUseCase _updateUserNameUseCase;
  final UpdateUserGenderUseCase _updateUserGenderUseCase;
  final UpdateProfileImageUseCase _updateProfileImageUseCase;
  final String _uid;

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  UserProfile? _profile;
  File? _selectedImage;
  String? _tempName;
  String? _tempGender;

  EditProfileViewModel({
    required String uid,
    required GetUserProfileUseCase getUserProfileUseCase,
    required UpdateUserNameUseCase updateUserNameUseCase,
    required UpdateUserGenderUseCase updateUserGenderUseCase,
    required UpdateProfileImageUseCase updateProfileImageUseCase,
  })  : _uid = uid,
        _getUserProfileUseCase = getUserProfileUseCase,
        _updateUserNameUseCase = updateUserNameUseCase,
        _updateUserGenderUseCase = updateUserGenderUseCase,
        _updateProfileImageUseCase = updateProfileImageUseCase {
    loadUserProfile();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  UserProfile? get profile => _profile;
  File? get selectedImage => _selectedImage;
  String get displayName => _profile?.name ?? '';
  String get displayGender => _profile?.gender ?? '';
  bool get hasUnsavedChanges => false; // No unsaved changes since we save immediately

  // Load user profile
  Future<void> loadUserProfile() async {
    _isLoading = true;
    notifyListeners();

    final result = await _getUserProfileUseCase.execute(_uid);

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _isLoading = false;
      notifyListeners();
    } else {
      _profile = result.right;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Pick image from gallery (just selects, doesn't save)
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  // Save name only (called immediately from dialog)
  Future<bool> saveNameOnly(String newName) async {
    _isSaving = true;
    notifyListeners();

    final nameResult = await _updateUserNameUseCase.execute(
      uid: _uid,
      name: newName,
    );

    if (nameResult.isLeft()) {
      _errorMessage = _getErrorMessage(nameResult.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    // Update local profile with new name
    _profile = _profile?.copyWith(name: newName);
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // Save gender only (called immediately from dialog)
  Future<bool> saveGenderOnly(String newGender) async {
    _isSaving = true;
    notifyListeners();

    final genderResult = await _updateUserGenderUseCase.execute(
      uid: _uid,
      gender: newGender,
    );

    if (genderResult.isLeft()) {
      _errorMessage = _getErrorMessage(genderResult.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    // Update local profile with new gender
    _profile = _profile?.copyWith(gender: newGender);
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // Save image only (called immediately after picking)
  Future<bool> saveImageOnly() async {
    if (_selectedImage == null) return false;

    _isSaving = true;
    notifyListeners();

    final imageResult = await _updateProfileImageUseCase.execute(
      uid: _uid,
      imageFile: _selectedImage!,
    );

    if (imageResult.isLeft()) {
      _errorMessage = _getErrorMessage(imageResult.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    // Update local profile with new image URL (will be reloaded, but we can clear selected)
    await loadUserProfile(); // Reload to get the new image URL
    _selectedImage = null;
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get user-friendly error message
  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.message;
    }
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    if (failure is ServerFailure) {
      return 'Server error. Please try again later.';
    }
    if (failure is NotFoundFailure) {
      return failure.message;
    }
    return failure.message;
  }
}