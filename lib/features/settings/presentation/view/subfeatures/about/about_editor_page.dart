import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../domain/usecases/get_about_content_usecase.dart';
import '../../../../domain/usecases/save_about_content_usecase.dart';
import '../../../viewmodel/about/about_editor_viewmodel.dart';

class AboutEditorPage extends StatelessWidget {
  final String documentId;
  final String title;

  const AboutEditorPage({
    super.key,
    required this.documentId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
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

class _AboutEditorPageView extends StatelessWidget {
  const _AboutEditorPageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AboutEditorViewModel>();

    return Scaffold(
      appBar: CustomAppBar(
        title: viewModel.title,
        centerTitle: true,
        actions: [
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
          ? const Center(child: CircularProgressIndicator())
          : _buildEditor(context, viewModel),
    );
  }

  Widget _buildEditor(BuildContext context, AboutEditorViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Edit the content below:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (viewModel.content.isEmpty && !viewModel.isLoading)
                const Text(
                  'No content yet. Start writing...',
                  style: TextStyle(color: Colors.grey),
                ),
              Text(
                '${viewModel.content.length}/10000',
                style: TextStyle(
                  color: viewModel.content.length > 10000 ? Colors.red : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: viewModel.contentController,  // ✅ Use the controller from ViewModel
              onChanged: viewModel.updateContent,       // ✅ Update ViewModel when text changes
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
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Save Changes',
            onPressed: viewModel.isSaveDisabled ? null : () => _saveAndClose(context, viewModel),
            isLoading: viewModel.isSaving,
          ),
        ],
      ),
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

  Future<void> _saveAndClose(BuildContext context, AboutEditorViewModel viewModel) async {
    final success = await viewModel.saveContent();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content saved successfully!')),
      );
      Navigator.pop(context, true);
    } else if (context.mounted && viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage!)),
      );
    }
  }
}