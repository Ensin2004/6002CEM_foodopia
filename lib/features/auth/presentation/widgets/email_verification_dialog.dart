import 'dart:async';
import 'package:flutter/material.dart';

class EmailVerificationDialog extends StatefulWidget {
  final VoidCallback onResendPressed;
  final Future<bool> Function() onCheckVerified;

  const EmailVerificationDialog({
    super.key,
    required this.onResendPressed,
    required this.onCheckVerified,
  });

  @override
  State<EmailVerificationDialog> createState() => _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  Timer? _checkTimer;
  Timer? _countdownTimer;
  int _secondsLeft = 30;
  bool _isResendDisabled = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startVerificationCheck();
  }

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

  Future<void> _resendEmail() async {
    if (_isResendDisabled) return;

    setState(() {
      _isResendDisabled = true;
    });

    // Call the callback
    widget.onResendPressed();

    setState(() {
      _secondsLeft = 30;
    });

    _startCountdown();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Text('Email Verification Required'),
          SizedBox(height: 8),
          Icon(Icons.mark_email_read_outlined, color: Colors.blue, size: 100),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please verify your email address to continue.\n\n'
                'A verification link has been sent to your email inbox.\n'
                'This dialog will close automatically once your email is verified.',
          ),
          const SizedBox(height: 16),
          if (_isVerifying)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Text(
              _isResendDisabled
                  ? 'You can request another email in $_secondsLeft seconds'
                  : 'Didn\'t receive the email? Request a new one.',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isResendDisabled ? null : _resendEmail,
          child: const Text('Resend Email'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}