import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/auth/role_manager.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../viewmodel/signup_viewmodel.dart';
import '../widgets/age_group_picker_dialog.dart';
import '../widgets/curved_header.dart';
import '../widgets/email_verification_dialog.dart';

/// Runs the signup screen operation.
class SignupScreen extends StatelessWidget {
  /// Runs the signup screen operation.
  const SignupScreen({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => sl<SignupViewModel>(),
      child: const _SignupView(),
    );
  }
}

/// Defines behavior for signup view.
class _SignupView extends StatefulWidget {
  /// Handles the signup view operation.
  const _SignupView();

  /// Creates data for the create state operation.
  @override
  State<_SignupView> createState() => _SignupViewState();
}

/// Defines behavior for signup view state.
class _SignupViewState extends State<_SignupView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// Initializes state before the first widget build.
  @override
  void initState() {
    super.initState();
    // Load age groups when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SignupViewModel>().loadAgeGroups();
    });
  }

  /// Releases resources before widget removal.
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignupViewModel>();

    /// Handles the scaffold operation.
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// Creates a curved header instance.
              CurvedHeader(
                onLeadingPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRouter.login);
                  }
                },
                leadingText: "Back",
                onTrailingPressed: () => context.go(AppRouter.login),
                trailingText: "Login",
              ),

              /// Creates a padding instance.
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTitle(context),

                    /// Creates a sized box instance.
                    const SizedBox(height: 16),

                    // Email Field
                    _buildEmailField(viewModel),

                    /// Creates a sized box instance.
                    const SizedBox(height: 16),

                    // Name Field
                    _buildNameField(viewModel),

                    /// Creates a sized box instance.
                    const SizedBox(height: 16),

                    // Gender Field
                    _buildGenderField(viewModel),

                    /// Creates a sized box instance.
                    const SizedBox(height: 16),

                    // Age Group Field
                    _buildAgeGroupField(viewModel),

                    /// Creates a sized box instance.
                    const SizedBox(height: 16),

                    // Password Field
                    _buildPasswordField(viewModel),

                    /// Creates a sized box instance.
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    _buildConfirmPasswordField(viewModel),

                    /// Creates a sized box instance.
                    const SizedBox(height: 16),

                    // Terms and Conditions
                    _buildTermsField(viewModel),

                    /// Creates a sized box instance.
                    const SizedBox(height: 24),

                    // Error Message
                    if (viewModel.errorMessage != null)
                      _buildErrorMessage(viewModel.errorMessage!),

                    /// Creates a sized box instance.
                    const SizedBox(height: 16),

                    // Sign Up Button
                    PrimaryButton(
                      text: 'Sign Up',
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _handleSignup(context, viewModel),
                      isLoading: viewModel.isLoading,
                    ),

                    /// Creates a sized box instance.
                    const SizedBox(height: 16),

                    // Login Link
                    _buildLoginLink(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles the build title operation.
  Widget _buildTitle(BuildContext context) {
    /// Handles the text operation.
    return Text(
      "Create Account",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }

  /// Handles the build email field operation.
  Widget _buildEmailField(SignupViewModel viewModel) {
    /// Handles the column operation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Creates a text instance.
        const Text("Email"),

        /// Creates a sized box instance.
        const SizedBox(height: 8),

        /// Creates a text field instance.
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email),
            hintText: "e.g. john@example.com",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _emailController.clear();
                viewModel.updateEmail('');
              },
            ),
          ),
          onChanged: (value) {
            viewModel.updateEmail(value);
            viewModel.clearError();
            viewModel.markEmailTouched();
          },
          onTap: () => viewModel.markEmailTouched(),
        ),
        if (viewModel.getEmailError() != null)
          /// Creates a padding instance.
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              viewModel.getEmailError()!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// Handles the build name field operation.
  Widget _buildNameField(SignupViewModel viewModel) {
    /// Handles the column operation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Creates a text instance.
        const Text("Full Name"),

        /// Creates a sized box instance.
        const SizedBox(height: 8),

        /// Creates a text field instance.
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person),
            hintText: "e.g. John Doe",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _nameController.clear();
                viewModel.updateName('');
              },
            ),
          ),
          onChanged: (value) {
            viewModel.updateName(value);
            viewModel.clearError();
            viewModel.markNameTouched();
          },
          onTap: () => viewModel.markNameTouched(),
        ),
        if (viewModel.getNameError() != null)
          /// Creates a padding instance.
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              viewModel.getNameError()!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// Handles the build gender field operation.
  Widget _buildGenderField(SignupViewModel viewModel) {
    /// Handles the column operation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Creates a text instance.
        const Text("Gender"),

        /// Creates a sized box instance.
        const SizedBox(height: 8),

        /// Creates a row instance.
        Row(
          children: [
            /// Creates a expanded instance.
            Expanded(
              child: _buildGenderButton(
                label: "Male",
                value: "male",
                selected: viewModel.selectedGender == "male",
                onTap: () => viewModel.selectGender("male"),
              ),
            ),

            /// Creates a sized box instance.
            const SizedBox(width: 8),

            /// Creates a expanded instance.
            Expanded(
              child: _buildGenderButton(
                label: "Female",
                value: "female",
                selected: viewModel.selectedGender == "female",
                onTap: () => viewModel.selectGender("female"),
              ),
            ),
          ],
        ),
        if (viewModel.genderTouched && viewModel.selectedGender.isEmpty)
          /// Creates a padding instance.
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Please select your gender',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// Handles the build gender button operation.
  Widget _buildGenderButton({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    /// Handles the gesture detector operation.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSecondary,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeGroupField(SignupViewModel viewModel) {
    /// Handles the column operation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Creates a text instance.
        const Text("Age Group"),

        /// Creates a sized box instance.
        const SizedBox(height: 8),
        if (viewModel.ageGroups.isEmpty)
          /// Creates a linear progress indicator instance.
          const LinearProgressIndicator()
        else
          /// Creates a gesture detector instance.
          GestureDetector(
            onTap: () async {
              final picked = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (_) => AgeGroupPickerDialog(
                  items: viewModel.ageGroups,
                  selectedId: viewModel.selectedAgeGroupId,
                ),
              );
              if (picked != null) {
                viewModel.selectAgeGroup(picked['id'], picked['name']);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                viewModel.selectedAgeGroupName ?? "Select your age group",
                style: TextStyle(
                  color: viewModel.selectedAgeGroupName != null
                      ? Theme.of(context).colorScheme.onSecondary
                      : Colors.grey,
                ),
              ),
            ),
          ),
        if (viewModel.ageGroupTouched && viewModel.selectedAgeGroupId == null)
          /// Creates a padding instance.
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Please select your age group',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// Handles the build password field operation.
  Widget _buildPasswordField(SignupViewModel viewModel) {
    /// Handles the column operation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Creates a text instance.
        const Text("Password"),

        /// Creates a sized box instance.
        const SizedBox(height: 8),

        /// Creates a text field instance.
        TextField(
          controller: _passwordController,
          obscureText: viewModel.obscurePassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock),
            hintText: "Create a strong password",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(
                viewModel.obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: viewModel.togglePasswordVisibility,
            ),
          ),
          onChanged: (value) {
            viewModel.updatePassword(value);
            viewModel.clearError();
            viewModel.markPasswordTouched();
          },
          onTap: () => viewModel.markPasswordTouched(),
        ),
        // Password strength indicator
        if (viewModel.password.isNotEmpty)
          /// Creates a padding instance.
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: viewModel.getPasswordRules().map((rule) {
                /// Handles the padding operation.
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(rule, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
          ),
        if (viewModel.getPasswordError() != null)
          /// Creates a padding instance.
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              viewModel.getPasswordError()!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// Handles the build confirm password field operation.
  Widget _buildConfirmPasswordField(SignupViewModel viewModel) {
    /// Handles the column operation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Creates a text instance.
        const Text("Confirm Password"),

        /// Creates a sized box instance.
        const SizedBox(height: 8),

        /// Creates a text field instance.
        TextField(
          controller: _confirmPasswordController,
          obscureText: viewModel.obscureConfirmPassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline),
            hintText: "Confirm your password",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(
                viewModel.obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: viewModel.toggleConfirmPasswordVisibility,
            ),
          ),
          onChanged: (value) {
            viewModel.updateConfirmPassword(value);
            viewModel.clearError();
            viewModel.markConfirmTouched();
          },
          onTap: () => viewModel.markConfirmTouched(),
        ),
        if (viewModel.getConfirmPasswordError() != null)
          /// Creates a padding instance.
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              viewModel.getConfirmPasswordError()!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// Handles the build terms field operation.
  Widget _buildTermsField(SignupViewModel viewModel) {
    /// Handles the column operation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Creates a row instance.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Creates a checkbox instance.
            Checkbox(
              value: viewModel.acceptedTerms,
              onChanged: viewModel.toggleTermsAccepted,
            ),

            /// Creates a expanded instance.
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    /// Creates a text span instance.
                    const TextSpan(text: "I accept the "),

                    /// Creates a text span instance.
                    TextSpan(
                      text: "Terms and Conditions",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _showTermsAndConditions(context),
                    ),

                    /// Creates a text span instance.
                    const TextSpan(text: " and "),

                    /// Creates a text span instance.
                    TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _showPrivacyPolicy(context),
                    ),

                    /// Creates a text span instance.
                    const TextSpan(text: "."),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (viewModel.termsTouched && !viewModel.acceptedTerms)
          /// Creates a padding instance.
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Please accept the terms and conditions',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
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
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  /// Handles the build login link operation.
  Widget _buildLoginLink(BuildContext context) {
    /// Handles the row operation.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// Creates a text instance.
        const Text("Already have an account?"),

        /// Creates a text button instance.
        TextButton(
          onPressed: () {
            context.go(AppRouter.login);
          },
          child: Text(
            "Login",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }

  /// Handles the show terms and conditions operation.
  void _showTermsAndConditions(BuildContext context) {
    // Navigate to terms and conditions page
    // Implement based on the existing AboutViewerPage.
    ScaffoldMessenger.of(context).showSnackBar(
      /// Creates a snack bar instance.
      const SnackBar(content: Text('Terms and Conditions feature coming soon')),
    );
  }

  /// Handles the show privacy policy operation.
  void _showPrivacyPolicy(BuildContext context) {
    // Navigate to privacy policy page
    ScaffoldMessenger.of(context).showSnackBar(
      /// Creates a snack bar instance.
      const SnackBar(content: Text('Privacy Policy feature coming soon')),
    );
  }

  /// Handles the handle signup operation.
  Future<void> _handleSignup(
    BuildContext context,
    SignupViewModel viewModel,
  ) async {
    final ageGroupId = viewModel.selectedAgeGroupId;

    if (ageGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        /// Creates a snack bar instance.
        const SnackBar(
          content: Text('Please select an age group'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(),
    );

    // Get data from controllers
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final gender = viewModel.selectedGender;
    final ageGroupName = viewModel.selectedAgeGroupName ?? '';

    // Call ViewModel with data
    final user = await viewModel.signup(
      email: email,
      password: password,
      name: name,
      gender: gender,
      ageGroupId: ageGroupId,
      ageGroupName: ageGroupName,
    );

    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Screen handles navigation based on result
    if (user != null && context.mounted) {
      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => EmailVerificationDialog(
          onResendPressed: () => viewModel.resendVerificationEmail(),
          onCheckVerified: () => viewModel.checkEmailVerified(),
        ),
      );

      if (verified == true && context.mounted) {
        _navigateToHome(context, user);
      } else if (verified == false && context.mounted) {
        context.go(AppRouter.login);
      }
    }
  }

  /// Handles the navigate to user_home operation.
  void _navigateToHome(BuildContext context, dynamic user) {
    final roleManager = RoleManager();

    // Use the roleToString method
    final roleString = roleManager.roleToString(user.role);

    context.go(
      AppRouter.setupDiet,
      extra: UserSetupArgs(uid: user.uid, user: user, role: roleString),
    );
  }
}
