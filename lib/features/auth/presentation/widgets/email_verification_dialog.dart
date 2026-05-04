import 'dart:async';
import 'package:flutter/material.dart';

/// Defines behavior for email verification dialog.
class EmailVerificationDialog extends StatefulWidget {
  final VoidCallback onResendPressed;
  /// Handles the function operation.
  final Future<bool> Function() onCheckVerified;

  /// Creates a email verification dialog instance.
  const EmailVerificationDialog({
    super.key,
    required this.onResendPressed,
    required this.onCheckVerified,
  });

  /// Creates data for the create state operation.
  @override
  State<EmailVerificationDialog> createState() => _EmailVerificationDialogState();
}

/// Defines behavior for email verification dialog state.
class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  Timer? _checkTimer;
  Timer? _countdownTimer;
  int _secondsLeft = 30;
  bool _isResendDisabled = true;
  bool _isVerifying = false;

  /// Initializes state before the first widget build.
  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startVerificationCheck();
  }

  /// Handles the start verification check operation.
  void _startVerificationCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isVerifying) return;

      setState(() => _isVerifying = true);
      final isVerified = await widget.onCheckVerified();
      setState(() => _isVerifying = false);

      if (isVerified && mounted) {
        timer.cancel();
        _countdownTimer?.cancel();
        Navigator.of(context, rootNavigator: true).pop(true);
      }
    });
  }

  /// Handles the start countdown operation.
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        setState(() => _isResendDisabled = false);
      }
    });
  }

  /// Handles the resend email operation.
  Future<void> _resendEmail() async {
    if (_isResendDisabled) return;

    setState(() {
      // Updates state values displayed by the current screen.
      _isResendDisabled = true;
    });

    // Call the callback
    widget.onResendPressed();

    setState(() {
      // Updates state values displayed by the current screen.
      _secondsLeft = 30;
    });

    _startCountdown();
  }

  /// Releases resources before widget removal.
  @override
  void dispose() {
    _checkTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the alert dialog operation.
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          /// Creates a text instance.
          Text('Email Verification Required'),
          /// Creates a sized box instance.
          SizedBox(height: 8),
          /// Creates a icon instance.
          Icon(Icons.mark_email_read_outlined, color: Colors.blue, size: 100),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Creates a text instance.
          const Text(
            'Please verify your email address to continue.\n\n'
                'A verification link has been sent to your email inbox.\n'
                'This dialog will close automatically once your email is verified.',
          ),
          /// Creates a sized box instance.
          const SizedBox(height: 16),
          if (_isVerifying)
            /// Creates a center instance.
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            /// Creates a text instance.
            Text(
              _isResendDisabled
                  ? 'You can request another email in $_secondsLeft seconds'
                  : 'Didn\'t receive the email? Request a new one.',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      actions: [
        /// Creates a text button instance.
        TextButton(
          onPressed: _isResendDisabled ? null : _resendEmail,
          child: const Text('Resend Email'),
        ),
        /// Creates a text button instance.
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
