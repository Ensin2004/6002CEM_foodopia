import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../domain/entities/faq_item.dart';
import '../../../../domain/usecases/get_admin_faq_items_usecase.dart';
import '../../../../domain/usecases/add_faq_item_usecase.dart';
import '../../../../domain/usecases/update_faq_item_usecase.dart';
import '../../../../domain/usecases/delete_faq_item_usecase.dart';
import '../../../../domain/usecases/upload_faq_image_usecase.dart';
import '../../../viewmodel/support/admin_faq_viewmodel.dart';
import 'faq_form_page.dart';

class AdminFaqPage extends StatelessWidget {
  const AdminFaqPage({super.key});

  @override
  Widget build(BuildContext context) {
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

class _AdminFaqPageView extends StatelessWidget {
  const _AdminFaqPageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminFaqViewModel>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manage FAQs', centerTitle: true),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildSearchAndSortRow(viewModel),
          _buildContentList(viewModel),
        ],
      ),
      floatingActionButton: _buildAddButton(context, viewModel),
    );
  }

  Widget _buildSearchAndSortRow(AdminFaqViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
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
          const SizedBox(width: 12),
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
                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                  DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                  DropdownMenuItem(value: 'a-z', child: Text('A-Z')),
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

  Widget _buildContentList(AdminFaqViewModel viewModel) {
    if (viewModel.filteredItems.isEmpty) {
      return const Expanded(child: Center(child: Text('No FAQs found')));
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: viewModel.loadItems,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: viewModel.filteredItems.length,
          itemBuilder: (context, index) {
            final item = viewModel.filteredItems[index];
            return _buildFaqItem(context, viewModel, item);
          },
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, AdminFaqViewModel viewModel, FaqItem item) {
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt);

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
              Text(formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(item.question, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          trailing: _buildItemMenu(context, viewModel, item),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.answer, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                  if (item.answerImageUrl != null) ...[
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

  Widget _buildItemThumbnail(BuildContext context, String? imageUrl) {
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

  Widget _buildAnswerImage(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullImage(context, imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(imageUrl, height: 120, width: double.infinity, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildItemMenu(BuildContext context, AdminFaqViewModel viewModel, FaqItem item) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'edit') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FaqFormPage(
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
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, AdminFaqViewModel viewModel, FaqItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this FAQ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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

  void _showFullImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: Center(child: PhotoView(imageProvider: NetworkImage(imageUrl))),
        ),
      ),
    );
  }

  // ✅ Fixed: Use named parameters in callback
  Widget _buildAddButton(BuildContext context, AdminFaqViewModel viewModel) {
    return FloatingActionButton(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FaqFormPage(
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