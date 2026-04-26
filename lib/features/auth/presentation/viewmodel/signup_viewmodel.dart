import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_countries_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

class SignupViewModel extends ChangeNotifier {
  final SignupUseCase _signupUseCase;
  final GetCountriesUseCase _getCountriesUseCase;
  final AuthRepository _authRepository;

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Form state
  bool _isLoading = false;
  String? _errorMessage;
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

  SignupViewModel({
    required SignupUseCase signupUseCase,
    required GetCountriesUseCase getCountriesUseCase,
    required AuthRepository authRepository,
  })  : _signupUseCase = signupUseCase,
        _getCountriesUseCase = getCountriesUseCase,
        _authRepository = authRepository;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get acceptedTerms => _acceptedTerms;
  String get selectedGender => _selectedGender;
  String? get selectedCountryId => _selectedCountryId;
  String? get selectedCountryName => _selectedCountryName;
  String? get selectedCurrency => _selectedCurrency;
  List<Map<String, dynamic>> get countries => _countries;

  // Validation getters
  bool get nameTouched => _nameTouched;
  bool get emailTouched => _emailTouched;
  bool get passwordTouched => _passwordTouched;
  bool get confirmTouched => _confirmTouched;
  bool get genderTouched => _genderTouched;
  bool get countryTouched => _countryTouched;
  bool get termsTouched => _termsTouched;

  // Form validation
  bool get isFormValid {
    return emailController.text.trim().isNotEmpty &&
        nameController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        confirmPasswordController.text.trim().isNotEmpty &&
        _selectedGender.isNotEmpty &&
        _selectedCountryId != null &&
        _acceptedTerms &&
        _isPasswordValid &&
        _doPasswordsMatch;
  }

  bool get _isPasswordValid {
    final password = passwordController.text.trim();
    if (password.length < 12) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    return true;
  }

  bool get _doPasswordsMatch {
    return passwordController.text.trim() == confirmPasswordController.text.trim();
  }

  // Password rules
  List<String> getPasswordRules() {
    final password = passwordController.text.trim();
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
    if (passwordController.text.trim().isEmpty) {
      return 'Please enter your password';
    }
    if (!_isPasswordValid) {
      return 'Password does not meet requirements';
    }
    return null;
  }

  String? getConfirmPasswordError() {
    if (!_confirmTouched) return null;
    if (confirmPasswordController.text.trim().isEmpty) {
      return 'Please confirm your password';
    }
    if (!_doPasswordsMatch) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? getEmailError() {
    if (!_emailTouched) return null;
    final email = emailController.text.trim();
    if (email.isEmpty) {
      return 'Please enter your email';
    }
    if (!EmailValidator.validate(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? getNameError() {
    if (!_nameTouched) return null;
    if (nameController.text.trim().isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  // Actions
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void toggleTermsAccepted(bool? value) {
    _acceptedTerms = value ?? false;
    _termsTouched = true;
    notifyListeners();
  }

  void selectGender(String gender) {
    _selectedGender = gender;
    _genderTouched = true;
    notifyListeners();
  }

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

  void markEmailTouched() {
    _emailTouched = true;
    notifyListeners();
  }

  void markPasswordTouched() {
    _passwordTouched = true;
    notifyListeners();
  }

  void markConfirmTouched() {
    _confirmTouched = true;
    notifyListeners();
  }

  void markGenderTouched() {
    _genderTouched = true;
    notifyListeners();
  }

  void markCountryTouched() {
    _countryTouched = true;
    notifyListeners();
  }

  void markTermsTouched() {
    _termsTouched = true;
    notifyListeners();
  }

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
        _loadMockCountries();  // ✅ Load mock data
        notifyListeners();
      },
          (countries) {
        if (countries.isEmpty) {
          _loadMockCountries();  // ✅ Load mock data if empty
        } else {
          _countries = countries;
        }
        notifyListeners();
      },
    );
  }

// ✅ Add this method to provide mock country data
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

    return result.fold(
          (failure) {
        _isLoading = false;
        _errorMessage = failure.message;
        notifyListeners();
        return null;
      },
          (user) {
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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}