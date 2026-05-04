import 'package:flutter/foundation.dart';
import 'package:email_validator/email_validator.dart';

import '../../../../core/services/shared_prefs_manager.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_countries_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

/// Runs the signup view model operation.
class SignupViewModel extends ChangeNotifier {
  final SignupUseCase _signupUseCase;
  final GetCountriesUseCase _getCountriesUseCase;
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
  String? _selectedCountryId;
  String? _selectedCountryName;
  String? _selectedCurrency;

  // Countries list
  List<Map<String, dynamic>> _countries = [];

  // Validation flags
  bool _nameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmTouched = false;
  bool _genderTouched = false;
  bool _countryTouched = false;
  bool _termsTouched = false;

  /// Runs the signup view model operation.
  SignupViewModel({
    required SignupUseCase signupUseCase,
    required GetCountriesUseCase getCountriesUseCase,
    required AuthRepository authRepository,
  })  : _signupUseCase = signupUseCase,
        _getCountriesUseCase = getCountriesUseCase,
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
  /// Handles the selected country id operation.
  String? get selectedCountryId => _selectedCountryId;
  /// Handles the selected country name operation.
  String? get selectedCountryName => _selectedCountryName;
  /// Handles the selected currency operation.
  String? get selectedCurrency => _selectedCurrency;
  /// Handles the countries operation.
  List<Map<String, dynamic>> get countries => _countries;

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
  /// Handles the country touched operation.
  bool get countryTouched => _countryTouched;
  /// Handles the terms touched operation.
  bool get termsTouched => _termsTouched;

  // Form validation
  bool get isFormValid {
    return _email.trim().isNotEmpty &&
        _name.trim().isNotEmpty &&
        _password.trim().isNotEmpty &&
        _confirmPassword.trim().isNotEmpty &&
        _selectedGender.isNotEmpty &&
        _selectedCountryId != null &&
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

  /// Handles the select country operation.
  void selectCountry(String id, String name, String currency) {
    _selectedCountryId = id;
    _selectedCountryName = name;
    _selectedCurrency = currency;
    _countryTouched = true;
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

  /// Handles the mark country touched operation.
  void markCountryTouched() {
    _countryTouched = true;
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

  // Load countries from Firestore
  Future<void> loadCountries() async {
    final result = await _getCountriesUseCase.execute();

    result.fold(
          (failure) {
        // If Firestore fails, use mock data
        print('⚠️ Failed to load countries: ${failure.message}');
        _loadMockCountries();  // Loads mock data
        notifyListeners();
      },
          (countries) {
        if (countries.isEmpty) {
          _loadMockCountries();  // Loads mock data if empty
        } else {
          _countries = countries;
        }
        notifyListeners();
      },
    );
  }

// Adds this method to provide mock country data
  void _loadMockCountries() {
    _countries = [
      {'id': '1', 'country': 'United States', 'currency': 'USD'},
      {'id': '2', 'country': 'United Kingdom', 'currency': 'GBP'},
      {'id': '3', 'country': 'Canada', 'currency': 'CAD'},
      {'id': '4', 'country': 'Australia', 'currency': 'AUD'},
      {'id': '5', 'country': 'Germany', 'currency': 'EUR'},
      {'id': '6', 'country': 'France', 'currency': 'EUR'},
      {'id': '7', 'country': 'Japan', 'currency': 'JPY'},
      {'id': '8', 'country': 'Singapore', 'currency': 'SGD'},
      {'id': '9', 'country': 'Malaysia', 'currency': 'MYR'},
      {'id': '10', 'country': 'Thailand', 'currency': 'THB'},
      {'id': '11', 'country': 'Vietnam', 'currency': 'VND'},
      {'id': '12', 'country': 'Indonesia', 'currency': 'IDR'},
      {'id': '13', 'country': 'Philippines', 'currency': 'PHP'},
      {'id': '14', 'country': 'India', 'currency': 'INR'},
      {'id': '15', 'country': 'Brazil', 'currency': 'BRL'},
    ];
    print('📱 Loaded ${_countries.length} mock countries');
  }


  // Signup
  Future<UserEntity?> signup({
    required String email,
    required String password,
    required String name,
    required String gender,
    required String countryId,
  }) async {
    // Mark all fields as touched
    _nameTouched = true;
    _emailTouched = true;
    _passwordTouched = true;
    _confirmTouched = true;
    _genderTouched = true;
    _countryTouched = true;
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
      countryId: countryId,
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
