import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../domain/usecases/account/change_password_usecase.dart';
import '../../../viewmodel/account/change_password_viewmodel.dart';

/// Runs the change password page operation.
class ChangePasswordPage extends StatelessWidget {
  /// Runs the change password page operation.
  const ChangePasswordPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => ChangePasswordViewModel(
        changePasswordUseCase: sl<ChangePasswordUseCase>(),
      ),
      child: const _ChangePasswordPageView(),
    );
  }
}

/// Defines behavior for change password page view.
class _ChangePasswordPageView extends StatefulWidget {
  /// Handles the change password page view operation.
  const _ChangePasswordPageView();

  /// Creates data for the create state operation.
  @override
  State<_ChangePasswordPageView> createState() => _ChangePasswordPageViewState();
}

/// Defines behavior for change password page view state.
class _ChangePasswordPageViewState extends State<_ChangePasswordPageView> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// Releases resources before widget removal.
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChangePasswordViewModel>();

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Change Password',
        centerTitle: true,
      ),
      body: Stack(
        children: [
          /// Creates a single child scroll view instance.
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  /// Creates a sized box instance.
                  const SizedBox(height: 30),
                  _buildPasswordIcon(context),
                  /// Creates a sized box instance.
                  const SizedBox(height: 20),
                  _buildInstructionText(),
                  /// Creates a sized box instance.
                  const SizedBox(height: 30),
                  _buildCurrentPasswordField(viewModel),
                  _buildNewPasswordField(viewModel),
                  _buildConfirmPasswordField(viewModel),
                  if (viewModel.errorMessage != null)
                    _buildErrorMessage(viewModel.errorMessage!),
                  /// Creates a sized box instance.
                  const SizedBox(height: 40),
                  _buildChangePasswordButton(viewModel),
                  /// Creates a sized box instance.
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

  /// Handles the build password icon operation.
  Widget _buildPasswordIcon(BuildContext context) {
    /// Handles the center operation.
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            /// Creates a box shadow instance.
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

  /// Handles the build instruction text operation.
  Widget _buildInstructionText() {
    /// Handles the text operation.
    return const Text(
      'Ready for a change? Update your password here.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16),
    );
  }

  /// Handles the build current password field operation.
  Widget _buildCurrentPasswordField(ChangePasswordViewModel viewModel) {
    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Current Password'),
          /// Creates a sized box instance.
          const SizedBox(height: 8),
          _buildPasswordInputRow(
            controller: _currentPasswordController,
            isVisible: viewModel.showCurrentPassword,
            onToggle: viewModel.toggleCurrentPasswordVisibility,
            validator: viewModel.validateCurrentPassword,
          ),
        ],
      ),
    );
  }

  /// Handles the build new password field operation.
  Widget _buildNewPasswordField(ChangePasswordViewModel viewModel) {
    final password = _newPasswordController.text;
    final rules = viewModel.getPasswordRules(password);

    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('New Password'),
          /// Creates a sized box instance.
          const SizedBox(height: 8),
          _buildPasswordInputRow(
            controller: _newPasswordController,
            isVisible: viewModel.showNewPassword,
            onToggle: viewModel.toggleNewPasswordVisibility,
            validator: viewModel.validateNewPassword,
          ),
          if (password.isNotEmpty)
            /// Creates a padding instance.
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rules.map((rule) {
                  final isCheckmark = rule.startsWith('✓');
                  /// Handles the padding operation.
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

  /// Handles the build confirm password field operation.
  Widget _buildConfirmPasswordField(ChangePasswordViewModel viewModel) {
    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Confirm New Password'),
          /// Creates a sized box instance.
          const SizedBox(height: 8),
          _buildPasswordInputRow(
            controller: _confirmPasswordController,
            isVisible: viewModel.showConfirmPassword,
            onToggle: viewModel.toggleConfirmPasswordVisibility,
            validator: (value) => viewModel.validateConfirmPassword(
              value,
              _newPasswordController.text,
            ),
          ),
        ],
      ),
    );
  }

  /// Handles the build field label operation.
  Widget _buildFieldLabel(String label) {
    /// Handles the text operation.
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Handles the build password input row operation.
  Widget _buildPasswordInputRow({
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
    /// Handles the function operation.
    required String? Function(String?)? validator,
  }) {
    /// Handles the row operation.
    return Row(
      children: [
        /// Creates a icon instance.
        Icon(Icons.vpn_key, color: Theme.of(context).colorScheme.primary),
        /// Creates a sized box instance.
        const SizedBox(width: 12),
        /// Creates a expanded instance.
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

  /// Handles the build change password button operation.
  Widget _buildChangePasswordButton(ChangePasswordViewModel viewModel) {
    /// Handles the primary button operation.
    return PrimaryButton(
      text: 'Change Password',
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          final success = await viewModel.changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
          if (success && mounted) {
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
            _showSuccessDialog(context);
          } else if (mounted && viewModel.errorMessage != null) {
            // Error is already shown in the UI
          }
        }
      },
      isLoading: viewModel.isLoading,
    );
  }

  /// Handles the build error message operation.
  Widget _buildErrorMessage(String message) {
    /// Handles the container operation.
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

  /// Handles the build loading overlay operation.
  Widget _buildLoadingOverlay() {
    /// Handles the container operation.
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const LoadingDialog(),
    );
  }

  /// Handles the show success dialog operation.
  void _showSuccessDialog(BuildContext context) {
    /// Displays the show dialog flow.
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
          /// Creates a text button instance.
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
