import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';

import '../../domain/usecases/request_password_reset_usecase.dart';

/// ViewModel for the Forgot Password feature.
/// Handles password reset request logic and state management.
class ForgotPasswordViewModel extends ChangeNotifier {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// Use case for requesting password reset.
  final RequestPasswordResetUseCase _requestPasswordResetUseCase;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Creates a new forgot password view model instance.
  ForgotPasswordViewModel({
    required RequestPasswordResetUseCase requestPasswordResetUseCase,
  }) : _requestPasswordResetUseCase = requestPasswordResetUseCase;

  // =========================================================================
  // STATE
  // =========================================================================

  /// Whether a request is in progress.
  bool _isLoading = false;

  /// Error message to display.
  String? _errorMessage;

  /// Success message to display.
  String? _successMessage;

  /// Whether the ViewModel has been disposed.
  bool _isDisposed = false;

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// Whether a request is in progress.
  bool get isLoading => _isLoading;

  /// Error message to display.
  String? get errorMessage => _errorMessage;

  /// Success message to display.
  String? get successMessage => _successMessage;

  // =========================================================================
  // REQUEST RESET
  // =========================================================================

  /// Requests a password reset email for the given email address.
  Future<bool> requestReset(String email) async {
    // Trim the email.
    final trimmed = email.trim();

    // Clear previous messages.
    _errorMessage = null;
    _successMessage = null;

    // Validate email is not empty.
    if (trimmed.isEmpty) {
      _errorMessage = 'Please enter your email';
      _notifyIfActive();
      return false;
    }

    // Validate email format.
    if (!EmailValidator.validate(trimmed)) {
      _errorMessage = 'Please enter a valid email address';
      _notifyIfActive();
      return false;
    }

    // Set loading state.
    _isLoading = true;
    _notifyIfActive();

    // Execute the use case.
    final result = await _requestPasswordResetUseCase.execute(email: trimmed);

    // Check if disposed.
    if (_isDisposed) return false;

    // Handle the result.
    var sent = false;
    result.fold(
          (failure) => _errorMessage = failure.message,
          (_) {
        sent = true;
        _successMessage = 'Email sent succesfully';
      },
    );

    // Reset loading state.
    _isLoading = false;
    _notifyIfActive();

    return sent;
  }

  // =========================================================================
  // CLEAR MESSAGES
  // =========================================================================

  /// Clears all error and success messages.
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _notifyIfActive();
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Notifies listeners if the ViewModel is not disposed.
  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
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