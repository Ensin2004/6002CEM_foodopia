part of '../../../view/manage_grocery_list_page.dart';

/// Header widgets for the manage grocery list screen.
///
/// Summary metrics and title editing entry points stay close to the header UI.
/// Header card with grocery list summary.
class _HeaderCard extends StatelessWidget {
  /// The grocery list detail.
  final ManageGroceryListDetail detail;

  /// Creates a new header card instance.
  const _HeaderCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and edit button.
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F7E4),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: const Icon(
                  Icons.shopping_basket,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grocery list',
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Edit grocery list',
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(38, 38),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showEditListDialog(context, detail),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Metrics row.
          Row(
            children: [
              _HeaderMetric(
                icon: Icons.shopping_cart_outlined,
                value: '${detail.itemCount}',
                label: 'Items',
                sublabel: '${detail.categoryCount} categories',
              ),
              _HeaderDivider(),
              _HeaderMetric(
                icon: Icons.restaurant_outlined,
                value: '${detail.mealCount}',
                label: 'Meals',
                sublabel: _shortDateRange(detail.startDate, detail.endDate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Divider between header metrics.
class _HeaderDivider extends StatelessWidget {
  /// Creates a new header divider instance.
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.primary.withValues(alpha: 0.14),
    );
  }
}
