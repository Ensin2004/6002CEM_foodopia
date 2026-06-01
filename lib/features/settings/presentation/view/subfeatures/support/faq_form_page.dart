import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../domain/entities/faq_item.dart';

/// Defines behavior for faq form page.
class FaqFormPage extends StatefulWidget {
  final FaqItem? item;

  /// Handles the function operation.
  final Future<bool> Function({
    required String question,
    required String answer,
    File? questionImageFile,
    File? answerImageFile,
  })
  onSave;

  /// Creates a faq form page instance.
  const FaqFormPage({super.key, this.item, required this.onSave});

  /// Creates data for the create state operation.
  @override
  State<FaqFormPage> createState() => _FaqFormPageState();
}

/// Defines behavior for faq form page state.
class _FaqFormPageState extends State<FaqFormPage> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  bool _isSaving = false;

  /// Initializes state before the first widget build.
  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _questionController.text = widget.item!.question;
      _answerController.text = widget.item!.answer;
    }
  }

  /// Releases resources before widget removal.
  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  /// Handles the save operation.
  Future<void> _save() async {
    setState(() => _isSaving = true);

    final success = await widget.onSave(
      question: _questionController.text.trim(),
      answer: _answerController.text.trim(),
      questionImageFile: null,
      answerImageFile: null,
    );

    if (success && mounted) {
      Navigator.pop(context);
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: CustomAppBar(
        title: '${isEditing ? 'Edit' : 'Add'} FAQ',
        centerTitle: true,
        actions: [
          if (_isSaving)
            /// Creates a padding instance.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_isSaving)
            /// Creates a text button instance.
            TextButton(
              onPressed: _save,
              child: const Text(
                'SAVE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Section
            const Text(
              'Question',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            /// Creates a sized box instance.
            const SizedBox(height: 8),

            /// Creates a text field instance.
            TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            /// Creates a sized box instance.
            const SizedBox(height: 24),

            // Answer Section
            const Text(
              'Answer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            /// Creates a sized box instance.
            const SizedBox(height: 8),

            /// Creates a text field instance.
            TextField(
              controller: _answerController,
              maxLines: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: PrimaryButton(
          text: isEditing ? 'Update' : 'Add',
          onPressed: _isSaving ? null : _save,
          isLoading: _isSaving,
        ),
      ),
    );
  }
}
