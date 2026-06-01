import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../domain/entities/add_recipe_food_search_result.dart';

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

class _IngredientNamePickerSheetState extends State<IngredientNamePickerSheet> {
  final TextEditingController _nameController = TextEditingController();
  Timer? _debounce;
  List<AddRecipeFoodSearchResult> _results = [];
  AddRecipeFoodSearchResult? _selectedFood;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.selectedName;
    _nameController.addListener(_onQueryChanged);
  }

  @override
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
              Text(
                "Select Ingredient",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
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
              Expanded(child: _buildResults(context, query)),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: _selectedFood != null ? "Select Ingredient" : "Use Custom Ingredient",
                onPressed: _selectedFood != null || query.isNotEmpty ? _submitSelection : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, String query) {
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

    if (query.length < 2 || _results.isEmpty) {
      return Center(
        child: Image.asset("assets/images/empty_page.png", height: 120),
      );
    }

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
              ..._results.map((food) {
                final selected = food.fdcId == _selectedFood?.fdcId;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm,),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: selected
                        ? CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.primary,
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          )
                        : null,
                    onTap: () => _toggleFood(food),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // Toggle Helper
  void _toggleFood(AddRecipeFoodSearchResult food) {
    setState(() {
      if (food.fdcId == _selectedFood?.fdcId) {
        _selectedFood = null;
      } else {
        _selectedFood = food;
      }
    });
  }

  // Submit Button Helper
  void _submitSelection() {
    final selectedFood = _selectedFood;
    if (selectedFood != null) {
      Navigator.of(context).pop(IngredientNamePickerSelection.usda(selectedFood));
      return;
    }

    final customName = _nameController.text.trim();
    if (customName.isEmpty) return;
    Navigator.of(context).pop(IngredientNamePickerSelection.custom(customName));
  }

  // Listener Helper
  void _onQueryChanged() {
    setState(() => _selectedFood = null);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchFoods(_nameController.text);
    });
  }

  Future<void> _searchFoods(String query) async {
    final trimmed = query.trim();
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

  factory IngredientNamePickerSelection.usda(AddRecipeFoodSearchResult food) {
    return IngredientNamePickerSelection(
      name: food.name,
      usdaId: food.fdcId,
      isCustom: false,
    );
  }

  factory IngredientNamePickerSelection.custom(String name) {
    return IngredientNamePickerSelection(
      name: name,
      usdaId: null,
      isCustom: true,
    );
  }
}
