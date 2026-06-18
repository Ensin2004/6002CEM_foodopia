import 'dart:async';
import 'package:flutter/material.dart';

/// Defines behavior for email verification dialog.
/// Shows a dialog that checks for email verification status automatically.
class EmailVerificationDialog extends StatefulWidget {
  /// Callback when resend is pressed.
  final VoidCallback onResendPressed;

  /// Callback to check if email is verified.
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
  /// Timer for periodic verification checks.
  Timer? _checkTimer;

  /// Timer for the resend countdown.
  Timer? _countdownTimer;

  /// Seconds remaining in the countdown.
  int _secondsLeft = 30;

  /// Whether the resend button is disabled.
  bool _isResendDisabled = true;

  /// Whether verification is in progress.
  bool _isVerifying = false;

  /// Initializes state before the first widget build.
  @override
  void initState() {
    super.initState();

    // Start the resend countdown.
    _startCountdown();

    // Start periodic verification checks.
    _startVerificationCheck();
  }

  /// Handles the start verification check operation.
  void _startVerificationCheck() {
    // Check every 5 seconds.
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Skip if already verifying.
      if (_isVerifying) return;

      // Set verifying state.
      setState(() => _isVerifying = true);

      // Check if email is verified.
      final isVerified = await widget.onCheckVerified();

      // Reset verifying state.
      setState(() => _isVerifying = false);

      // Close dialog if verified.
      if (isVerified && mounted) {
        // Cancel timers.
        timer.cancel();
        _countdownTimer?.cancel();

        // Pop with true (verified).
        Navigator.of(context, rootNavigator: true).pop(true);
      }
    });
  }

  /// Handles the start countdown operation.
  void _startCountdown() {
    // Reset countdown.
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        // Decrement seconds.
        setState(() => _secondsLeft--);
      } else {
        // Cancel timer and enable resend button.
        timer.cancel();
        setState(() => _isResendDisabled = false);
      }
    });
  }

  /// Handles the resend email operation.
  Future<void> _resendEmail() async {
    // Return if disabled.
    if (_isResendDisabled) return;

    // Disable resend button.
    setState(() {
      _isResendDisabled = true;
    });

    // Call the callback.
    widget.onResendPressed();

    // Reset countdown.
    setState(() {
      _secondsLeft = 30;
    });

    // Start countdown again.
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

          // Loading or status message.
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