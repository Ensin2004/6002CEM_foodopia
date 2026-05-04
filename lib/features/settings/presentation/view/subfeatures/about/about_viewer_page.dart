import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../domain/usecases/about/get_about_content_usecase.dart';
import '../../../viewmodel/about/about_viewer_viewmodel.dart';

/// Defines behavior for about viewer page.
class AboutViewerPage extends StatelessWidget {
  final String documentId;
  final String title;

  /// Creates a about viewer page instance.
  const AboutViewerPage({
    super.key,
    required this.documentId,
    required this.title,
  });

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
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

/// Defines behavior for about viewer page view.
class _AboutViewerPageView extends StatelessWidget {
  /// Handles the about viewer page view operation.
  const _AboutViewerPageView();

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AboutViewerViewModel>();

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: CustomAppBar(
        title: viewModel.title,
        centerTitle: true,
      ),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : _buildContent(context, viewModel),
    );
  }

  /// Handles the build content operation.
  Widget _buildContent(BuildContext context, AboutViewerViewModel viewModel) {
    if (viewModel.errorMessage != null) {
      /// Handles the build error widget operation.
      return _buildErrorWidget(context, viewModel.errorMessage!);
    }

    final content = viewModel.content?.content ?? '';

    // Show "No content yet" message if content is empty
    if (content.isEmpty) {
      /// Handles the build empty content widget operation.
      return _buildEmptyContentWidget();
    }

    /// Handles the single child scroll view operation.
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
    /// Handles the center operation.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Creates a icon instance.
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            /// Creates a sized box instance.
            const SizedBox(height: 16),
            /// Creates a text instance.
            Text(
              'No Content Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            /// Creates a sized box instance.
            const SizedBox(height: 8),
            /// Creates a text instance.
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
    /// Handles the center operation.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Creates a icon instance.
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            /// Creates a sized box instance.
            const SizedBox(height: 16),
            /// Creates a text instance.
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            /// Creates a sized box instance.
            const SizedBox(height: 24),
            /// Creates a sized box instance.
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
