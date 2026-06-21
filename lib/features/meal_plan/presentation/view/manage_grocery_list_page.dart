import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../../../core/widgets/media/app_recipe_media.dart';
import '../../../../core/widgets/tabs/app_pill_segmented_control.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';
import '../../domain/usecases/add_grocery_item_usecase.dart';
import '../../domain/usecases/delete_grocery_item_usecase.dart';
import '../../domain/usecases/delete_grocery_list_usecase.dart';
import '../../domain/usecases/get_manage_grocery_list_detail_usecase.dart';
import '../../domain/usecases/update_grocery_item_bought_usecase.dart';
import '../../domain/usecases/update_grocery_list_usecase.dart';
import '../viewmodel/grocery/manage_grocery_list_viewmodel.dart';

part '../widgets/grocery/manage_grocery/manage_grocery_header_widgets.dart';
part '../widgets/grocery/manage_grocery/manage_grocery_dialogs.dart';
part '../widgets/grocery/manage_grocery/manage_grocery_common_widgets.dart';
part '../widgets/grocery/manage_grocery/manage_grocery_list_mode.dart';
part '../widgets/grocery/manage_grocery/manage_grocery_timeline_mode.dart';
part '../widgets/grocery/manage_grocery/manage_grocery_shared_widgets.dart';

/// Page for managing an existing grocery list.
/// Provides list view and timeline view modes with item management.
class ManageGroceryListPage extends StatelessWidget {
  /// ID of the grocery list to manage.
  final String listId;

  /// Creates a new manage grocery list page instance.
  const ManageGroceryListPage({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => ManageGroceryListViewModel(
        listId: listId,
        getDetailUseCase: sl<GetManageGroceryListDetailUseCase>(),
        addGroceryItemUseCase: sl<AddGroceryItemUseCase>(),
        deleteGroceryItemUseCase: sl<DeleteGroceryItemUseCase>(),
        deleteGroceryListUseCase: sl<DeleteGroceryListUseCase>(),
        updateItemBoughtUseCase: sl<UpdateGroceryItemBoughtUseCase>(),
        updateGroceryListUseCase: sl<UpdateGroceryListUseCase>(),
      ),
      child: const _ManageGroceryListView(),
    );
  }
}

/// Internal view for the manage grocery list page.
class _ManageGroceryListView extends StatelessWidget {
  /// Creates a new manage grocery list view instance.
  const _ManageGroceryListView();

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Show loading dialog while detail is loading.
    if (viewModel.isLoading && viewModel.detail == null) {
      return const Scaffold(
        body: LoadingDialog(inline: true, message: 'Loading grocery list...'),
      );
    }

    // Get the detail.
    final detail = viewModel.detail;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.pop(viewModel.hasSavedChanges);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Manage Grocery List',
          leading: IconButton(
            onPressed: () => context.pop(viewModel.hasSavedChanges),
            icon: const Icon(Icons.chevron_left),
          ),
          actions: [
            IconButton(
              tooltip: 'Delete grocery list',
              onPressed: viewModel.isSaving || detail == null
                  ? null
                  : () => _confirmDeleteList(context, detail),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
          ],
        ),
        body: detail == null
            ? _ErrorState(
                message:
                    viewModel.errorMessage ?? 'Unable to load grocery list',
                onRetry: viewModel.loadDetail,
              )
            : _ManageContent(detail: detail),
      ),
    );
  }
}

/// Confirms and deletes the current grocery list.
Future<void> _confirmDeleteList(
  BuildContext context,
  ManageGroceryListDetail detail,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete grocery list?', style: context.text.titleMedium),
      content: Text(
        'Delete "${detail.title}"? This will remove this grocery list and its shopping items.',
        style: context.text.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const LoadingDialog(message: 'Deleting grocery list...'),
  );

  final viewModel = context.read<ManageGroceryListViewModel>();
  final deleted = await viewModel.deleteList();

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  if (deleted) {
    context.pop(true);
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          viewModel.actionErrorMessage ?? 'Unable to delete grocery list.',
        ),
      ),
    );
}

/// Main content widget for the manage grocery list page.
class _ManageContent extends StatelessWidget {
  /// The grocery list detail.
  final ManageGroceryListDetail detail;

  /// Creates a new manage content instance.
  const _ManageContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return Stack(
      children: [
        // Main scrollable content.
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            88,
          ),
          children: [
            // Header card with summary metrics.
            _HeaderCard(detail: detail),
            const SizedBox(height: AppSpacing.lg),

            // View mode tabs.
            const _ViewModeTabs(),
            const SizedBox(height: AppSpacing.xl),

            // Dynamic content based on view mode.
            if (viewModel.viewMode == ManageGroceryViewMode.list)
              _ListMode(detail: detail)
            else
              _TimelineMode(detail: detail),

            // Error message if any.
            if (viewModel.actionErrorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              _InlineActionError(message: viewModel.actionErrorMessage!),
            ],
          ],
        ),

        // Bottom bar based on view mode.
        if (viewModel.viewMode == ManageGroceryViewMode.list)
          const Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: _AddIngredientBar(),
          )
        else
          const Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: _HideBoughtBar(),
          ),
      ],
    );
  }
}
