import 'package:flutter/foundation.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../domain/usecases/account/change_password_usecase.dart';

/// Runs the change password view model operation.
class ChangePasswordViewModel extends ChangeNotifier {
  final ChangePasswordUseCase _changePasswordUseCase;

  // Form state
  bool _isLoading = false;
  String? _errorMessage;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  /// Runs the change password view model operation.
  ChangePasswordViewModel({
    required ChangePasswordUseCase changePasswordUseCase,
  }) : _changePasswordUseCase = changePasswordUseCase;

  // Getters
  bool get isLoading => _isLoading;

  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;

  /// Displays the show current password flow.
  bool get showCurrentPassword => _showCurrentPassword;

  /// Displays the show new password flow.
  bool get showNewPassword => _showNewPassword;

  /// Displays the show confirm password flow.
  bool get showConfirmPassword => _showConfirmPassword;

  // Toggle password visibility
  void toggleCurrentPasswordVisibility() {
    _showCurrentPassword = !_showCurrentPassword;
    notifyListeners();
  }

  /// Toggles new password text visibility.
  void toggleNewPasswordVisibility() {
    _showNewPassword = !_showNewPassword;
    notifyListeners();
  }

  /// Toggles confirm password text visibility.
  void toggleConfirmPasswordVisibility() {
    _showConfirmPassword = !_showConfirmPassword;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Password validation
  String? validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your current password';
    }
    return null;
  }

  /// Handles the validate new password operation.
  String? validateNewPassword(String? value, {String? currentPassword}) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (currentPassword != null && value == currentPassword) {
      return 'New password cannot be the same as current password';
    }
    if (!_isStrongPassword(value)) {
      return 'Password must meet all requirements below';
    }
    return null;
  }

  /// Handles the validate confirm password operation.
  String? validateConfirmPassword(String? value, String newPassword) {
    if (value != newPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Get password strength rules
  List<String> getPasswordRules(String password) {
    final rules = <String>[];

    if (password.isEmpty) return rules;

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

  /// Handles the is strong password operation.
  bool _isStrongPassword(String password) {
    return password.length >= 12 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _changePasswordUseCase.execute(
      currentPassword: currentPassword.trim(),
      newPassword: newPassword.trim(),
    );

    if (result.isLeft()) {
      _errorMessage = _getErrorMessage(result.left!);
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Handles the get error message operation.
  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.message;
    }
    if (failure is AuthFailure) {
      return failure.message;
    }
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    return failure.message;
  }
}
