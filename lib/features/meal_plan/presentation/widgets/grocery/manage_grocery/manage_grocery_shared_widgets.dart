part of '../../../view/manage_grocery_list_page.dart';

/// Shared manage grocery widgets and formatting helpers.
///
/// Media preview, count badges, bottom bars, and error states support both modes.
/// Meal image widget.
class _MealImage extends StatelessWidget {
  /// Image path.
  final String path;

  /// Image width.
  final double width;

  /// Image height.
  final double height;

  /// Image fit.
  final BoxFit fit;

  /// Creates a new meal image instance.
  const _MealImage({
    required this.path,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final previewPath = recipeMediaStaticPreviewPath(path);
    if (previewPath != path.trim()) {
      return AppRemoteOrAssetImage(
        imagePath: previewPath,
        width: width,
        height: height,
        fit: fit,
      );
    }

    // Shared media preview handles regular image paths and non-Cloudinary videos.
    return SizedBox(
      width: width,
      height: height,
      child: AppRecipeMediaPreview(
        mediaPath: path,
        fit: fit,
        playOverlaySize: width < 60 ? 30 : 38,
        playIconSize: width < 60 ? 20 : 26,
      ),
    );
  }
}

/// Timeline ingredient widget.
class _TimelineIngredient extends StatelessWidget {
  /// The ingredient item.
  final ManageGroceryItem item;

  /// Creates a new timeline ingredient instance.
  const _TimelineIngredient({required this.item});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Skip if item should be hidden.
    if (!viewModel.shouldShowItem(item.id)) return const SizedBox.shrink();

    return Row(
      children: [
        Checkbox(
          value: viewModel.isBought(item.id),
          onChanged: (_) =>
              context.read<ManageGroceryListViewModel>().toggleBought(item.id),
        ),
        Expanded(child: Text(item.name, style: context.text.bodySmall)),
        Text(item.quantityLabel, style: context.text.bodySmall),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: 'Delete ingredient',
          visualDensity: VisualDensity.compact,
          onPressed: viewModel.isSaving
              ? null
              : () => context.read<ManageGroceryListViewModel>().deleteItem(
                  item.id,
                ),
          icon: const Icon(Icons.delete_outline, size: 16),
        ),
      ],
    );
  }
}

/// Count badge widget.
class _CountBadge extends StatelessWidget {
  /// Label text.
  final String label;

  /// Creates a new count badge instance.
  const _CountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: context.text.bodySmall?.copyWith(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Add ingredient bar widget.
class _AddIngredientBar extends StatelessWidget {
  /// Creates a new add ingredient bar instance.
  const _AddIngredientBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _showAddIngredientDialog(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 44,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Add Ingredient', style: context.text.bodyMedium),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 88,
          height: 44,
          child: ElevatedButton(
            onPressed: () => _showAddIngredientDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add'),
          ),
        ),
      ],
    );
  }
}

/// Hide bought items bar widget.
class _HideBoughtBar extends StatelessWidget {
  /// Creates a new hide bought bar instance.
  const _HideBoughtBar();

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Hide bought items', style: context.text.bodyMedium),
                Text(
                  'Checked items will be hidden',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: viewModel.hideBoughtItems,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
            onChanged: context
                .read<ManageGroceryListViewModel>()
                .toggleHideBoughtItems,
          ),
        ],
      ),
    );
  }
}

/// Error state widget.
class _ErrorState extends StatelessWidget {
  /// Error message.
  final String message;

  /// Callback when retry is pressed.
  final Future<void> Function() onRetry;

  /// Creates a new error state instance.
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', height: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

/// Formats a short date range.
String _shortDateRange(DateTime start, DateTime end) {
  return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}';
}
