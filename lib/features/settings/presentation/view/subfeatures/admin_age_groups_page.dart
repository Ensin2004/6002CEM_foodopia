import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/widgets/buttons/app_floating_action_button.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../viewmodel/admin_age_groups_viewmodel.dart';

/// Admin page for managing signup/profile age-group options.
class AdminAgeGroupsPage extends StatelessWidget {
  const AdminAgeGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminAgeGroupsViewModel(),
      child: const _AdminAgeGroupsPageView(),
    );
  }
}

class _AdminAgeGroupsPageView extends StatelessWidget {
  const _AdminAgeGroupsPageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminAgeGroupsViewModel>();

    return Scaffold(
      appBar: CustomAppBar(title: 'Age Groups', centerTitle: true),
      floatingActionButton: AppFloatingActionButton(
        onPressed: viewModel.isSaving
            ? null
            : () => _showAgeGroupDialog(context, viewModel),
        tooltip: 'Add Age Group',
      ),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : RefreshIndicator(
              onRefresh: viewModel.loadAgeGroups,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (viewModel.errorMessage != null)
                    _buildErrorMessage(viewModel.errorMessage!),
                  if (viewModel.ageGroups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: Text('No age groups yet')),
                    )
                  else
                    ...viewModel.ageGroups.map(
                      (item) => _buildAgeGroupItem(context, viewModel, item),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildAgeGroupItem(
    BuildContext context,
    AdminAgeGroupsViewModel viewModel,
    Map<String, dynamic> item,
  ) {
    final isActive = item['isActive'] as bool? ?? true;
    final description = item['description'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : Colors.grey.shade200,
          child: Icon(
            Icons.cake,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade600,
          ),
        ),
        title: Text(item['name'] as String? ?? ''),
        subtitle: Text(
          [
            if (description.isNotEmpty) description,
            isActive ? 'Active' : 'Inactive',
          ].join(' - '),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAgeGroupDialog(context, viewModel, item: item);
            } else if (value == 'delete') {
              _confirmDelete(context, viewModel, item);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade700)),
    );
  }

  void _showAgeGroupDialog(
    BuildContext context,
    AdminAgeGroupsViewModel viewModel, {
    Map<String, dynamic>? item,
  }) {
    final nameController = TextEditingController(
      text: item?['name'] as String? ?? '',
    );
    final descriptionController = TextEditingController(
      text: item?['description'] as String? ?? '',
    );
    final sortOrderController = TextEditingController(
      text: (item?['sortOrder'] ?? viewModel.ageGroups.length + 1).toString(),
    );
    var isActive = item?['isActive'] as bool? ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(item == null ? 'Add Age Group' : 'Edit Age Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 60,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sortOrderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sort order',
                    border: OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            SizedBox(
              width: 110,
              child: PrimaryButton(
                onPressed: () async {
                  final sortOrder =
                      int.tryParse(sortOrderController.text.trim()) ??
                      viewModel.ageGroups.length + 1;
                  final success = await viewModel.saveAgeGroup(
                    id: item?['id'] as String?,
                    name: nameController.text,
                    description: descriptionController.text,
                    sortOrder: sortOrder,
                    isActive: isActive,
                  );
                  if (success && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Age group saved')),
                    );
                  }
                },
                text: 'Save',
                verticalPadding: 10,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AdminAgeGroupsViewModel viewModel,
    Map<String, dynamic> item,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Age Group'),
        content: Text(
          'Delete ${item['name']}? Existing user profiles keep their current saved value.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await viewModel.deleteAgeGroup(
                item['id'] as String,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Age group deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
