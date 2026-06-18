part of 'inspiration_tab_main_view.dart';

/// Ingredient picker bottom sheet for inspiration inputs.
///
/// Search state remains local while selected ingredients stay in the view model.
/// Ingredient picker bottom sheet.
class _IngredientPickerSheet extends StatefulWidget {
  /// Creates a new ingredient picker sheet instance.
  const _IngredientPickerSheet();

  @override
  State<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

/// State for the ingredient picker sheet.
class _IngredientPickerSheetState extends State<_IngredientPickerSheet> {
  /// Text controller for search input.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<MealPlanViewModel>();

    // Get bottom inset for keyboard.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle.
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Header.
            Text('Ingredients you have', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.md),

            // Search input.
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search or add custom ingredient',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: const Icon(Icons.search),
              ),
              onChanged: viewModel.searchIngredients,
              onSubmitted: viewModel.addCustomIngredient,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Add custom button.
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () {
                  viewModel.addCustomIngredient(_controller.text);
                  _controller.clear();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add typed ingredient'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Selected ingredients.
            Expanded(
              child: ListView(
                children: [
                  // Selected section.
                  Text('Selected', style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (viewModel.selectedIngredients.isEmpty)
                    Text(
                      'No ingredients added yet.',
                      style: context.text.bodyMedium,
                    )
                  else
                    _IngredientChips(
                      ingredients: viewModel.selectedIngredients,
                      isSelected: (_) => true,
                      onTap: viewModel.toggleIngredient,
                    ),

                  // Search results section.
                  Text('Search results', style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (viewModel.isIngredientSearching)
                    const LoadingDialog(
                      inline: true,
                      message: 'Searching ingredients...',
                    )
                  else if (_controller.text.trim().length < 2)
                    Text(
                      'Type at least 2 characters to search.',
                      style: context.text.bodyMedium,
                    )
                  else if (viewModel.ingredientSearchResults.isEmpty)
                    Center(
                      child: Image.asset(
                        'assets/images/empty_page.png',
                        height: 110,
                      ),
                    )
                  else
                    _IngredientChips(
                      ingredients: viewModel.ingredientSearchResults,
                      isSelected: (item) =>
                          viewModel.isIngredientSelected(item.name),
                      onTap: viewModel.toggleIngredient,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
