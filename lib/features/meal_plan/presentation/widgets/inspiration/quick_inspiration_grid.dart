part of 'inspiration_tab_main_view.dart';

/// Quick inspiration grid and card widgets.
///
/// Preset inspiration cards provide fast entry points into AI meal generation.
/// Quick inspiration grid widget.
class _QuickInspirationGrid extends StatelessWidget {
  /// List of quick inspiration items.
  final List<MealPlanQuickInspiration> items;

  /// Callback when a quick inspiration item is selected.
  final ValueChanged<MealPlanQuickInspiration> onSelected;

  /// Creates a new quick inspiration grid instance.
  const _QuickInspirationGrid({required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    // Show empty state if no items.
    if (items.isEmpty) {
      return Center(
        child: Image.asset('assets/images/empty_page.png', height: 140),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive item width.
        const columns = 3;
        const spacing = AppSpacing.sm;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                height: 160,
                child: _QuickInspirationCard(
                  item: item,
                  onTap: () => onSelected(item),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Quick inspiration card widget.
class _QuickInspirationCard extends StatelessWidget {
  /// The inspiration item.
  final MealPlanQuickInspiration item;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Creates a new quick inspiration card instance.
  const _QuickInspirationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image.
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Stack(
                children: [
                  Image.asset(
                    item.imagePath,
                    height: 64,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.textPrimary,
                        size: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(height: 1.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
