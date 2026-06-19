part of 'inspiration_tab_main_view.dart';

/// Preference editor bottom sheet for inspiration inputs.
///
/// Diet, allergies, and dislikes are edited in one settings-style sheet.
/// Preference editor bottom sheet.
class _PreferenceEditorSheet extends StatefulWidget {
  /// Creates a new preference editor sheet instance.
  const _PreferenceEditorSheet();

  @override
  State<_PreferenceEditorSheet> createState() => _PreferenceEditorSheetState();
}

/// State for the preference editor sheet.
class _PreferenceEditorSheetState extends State<_PreferenceEditorSheet> {
  /// Controller for allergy input.
  final _allergyController = TextEditingController();

  /// Controller for dislike input.
  final _dislikeController = TextEditingController();

  @override
  void dispose() {
    _allergyController.dispose();
    _dislikeController.dispose();
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
        child: ListView(
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
            Text(
              'Set your preferences',
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Meal preference uses saved defaults. Allergies and dislikes can also come from search or custom input.',
              style: context.text.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Meal preference section.
            _PreferenceOptionSection(
              title: 'Meal preference',
              options: viewModel.dietOptions,
              selectedValues: {viewModel.overrideDiet},
              onSelected: viewModel.selectOverrideDiet,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Allergies section.
            _PreferenceSearchOptionSection(
              title: 'Allergies',
              options: viewModel.allergyOptions,
              selectedValues: viewModel.overrideAllergies.toSet(),
              onSelected: viewModel.toggleOverrideAllergy,
              controller: _allergyController,
              onSearch: viewModel.searchPreferenceFoods,
              onAddCustom: viewModel.addCustomOverrideAllergy,
              isSearching: viewModel.isPreferenceSearching,
              searchResults: viewModel.preferenceSearchResults,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Dislikes section.
            _PreferenceSearchOptionSection(
              title: 'Dislikes',
              options: viewModel.dislikeOptions,
              selectedValues: viewModel.overrideDislikes.toSet(),
              onSelected: viewModel.toggleOverrideDislike,
              controller: _dislikeController,
              onSearch: viewModel.searchPreferenceFoods,
              onAddCustom: viewModel.addCustomOverrideDislike,
              isSearching: viewModel.isPreferenceSearching,
              searchResults: viewModel.preferenceSearchResults,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Done button.
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Done',
                  style: context.text.labelLarge?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preference option section widget.
class _PreferenceOptionSection extends StatelessWidget {
  /// Section title.
  final String title;

  /// List of options.
  final List<MealPlanPreferenceOption> options;

  /// Set of selected values.
  final Set<String> selectedValues;

  /// Callback when an option is selected.
  final ValueChanged<String> onSelected;

  /// Creates a new preference option section instance.
  const _PreferenceOptionSection({
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),

        // Show options or empty message.
        if (options.isEmpty)
          Text('No options available yet.', style: context.text.bodyMedium)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                _MiniChoiceChip(
                  label: option.name,
                  selected: selectedValues.contains(option.name),
                  onTap: () => onSelected(option.name),
                ),
            ],
          ),
      ],
    );
  }
}

/// Preference search option section widget.
class _PreferenceSearchOptionSection extends StatelessWidget {
  /// Section title.
  final String title;

  /// List of options.
  final List<MealPlanPreferenceOption> options;

  /// Set of selected values.
  final Set<String> selectedValues;

  /// Callback when an option is selected.
  final ValueChanged<String> onSelected;

  /// Text controller for search input.
  final TextEditingController controller;

  /// Callback when search text changes.
  final ValueChanged<String> onSearch;

  /// Callback when adding a custom value.
  final ValueChanged<String> onAddCustom;

  /// Whether search is in progress.
  final bool isSearching;

  /// Search results.
  final List<MealPlanInspirationIngredient> searchResults;

  /// Creates a new preference search option section instance.
  const _PreferenceSearchOptionSection({
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onSelected,
    required this.controller,
    required this.onSearch,
    required this.onAddCustom,
    required this.isSearching,
    required this.searchResults,
  });

  @override
  Widget build(BuildContext context) {
    // Get the search query.
    final query = controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Options section.
        _PreferenceOptionSection(
          title: title,
          options: options,
          selectedValues: selectedValues,
          onSelected: onSelected,
        ),
        const SizedBox(height: AppSpacing.md),

        // Search input.
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search or add custom ${title.toLowerCase()}',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              onPressed: () {
                onAddCustom(controller.text);
                controller.clear();
              },
              icon: const Icon(Icons.add),
            ),
          ),
          onChanged: onSearch,
          onSubmitted: onAddCustom,
        ),

        // Search results.
        if (query.length >= 2) ...[
          const SizedBox(height: AppSpacing.sm),
          if (isSearching)
            const LoadingDialog(inline: true, message: 'Searching foods...')
          else if (searchResults.isEmpty)
            Text('No results found.', style: context.text.bodyMedium)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in searchResults)
                  _MiniChoiceChip(
                    label: item.name,
                    selected: selectedValues.contains(item.name),
                    onTap: () => onSelected(item.name),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}
