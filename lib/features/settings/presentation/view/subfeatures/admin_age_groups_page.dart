import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/widgets/buttons/app_floating_action_button.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../viewmodel/admin_age_groups_viewmodel.dart';

/// Admin page for managing signup/profile age-group options.
/// Provides CRUD operations for age groups with reorderable list.
class AdminAgeGroupsPage extends StatelessWidget {
  /// Creates a new admin age groups page instance.
  const AdminAgeGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => AdminAgeGroupsViewModel(),
      child: const _AdminAgeGroupsPageView(),
    );
  }
}

/// Internal view for the admin age groups page.
class _AdminAgeGroupsPageView extends StatelessWidget {
  /// Creates a new admin age groups page view instance.
  const _AdminAgeGroupsPageView();

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
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
          : viewModel.ageGroups.isEmpty
          ? RefreshIndicator(
        onRefresh: viewModel.loadAgeGroups,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Error message if any.
            if (viewModel.errorMessage != null)
              _buildErrorMessage(viewModel.errorMessage!),

            // Empty state.
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: Text('No age groups yet')),
            ),
            const SizedBox(height: 80),
          ],
        ),
      )
          : ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount:
        viewModel.ageGroups.length +
            (viewModel.errorMessage != null ? 2 : 1),
        onReorder: (oldIndex, newIndex) {
          // Adjust index offset for error message.
          final offset = viewModel.errorMessage != null ? 1 : 0;
          if (oldIndex < offset) return;
          viewModel.reorderAgeGroups(
            oldIndex: oldIndex - offset,
            newIndex: newIndex - offset,
          );
        },
        itemBuilder: (context, index) {
          // Build error message at the top if present.
          if (viewModel.errorMessage != null && index == 0) {
            return Container(
              key: const ValueKey('age_group_error'),
              child: _buildErrorMessage(viewModel.errorMessage!),
            );
          }

          // Calculate the actual item index.
          final offset = viewModel.errorMessage != null ? 1 : 0;
          final itemIndex = index - offset;

          // Add bottom spacing.
          if (itemIndex == viewModel.ageGroups.length) {
            return const SizedBox(
              key: ValueKey('age_group_bottom_space'),
              height: 80,
            );
          }

          // Build the age group item.
          final item = viewModel.ageGroups[itemIndex];
          return _buildAgeGroupItem(context, viewModel, item);
        },
      ),
    );
  }

  // =========================================================================
  // WIDGET BUILDERS
  // =========================================================================

  /// Builds an age group list item.
  Widget _buildAgeGroupItem(
      BuildContext context,
      AdminAgeGroupsViewModel viewModel,
      Map<String, dynamic> item,
      ) {
    // Get active status.
    final isActive = item['isActive'] as bool? ?? true;

    // Get description.
    final description = item['description'] as String? ?? '';

    return Card(
      key: ValueKey(item['id']),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle for reordering.
            const Icon(Icons.drag_handle, color: Colors.grey),

            // Edit/delete popup menu.
            PopupMenuButton<String>(
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
          ],
        ),
      ),
    );
  }

  /// Builds an error message widget.
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

  // =========================================================================
  // DIALOGS
  // =========================================================================

  /// Shows the add/edit age group dialog.
  void _showAgeGroupDialog(
      BuildContext context,
      AdminAgeGroupsViewModel viewModel, {
        Map<String, dynamic>? item,
      }) {
    // Initialize controllers with existing data if editing.
    final nameController = TextEditingController(
      text: item?['name'] as String? ?? '',
    );
    final descriptionController = TextEditingController(
      text: item?['description'] as String? ?? '',
    );

    // Get active status.
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
                // Name field.
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 60,
                ),
                const SizedBox(height: 12),

                // Description field.
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                ),

                // Active toggle.
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
                  // Save the age group.
                  final success = await viewModel.saveAgeGroup(
                    id: item?['id'] as String?,
                    name: nameController.text,
                    description: descriptionController.text,
                    sortOrder:
                    item?['sortOrder'] as int? ??
                        viewModel.ageGroups.length + 1,
                    isActive: isActive,
                  );

                  // Close dialog and show feedback if successful.
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

  /// Shows the delete confirmation dialog.
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
              // Delete the age group.
              final success = await viewModel.deleteAgeGroup(
                item['id'] as String,
              );

              // Close dialog.
              if (dialogContext.mounted) Navigator.pop(dialogContext);

              // Show feedback if successful.
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