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

class ForgotPasswordScreen extends StatelessWidget {
  final ForgotPasswordArgs args;

  const ForgotPasswordScreen({
    super.key,
    this.args = const ForgotPasswordArgs(),
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<ForgotPasswordViewModel>(),
      child: _ForgotPasswordView(args: args),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  final ForgotPasswordArgs args;

  const _ForgotPasswordView({required this.args});

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.args.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      'Enter your email',
                      textAlign: TextAlign.center,
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _EmailIcon(showSuccessTick: false),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Enter the email linked to your Foodopia account and a secure password reset link will be sent to your email.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl * 1.5),
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

  Future<void> _handleSubmit(
    BuildContext context,
    ForgotPasswordViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(),
    );

    final email = _emailController.text.trim();
    final sent = await viewModel.requestReset(email);

    if (context.mounted) {
      context.pop();
    }

    if (sent && context.mounted) {
      context.go(
        AppRouter.forgotPasswordSent,
        extra: ForgotPasswordSentArgs(email: email),
      );
    }
  }
}

class ForgotPasswordSentScreen extends StatelessWidget {
  final ForgotPasswordSentArgs args;

  const ForgotPasswordSentScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<ForgotPasswordViewModel>(),
      child: _ForgotPasswordSentView(args: args),
    );
  }
}

class _ForgotPasswordSentView extends StatefulWidget {
  final ForgotPasswordSentArgs args;

  const _ForgotPasswordSentView({required this.args});

  @override
  State<_ForgotPasswordSentView> createState() =>
      _ForgotPasswordSentViewState();
}

class _ForgotPasswordSentViewState extends State<_ForgotPasswordSentView> {
  static const _resendSeconds = 60;

  Timer? _timer;
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
    final viewModel = context.watch<ForgotPasswordViewModel>();
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
                    Text(
                      'Email sent succesfully',
                      textAlign: TextAlign.center,
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _EmailIcon(showSuccessTick: true),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Please check your inbox and spam mail for reset link. If you did not receive any email, you may click on the button below to resend.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium,
                    ),
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

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _resendSeconds);
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

  Future<void> _handleResend(
    BuildContext context,
    ForgotPasswordViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(),
    );

    final sent = await viewModel.requestReset(widget.args.email);

    if (context.mounted) {
      context.pop();
    }

    if (sent && mounted) {
      _startCountdown();
    }
  }
}

class _EmailIcon extends StatelessWidget {
  final bool showSuccessTick;

  const _EmailIcon({required this.showSuccessTick});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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

class _MessageBox extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

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
