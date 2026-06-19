import 'package:flutter/foundation.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../core/services/shared_prefs_manager.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';

/// Runs the login view model operation.
/// Manages login state, validation, and navigation.
class LoginViewModel extends ChangeNotifier {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// Use case for login.
  final LoginUseCase _loginUseCase;

  /// Repository for authentication operations.
  final AuthRepository _authRepository;

  // =========================================================================
  // STATE
  // =========================================================================

  /// Whether login is in progress.
  bool _isLoading = false;

  /// Error message to display.
  String? _errorMessage;

  /// Whether the password is obscured.
  bool _obscurePassword = true;

  /// The authenticated user.
  UserEntity? _authenticatedUser;

  /// Whether the ViewModel has been disposed.
  bool _isDisposed = false;

  /// Navigation event to emit.
  AuthNavigationEvent? _navigationEvent;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Runs the login view model operation.
  LoginViewModel({
    required LoginUseCase loginUseCase,
    required AuthRepository authRepository,
  }) : _loginUseCase = loginUseCase,
        _authRepository = authRepository;

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// Whether login is in progress.
  bool get isLoading => _isLoading;

  /// Error message to display.
  String? get errorMessage => _errorMessage;

  /// Whether the password is obscured.
  bool get obscurePassword => _obscurePassword;

  /// The authenticated user.
  UserEntity? get authenticatedUser => _authenticatedUser;

  /// One-time navigation event. Returns and clears the event.
  AuthNavigationEvent? get navigationEvent {
    final event = _navigationEvent;
    _navigationEvent = null;
    return event;
  }

  // =========================================================================
  // PASSWORD VISIBILITY
  // =========================================================================

  /// Toggles password text visibility.
  void togglePasswordVisibility() {
    if (_isDisposed) return;
    _obscurePassword = !_obscurePassword;
    _notifyListeners();
  }

  // =========================================================================
  // ERROR HANDLING
  // =========================================================================

  /// Handles the clear error operation.
  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    _notifyListeners();
  }

  // =========================================================================
  // LOGIN
  // =========================================================================

  /// Logs in a user with email and password.
  Future<void> login({required String email, required String password}) async {
    // Return if disposed.
    if (_isDisposed) return;

    // Set loading state.
    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();

    // Execute the use case.
    final result = await _loginUseCase.execute(
      email: email,
      password: password,
    );

    // Return if disposed.
    if (_isDisposed) return;

    // Handle the result.
    await result.fold<Future<void>>(
          (failure) async {
        if (_isDisposed) return;
        _isLoading = false;
        _errorMessage = failure.message;
        _notifyListeners();
      },
          (user) async {
        // Mark onboarding as completed.
        await SharedPrefsManager.setOnboardingCompleted(true);

        if (_isDisposed) return;
        _isLoading = false;
        _authenticatedUser = user;

        // Emit navigation event instead of navigating directly.
        _navigationEvent = AuthNavigationEvent.goToHome;
        _notifyListeners();
      },
    );
  }

  // =========================================================================
  // NAVIGATION
  // =========================================================================

  /// Navigate to signup.
  void goToSignup() {
    if (_isDisposed) return;
    _navigationEvent = AuthNavigationEvent.goToSignup;
    _notifyListeners();
  }

  // =========================================================================
  // EMAIL VERIFICATION
  // =========================================================================

  /// Handles the check email verified operation.
  Future<bool> checkEmailVerified() async {
    final result = await _authRepository.checkEmailVerified();
    return result.fold((failure) => false, (isVerified) => isVerified);
  }

  /// Handles the resend verification email operation.
  Future<void> resendVerificationEmail() async {
    await _authRepository.resendVerificationEmail();
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Notifies listeners if not disposed.
  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // =========================================================================
  // DISPOSAL
  // =========================================================================

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}