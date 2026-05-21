import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../viewmodel/login_viewmodel.dart';
import '../widgets/curved_header.dart';
import '../widgets/email_verification_dialog.dart';

/// Runs the login screen operation.
class LoginScreen extends StatelessWidget {
  /// Runs the login screen operation.
  const LoginScreen({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => sl<LoginViewModel>(),
      child: const _LoginView(),
    );
  }
}

/// Defines behavior for login view.
class _LoginView extends StatefulWidget {
  /// Handles the login view operation.
  const _LoginView();

  /// Creates data for the create state operation.
  @override
  State<_LoginView> createState() => _LoginViewState();
}

/// Defines behavior for login view state.
class _LoginViewState extends State<_LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Releases resources before widget removal.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    // Handle navigation events
    final navigationEvent = viewModel.navigationEvent;
    if (navigationEvent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNavigation(context, navigationEvent, viewModel);
      });
    }

    /// Handles the scaffold operation.
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// Creates a curved header instance.
              CurvedHeader(
                onLeadingPressed: () => _handleBackPress(context),
                leadingText: "Back",
                onTrailingPressed: () => viewModel.goToSignup(),
                trailingText: "Sign Up",
              ),
              /// Creates a padding instance.
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTitle(context),
                    /// Creates a sized box instance.
                    const SizedBox(height: 16),
                    _buildEmailField(viewModel),
                    /// Creates a sized box instance.
                    const SizedBox(height: 16),
                    _buildPasswordField(viewModel),
                    if (viewModel.errorMessage != null) ...[
                      /// Creates a sized box instance.
                      const SizedBox(height: 8),
                      _buildErrorMessage(viewModel.errorMessage!),
                    ],
                    /// Creates a sized box instance.
                    const SizedBox(height: 24),
                    /// Creates a primary button instance.
                    PrimaryButton(
                      text: 'Login',
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _handleLogin(context, viewModel),
                      isLoading: viewModel.isLoading,
                    ),
                    /// Creates a sized box instance.
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

  // Type-safe navigation handler
  void _handleNavigation(
      BuildContext context,
      AuthNavigationEvent event,
      LoginViewModel viewModel,
      ) {
    switch (event) {
      case AuthNavigationEvent.goToHome:
        final user = viewModel.authenticatedUser;
        if (user != null) {
          context.go(
            AppRouter.home,
            extra: HomeArgs(user: user, role: user.role.name),
          );
        }
        break;
      case AuthNavigationEvent.goToSignup:
        context.go(AppRouter.signup);
        break;
      default:
        break;
    }
  }

  /// Handles the build title operation.
  Widget _buildTitle(BuildContext context) {
    /// Handles the text operation.
    return Text(
      "Welcome Back",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }

  /// Handles the build email field operation.
  Widget _buildEmailField(LoginViewModel viewModel) {
    /// Handles the text field operation.
    return TextField(
      controller: _emailController,
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

  /// Handles the build password field operation.
  Widget _buildPasswordField(LoginViewModel viewModel) {
    /// Handles the text field operation.
    return TextField(
      controller: _passwordController,
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

  /// Handles the build error message operation.
  Widget _buildErrorMessage(String message) {
    /// Handles the container operation.
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          /// Creates a icon instance.
          Icon(Icons.error_outline, color: Colors.red.shade700),
          /// Creates a sized box instance.
          const SizedBox(width: 8),
          /// Creates a expanded instance.
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

  /// Handles the build forgot password link operation.
  Widget _buildForgotPasswordLink(BuildContext context) {
    /// Handles the text button operation.
    return TextButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          /// Creates a snack bar instance.
          const SnackBar(content: Text('Forgot password feature coming soon')),
        );
      },
      child: const Text('Forgot Password?'),
    );
  }

  /// Handles the handle login operation.
  Future<void> _handleLogin(BuildContext context, LoginViewModel viewModel) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    await viewModel.login(email: email, password: password);
  }

  /// Handles the handle back press operation.
  void _handleBackPress(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Handles the show exit dialog operation.
  void _showExitDialog(BuildContext context) {
    /// Displays the show dialog flow.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit the app?'),
        actions: [
          /// Creates a text button instance.
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          /// Creates a text button instance.
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => false),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
