import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../domain/usecases/change_password_usecase.dart';
import '../../../viewmodel/account/change_password_viewmodel.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChangePasswordViewModel(
        changePasswordUseCase: sl<ChangePasswordUseCase>(),
      ),
      child: const _ChangePasswordPageView(),
    );
  }
}

class _ChangePasswordPageView extends StatefulWidget {
  const _ChangePasswordPageView();

  @override
  State<_ChangePasswordPageView> createState() => _ChangePasswordPageViewState();
}

class _ChangePasswordPageViewState extends State<_ChangePasswordPageView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChangePasswordViewModel>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Change Password',
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _buildPasswordIcon(context),
                  const SizedBox(height: 20),
                  _buildInstructionText(),
                  const SizedBox(height: 30),
                  _buildCurrentPasswordField(viewModel),
                  _buildNewPasswordField(viewModel),
                  _buildConfirmPasswordField(viewModel),
                  if (viewModel.errorMessage != null)
                    _buildErrorMessage(viewModel.errorMessage!),
                  const SizedBox(height: 40),
                  _buildChangePasswordButton(viewModel),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (viewModel.isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPasswordIcon(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          Icons.vpn_key,
          size: 80,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildInstructionText() {
    return const Text(
      'Ready for a change? Update your password here.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16),
    );
  }

  Widget _buildCurrentPasswordField(ChangePasswordViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Current Password'),
          const SizedBox(height: 8),
          _buildPasswordInputRow(
            controller: viewModel.currentPasswordController,
            isVisible: viewModel.showCurrentPassword,
            onToggle: viewModel.toggleCurrentPasswordVisibility,
            validator: viewModel.validateCurrentPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordField(ChangePasswordViewModel viewModel) {
    final password = viewModel.newPasswordController.text;
    final rules = viewModel.getPasswordRules(password);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('New Password'),
          const SizedBox(height: 8),
          _buildPasswordInputRow(
            controller: viewModel.newPasswordController,
            isVisible: viewModel.showNewPassword,
            onToggle: viewModel.toggleNewPasswordVisibility,
            validator: viewModel.validateNewPassword,
          ),
          if (password.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rules.map((rule) {
                  final isCheckmark = rule.startsWith('✓');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      rule,
                      style: TextStyle(
                        color: isCheckmark ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField(ChangePasswordViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Confirm New Password'),
          const SizedBox(height: 8),
          _buildPasswordInputRow(
            controller: viewModel.confirmPasswordController,
            isVisible: viewModel.showConfirmPassword,
            onToggle: viewModel.toggleConfirmPasswordVisibility,
            validator: viewModel.validateConfirmPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPasswordInputRow({
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
    required String? Function(String?)? validator,
  }) {
    return Row(
      children: [
        Icon(Icons.vpn_key, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: controller,
              obscureText: !isVisible,
              validator: validator,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter password',
                suffixIcon: IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: onToggle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangePasswordButton(ChangePasswordViewModel viewModel) {
    return PrimaryButton(
      text: 'Change Password',
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          final success = await viewModel.changePassword();
          if (success && mounted) {
            _showSuccessDialog(context);
          } else if (mounted && viewModel.errorMessage != null) {
            // Error is already shown in the UI
          }
        }
      },
      isLoading: viewModel.isLoading,
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 16),
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

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Your password has been changed successfully.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to settings
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}