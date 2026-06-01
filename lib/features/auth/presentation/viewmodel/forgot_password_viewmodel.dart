import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';

import '../../domain/usecases/request_password_reset_usecase.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final RequestPasswordResetUseCase _requestPasswordResetUseCase;

  ForgotPasswordViewModel({
    required RequestPasswordResetUseCase requestPasswordResetUseCase,
  }) : _requestPasswordResetUseCase = requestPasswordResetUseCase;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> requestReset(String email) async {
    final trimmed = email.trim();
    _errorMessage = null;
    _successMessage = null;

    if (trimmed.isEmpty) {
      _errorMessage = 'Please enter your email';
      _notifyIfActive();
      return false;
    }

    if (!EmailValidator.validate(trimmed)) {
      _errorMessage = 'Please enter a valid email address';
      _notifyIfActive();
      return false;
    }

    _isLoading = true;
    _notifyIfActive();

    final result = await _requestPasswordResetUseCase.execute(email: trimmed);
    if (_isDisposed) return false;

    var sent = false;
    result.fold((failure) => _errorMessage = failure.message, (_) {
      sent = true;
      _successMessage = 'Email sent succesfully';
    });

    _isLoading = false;
    _notifyIfActive();
    return sent;
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _notifyIfActive();
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
