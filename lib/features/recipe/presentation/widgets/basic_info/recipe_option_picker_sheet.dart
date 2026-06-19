import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../domain/entities/add_recipe_food_search_result.dart';
import '../../../domain/entities/add_recipe_option.dart';

typedef SearchFoodsCallback = Future<List<AddRecipeFoodSearchResult>> Function(String query);

/// Bottom sheet for selecting and searching categories or allergen info
class RecipeOptionPickerSheet extends StatefulWidget {
  final String pickType;
  final List<AddRecipeOption> options;
  final List<String> selectedOptionIds;
  final List<String> selectedCustomOptions;
  final SearchFoodsCallback? onSearchFoods;

  const RecipeOptionPickerSheet({
    super.key,
    required this.pickType,
    required this.options,
    required this.selectedOptionIds,
    required this.selectedCustomOptions,
    this.onSearchFoods,
  });

  @override
  State<RecipeOptionPickerSheet> createState() =>
      _RecipeOptionPickerSheetState();
}

class _RecipeOptionPickerSheetState extends State<RecipeOptionPickerSheet> {
  final TextEditingController _customController = TextEditingController();
  late final Set<String> _selectedOptionIds;
  late final List<String> _customOptions;
  Timer? _debounce;
  List<AddRecipeFoodSearchResult> _searchResults = [];
  bool _isSearchingFoods = false;

  @override
  void initState() {
    super.initState();
    _selectedOptionIds = widget.selectedOptionIds.toSet();
    _customOptions = List<String>.from(widget.selectedCustomOptions);
    _customController.addListener(_onCustomTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _customController.removeListener(_onCustomTextChanged);
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    final query = _customController.text.trim();
    final visibleOptions = _matchingOptions(query);
    final visibleCustomOptions = _matchingCustomOptions(query);
    final hasSelection =
        _selectedOptionIds.isNotEmpty || _customOptions.isNotEmpty;

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
                "Select ${widget.pickType}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _customController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: widget.pickType,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onSubmitted: (_) => _addCustomOption(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child:
                    visibleCustomOptions.isEmpty &&
                        visibleOptions.isEmpty &&
                        _searchResults.isEmpty &&
                        !_isSearchingFoods
                    ? Center(
                        child: Image.asset(
                          "assets/images/empty_page.png",
                          height: 120,
                        ),
                      )
                    : ListView(
                        children: [
                          if (visibleCustomOptions.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      "Custom ${widget.pickType}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.labelLarge?.copyWith(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Divider(color: AppColors.border),
                                  ...visibleCustomOptions.map((option) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          option,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: AppColors.primary,
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                        onTap: () => _removeCustomOption(option),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                          if (visibleOptions.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      "Preset ${widget.pickType}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.labelLarge?.copyWith(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Divider(color: AppColors.border),
                                  ...visibleOptions.map((option) {
                                    final selected = _selectedOptionIds.contains(option.id);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          option.name,
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
                                        onTap: () => _toggleOption(option.id),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                          if (_isSearchingFoods) ...[
                            const Padding(
                              padding: EdgeInsets.only(top: AppSpacing.sm),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ],
                          if (_searchResults.isNotEmpty) ...[
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
                                  ..._searchResults.map((food) {
                                    final selected = _customOptions.any(
                                      (option) => option.toLowerCase() == food.name.toLowerCase(),
                                    );
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
                                        onTap: () => _toggleFoodOption(food),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: query.isNotEmpty ? "Use Custom ${widget.pickType}" : "Select ${widget.pickType}",
                onPressed: hasSelection || query.isNotEmpty ? _submitSelection : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get Option by Name
  AddRecipeOption? _optionByName(String name) {
    final normalizedName = name.toLowerCase();
    for (final option in widget.options) {
      if (option.name.toLowerCase() == normalizedName) return option;
    }
    return null;
  }

  // Match Helper
  List<AddRecipeOption> _matchingOptions(String query) {
    final normalized = query.toLowerCase();
    final matches = query.isEmpty
        ? List<AddRecipeOption>.from(widget.options)
        : widget.options
              .where((option) => option.name.toLowerCase().contains(normalized))
              .toList();

    return matches..sort(
      (first, second) => first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
  }

  List<String> _matchingCustomOptions(String query) {
    final normalized = query.toLowerCase();
    final matches = query.isEmpty
        ? List<String>.from(_customOptions)
        : _customOptions
              .where((option) => option.toLowerCase().contains(normalized))
              .toList();

    return matches..sort(
      (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
    );
  }

  // Toggle Helper
  void _toggleOption(String optionId) {
    setState(() {
      if (_selectedOptionIds.contains(optionId)) {
        _selectedOptionIds.remove(optionId);
      } else {
        _selectedOptionIds.add(optionId);
        _customController.clear();
      }
    });
  }

  void _toggleFoodOption(AddRecipeFoodSearchResult food) {
    final existingIndex = _customOptions.indexWhere(
      (option) => option.toLowerCase() == food.name.toLowerCase(),
    );

    setState(() {
      if (existingIndex >= 0) {
        _customOptions.removeAt(existingIndex);
      } else {
        _customOptions.add(food.name);
        _customController.clear();
      }
    });
  }

  // Add, Remove Custom Helper
  void _addCustomOption() {
    final customOption = _customController.text.trim();
    if (customOption.isEmpty) return;

    final existsInCustom = _customOptions.any(
      (option) => option.toLowerCase() == customOption.toLowerCase(),
    );
    final matchingOption = _optionByName(customOption);
    if (matchingOption != null) {
      setState(() {
        _selectedOptionIds.add(matchingOption.id);
        _customController.clear();
      });
      return;
    }

    if (existsInCustom) {
      _customController.clear();
      return;
    }

    setState(() {
      _customOptions.add(customOption);
      _customController.clear();
    });
  }

  void _removeCustomOption(String option) {
    setState(() => _customOptions.remove(option));
  }

  // Submit Button Helper
  void _submitSelection() {
    _addCustomOption();
    _movePresetMatchingCustomOptions();
    Navigator.of(context).pop(
      RecipeOptionPickerSelection(
        optionIds: _selectedOptionIds.toList(),
        customOptions: _customOptions,
      ),
    );
  }

  void _movePresetMatchingCustomOptions() {
    final remainingCustomOptions = <String>[];
    for (final customOption in _customOptions) {
      final matchingOption = _optionByName(customOption);
      if (matchingOption == null) {
        remainingCustomOptions.add(customOption);
      } else {
        _selectedOptionIds.add(matchingOption.id);
      }
    }

    _customOptions
      ..clear()
      ..addAll(remainingCustomOptions);
  }

  // Listener Helper
  void _onCustomTextChanged() {
    setState(() {});
    if (widget.onSearchFoods == null) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchFoods(_customController.text);
    });
  }

  Future<void> _searchFoods(String query) async {
    final searchFoods = widget.onSearchFoods;
    final trimmed = query.trim();
    if (searchFoods == null || trimmed.length < 2) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearchingFoods = false;
      });
      return;
    }

    setState(() => _isSearchingFoods = true);
    final results = await searchFoods(trimmed);
    if (!mounted || trimmed != _customController.text.trim()) return;

    setState(() {
      _searchResults = results;
      _isSearchingFoods = false;
    });
  }
}

// Recipe Option Picker Selection Class
class RecipeOptionPickerSelection {
  final List<String> optionIds;
  final List<String> customOptions;

  const RecipeOptionPickerSelection({
    required this.optionIds,
    required this.customOptions,
  });
}
