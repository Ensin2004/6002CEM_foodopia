import 'package:flutter/foundation.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../core/services/shared_prefs_manager.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';

/// Runs the login view model operation.
class LoginViewModel extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final AuthRepository _authRepository;

  // Form state
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  UserEntity? _authenticatedUser;
  bool _isDisposed = false;

  // Navigation event
  AuthNavigationEvent? _navigationEvent;

  /// Runs the login view model operation.
  LoginViewModel({
    required LoginUseCase loginUseCase,
    required AuthRepository authRepository,
  }) : _loginUseCase = loginUseCase,
       _authRepository = authRepository;

  // Getters
  bool get isLoading => _isLoading;

  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;

  /// Handles the obscure password operation.
  bool get obscurePassword => _obscurePassword;

  /// Handles the authenticated user operation.
  UserEntity? get authenticatedUser => _authenticatedUser;

  // One-time navigation event
  AuthNavigationEvent? get navigationEvent {
    final event = _navigationEvent;
    _navigationEvent = null;
    return event;
  }

  /// Toggles password text visibility.
  void togglePasswordVisibility() {
    if (_isDisposed) return;
    _obscurePassword = !_obscurePassword;
    _notifyListeners();
  }

  /// Handles the clear error operation.
  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    _notifyListeners();
  }

  // Login - emits event on success
  Future<void> login({required String email, required String password}) async {
    if (_isDisposed) return;
    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();

    final result = await _loginUseCase.execute(
      email: email,
      password: password,
    );

    if (_isDisposed) return;
    await result.fold<Future<void>>(
      (failure) async {
        if (_isDisposed) return;
        _isLoading = false;
        _errorMessage = failure.message;
        _notifyListeners();
      },
      (user) async {
        await SharedPrefsManager.setOnboardingCompleted(true);

        if (_isDisposed) return;
        _isLoading = false;
        _authenticatedUser = user;

        // Emit navigation event instead of navigating directly
        _navigationEvent = AuthNavigationEvent.goToHome;
        _notifyListeners();
      },
    );
  }

  // Navigate to signup
  void goToSignup() {
    if (_isDisposed) return;
    _navigationEvent = AuthNavigationEvent.goToSignup;
    _notifyListeners();
  }

  /// Handles the check email verified operation.
  Future<bool> checkEmailVerified() async {
    final result = await _authRepository.checkEmailVerified();
    return result.fold((failure) => false, (isVerified) => isVerified);
  }

  /// Handles the resend verification email operation.
  Future<void> resendVerificationEmail() async {
    await _authRepository.resendVerificationEmail();
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
