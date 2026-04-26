import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../viewmodel/support/user_help_center_viewmodel.dart';

class IssueSubmissionForm extends StatefulWidget {
  final VoidCallback onSubmit;

  const IssueSubmissionForm({super.key, required this.onSubmit});

  @override
  State<IssueSubmissionForm> createState() => _IssueSubmissionFormState();
}

class _IssueSubmissionFormState extends State<IssueSubmissionForm> {
  final TextEditingController _messageController = TextEditingController();
  File? _selectedImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

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

  @override
  Widget build(BuildContext context) {
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
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe your issue...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Image'),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(width: 8),
                SizedBox(width: 60, height: 60, child: Image.file(_selectedImage!, fit: BoxFit.cover)),
              ],
            ],
          ),
          const SizedBox(height: 8),
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