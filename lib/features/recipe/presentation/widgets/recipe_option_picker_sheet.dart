import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../domain/entities/add_recipe_option.dart';

class RecipeOptionPickerSheet extends StatefulWidget {
  final String title;
  final String customHint;
  final String presetHeaderText;
  final String selectButtonText;
  final String customButtonText;
  final List<AddRecipeOption> options;
  final List<String> selectedOptionIds;
  final List<String> selectedCustomOptions;

  const RecipeOptionPickerSheet({
    super.key,
    required this.title,
    required this.customHint,
    required this.presetHeaderText,
    required this.selectButtonText,
    required this.customButtonText,
    required this.options,
    required this.selectedOptionIds,
    required this.selectedCustomOptions,
  });

  @override
  State<RecipeOptionPickerSheet> createState() =>
      _RecipeOptionPickerSheetState();
}

class _RecipeOptionPickerSheetState extends State<RecipeOptionPickerSheet> {
  final TextEditingController _customController = TextEditingController();
  late final Set<String> _selectedOptionIds;
  late final List<String> _customOptions;

  @override
  void initState() {
    super.initState();
    _selectedOptionIds = widget.selectedOptionIds.toSet();
    _customOptions = List<String>.from(widget.selectedCustomOptions);
    _customController.addListener(_onCustomTextChanged);
  }

  @override
  void dispose() {
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
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _customController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: widget.customHint,
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
                child: visibleOptions.isEmpty
                    ? Center(
                        child: Image.asset(
                          "assets/images/empty_page.png",
                          height: 120,
                        ),
                      )
                    : ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_customOptions.isNotEmpty) ...[
                                  Center(
                                    child: Text(
                                      widget.customHint,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.titleMedium,
                                    ),
                                  ),
                                  const Divider(color: AppColors.border),
                                  ..._customOptions.map((option) {
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
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    widget.presetHeaderText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.titleMedium,
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
                          )
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: hasSelection ? widget.selectButtonText : widget.customButtonText,
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
    if (query.isEmpty) return widget.options;
    final normalized = query.toLowerCase();
    return widget.options
        .where((option) => option.name.toLowerCase().contains(normalized))
        .toList();
  }

  // Toggle Helper
  void _toggleOption(String optionId) {
    setState(() {
      if (_selectedOptionIds.contains(optionId)) {
        _selectedOptionIds.remove(optionId);
      } else {
        _selectedOptionIds.add(optionId);
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
    Navigator.of(context).pop(
      RecipeOptionPickerSelection(
        optionIds: _selectedOptionIds.toList(),
        customOptions: List<String>.unmodifiable(_customOptions),
      ),
    );
  }

  void _onCustomTextChanged() {
    setState(() {});
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
