// Defines the issue submission form widget.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../viewmodel/support/user_help_center_viewmodel.dart';

/// Defines behavior for issue submission form.
class IssueSubmissionForm extends StatefulWidget {
  final VoidCallback onSubmit;

  /// Creates a issue submission form instance.
  const IssueSubmissionForm({super.key, required this.onSubmit});

  /// Creates data for the create state operation.
  @override
  State<IssueSubmissionForm> createState() => _IssueSubmissionFormState();
}

/// Defines behavior for issue submission form state.
class _IssueSubmissionFormState extends State<IssueSubmissionForm> {
  final TextEditingController _messageController = TextEditingController();
  File? _selectedImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  /// Releases resources before widget removal.
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Handles the pick image operation.
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  /// Handles the submit operation.
  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final viewModel = context.read<UserHelpCenterViewModel>();
    setState(() => _isSubmitting = true);

    final success = await viewModel.submitIssue(message, _selectedImage);

    if (success && mounted) {
      widget.onSubmit();
      Navigator.pop(context);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the padding operation.
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Creates a text field instance.
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe your issue...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          /// Creates a sized box instance.
          const SizedBox(height: 8),
          /// Creates a row instance.
          Row(
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Image'),
              ),
              if (_selectedImage != null) ...[
                /// Creates a sized box instance.
                const SizedBox(width: 8),
                /// Creates a sized box instance.
                SizedBox(width: 60, height: 60, child: Image.file(_selectedImage!, fit: BoxFit.cover)),
              ],
            ],
          ),
          /// Creates a sized box instance.
          const SizedBox(height: 8),
          /// Creates a sized box instance.
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Submit',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
