import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../domain/usecases/get_about_content_usecase.dart';
import '../../../viewmodel/about/about_viewer_viewmodel.dart';

class AboutViewerPage extends StatelessWidget {
  final String documentId;
  final String title;

  const AboutViewerPage({
    super.key,
    required this.documentId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AboutViewerViewModel(
        documentId: documentId,
        title: title,
        getAboutContentUseCase: sl<GetAboutContentUseCase>(),
      ),
      child: const _AboutViewerPageView(),
    );
  }
}

class _AboutViewerPageView extends StatelessWidget {
  const _AboutViewerPageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AboutViewerViewModel>();

    return Scaffold(
      appBar: CustomAppBar(
        title: viewModel.title,
        centerTitle: true,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context, viewModel),
    );
  }

  Widget _buildContent(BuildContext context, AboutViewerViewModel viewModel) {
    if (viewModel.errorMessage != null) {
      return _buildErrorWidget(context, viewModel.errorMessage!);
    }

    final content = viewModel.content?.content ?? '';

    // Show "No content yet" message if content is empty
    if (content.isEmpty) {
      return _buildEmptyContentWidget();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
        ),
      ),
    );
  }

  // Empty content widget
  Widget _buildEmptyContentWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Content Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This content is currently being prepared.\nPlease check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error widget with PrimaryButton
  Widget _buildErrorWidget(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              child: PrimaryButton(
                text: 'Retry',
                onPressed: () => context.read<AboutViewerViewModel>().loadContent(),
                verticalPadding: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}