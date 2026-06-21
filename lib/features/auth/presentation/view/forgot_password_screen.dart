import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../viewmodel/forgot_password_viewmodel.dart';

/// Screen for requesting a password reset.
/// Allows users to enter their email to receive a reset link.
class ForgotPasswordScreen extends StatelessWidget {
  /// Arguments passed to the screen.
  final ForgotPasswordArgs args;

  /// Creates a new forgot password screen instance.
  const ForgotPasswordScreen({
    super.key,
    this.args = const ForgotPasswordArgs(),
  });

  @override
  Widget build(BuildContext context) {
    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => sl<ForgotPasswordViewModel>(),
      child: _ForgotPasswordView(args: args),
    );
  }
}

/// Internal view for the forgot password screen.
class _ForgotPasswordView extends StatefulWidget {
  /// Arguments passed to the screen.
  final ForgotPasswordArgs args;

  /// Creates a new forgot password view instance.
  const _ForgotPasswordView({required this.args});

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

/// State for the forgot password view.
class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  /// Controller for the email input field.
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();

    // Initialize with the email from args if provided.
    _emailController = TextEditingController(text: widget.args.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ForgotPasswordViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Forgot Password',
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.go(AppRouter.login),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title.
                    Text(
                      'Enter your email',
                      textAlign: TextAlign.center,
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Email icon.
                    const _EmailIcon(showSuccessTick: false),
                    const SizedBox(height: AppSpacing.xl),

                    // Description.
                    Text(
                      'Enter the email linked to your Foodopia account and a secure password reset link will be sent to your email.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl * 1.5),

                    // Email input field.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          labelText: 'Email',
                          hintText: 'e.g. john@example.com',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) => viewModel.clearMessages(),
                        onSubmitted: (_) => _handleSubmit(context, viewModel),
                      ),
                    ),

                    // Error message.
                    if (viewModel.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _MessageBox(
                          message: viewModel.errorMessage!,
                          color: Colors.red,
                          icon: Icons.error_outline,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl * 1.5),

                    // Submit button.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: PrimaryButton(
                        text: 'Send Reset Link',
                        onPressed: viewModel.isLoading
                            ? null
                            : () => _handleSubmit(context, viewModel),
                        isLoading: viewModel.isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Handles the submit action.
  Future<void> _handleSubmit(
      BuildContext context,
      ForgotPasswordViewModel viewModel,
      ) async {
    // Show loading dialog.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(),
    );

    // Get the email.
    final email = _emailController.text.trim();

    // Request password reset.
    final sent = await viewModel.requestReset(email);

    // Dismiss loading dialog.
    if (context.mounted) {
      context.pop();
    }

    // Navigate to success screen if sent.
    if (sent && context.mounted) {
      context.go(
        AppRouter.forgotPasswordSent,
        extra: ForgotPasswordSentArgs(email: email),
      );
    }
  }
}

/// Screen shown after the reset email is sent.
class ForgotPasswordSentScreen extends StatelessWidget {
  /// Arguments passed to the screen.
  final ForgotPasswordSentArgs args;

  /// Creates a new forgot password sent screen instance.
  const ForgotPasswordSentScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => sl<ForgotPasswordViewModel>(),
      child: _ForgotPasswordSentView(args: args),
    );
  }
}

/// Internal view for the forgot password sent screen.
class _ForgotPasswordSentView extends StatefulWidget {
  /// Arguments passed to the screen.
  final ForgotPasswordSentArgs args;

  /// Creates a new forgot password sent view instance.
  const _ForgotPasswordSentView({required this.args});

  @override
  State<_ForgotPasswordSentView> createState() =>
      _ForgotPasswordSentViewState();
}

/// State for the forgot password sent view.
class _ForgotPasswordSentViewState extends State<_ForgotPasswordSentView> {
  /// Resend cooldown in seconds.
  static const _resendSeconds = 60;

  /// Timer for the resend cooldown.
  Timer? _timer;

  /// Seconds remaining in the cooldown.
  int _secondsRemaining = _resendSeconds;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ForgotPasswordViewModel>();

    // Check if resend is available.
    final canResend = _secondsRemaining == 0 && !viewModel.isLoading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Forgot Password',
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.go(AppRouter.login),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title.
                    Text(
                      'Email sent succesfully',
                      textAlign: TextAlign.center,
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Email icon with success tick.
                    const _EmailIcon(showSuccessTick: true),
                    const SizedBox(height: AppSpacing.xl),

                    // Instructions.
                    Text(
                      'Please check your inbox and spam mail for reset link. If you did not receive any email, you may click on the button below to resend.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium,
                    ),

                    // Error message.
                    if (viewModel.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _MessageBox(
                          message: viewModel.errorMessage!,
                          color: Colors.red,
                          icon: Icons.error_outline,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl * 1.5),

                    // Resend button.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: PrimaryButton(
                        text: canResend
                            ? 'Resend Email'
                            : 'Resend in $_secondsRemaining s',
                        onPressed: canResend
                            ? () => _handleResend(context, viewModel)
                            : null,
                        isLoading: viewModel.isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Starts the resend cooldown timer.
  void _startCountdown() {
    // Cancel existing timer.
    _timer?.cancel();

    // Reset seconds remaining.
    setState(() => _secondsRemaining = _resendSeconds);

    // Start new timer.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _secondsRemaining = 0);
        return;
      }

      if (mounted) {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  /// Handles the resend action.
  Future<void> _handleResend(
      BuildContext context,
      ForgotPasswordViewModel viewModel,
      ) async {
    // Show loading dialog.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(),
    );

    // Request password reset again.
    final sent = await viewModel.requestReset(widget.args.email);

    // Dismiss loading dialog.
    if (context.mounted) {
      context.pop();
    }

    // Restart countdown if sent.
    if (sent && mounted) {
      _startCountdown();
    }
  }
}

/// Email icon widget with optional success tick.
class _EmailIcon extends StatelessWidget {
  /// Whether to show the success tick.
  final bool showSuccessTick;

  /// Creates a new email icon instance.
  const _EmailIcon({required this.showSuccessTick});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Email icon circle.
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.email_outlined,
                size: 46,
                color: context.colors.primary,
              ),
            ),
          ),
          // Success tick overlay.
          if (showSuccessTick)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

/// Message box widget for displaying errors and info.
class _MessageBox extends StatelessWidget {
  /// Message text.
  final String message;

  /// Color of the message box.
  final Color color;

  /// Icon to display.
  final IconData icon;

  /// Creates a new message box instance.
  const _MessageBox({
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}