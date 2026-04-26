import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/utils/role_manager.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../main/presentation/view/main_page.dart';
import '../viewmodel/signup_viewmodel.dart';
import '../widgets/country_picker_dialog.dart';
import '../widgets/curved_header.dart';
import 'login_screen.dart';
import '../widgets/email_verification_dialog.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<SignupViewModel>(),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  @override
  void initState() {
    super.initState();
    // Load countries when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SignupViewModel>().loadCountries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignupViewModel>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              CurvedHeader(
                onLeadingPressed: () => Navigator.pop(context),
                leadingText: "Back",
                onTrailingPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                trailingText: "Login",
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTitle(context),
                    const SizedBox(height: 16),

                    // Email Field
                    _buildEmailField(viewModel),
                    const SizedBox(height: 16),

                    // Name Field
                    _buildNameField(viewModel),
                    const SizedBox(height: 16),

                    // Gender Field
                    _buildGenderField(viewModel),
                    const SizedBox(height: 16),

                    // Country Field
                    _buildCountryField(viewModel),
                    const SizedBox(height: 16),

                    // Password Field
                    _buildPasswordField(viewModel),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    _buildConfirmPasswordField(viewModel),
                    const SizedBox(height: 16),

                    // Terms and Conditions
                    _buildTermsField(viewModel),
                    const SizedBox(height: 24),

                    // Error Message
                    if (viewModel.errorMessage != null)
                      _buildErrorMessage(viewModel.errorMessage!),

                    const SizedBox(height: 16),

                    // Sign Up Button
                    PrimaryButton(
                      text: 'Sign Up',
                      onPressed: viewModel.isLoading ? null : () => _handleSignup(context, viewModel),
                      isLoading: viewModel.isLoading,
                    ),

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

  Widget _buildTitle(BuildContext context) {
    return Text(
      "Create Account",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }

  Widget _buildEmailField(SignupViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Email"),
        const SizedBox(height: 8),
        TextField(
          controller: viewModel.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email),
            hintText: "e.g. john@example.com",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => viewModel.emailController.clear(),
            ),
          ),
          onChanged: (_) {
            viewModel.clearError();
            viewModel.markEmailTouched();
          },
          onTap: () => viewModel.markEmailTouched(),
        ),
        if (viewModel.getEmailError() != null)
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

  Widget _buildNameField(SignupViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Full Name"),
        const SizedBox(height: 8),
        TextField(
          controller: viewModel.nameController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person),
            hintText: "e.g. John Doe",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => viewModel.nameController.clear(),
            ),
          ),
          onChanged: (_) {
            viewModel.clearError();
            viewModel.markNameTouched();
          },
          onTap: () => viewModel.markNameTouched(),
        ),
        if (viewModel.getNameError() != null)
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

  Widget _buildGenderField(SignupViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Gender"),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGenderButton(
                label: "Male",
                value: "male",
                selected: viewModel.selectedGender == "male",
                onTap: () => viewModel.selectGender("male"),
              ),
            ),
            const SizedBox(width: 8),
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

  Widget _buildGenderButton({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
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


  Widget _buildCountryField(SignupViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Country"),
        const SizedBox(height: 8),
        // ✅ Check if countries list is empty (loading state)
        if (viewModel.countries.isEmpty)
          const LinearProgressIndicator()
        else
          GestureDetector(
            onTap: () async {
              final picked = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (_) => CountryPickerDialog(
                  items: viewModel.countries,  // ✅ Now non-nullable
                  selectedId: viewModel.selectedCountryId,
                ),
              );
              if (picked != null) {
                viewModel.selectCountry(
                  picked['id'],
                  picked['country'],
                  picked['currency'],
                );
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                viewModel.selectedCountryName != null
                    ? "${viewModel.selectedCountryName} (${viewModel.selectedCurrency})"
                    : "Select your country",
                style: TextStyle(
                  color: viewModel.selectedCountryName != null
                      ? Theme.of(context).colorScheme.onSecondary
                      : Colors.grey,
                ),
              ),
            ),
          ),
        if (viewModel.countryTouched && viewModel.selectedCountryId == null)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Please select your country',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField(SignupViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Password"),
        const SizedBox(height: 8),
        TextField(
          controller: viewModel.passwordController,
          obscureText: viewModel.obscurePassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock),
            hintText: "Create a strong password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                viewModel.obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: viewModel.togglePasswordVisibility,
            ),
          ),
          onChanged: (_) {
            viewModel.clearError();
            viewModel.markPasswordTouched();
          },
          onTap: () => viewModel.markPasswordTouched(),
        ),
        // Password strength indicator
        if (viewModel.passwordController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: viewModel.getPasswordRules().map((rule) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    rule,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ),
        if (viewModel.getPasswordError() != null)
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

  Widget _buildConfirmPasswordField(SignupViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Confirm Password"),
        const SizedBox(height: 8),
        TextField(
          controller: viewModel.confirmPasswordController,
          obscureText: viewModel.obscureConfirmPassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline),
            hintText: "Confirm your password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                viewModel.obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: viewModel.toggleConfirmPasswordVisibility,
            ),
          ),
          onChanged: (_) {
            viewModel.clearError();
            viewModel.markConfirmTouched();
          },
          onTap: () => viewModel.markConfirmTouched(),
        ),
        if (viewModel.getConfirmPasswordError() != null)
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

  Widget _buildTermsField(SignupViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: viewModel.acceptedTerms,
              onChanged: viewModel.toggleTermsAccepted,
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: "I accept the "),
                    TextSpan(
                      text: "Terms and Conditions",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _showTermsAndConditions(context),
                    ),
                    const TextSpan(text: " and "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _showPrivacyPolicy(context),
                    ),
                    const TextSpan(text: "."),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (viewModel.termsTouched && !viewModel.acceptedTerms)
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

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?"),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: Text(
            "Login",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    // Navigate to terms and conditions page
    // You can implement this based on your existing AboutViewerPage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms and Conditions feature coming soon')),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    // Navigate to privacy policy page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy Policy feature coming soon')),
    );
  }

  Future<void> _handleSignup(BuildContext context, SignupViewModel viewModel) async {
    // Check if country is selected first
    final countryId = viewModel.selectedCountryId;

    if (countryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a country'),
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
    final email = viewModel.emailController.text.trim();
    final password = viewModel.passwordController.text.trim();
    final name = viewModel.nameController.text.trim();
    final gender = viewModel.selectedGender;

    // Call ViewModel with data
    final user = await viewModel.signup(
      email: email,
      password: password,
      name: name,
      gender: gender,
      countryId: countryId,
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  void _navigateToHome(BuildContext context, dynamic user) {
    final roleManager = RoleManager();

    // Use the roleToString method
    final roleString = roleManager.roleToString(user.role);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainPage(
          user: user,
          role: roleString,
        ),
      ),
    );
  }
}