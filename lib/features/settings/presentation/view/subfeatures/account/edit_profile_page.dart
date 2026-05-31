import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../../auth/domain/usecases/get_age_groups_usecase.dart';
import '../../../../../auth/presentation/widgets/age_group_picker_dialog.dart';
import '../../../../domain/usecases/account/get_user_profile_usecase.dart';
import '../../../../domain/usecases/account/update_user_name_usecase.dart';
import '../../../../domain/usecases/account/update_user_age_group_usecase.dart';
import '../../../../domain/usecases/account/update_user_gender_usecase.dart';
import '../../../../domain/usecases/account/update_profile_image_usecase.dart';
import '../../../viewmodel/account/edit_profile_viewmodel.dart';

/// Defines behavior for edit profile page.
class EditProfilePage extends StatelessWidget {
  final String uid;

  /// Creates a edit profile page instance.
  const EditProfilePage({super.key, required this.uid});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => EditProfileViewModel(
        uid: uid,
        getUserProfileUseCase: sl<GetUserProfileUseCase>(),
        updateUserNameUseCase: sl<UpdateUserNameUseCase>(),
        updateUserGenderUseCase: sl<UpdateUserGenderUseCase>(),
        updateUserAgeGroupUseCase: sl<UpdateUserAgeGroupUseCase>(),
        getAgeGroupsUseCase: sl<GetAgeGroupsUseCase>(),
        updateProfileImageUseCase: sl<UpdateProfileImageUseCase>(),
      ),
      child: const _EditProfilePageView(),
    );
  }
}

/// Defines behavior for edit profile page view.
class _EditProfilePageView extends StatefulWidget {
  /// Handles the edit profile page view operation.
  const _EditProfilePageView();

  /// Creates data for the create state operation.
  @override
  State<_EditProfilePageView> createState() => _EditProfilePageViewState();
}

/// Defines behavior for edit profile page view state.
class _EditProfilePageViewState extends State<_EditProfilePageView> {
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EditProfileViewModel>();

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Profile',
        centerTitle: true,
        // No need for unsaved changes confirmation since changes are saved immediately
        showConfirmationOnBack: false,
      ),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfilePictureSection(context, viewModel),

                  /// Creates a sized box instance.
                  const SizedBox(height: 16),
                  _buildProfileFieldsSection(context, viewModel),
                  if (viewModel.errorMessage != null)
                    _buildErrorMessage(viewModel.errorMessage!),
                ],
              ),
            ),
    );
  }

  // Profile Picture Section
  Widget _buildProfilePictureSection(
    BuildContext context,
    EditProfileViewModel viewModel,
  ) {
    /// Handles the gesture detector operation.
    return GestureDetector(
      onTap: () => _pickImage(context, viewModel),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          /// Creates a circle avatar instance.
          CircleAvatar(
            radius: 80,
            backgroundImage: _getProfileImageProvider(viewModel),
            child: _buildAvatarPlaceholder(viewModel),
          ),

          /// Creates a container instance.
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles the get profile image provider operation.
  ImageProvider? _getProfileImageProvider(EditProfileViewModel viewModel) {
    if (_selectedImage != null) {
      /// Handles the file image operation.
      return FileImage(_selectedImage!);
    }
    if (viewModel.profile?.profileImageUrl != null &&
        viewModel.profile!.profileImageUrl!.isNotEmpty) {
      /// Handles the network image operation.
      return NetworkImage(viewModel.profile!.profileImageUrl!);
    }
    return null;
  }

  /// Handles the build avatar placeholder operation.
  Widget? _buildAvatarPlaceholder(EditProfileViewModel viewModel) {
    if (_selectedImage == null &&
        (viewModel.profile?.profileImageUrl == null ||
            viewModel.profile!.profileImageUrl!.isEmpty)) {
      /// Handles the icon operation.
      return Icon(Icons.person, size: 80, color: Colors.grey[400]);
    }
    return null;
  }

  // Profile Fields Section
  Widget _buildProfileFieldsSection(
    BuildContext context,
    EditProfileViewModel viewModel,
  ) {
    /// Handles the column operation.
    return Column(
      children: [
        _buildEmailField(context, viewModel),

        /// Creates a sized box instance.
        const SizedBox(height: 16),
        _buildNameField(context, viewModel),

        /// Creates a sized box instance.
        const SizedBox(height: 16),
        _buildGenderField(context, viewModel),
        const SizedBox(height: 16),
        _buildAgeGroupField(context, viewModel),
      ],
    );
  }

  /// Handles the build email field operation.
  Widget _buildEmailField(
    BuildContext context,
    EditProfileViewModel viewModel,
  ) {
    /// Handles the column operation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Creates a text instance.
        Text(
          'Email',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),

        /// Creates a sized box instance.
        const SizedBox(height: 8),

        /// Creates a container instance.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              /// Creates a icon instance.
              Icon(Icons.email, color: Theme.of(context).colorScheme.primary),

              /// Creates a sized box instance.
              const SizedBox(width: 12),

              /// Creates a expanded instance.
              Expanded(
                child: Text(
                  viewModel.profile?.email ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgeGroupField(
    BuildContext context,
    EditProfileViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age Group',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showAgeGroupDialog(context, viewModel),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.cake, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    viewModel.displayAgeGroup.isNotEmpty
                        ? viewModel.displayAgeGroup
                        : 'Not specified',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Handles the build name field operation.
  Widget _buildNameField(BuildContext context, EditProfileViewModel viewModel) {
    /// Handles the column operation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Creates a text instance.
        Text(
          'Full Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),

        /// Creates a sized box instance.
        const SizedBox(height: 8),

        /// Creates a gesture detector instance.
        GestureDetector(
          onTap: () => _showEditNameDialog(context, viewModel),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                /// Creates a icon instance.
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),

                /// Creates a sized box instance.
                const SizedBox(width: 12),

                /// Creates a expanded instance.
                Expanded(
                  child: Text(
                    viewModel.displayName,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                /// Creates a icon instance.
                Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Handles the build gender field operation.
  Widget _buildGenderField(
    BuildContext context,
    EditProfileViewModel viewModel,
  ) {
    /// Handles the column operation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Creates a text instance.
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),

        /// Creates a sized box instance.
        const SizedBox(height: 8),

        /// Creates a gesture detector instance.
        GestureDetector(
          onTap: () => _showGenderDialog(context, viewModel),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                /// Creates a icon instance.
                Icon(Icons.wc, color: Theme.of(context).colorScheme.primary),

                /// Creates a sized box instance.
                const SizedBox(width: 12),

                /// Creates a expanded instance.
                Expanded(
                  child: Text(
                    viewModel.displayGender.isNotEmpty
                        ? viewModel.displayGender
                        : 'Not specified',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                /// Creates a icon instance.
                Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Edit Name Dialog with immediate save
  void _showEditNameDialog(
    BuildContext context,
    EditProfileViewModel viewModel,
  ) {
    final pageContext = context;
    final controller = TextEditingController(text: viewModel.displayName);

    /// Displays the show dialog flow.
    showDialog(
      context: pageContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
          ),
          maxLength: 100,
          autofocus: true,
        ),
        actions: [
          /// Creates a text button instance.
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),

          /// Creates a text button instance.
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != viewModel.displayName) {
                // Show loading indicator
                Navigator.pop(dialogContext); // Close dialog first

                if (!pageContext.mounted) return;

                // Show saving indicator
                _showSavingDialog(pageContext);

                // Save the change
                final success = await viewModel.saveNameOnly(newName);

                // Close loading dialog
                if (!pageContext.mounted) return;
                Navigator.of(pageContext, rootNavigator: true).pop();

                if (success && pageContext.mounted) {
                  _showSuccessMessage(pageContext, 'Name updated successfully');
                } else if (pageContext.mounted &&
                    viewModel.errorMessage != null) {
                  _showErrorMessage(pageContext, viewModel.errorMessage!);
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Edit Gender Dialog with immediate save
  void _showGenderDialog(BuildContext context, EditProfileViewModel viewModel) {
    final pageContext = context;
    String selectedGender = viewModel.displayGender.isEmpty
        ? 'Prefer not to say'
        : viewModel.displayGender;

    /// Displays the show dialog flow.
    showDialog(
      context: pageContext,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Edit Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Creates a radio list tile instance.
              RadioListTile(
                title: const Text('Male'),
                value: 'Male',
                groupValue: selectedGender,
                onChanged: (value) {
                  setState(() {
                    // Updates state values displayed by the current screen.
                    selectedGender = value!;
                  });
                },
              ),

              /// Creates a radio list tile instance.
              RadioListTile(
                title: const Text('Female'),
                value: 'Female',
                groupValue: selectedGender,
                onChanged: (value) {
                  setState(() {
                    // Updates state values displayed by the current screen.
                    selectedGender = value!;
                  });
                },
              ),

              /// Creates a radio list tile instance.
              RadioListTile(
                title: const Text('Prefer not to say'),
                value: 'Prefer not to say',
                groupValue: selectedGender,
                onChanged: (value) {
                  setState(() {
                    // Updates state values displayed by the current screen.
                    selectedGender = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            /// Creates a text button instance.
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),

            /// Creates a text button instance.
            TextButton(
              onPressed: () async {
                final currentGender = viewModel.displayGender.isEmpty
                    ? 'Prefer not to say'
                    : viewModel.displayGender;
                if (selectedGender != currentGender) {
                  // Close dialog first
                  Navigator.pop(dialogContext);

                  if (!pageContext.mounted) return;

                  // Show saving indicator
                  _showSavingDialog(pageContext);

                  // Save the change
                  final success = await viewModel.saveGenderOnly(
                    selectedGender,
                  );

                  // Close loading dialog
                  if (!pageContext.mounted) return;
                  Navigator.of(pageContext, rootNavigator: true).pop();

                  if (success && pageContext.mounted) {
                    _showSuccessMessage(
                      pageContext,
                      'Gender updated successfully',
                    );
                  } else if (pageContext.mounted &&
                      viewModel.errorMessage != null) {
                    _showErrorMessage(pageContext, viewModel.errorMessage!);
                  }
                } else {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAgeGroupDialog(
    BuildContext context,
    EditProfileViewModel viewModel,
  ) async {
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AgeGroupPickerDialog(
        items: viewModel.ageGroups,
        selectedId: viewModel.selectedAgeGroupId,
      ),
    );

    if (picked == null) return;

    final ageGroupId = picked['id'] as String? ?? '';
    final ageGroupName = picked['name'] as String? ?? '';
    if (ageGroupId.isEmpty ||
        ageGroupName.isEmpty ||
        ageGroupId == viewModel.selectedAgeGroupId) {
      return;
    }

    if (!context.mounted) return;
    _showSavingDialog(context);
    final success = await viewModel.saveAgeGroupOnly(ageGroupId, ageGroupName);

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (success && context.mounted) {
      _showSuccessMessage(context, 'Age group updated successfully');
    } else if (context.mounted && viewModel.errorMessage != null) {
      _showErrorMessage(context, viewModel.errorMessage!);
    }
  }

  // Pick and upload profile image
  Future<void> _pickImage(
    BuildContext context,
    EditProfileViewModel viewModel,
  ) async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null && context.mounted) {
      final selectedImage = File(pickedFile.path);
      setState(() => _selectedImage = selectedImage);

      // Show saving indicator
      _showSavingDialog(context);

      // Upload and save the image
      final success = await viewModel.saveImageOnly(selectedImage);

      // Close loading dialog
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (mounted) setState(() => _selectedImage = null);

      if (success && context.mounted) {
        _showSuccessMessage(context, 'Profile picture updated successfully');
      } else if (context.mounted && viewModel.errorMessage != null) {
        _showErrorMessage(context, viewModel.errorMessage!);
      }
    }
  }

  // Helper methods
  void _showSavingDialog(BuildContext context) {
    /// Displays the show dialog flow.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(message: 'Saving...'),
    );
  }

  /// Handles the show success message operation.
  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      /// Creates a snack bar instance.
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handles the show error message operation.
  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      /// Creates a snack bar instance.
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Error Message Widget
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
}
