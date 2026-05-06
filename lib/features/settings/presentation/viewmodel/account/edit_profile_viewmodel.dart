import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/usecases/account/get_user_profile_usecase.dart';
import '../../../domain/usecases/account/update_profile_image_usecase.dart';
import '../../../domain/usecases/account/update_user_age_group_usecase.dart';
import '../../../domain/usecases/account/update_user_gender_usecase.dart';
import '../../../domain/usecases/account/update_user_name_usecase.dart';
import '../../../../auth/domain/usecases/get_age_groups_usecase.dart';

/// Defines behavior for edit profile view model.
class EditProfileViewModel extends ChangeNotifier {
  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateUserNameUseCase _updateUserNameUseCase;
  final UpdateUserGenderUseCase _updateUserGenderUseCase;
  final UpdateUserAgeGroupUseCase _updateUserAgeGroupUseCase;
  final GetAgeGroupsUseCase _getAgeGroupsUseCase;
  final UpdateProfileImageUseCase _updateProfileImageUseCase;
  final String _uid;

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  UserProfile? _profile;
  List<Map<String, dynamic>> _ageGroups = [];

  /// Creates a edit profile view model instance.
  EditProfileViewModel({
    required String uid,
    required GetUserProfileUseCase getUserProfileUseCase,
    required UpdateUserNameUseCase updateUserNameUseCase,
    required UpdateUserGenderUseCase updateUserGenderUseCase,
    required UpdateUserAgeGroupUseCase updateUserAgeGroupUseCase,
    required GetAgeGroupsUseCase getAgeGroupsUseCase,
    required UpdateProfileImageUseCase updateProfileImageUseCase,
  })  : _uid = uid,
        _getUserProfileUseCase = getUserProfileUseCase,
        _updateUserNameUseCase = updateUserNameUseCase,
        _updateUserGenderUseCase = updateUserGenderUseCase,
        _updateUserAgeGroupUseCase = updateUserAgeGroupUseCase,
        _getAgeGroupsUseCase = getAgeGroupsUseCase,
        _updateProfileImageUseCase = updateProfileImageUseCase {
    /// Loads data for the load user profile operation.
    loadUserProfile();
  }

  // Getters
  bool get isLoading => _isLoading;
  /// Handles the is saving operation.
  bool get isSaving => _isSaving;
  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;
  /// Handles the profile operation.
  UserProfile? get profile => _profile;
  /// Handles the display name operation.
  String get displayName => _profile?.name ?? '';
  /// Handles the display gender operation.
  String get displayGender => _profile?.gender ?? '';
  String get displayAgeGroup => _profile?.ageGroupName ?? '';
  String get selectedAgeGroupId => _profile?.ageGroupId ?? '';
  List<Map<String, dynamic>> get ageGroups => _ageGroups;
  /// Handles the has unsaved changes operation.
  bool get hasUnsavedChanges => false; // No unsaved changes because profile data saves immediately

  // Load user profile
  Future<void> loadUserProfile() async {
    _isLoading = true;
    notifyListeners();

    final result = await _getUserProfileUseCase.execute(_uid);
    final ageGroupsResult = await _getAgeGroupsUseCase.execute();

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _isLoading = false;
      notifyListeners();
    } else {
      _profile = result.right;
      ageGroupsResult.fold(
        (_) => _loadDefaultAgeGroups(),
        (ageGroups) {
          _ageGroups = ageGroups.isEmpty ? _defaultAgeGroups() : ageGroups;
        },
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadDefaultAgeGroups() {
    _ageGroups = _defaultAgeGroups();
  }

  List<Map<String, dynamic>> _defaultAgeGroups() {
    return [
      {'id': 'children', 'name': 'Children', 'description': 'Under 13', 'sortOrder': 1, 'isActive': true},
      {'id': 'teens', 'name': 'Teens', 'description': '13-17', 'sortOrder': 2, 'isActive': true},
      {'id': 'young_adults', 'name': 'Young Adults', 'description': '18-25', 'sortOrder': 3, 'isActive': true},
      {'id': 'adults', 'name': 'Adults', 'description': '26-59', 'sortOrder': 4, 'isActive': true},
      {'id': 'seniors', 'name': 'Seniors', 'description': '60+', 'sortOrder': 5, 'isActive': true},
    ];
  }

  // Save name only (called immediately from dialog)
  Future<bool> saveNameOnly(String newName) async {
    _isSaving = true;
    _errorMessage = null;
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
    _errorMessage = null;
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

  Future<bool> saveAgeGroupOnly(String ageGroupId, String ageGroupName) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final ageGroupResult = await _updateUserAgeGroupUseCase.execute(
      uid: _uid,
      ageGroupId: ageGroupId,
      ageGroupName: ageGroupName,
    );

    if (ageGroupResult.isLeft()) {
      _errorMessage = _getErrorMessage(ageGroupResult.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    _profile = _profile?.copyWith(
      ageGroupId: ageGroupId,
      ageGroupName: ageGroupName,
    );
    _isSaving = false;
    notifyListeners();
    return true;
  }

  // Save image only (called immediately after picking)
  Future<bool> saveImageOnly(File imageFile) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final imageResult = await _updateProfileImageUseCase.execute(
      uid: _uid,
      imageFile: imageFile,
    );

    if (imageResult.isLeft()) {
      _errorMessage = _getErrorMessage(imageResult.left!);
      _isSaving = false;
      notifyListeners();
      return false;
    }

    // Reload to get the new image URL.
    await loadUserProfile(); // Reload to get the new image URL
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
      if (failure.message.contains('Cloudinary configuration is missing')) {
        return 'Cloudinary configuration is missing. Run Flutter with '
            '--dart-define-from-file=.env';
      }
      return 'Server error. Please try again later.';
    }
    if (failure is NotFoundFailure) {
      return failure.message;
    }
    return failure.message;
  }
}
