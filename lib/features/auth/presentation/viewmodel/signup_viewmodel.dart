import 'package:flutter/foundation.dart';
import 'package:email_validator/email_validator.dart';

import '../../../../core/services/shared_prefs_manager.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_age_groups_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

/// Runs the signup view model operation.
/// Manages signup state, validation, and form submission.
class SignupViewModel extends ChangeNotifier {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// Use case for signup.
  final SignupUseCase _signupUseCase;

  /// Use case for getting age groups.
  final GetAgeGroupsUseCase _getAgeGroupsUseCase;

  /// Repository for authentication operations.
  final AuthRepository _authRepository;

  // =========================================================================
  // FORM STATE
  // =========================================================================

  /// Whether signup is in progress.
  bool _isLoading = false;

  /// Error message to display.
  String? _errorMessage;

  /// Name input value.
  String _name = '';

  /// Email input value.
  String _email = '';

  /// Password input value.
  String _password = '';

  /// Confirm password input value.
  String _confirmPassword = '';

  /// Whether the password is obscured.
  bool _obscurePassword = true;

  /// Whether the confirm password is obscured.
  bool _obscureConfirmPassword = true;

  /// Whether terms are accepted.
  bool _acceptedTerms = false;

  /// Selected gender.
  String _selectedGender = '';

  /// Selected age group ID.
  String? _selectedAgeGroupId;

  /// Selected age group name.
  String? _selectedAgeGroupName;

  /// List of age groups.
  List<Map<String, dynamic>> _ageGroups = [];

  // =========================================================================
  // VALIDATION FLAGS
  // =========================================================================

  /// Whether the name field has been touched.
  bool _nameTouched = false;

  /// Whether the email field has been touched.
  bool _emailTouched = false;

  /// Whether the password field has been touched.
  bool _passwordTouched = false;

  /// Whether the confirm password field has been touched.
  bool _confirmTouched = false;

  /// Whether the gender field has been touched.
  bool _genderTouched = false;

  /// Whether the age group field has been touched.
  bool _ageGroupTouched = false;

  /// Whether the terms field has been touched.
  bool _termsTouched = false;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Runs the signup view model operation.
  SignupViewModel({
    required SignupUseCase signupUseCase,
    required GetAgeGroupsUseCase getAgeGroupsUseCase,
    required AuthRepository authRepository,
  })  : _signupUseCase = signupUseCase,
        _getAgeGroupsUseCase = getAgeGroupsUseCase,
        _authRepository = authRepository;

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// Whether signup is in progress.
  bool get isLoading => _isLoading;

  /// Error message to display.
  String? get errorMessage => _errorMessage;

  /// Whether the password is obscured.
  bool get obscurePassword => _obscurePassword;

  /// Whether the confirm password is obscured.
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  /// Password value.
  String get password => _password;

  /// Whether terms are accepted.
  bool get acceptedTerms => _acceptedTerms;

  /// Selected gender.
  String get selectedGender => _selectedGender;

  /// Selected age group ID.
  String? get selectedAgeGroupId => _selectedAgeGroupId;

  /// Selected age group name.
  String? get selectedAgeGroupName => _selectedAgeGroupName;

  /// List of age groups.
  List<Map<String, dynamic>> get ageGroups => _ageGroups;

  // =========================================================================
  // VALIDATION GETTERS
  // =========================================================================

  /// Whether the name field has been touched.
  bool get nameTouched => _nameTouched;

  /// Whether the email field has been touched.
  bool get emailTouched => _emailTouched;

  /// Whether the password field has been touched.
  bool get passwordTouched => _passwordTouched;

  /// Whether the confirm password field has been touched.
  bool get confirmTouched => _confirmTouched;

  /// Whether the gender field has been touched.
  bool get genderTouched => _genderTouched;

  /// Whether the age group field has been touched.
  bool get ageGroupTouched => _ageGroupTouched;

  /// Whether the terms field has been touched.
  bool get termsTouched => _termsTouched;

  // =========================================================================
  // FORM VALIDATION
  // =========================================================================

  /// Whether the form is valid for submission.
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

  /// Whether the password meets strength requirements.
  bool get _isPasswordValid {
    final password = _password.trim();

    // Check minimum length.
    if (password.length < 12) return false;

    // Check for uppercase letter.
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;

    // Check for lowercase letter.
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;

    // Check for number.
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;

    // Check for special character.
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;

    return true;
  }

  /// Whether the passwords match.
  bool get _doPasswordsMatch {
    return _password.trim() == _confirmPassword.trim();
  }

  // =========================================================================
  // PASSWORD RULES
  // =========================================================================

  /// Returns password strength rules with status indicators.
  List<String> getPasswordRules() {
    final password = _password.trim();
    final rules = <String>[];

    // Return empty if password is empty.
    if (password.isEmpty) {
      return rules;
    }

    // Check length.
    if (password.length < 12) {
      rules.add("• At least 12 characters");
    } else {
      rules.add("✓ At least 12 characters");
    }

    // Check uppercase.
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      rules.add("• One uppercase letter");
    } else {
      rules.add("✓ One uppercase letter");
    }

    // Check lowercase.
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      rules.add("• One lowercase letter");
    } else {
      rules.add("✓ One lowercase letter");
    }

    // Check number.
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      rules.add("• One number");
    } else {
      rules.add("✓ One number");
    }

    // Check special character.
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      rules.add("• One special character");
    } else {
      rules.add("✓ One special character");
    }

    return rules;
  }

  // =========================================================================
  // ERROR MESSAGES
  // =========================================================================

  /// Returns the password error message.
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

  /// Returns the confirm password error message.
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

  /// Returns the email error message.
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

  /// Returns the name error message.
  String? getNameError() {
    if (!_nameTouched) return null;
    if (_name.trim().isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  // =========================================================================
  // FORM ACTIONS
  // =========================================================================

  /// Toggles password visibility.
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Updates the name value.
  void updateName(String value) {
    _name = value;
    notifyListeners();
  }

  /// Updates the email value.
  void updateEmail(String value) {
    _email = value;
    notifyListeners();
  }

  /// Updates the password value.
  void updatePassword(String value) {
    _password = value;
    notifyListeners();
  }

  /// Updates the confirm password value.
  void updateConfirmPassword(String value) {
    _confirmPassword = value;
    notifyListeners();
  }

  /// Toggles confirm password visibility.
  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  /// Toggles terms acceptance.
  void toggleTermsAccepted(bool? value) {
    _acceptedTerms = value ?? false;
    _termsTouched = true;
    notifyListeners();
  }

  /// Selects a gender.
  void selectGender(String gender) {
    _selectedGender = gender;
    _genderTouched = true;
    notifyListeners();
  }

  /// Selects an age group.
  void selectAgeGroup(String id, String name) {
    _selectedAgeGroupId = id;
    _selectedAgeGroupName = name;
    _ageGroupTouched = true;
    notifyListeners();
  }

  // =========================================================================
  // TOUCH HANDLERS
  // =========================================================================

  /// Marks the name field as touched.
  void markNameTouched() {
    _nameTouched = true;
    notifyListeners();
  }

  /// Marks the email field as touched.
  void markEmailTouched() {
    _emailTouched = true;
    notifyListeners();
  }

  /// Marks the password field as touched.
  void markPasswordTouched() {
    _passwordTouched = true;
    notifyListeners();
  }

  /// Marks the confirm password field as touched.
  void markConfirmTouched() {
    _confirmTouched = true;
    notifyListeners();
  }

  /// Marks the gender field as touched.
  void markGenderTouched() {
    _genderTouched = true;
    notifyListeners();
  }

  /// Marks the age group field as touched.
  void markAgeGroupTouched() {
    _ageGroupTouched = true;
    notifyListeners();
  }

  /// Marks the terms field as touched.
  void markTermsTouched() {
    _termsTouched = true;
    notifyListeners();
  }

  /// Clears the error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // =========================================================================
  // AGE GROUPS
  // =========================================================================

  /// Loads age groups from the repository.
  Future<void> loadAgeGroups() async {
    // Execute the use case.
    final result = await _getAgeGroupsUseCase.execute();

    // Handle result.
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

  /// Loads default age groups as fallback.
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

  // =========================================================================
  // SIGNUP
  // =========================================================================

  /// Performs signup with the provided data.
  Future<UserEntity?> signup({
    required String email,
    required String password,
    required String name,
    required String gender,
    required String ageGroupId,
    required String ageGroupName,
  }) async {
    // Mark all fields as touched.
    _nameTouched = true;
    _emailTouched = true;
    _passwordTouched = true;
    _confirmTouched = true;
    _genderTouched = true;
    _ageGroupTouched = true;
    _termsTouched = true;
    notifyListeners();

    // Validate the form.
    if (!isFormValid) {
      _errorMessage = 'Please fill all required fields correctly';
      notifyListeners();
      return null;
    }

    // Set loading state.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Execute the use case.
    final result = await _signupUseCase.execute(
      email: email,
      password: password,
      name: name,
      gender: gender,
      ageGroupId: ageGroupId,
      ageGroupName: ageGroupName,
    );

    // Handle result.
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

  // =========================================================================
  // EMAIL VERIFICATION
  // =========================================================================

  /// Resends the verification email.
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

  /// Checks if the email is verified.
  Future<bool> checkEmailVerified() async {
    final result = await _authRepository.checkEmailVerified();

    return result.fold(
          (failure) => false,
          (isVerified) => isVerified,
    );
  }
}