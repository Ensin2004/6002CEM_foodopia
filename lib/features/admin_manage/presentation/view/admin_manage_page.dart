import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/tabs/app_segmented_tabs.dart';
import '../../../../core/widgets/box/app_tip_box.dart';
import '../../../../core/widgets/buttons/app_floating_action_button.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/admin_manage_item.dart';
import '../viewmodel/admin_manage_viewmodel.dart';
import '../widgets/admin_manage_form_widgets.dart';

const _green = Color(0xFF10A84E);
const _softGreen = Color(0xFFEAF8EF);
const _amber = Color(0xFFFFB800);
const _softAmber = Color(0xFFFFF8E4);

const _iconOptions = {
  'sunny': Icons.wb_sunny_outlined,
  'soup': Icons.ramen_dining,
  'cutlery': Icons.restaurant,
  'moon': Icons.nightlight_round,
  'cake': Icons.cake_outlined,
  'cupcake': Icons.bakery_dining,
  'drink': Icons.local_drink_outlined,
  'more': Icons.apps,
};

/// Admin manage screen following the high-fidelity prototype.
class AdminManagePage extends StatelessWidget {
  const AdminManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<AdminManageViewModel>(),
      child: const _AdminManageDashboard(),
    );
  }
}

class _AdminManageDashboard extends StatefulWidget {
  const _AdminManageDashboard();

  @override
  State<_AdminManageDashboard> createState() => _AdminManageDashboardState();
}

class _AdminManageDashboardState extends State<_AdminManageDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminManageViewModel>();

    if (viewModel.isLoading) {
      return const LoadingDialog();
    }

    return Column(
      children: [
        AppSegmentedTabs(
          controller: _tabController,
          tabs: const ['Categories', 'Preferences'],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DashboardTab(
                categories: AdminManageViewModel.recipeSetupCategories,
                viewModel: viewModel,
                showTip: false,
              ),
              _DashboardTab(
                categories: AdminManageViewModel.preferenceCategories,
                viewModel: viewModel,
                showTip: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final List<AdminManageCategory> categories;
  final AdminManageViewModel viewModel;
  final bool showTip;

  const _DashboardTab({
    required this.categories,
    required this.viewModel,
    required this.showTip,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: viewModel.loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          if (showTip)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTipBox(
                backgroundColor: _softAmber,
                iconColor: _amber,
                message:
                    'These items are used as default options in the app. Users can still search and add more custom items.',
              ),
            ),
          for (final category in categories)
            _CategoryCard(category: category, viewModel: viewModel),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AdminManageCategory category;
  final AdminManageViewModel viewModel;

  const _CategoryCard({required this.category, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final count = viewModel.itemsFor(category.id).length;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: _softGreen,
          child: Icon(category.icon, color: _green),
        ),
        title: Text(category.title, style: context.text.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(category.description, style: context.text.bodySmall),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _softGreen,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: viewModel,
                child: _AdminManageListPage(category: category),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminManageListPage extends StatelessWidget {
  final AdminManageCategory category;

  const _AdminManageListPage({required this.category});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminManageViewModel>();
    final items = viewModel.itemsFor(category.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'Edit ${category.title}'),
      floatingActionButton: AppFloatingActionButton(
        icon: Icons.add_box_outlined,
        label: 'Add New List',
        tooltip: 'Add New List',
        onPressed: () => _openForm(context, category),
      ),
      body: items.isEmpty
          ? RefreshIndicator(
              onRefresh: viewModel.loadAll,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _ListTip(category: category),
                  _EmptyList(category: category),
                  const SizedBox(height: 90),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length + 2,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex == 0 || oldIndex > items.length) return;
                viewModel.reorderItems(
                  categoryId: category.id,
                  oldIndex: oldIndex - 1,
                  newIndex: newIndex - 1,
                );
              },
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ListTip(
                    key: const ValueKey('admin_manage_tip'),
                    category: category,
                  );
                }
                if (index == items.length + 1) {
                  return const SizedBox(
                    key: ValueKey('admin_manage_bottom_space'),
                    height: 90,
                  );
                }

                final item = items[index - 1];
                return _ManageItemTile(
                  key: ValueKey(item.id),
                  category: category,
                  item: item,
                );
              },
            ),
    );
  }

  void _openForm(BuildContext context, AdminManageCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<AdminManageViewModel>(),
          child: _AdminManageFormPage(category: category),
        ),
      ),
    );
  }
}

class _ListTip extends StatelessWidget {
  final AdminManageCategory category;

  const _ListTip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppTipBox(
        backgroundColor: _softGreen,
        iconColor: _green,
        message: category.tip,
      ),
    );
  }
}

class _ManageItemTile extends StatelessWidget {
  final AdminManageCategory category;
  final AdminManageItem item;

  const _ManageItemTile({
    super.key,
    required this.category,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AdminManageViewModel>();
    final icon = _iconOptions[item.iconKey] ?? category.icon;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _softAmber,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _amber),
        ),
        title: Text(item.name, style: context.text.titleMedium),
        subtitle: Text(
          item.description.isEmpty
              ? (item.isActive ? 'Active' : 'Inactive')
              : item.description,
          style: context.text.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle, color: Colors.grey),
            const SizedBox(width: 8),
            Switch(
              value: item.isActive,
              activeThumbColor: _green,
              onChanged: (value) => viewModel.saveItem(
                categoryId: category.id,
                id: item.id,
                name: item.name,
                description: item.description,
                iconKey: item.iconKey,
                sortOrder: item.sortOrder,
                isActive: value,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: viewModel,
                        child: _AdminManageFormPage(
                          category: category,
                          item: item,
                        ),
                      ),
                    ),
                  );
                } else if (value == 'delete') {
                  viewModel.deleteItem(categoryId: category.id, id: item.id);
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
}

class _EmptyList extends StatelessWidget {
  final AdminManageCategory category;

  const _EmptyList({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', width: 150),
            const SizedBox(height: AppSpacing.md),
            Text(category.emptyMessage, style: context.text.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _AdminManageFormPage extends StatefulWidget {
  final AdminManageCategory category;
  final AdminManageItem? item;

  const _AdminManageFormPage({required this.category, this.item});

  @override
  State<_AdminManageFormPage> createState() => _AdminManageFormPageState();
}

class _AdminManageFormPageState extends State<_AdminManageFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String _iconKey = 'sunny';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _iconKey = item?.iconKey ?? 'sunny';
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminManageViewModel>();
    final isEditing = widget.item != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: '${isEditing ? 'Edit' : 'Add'} ${widget.category.itemLabel}',
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AdminManageFormLabel('${widget.category.itemLabel} Name'),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'e.g. Breakfast',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              counterText: '',
            ),
            maxLength: 30,
          ),
          const SizedBox(height: 18),
          const AdminManageFormLabel('Category Description (Optional)'),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'e.g. Morning meals to start the day right.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              counterText: '',
            ),
            maxLength: 50,
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          const AdminManageFormLabel('Category Icon'),
          const SizedBox(height: 8),
          AdminManageIconGrid(
            iconOptions: _iconOptions,
            selectedKey: _iconKey,
            onSelected: (key) => setState(() => _iconKey = key),
            selectedColor: _green,
            selectedIconColor: _amber,
          ),
          const SizedBox(height: 24),
          const AdminManageFormLabel('Status'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active', style: context.text.titleMedium),
                      Text(
                        'Show this category to users',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isActive,
                  activeThumbColor: _green,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            onPressed: viewModel.isSaving ? null : () => _save(context),
            text: 'Save',
            isLoading: viewModel.isSaving,
            verticalPadding: 16,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final viewModel = context.read<AdminManageViewModel>();
    final sortOrder =
        widget.item?.sortOrder ??
        viewModel.itemsFor(widget.category.id).length + 1;
    final success = await viewModel.saveItem(
      categoryId: widget.category.id,
      id: widget.item?.id,
      name: _nameController.text,
      description: _descriptionController.text,
      iconKey: _iconKey,
      sortOrder: sortOrder,
      isActive: _isActive,
    );

    if (success && context.mounted) {
      Navigator.pop(context);
    }
  }
}
