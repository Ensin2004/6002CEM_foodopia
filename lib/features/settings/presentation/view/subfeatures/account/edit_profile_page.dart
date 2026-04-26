import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../domain/usecases/get_user_profile_usecase.dart';
import '../../../../domain/usecases/update_user_name_usecase.dart';
import '../../../../domain/usecases/update_user_gender_usecase.dart';
import '../../../../domain/usecases/update_profile_image_usecase.dart';
import '../../../viewmodel/account/edit_profile_viewmodel.dart';

class EditProfilePage extends StatelessWidget {
  final String uid;

  const EditProfilePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditProfileViewModel(
        uid: uid,
        getUserProfileUseCase: sl<GetUserProfileUseCase>(),
        updateUserNameUseCase: sl<UpdateUserNameUseCase>(),
        updateUserGenderUseCase: sl<UpdateUserGenderUseCase>(),
        updateProfileImageUseCase: sl<UpdateProfileImageUseCase>(),
      ),
      child: const _EditProfilePageView(),
    );
  }
}

class _EditProfilePageView extends StatelessWidget {
  const _EditProfilePageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EditProfileViewModel>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Profile',
        centerTitle: true,
        // No need for unsaved changes confirmation since changes are saved immediately
        showConfirmationOnBack: false,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfilePictureSection(context, viewModel),
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
  Widget _buildProfilePictureSection(BuildContext context, EditProfileViewModel viewModel) {
    return GestureDetector(
      onTap: () => _pickImage(context, viewModel),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundImage: _getProfileImageProvider(viewModel),
            child: _buildAvatarPlaceholder(viewModel),
          ),
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

  ImageProvider? _getProfileImageProvider(EditProfileViewModel viewModel) {
    if (viewModel.selectedImage != null) {
      return FileImage(viewModel.selectedImage!);
    }
    if (viewModel.profile?.profileImageUrl != null &&
        viewModel.profile!.profileImageUrl!.isNotEmpty) {
      return NetworkImage(viewModel.profile!.profileImageUrl!);
    }
    return null;
  }

  Widget? _buildAvatarPlaceholder(EditProfileViewModel viewModel) {
    if (viewModel.selectedImage == null &&
        (viewModel.profile?.profileImageUrl == null ||
            viewModel.profile!.profileImageUrl!.isEmpty)) {
      return Icon(Icons.person, size: 80, color: Colors.grey[400]);
    }
    return null;
  }

  // Profile Fields Section
  Widget _buildProfileFieldsSection(BuildContext context, EditProfileViewModel viewModel) {
    return Column(
      children: [
        _buildEmailField(context, viewModel),
        const SizedBox(height: 16),
        _buildNameField(context, viewModel),
        const SizedBox(height: 16),
        _buildGenderField(context, viewModel),
      ],
    );
  }

  Widget _buildEmailField(BuildContext context, EditProfileViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
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

  Widget _buildNameField(BuildContext context, EditProfileViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
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
                Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    viewModel.displayName,
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

  Widget _buildGenderField(BuildContext context, EditProfileViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
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
                Icon(Icons.wc, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    viewModel.displayGender.isNotEmpty
                        ? viewModel.displayGender
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

  // Edit Name Dialog with immediate save
  void _showEditNameDialog(BuildContext context, EditProfileViewModel viewModel) {
    final controller = TextEditingController(text: viewModel.displayName);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != viewModel.displayName) {
                // Show loading indicator
                Navigator.pop(context); // Close dialog first

                // Show saving indicator
                _showSavingDialog(context);

                // Save the change
                final success = await viewModel.saveNameOnly(newName);

                // Close loading dialog
                Navigator.pop(context);

                if (success && context.mounted) {
                  _showSuccessMessage(context, 'Name updated successfully');
                } else if (context.mounted && viewModel.errorMessage != null) {
                  _showErrorMessage(context, viewModel.errorMessage!);
                }
              } else {
                Navigator.pop(context);
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
    String selectedGender = viewModel.displayGender;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text('Male'),
                value: 'Male',
                groupValue: selectedGender,
                onChanged: (value) {
                  setState(() {
                    selectedGender = value!;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Female'),
                value: 'Female',
                groupValue: selectedGender,
                onChanged: (value) {
                  setState(() {
                    selectedGender = value!;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Prefer not to say'),
                value: '',
                groupValue: selectedGender,
                onChanged: (value) {
                  setState(() {
                    selectedGender = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedGender != viewModel.displayGender) {
                  // Close dialog first
                  Navigator.pop(context);

                  // Show saving indicator
                  _showSavingDialog(context);

                  // Save the change
                  final success = await viewModel.saveGenderOnly(selectedGender);

                  // Close loading dialog
                  Navigator.pop(context);

                  if (success && context.mounted) {
                    _showSuccessMessage(context, 'Gender updated successfully');
                  } else if (context.mounted && viewModel.errorMessage != null) {
                    _showErrorMessage(context, viewModel.errorMessage!);
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Pick and upload profile image
  Future<void> _pickImage(BuildContext context, EditProfileViewModel viewModel) async {
    await viewModel.pickImage();
    if (viewModel.selectedImage != null && context.mounted) {
      // Show saving indicator
      _showSavingDialog(context);

      // Upload and save the image
      final success = await viewModel.saveImageOnly();

      // Close loading dialog
      Navigator.pop(context);

      if (success && context.mounted) {
        _showSuccessMessage(context, 'Profile picture updated successfully');
      } else if (context.mounted && viewModel.errorMessage != null) {
        _showErrorMessage(context, viewModel.errorMessage!);
      }
    }
  }

  // Helper methods
  void _showSavingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Error Message Widget
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
}