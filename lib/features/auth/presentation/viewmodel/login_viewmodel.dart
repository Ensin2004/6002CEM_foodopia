import 'package:flutter/material.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final AuthRepository _authRepository;

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Form state
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  // ✅ Navigation event
  AuthNavigationEvent? _navigationEvent;

  LoginViewModel({
    required LoginUseCase loginUseCase,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _authRepository = authRepository;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;

  // ✅ One-time navigation event
  AuthNavigationEvent? get navigationEvent {
    final event = _navigationEvent;
    _navigationEvent = null;
    return event;
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ✅ Login - emits event on success
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _loginUseCase.execute(
      email: email,
      password: password,
    );

    result.fold(
          (failure) {
        _isLoading = false;
        _errorMessage = failure.message;
        notifyListeners();
      },
          (user) {
        _isLoading = false;
        notifyListeners();

        // ✅ Emit navigation event instead of navigating directly
        _navigationEvent = AuthNavigationEvent.goToHome;
        notifyListeners();
      },
    );
  }

  // ✅ Navigate to signup
  void goToSignup() {
    _navigationEvent = AuthNavigationEvent.goToSignup;
    notifyListeners();
  }

  Future<bool> checkEmailVerified() async {
    final result = await _authRepository.checkEmailVerified();
    return result.fold(
          (failure) => false,
          (isVerified) => isVerified,
    );
  }

  Future<void> resendVerificationEmail() async {
    await _authRepository.resendVerificationEmail();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}