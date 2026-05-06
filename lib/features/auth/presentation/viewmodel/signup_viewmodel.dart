import 'package:flutter/foundation.dart';
import 'package:email_validator/email_validator.dart';

import '../../../../core/services/shared_prefs_manager.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_age_groups_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

/// Runs the signup view model operation.
class SignupViewModel extends ChangeNotifier {
  final SignupUseCase _signupUseCase;
  final GetAgeGroupsUseCase _getAgeGroupsUseCase;
  final AuthRepository _authRepository;

  // Form state
  bool _isLoading = false;
  String? _errorMessage;
  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String _selectedGender = '';
  String? _selectedAgeGroupId;
  String? _selectedAgeGroupName;

  List<Map<String, dynamic>> _ageGroups = [];

  // Validation flags
  bool _nameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmTouched = false;
  bool _genderTouched = false;
  bool _ageGroupTouched = false;
  bool _termsTouched = false;

  /// Runs the signup view model operation.
  SignupViewModel({
    required SignupUseCase signupUseCase,
    required GetAgeGroupsUseCase getAgeGroupsUseCase,
    required AuthRepository authRepository,
  })  : _signupUseCase = signupUseCase,
        _getAgeGroupsUseCase = getAgeGroupsUseCase,
        _authRepository = authRepository;

  // Getters
  bool get isLoading => _isLoading;
  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;
  /// Handles the obscure password operation.
  bool get obscurePassword => _obscurePassword;
  /// Handles the obscure confirm password operation.
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  /// Handles the password operation.
  String get password => _password;
  /// Handles the accepted terms operation.
  bool get acceptedTerms => _acceptedTerms;
  /// Handles the selected gender operation.
  String get selectedGender => _selectedGender;
  String? get selectedAgeGroupId => _selectedAgeGroupId;
  String? get selectedAgeGroupName => _selectedAgeGroupName;
  List<Map<String, dynamic>> get ageGroups => _ageGroups;

  // Validation getters
  bool get nameTouched => _nameTouched;
  /// Handles the email touched operation.
  bool get emailTouched => _emailTouched;
  /// Handles the password touched operation.
  bool get passwordTouched => _passwordTouched;
  /// Handles the confirm touched operation.
  bool get confirmTouched => _confirmTouched;
  /// Handles the gender touched operation.
  bool get genderTouched => _genderTouched;
  bool get ageGroupTouched => _ageGroupTouched;
  /// Handles the terms touched operation.
  bool get termsTouched => _termsTouched;

  // Form validation
  bool get isFormValid {
    return _email.trim().isNotEmpty &&
        _name.trim().isNotEmpty &&
        _password.trim().isNotEmpty &&
        _confirmPassword.trim().isNotEmpty &&
        _selectedGender.isNotEmpty &&
        _selectedAgeGroupId != null &&
        _acceptedTerms &&
        _isPasswordValid &&
        _doPasswordsMatch;
  }

  /// Handles the is password valid operation.
  bool get _isPasswordValid {
    final password = _password.trim();
    if (password.length < 12) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    return true;
  }

  /// Handles the do passwords match operation.
  bool get _doPasswordsMatch {
    return _password.trim() == _confirmPassword.trim();
  }

  // Password rules
  List<String> getPasswordRules() {
    final password = _password.trim();
    final rules = <String>[];

    if (password.isEmpty) {
      return rules;
    }

    if (password.length < 12) {
      rules.add("• At least 12 characters");
    } else {
      rules.add("✓ At least 12 characters");
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      rules.add("• One uppercase letter");
    } else {
      rules.add("✓ One uppercase letter");
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      rules.add("• One lowercase letter");
    } else {
      rules.add("✓ One lowercase letter");
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      rules.add("• One number");
    } else {
      rules.add("✓ One number");
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      rules.add("• One special character");
    } else {
      rules.add("✓ One special character");
    }

    return rules;
  }

  // Error messages
  String? getPasswordError() {
    if (!_passwordTouched) return null;
    if (_password.trim().isEmpty) {
      return 'Please enter your password';
    }
    if (!_isPasswordValid) {
      return 'Password does not meet requirements';
    }
    return null;
  }

  /// Loads data for the get confirm password error operation.
  String? getConfirmPasswordError() {
    if (!_confirmTouched) return null;
    if (_confirmPassword.trim().isEmpty) {
      return 'Please confirm your password';
    }
    if (!_doPasswordsMatch) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Loads data for the get email error operation.
  String? getEmailError() {
    if (!_emailTouched) return null;
    final email = _email.trim();
    if (email.isEmpty) {
      return 'Please enter your email';
    }
    if (!EmailValidator.validate(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Loads data for the get name error operation.
  String? getNameError() {
    if (!_nameTouched) return null;
    if (_name.trim().isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  // Actions
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Runs the update name operation.
  void updateName(String value) {
    _name = value;
    notifyListeners();
  }

  /// Runs the update email operation.
  void updateEmail(String value) {
    _email = value;
    notifyListeners();
  }

  /// Runs the update password operation.
  void updatePassword(String value) {
    _password = value;
    notifyListeners();
  }

  /// Runs the update confirm password operation.
  void updateConfirmPassword(String value) {
    _confirmPassword = value;
    notifyListeners();
  }

  /// Toggles confirm password text visibility.
  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  /// Toggles terms acceptance state.
  void toggleTermsAccepted(bool? value) {
    _acceptedTerms = value ?? false;
    _termsTouched = true;
    notifyListeners();
  }

  /// Handles the select gender operation.
  void selectGender(String gender) {
    _selectedGender = gender;
    _genderTouched = true;
    notifyListeners();
  }

  void selectAgeGroup(String id, String name) {
    _selectedAgeGroupId = id;
    _selectedAgeGroupName = name;
    _ageGroupTouched = true;
    notifyListeners();
  }

  // Mark fields as touched
  void markNameTouched() {
    _nameTouched = true;
    notifyListeners();
  }

  /// Handles the mark email touched operation.
  void markEmailTouched() {
    _emailTouched = true;
    notifyListeners();
  }

  /// Handles the mark password touched operation.
  void markPasswordTouched() {
    _passwordTouched = true;
    notifyListeners();
  }

  /// Handles the mark confirm touched operation.
  void markConfirmTouched() {
    _confirmTouched = true;
    notifyListeners();
  }

  /// Handles the mark gender touched operation.
  void markGenderTouched() {
    _genderTouched = true;
    notifyListeners();
  }

  void markAgeGroupTouched() {
    _ageGroupTouched = true;
    notifyListeners();
  }

  /// Handles the mark terms touched operation.
  void markTermsTouched() {
    _termsTouched = true;
    notifyListeners();
  }

  /// Handles the clear error operation.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadAgeGroups() async {
    final result = await _getAgeGroupsUseCase.execute();

    result.fold(
          (failure) {
        debugPrint('Failed to load age groups: ${failure.message}');
        _loadDefaultAgeGroups();
        notifyListeners();
      },
          (ageGroups) {
        if (ageGroups.isEmpty) {
          _loadDefaultAgeGroups();
        } else {
          _ageGroups = ageGroups;
        }
        notifyListeners();
      },
    );
  }

  void _loadDefaultAgeGroups() {
    _ageGroups = [
      {'id': 'children', 'name': 'Children', 'description': 'Under 13', 'sortOrder': 1, 'isActive': true},
      {'id': 'teens', 'name': 'Teens', 'description': '13-17', 'sortOrder': 2, 'isActive': true},
      {'id': 'young_adults', 'name': 'Young Adults', 'description': '18-25', 'sortOrder': 3, 'isActive': true},
      {'id': 'adults', 'name': 'Adults', 'description': '26-59', 'sortOrder': 4, 'isActive': true},
      {'id': 'seniors', 'name': 'Seniors', 'description': '60+', 'sortOrder': 5, 'isActive': true},
    ];
    debugPrint('Loaded ${_ageGroups.length} default age groups');
  }


  // Signup
  Future<UserEntity?> signup({
    required String email,
    required String password,
    required String name,
    required String gender,
    required String ageGroupId,
    required String ageGroupName,
  }) async {
    // Mark all fields as touched
    _nameTouched = true;
    _emailTouched = true;
    _passwordTouched = true;
    _confirmTouched = true;
    _genderTouched = true;
    _ageGroupTouched = true;
    _termsTouched = true;
    notifyListeners();

    // Validate form
    if (!isFormValid) {
      _errorMessage = 'Please fill all required fields correctly';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _signupUseCase.execute(
      email: email,
      password: password,
      name: name,
      gender: gender,
      ageGroupId: ageGroupId,
      ageGroupName: ageGroupName,
    );

    return await result.fold<Future<UserEntity?>>(
          (failure) async {
        _isLoading = false;
        _errorMessage = failure.message;
        notifyListeners();
        return null;
      },
          (user) async {
        await SharedPrefsManager.setOnboardingCompleted(true);
        _isLoading = false;
        notifyListeners();
        return user;
      },
    );
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    final result = await _authRepository.resendVerificationEmail();

    result.fold(
          (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
          (_) {
        debugPrint('Verification email resent successfully');
      },
    );
  }

  // Check if email is verified
  Future<bool> checkEmailVerified() async {
    final result = await _authRepository.checkEmailVerified();

    return result.fold(
          (failure) => false,
          (isVerified) => isVerified,
    );
  }

}
