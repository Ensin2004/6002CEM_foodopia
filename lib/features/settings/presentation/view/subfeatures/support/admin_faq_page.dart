import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../../../app/routers/app_router.dart';
import '../../../../../../app/routers/router_args.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../domain/entities/faq_item.dart';
import '../../../../domain/usecases/support/faq/add_faq_item_usecase.dart';
import '../../../../domain/usecases/support/faq/delete_faq_item_usecase.dart';
import '../../../../domain/usecases/support/faq/get_admin_faq_items_usecase.dart';
import '../../../../domain/usecases/support/faq/update_faq_item_usecase.dart';
import '../../../../domain/usecases/support/faq/upload_faq_image_usecase.dart';
import '../../../viewmodel/support/admin_faq_viewmodel.dart';

/// Defines behavior for admin faq page.
class AdminFaqPage extends StatelessWidget {
  /// Creates a admin faq page instance.
  const AdminFaqPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => AdminFaqViewModel(
        getAdminFaqItemsUseCase: sl<GetAdminFaqItemsUseCase>(),
        addFaqItemUseCase: sl<AddFaqItemUseCase>(),
        updateFaqItemUseCase: sl<UpdateFaqItemUseCase>(),
        deleteFaqItemUseCase: sl<DeleteFaqItemUseCase>(),
        uploadFaqImageUseCase: sl<UploadFaqImageUseCase>(),
      ),
      child: const _AdminFaqPageView(),
    );
  }
}

/// Defines behavior for admin faq page view.
class _AdminFaqPageView extends StatelessWidget {
  /// Handles the admin faq page view operation.
  const _AdminFaqPageView();

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminFaqViewModel>();

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: const CustomAppBar(title: 'Manage FAQs', centerTitle: true),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : Column(
        children: [
          _buildSearchAndSortRow(viewModel),
          _buildContentList(viewModel),
        ],
      ),
      floatingActionButton: _buildAddButton(context, viewModel),
    );
  }

  /// Handles the build search and sort row operation.
  Widget _buildSearchAndSortRow(AdminFaqViewModel viewModel) {
    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          /// Creates a expanded instance.
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search FAQ...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: viewModel.setSearchTerm,
              ),
            ),
          ),
          /// Creates a sized box instance.
          const SizedBox(width: 12),
          /// Creates a sized box instance.
          SizedBox(
            height: 48,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: viewModel.sortOption,
                underline: const SizedBox(),
                items: const [
                  /// Creates a dropdown menu item instance.
                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                  /// Creates a dropdown menu item instance.
                  DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                  /// Creates a dropdown menu item instance.
                  DropdownMenuItem(value: 'a-z', child: Text('A-Z')),
                  /// Creates a dropdown menu item instance.
                  DropdownMenuItem(value: 'z-a', child: Text('Z-A')),
                ],
                onChanged: (value) => viewModel.setSortOption(value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles the build content list operation.
  Widget _buildContentList(AdminFaqViewModel viewModel) {
    if (viewModel.filteredItems.isEmpty) {
      /// Handles the expanded operation.
      return const Expanded(child: Center(child: Text('No FAQs found')));
    }

    /// Handles the expanded operation.
    return Expanded(
      child: RefreshIndicator(
        onRefresh: viewModel.loadItems,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: viewModel.filteredItems.length,
          itemBuilder: (context, index) {
            final item = viewModel.filteredItems[index];
            /// Handles the build faq item operation.
            return _buildFaqItem(context, viewModel, item);
          },
        ),
      ),
    );
  }

  /// Handles the build faq item operation.
  Widget _buildFaqItem(BuildContext context, AdminFaqViewModel viewModel, FaqItem item) {
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt);

    /// Handles the card operation.
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(12),
          leading: _buildItemThumbnail(context, item.questionImageUrl),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Creates a text instance.
              Text(formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              /// Creates a sized box instance.
              const SizedBox(height: 4),
              /// Creates a text instance.
              Text(item.question, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          trailing: _buildItemMenu(context, viewModel, item),
          children: [
            /// Creates a padding instance.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Creates a text instance.
                  Text(item.answer, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                  if (item.answerImageUrl != null) ...[
                    /// Creates a sized box instance.
                    const SizedBox(height: 8),
                    _buildAnswerImage(context, item.answerImageUrl!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles the build item thumbnail operation.
  Widget _buildItemThumbnail(BuildContext context, String? imageUrl) {
    /// Handles the gesture detector operation.
    return GestureDetector(
      onTap: () => _showFullImage(context, imageUrl),
      child: imageUrl != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.contain),
      )
          : Icon(Icons.image, size: 50, color: Colors.grey[400]),
    );
  }

  /// Handles the build answer image operation.
  Widget _buildAnswerImage(BuildContext context, String imageUrl) {
    /// Handles the gesture detector operation.
    return GestureDetector(
      onTap: () => _showFullImage(context, imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(imageUrl, height: 120, width: double.infinity, fit: BoxFit.contain),
      ),
    );
  }

  /// Handles the build item menu operation.
  Widget _buildItemMenu(BuildContext context, AdminFaqViewModel viewModel, FaqItem item) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'edit') {
          final result = await context.push(
            AppRouter.faqForm,
            extra: FaqFormArgs(
              item: item,
              onSave: ({
                required String question,
                required String answer,
                File? questionImageFile,
                File? answerImageFile,
              }) async {
                return await viewModel.updateItem(
                  id: item.id,
                  question: question,
                  answer: answer,
                  existingQuestionImageUrl: item.questionImageUrl,
                  existingAnswerImageUrl: item.answerImageUrl,
                  newQuestionImageFile: questionImageFile,
                  newAnswerImageFile: answerImageFile,
                );
              },
            ),
          );
          if (result == true && context.mounted) {
            viewModel.loadItems();
          }
        } else if (value == 'delete') {
          _showDeleteDialog(context, viewModel, item);
        }
      },
      itemBuilder: (context) => const [
        /// Creates a popup menu item instance.
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        /// Creates a popup menu item instance.
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  /// Handles the show delete dialog operation.
  void _showDeleteDialog(BuildContext context, AdminFaqViewModel viewModel, FaqItem item) {
    /// Displays the show dialog flow.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this FAQ?'),
        actions: [
          /// Creates a text button instance.
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          /// Creates a text button instance.
          TextButton(
            onPressed: () async {
              await viewModel.deleteItem(item.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Handles the show full image operation.
  void _showFullImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null) return;
    context.push(
      AppRouter.imagePreview,
      extra: ImagePreviewArgs(imageUrl: imageUrl),
    );
  }

  // Fix: Uses named parameters in callback
  Widget _buildAddButton(BuildContext context, AdminFaqViewModel viewModel) {
    /// Handles the floating action button operation.
    return FloatingActionButton(
      onPressed: () async {
        final result = await context.push(
          AppRouter.faqForm,
          extra: FaqFormArgs(
            onSave: ({
              required String question,
              required String answer,
              File? questionImageFile,
              File? answerImageFile,
            }) async {
              return await viewModel.addItem(
                question: question,
                answer: answer,
                questionImageFile: questionImageFile,
                answerImageFile: answerImageFile,
              );
            },
          ),
        );
        if (result == true && context.mounted) {
          viewModel.loadItems();
        }
      },
      child: const Icon(Icons.add),
    );
  }
}
