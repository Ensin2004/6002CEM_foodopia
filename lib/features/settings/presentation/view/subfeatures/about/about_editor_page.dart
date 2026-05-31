// Builds the about editor screen.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../domain/usecases/about/get_about_content_usecase.dart';
import '../../../../domain/usecases/about/save_about_content_usecase.dart';
import '../../../../domain/usecases/about/delete_about_content_usecase.dart';
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
        deleteAboutContentUseCase: sl<DeleteAboutContentUseCase>(),
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
        actions: viewModel.isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: viewModel.isSaving
                      ? null
                      : () => _confirmDelete(context, viewModel),
                ),

                /// Creates a icon button instance.
                IconButton(
                  icon: viewModel.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  onPressed: viewModel.isSaveDisabled
                      ? null
                      : () => _saveContent(context, viewModel),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: viewModel.startEditing,
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
          Text(
            viewModel.isEditing
                ? 'Edit the content below:'
                : 'Press edit to update this content.',
            style: const TextStyle(fontSize: 16),
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
                  color: viewModel.content.length > 10000
                      ? Colors.red
                      : Colors.grey,
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
              readOnly: !viewModel.isEditing,
              onChanged: viewModel.isEditing ? viewModel.updateContent : null,
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
          if (viewModel.isEditing)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: viewModel.isSaving
                        ? null
                        : viewModel.cancelEditing,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Save Changes',
                    onPressed: viewModel.isSaveDisabled
                        ? null
                        : () => _saveContent(context, viewModel),
                    isLoading: viewModel.isSaving,
                  ),
                ),
              ],
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
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  /// Handles the save and close operation.
  Future<void> _saveContent(
    BuildContext context,
    AboutEditorViewModel viewModel,
  ) async {
    final success = await viewModel.saveContent();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        /// Creates a snack bar instance.
        const SnackBar(content: Text('Content saved successfully!')),
      );
    } else if (context.mounted && viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        /// Creates a snack bar instance.
        SnackBar(content: Text(viewModel.errorMessage!)),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AboutEditorViewModel viewModel,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete content?'),
        content: const Text('This will remove all saved content.'),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    final success = await viewModel.deleteContent();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Content deleted successfully.'
              : viewModel.errorMessage ?? 'Unable to delete content.',
        ),
      ),
    );
  }
}
