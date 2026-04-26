import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../core/utils/role_manager.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../viewmodel/login_viewmodel.dart';
import '../widgets/curved_header.dart';
import 'signup_screen.dart';
import '../widgets/email_verification_dialog.dart';
import '../../../main/presentation/view/main_page.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<LoginViewModel>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    // ✅ Handle navigation events
    final navigationEvent = viewModel.navigationEvent;
    if (navigationEvent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNavigation(context, navigationEvent, viewModel);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              CurvedHeader(
                onLeadingPressed: () => _handleBackPress(context),
                leadingText: "Back",
                onTrailingPressed: () => viewModel.goToSignup(),
                trailingText: "Sign Up",
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTitle(context),
                    const SizedBox(height: 16),
                    _buildEmailField(viewModel),
                    const SizedBox(height: 16),
                    _buildPasswordField(viewModel),
                    if (viewModel.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      _buildErrorMessage(viewModel.errorMessage!),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Login',
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _handleLogin(context, viewModel),
                      isLoading: viewModel.isLoading,
                    ),
                    const SizedBox(height: 16),
                    _buildForgotPasswordLink(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Type-safe navigation handler
  void _handleNavigation(
      BuildContext context,
      AuthNavigationEvent event,
      LoginViewModel viewModel,
      ) {
    switch (event) {
      case AuthNavigationEvent.goToHome:
      // Navigate to home (will be handled by router in future)
        break;
      case AuthNavigationEvent.goToSignup:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        );
        break;
      default:
        break;
    }
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      "Welcome Back",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }

  Widget _buildEmailField(LoginViewModel viewModel) {
    return TextField(
      controller: viewModel.emailController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.email),
        hintText: "Enter your email",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      onChanged: (_) => viewModel.clearError(),
    );
  }

  Widget _buildPasswordField(LoginViewModel viewModel) {
    return TextField(
      controller: viewModel.passwordController,
      obscureText: viewModel.obscurePassword,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock),
        hintText: "Enter your password",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            viewModel.obscurePassword
                ? Icons.visibility_off
                : Icons.visibility,
          ),
          onPressed: viewModel.togglePasswordVisibility,
        ),
      ),
      onChanged: (_) => viewModel.clearError(),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordLink(BuildContext context) {
    return TextButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Forgot password feature coming soon')),
        );
      },
      child: const Text('Forgot Password?'),
    );
  }

  Future<void> _handleLogin(BuildContext context, LoginViewModel viewModel) async {
    final email = viewModel.emailController.text.trim();
    final password = viewModel.passwordController.text.trim();
    await viewModel.login(email: email, password: password);
  }

  void _handleBackPress(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => false),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}