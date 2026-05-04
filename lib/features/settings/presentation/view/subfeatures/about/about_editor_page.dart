// Builds the about editor screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../domain/usecases/about/get_about_content_usecase.dart';
import '../../../../domain/usecases/about/save_about_content_usecase.dart';
import '../../../viewmodel/about/about_editor_viewmodel.dart';

/// Defines behavior for about editor page.
class AboutEditorPage extends StatelessWidget {
  final String documentId;
  final String title;

  /// Creates a about editor page instance.
  const AboutEditorPage({
    super.key,
    required this.documentId,
    required this.title,
  });

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => AboutEditorViewModel(
        documentId: documentId,
        title: title,
        getAboutContentUseCase: sl<GetAboutContentUseCase>(),
        saveAboutContentUseCase: sl<SaveAboutContentUseCase>(),
      ),
      child: const _AboutEditorPageView(),
    );
  }
}

/// Defines behavior for about editor page view.
class _AboutEditorPageView extends StatefulWidget {
  /// Handles the about editor page view operation.
  const _AboutEditorPageView();

  /// Creates data for the create state operation.
  @override
  State<_AboutEditorPageView> createState() => _AboutEditorPageViewState();
}

/// Defines behavior for about editor page view state.
class _AboutEditorPageViewState extends State<_AboutEditorPageView> {
  final _contentController = TextEditingController();

  /// Releases resources before widget removal.
  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AboutEditorViewModel>();
    if (!viewModel.hasChanges && _contentController.text != viewModel.content) {
      _contentController.text = viewModel.content;
      _contentController.selection = TextSelection.collapsed(
        offset: _contentController.text.length,
      );
    }

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: CustomAppBar(
        title: viewModel.title,
        centerTitle: true,
        actions: [
          /// Creates a icon button instance.
          IconButton(
            icon: viewModel.isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.save),
            onPressed: viewModel.isSaveDisabled ? null : () => _saveAndClose(context, viewModel),
          ),
        ],
      ),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : _buildEditor(context, viewModel),
    );
  }

  /// Handles the build editor operation.
  Widget _buildEditor(BuildContext context, AboutEditorViewModel viewModel) {
    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// Creates a text instance.
          const Text(
            'Edit the content below:',
            style: TextStyle(fontSize: 16),
          ),
          /// Creates a sized box instance.
          const SizedBox(height: 8),
          /// Creates a row instance.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (viewModel.content.isEmpty && !viewModel.isLoading)
                /// Creates a text instance.
                const Text(
                  'No content yet. Start writing...',
                  style: TextStyle(color: Colors.grey),
                ),
              /// Creates a text instance.
              Text(
                '${viewModel.content.length}/10000',
                style: TextStyle(
                  color: viewModel.content.length > 10000 ? Colors.red : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          /// Creates a sized box instance.
          const SizedBox(height: 8),
          /// Creates a expanded instance.
          Expanded(
            child: TextField(
              controller: _contentController,
              onChanged: viewModel.updateContent,
              maxLines: null,
              maxLength: 10000,
              decoration: const InputDecoration(
                hintText: 'Enter content here...',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              style: const TextStyle(fontSize: 16),
              keyboardType: TextInputType.multiline,
            ),
          ),
          if (viewModel.errorMessage != null)
            _buildErrorMessage(viewModel.errorMessage!),
          /// Creates a sized box instance.
          const SizedBox(height: 16),
          /// Creates a primary button instance.
          PrimaryButton(
            text: 'Save Changes',
            onPressed: viewModel.isSaveDisabled ? null : () => _saveAndClose(context, viewModel),
            isLoading: viewModel.isSaving,
          ),
        ],
      ),
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

  /// Handles the save and close operation.
  Future<void> _saveAndClose(BuildContext context, AboutEditorViewModel viewModel) async {
    final success = await viewModel.saveContent();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        /// Creates a snack bar instance.
        const SnackBar(content: Text('Content saved successfully!')),
      );
      Navigator.pop(context, true);
    } else if (context.mounted && viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        /// Creates a snack bar instance.
        SnackBar(content: Text(viewModel.errorMessage!)),
      );
    }
  }
}
