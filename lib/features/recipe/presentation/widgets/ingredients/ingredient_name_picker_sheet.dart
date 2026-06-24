import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../domain/entities/add_recipe_food_search_result.dart';

/// Bottom sheet for selecting and searching ingredients
class IngredientNamePickerSheet extends StatefulWidget {
  final String selectedName;
  final int? selectedUsdaId;
  final Future<List<AddRecipeFoodSearchResult>> Function(String query)
  onSearchFoods;

  const IngredientNamePickerSheet({
    super.key,
    required this.selectedName,
    required this.selectedUsdaId,
    required this.onSearchFoods,
  });

  @override
  State<IngredientNamePickerSheet> createState() => _IngredientNamePickerSheetState();
}

/// The state class that manages search results and user input.
class _IngredientNamePickerSheetState extends State<IngredientNamePickerSheet> {
  final TextEditingController _nameController = TextEditingController();
  Timer? _debounce;
  List<AddRecipeFoodSearchResult> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onQueryChanged);
  }

  @override
  // Clean up resources
  void dispose() {
    _debounce?.cancel();
    _nameController.removeListener(_onQueryChanged);
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    final query = _nameController.text.trim();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual indicator that the sheet can be dragged down
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

              // Header
              Text(
                "Select Ingredient",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),

              // Search/Custom Input Field
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: "Ingredient Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onSubmitted: (_) => _submitSelection(),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Ingredients List
              Expanded(child: _buildResults(context, query)),
              const SizedBox(height: AppSpacing.lg),

              // Action Button
              PrimaryButton(
                text: "Use Custom Ingredient",
                onPressed: query.isNotEmpty ? _submitSelection : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the results display based on current state
  Widget _buildResults(BuildContext context, String query) {
    // Food Search Loading Indicator
    if (_isSearching) {
      return ListView(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    // Empty State
    if (query.length < 2 || _results.isEmpty) {
      return Center(
        child: Image.asset("assets/images/empty_page.png", height: 120),
      );
    }

    // Show Results
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Search Results",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Divider(color: AppColors.border),

              // Map each search result to a selectable list tile
              ..._results.map((food) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(context).pop(IngredientNamePickerSelection.usda(food)),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  /// Submits the current text as the selected ingredient
  void _submitSelection() {
    final customName = _nameController.text.trim();
    if (customName.isEmpty) return;
    Navigator.of(context).pop(IngredientNamePickerSelection.custom(customName));
  }

  // ============================================================
  // Search Methods
  // ============================================================

  /// Listener for text field changes
  void _onQueryChanged() {
    setState(() {});

    // Cancel pending search and start a new debounced search
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchFoods(_nameController.text);
    });
  }

  /// Searches for foods based on the query text
  Future<void> _searchFoods(String query) async {
    final trimmed = query.trim();

    // Don't search for short queries (less than 2 characters)
    if (trimmed.length < 2) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await widget.onSearchFoods(trimmed);
    if (!mounted || trimmed != _nameController.text.trim()) return;

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }
}

// Ingredient Name Picker Selection Class
class IngredientNamePickerSelection {
  final String name;
  final int? usdaId;
  final bool isCustom;

  const IngredientNamePickerSelection({
    required this.name,
    required this.usdaId,
    required this.isCustom,
  });

  /// Creates a selection from a USDA food search result
  factory IngredientNamePickerSelection.usda(AddRecipeFoodSearchResult food) {
    return IngredientNamePickerSelection(
      name: food.name,
      usdaId: food.fdcId,
      isCustom: false,
    );
  }

  /// Creates a custom selection from a user-entered name
  factory IngredientNamePickerSelection.custom(String name) {
    return IngredientNamePickerSelection(
      name: name,
      usdaId: null,
      isCustom: true,
    );
  }
}
