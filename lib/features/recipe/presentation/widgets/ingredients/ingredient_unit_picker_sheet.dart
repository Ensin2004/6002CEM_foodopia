import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../domain/entities/add_recipe_ingredient_unit.dart';

/// Bottom sheet for selecting and searching ingredient units
class IngredientUnitPickerSheet extends StatefulWidget {
  final List<AddRecipeIngredientUnit> units;
  final String selectedUnitId;
  final String selectedCustomUnit;

  const IngredientUnitPickerSheet({
    super.key,
    required this.units,
    required this.selectedUnitId,
    required this.selectedCustomUnit,
  });

  @override
  State<IngredientUnitPickerSheet> createState() => _UnitPickerSheetState();
}

/// The state class that manages unit selection and filtering.
class _UnitPickerSheetState extends State<IngredientUnitPickerSheet> {
  final TextEditingController _customUnitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customUnitController.addListener(_onCustomTextChanged);
  }

  @override
  // Clean up resources
  void dispose() {
    _customUnitController.removeListener(_onCustomTextChanged);
    _customUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    final query = _customUnitController.text.trim();
    final matchingUnits = _matchingUnits(query);
    final groupedUnits = _groupUnits(
      query.isEmpty ? widget.units : matchingUnits,
    );

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
                "Select Unit",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),

              // Search/Custom Input Field
              TextField(
                controller: _customUnitController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: "Unit",
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

              // Units List
              Expanded(
                child: groupedUnits.isEmpty
                    ? Center(
                      // Empty State
                        child: Image.asset(
                          "assets/images/empty_page.png",
                          height: 120,
                        ),
                      )
                    : ListView(
                        children: [
                          // Grouped units list
                          ...groupedUnits.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Header
                                  Center(
                                    child: Text(
                                      entry.key,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.labelLarge?.copyWith(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Divider(color: AppColors.border),

                                  // Units in the Category
                                  ...entry.value.map((unit) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          unit.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () => Navigator.of(context).pop(UnitPickerSelection.fromList(unit)),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action Button
              PrimaryButton(
                text: "Use Custom Unit",
                onPressed: query.isNotEmpty ? _submitSelection : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  /// Returns units that match the search query
  List<AddRecipeIngredientUnit> _matchingUnits(String query) {
    if (query.isEmpty) return widget.units;
    final normalized = query.toLowerCase();
    return widget.units
        .where((unit) => unit.name.toLowerCase().contains(normalized))
        .toList();
  }

  /// Groups units by their category name
  Map<String, List<AddRecipeIngredientUnit>> _groupUnits(
    List<AddRecipeIngredientUnit> units,
  ) {
    final grouped = <String, List<AddRecipeIngredientUnit>>{};
    for (final unit in units) {
      grouped.putIfAbsent(unit.categoryName, () => []).add(unit);
    }
    return grouped;
  }

  /// Submits the current text as the selected unit
  void _submitSelection() {
    final customUnit = _customUnitController.text.trim();
    if (customUnit.isEmpty) return;
    final matchingUnit = _unitByName(customUnit);
    if (matchingUnit != null) {
      Navigator.of(context).pop(UnitPickerSelection.fromList(matchingUnit));
      return;
    }
    Navigator.of(context).pop(UnitPickerSelection.custom(customUnit));
  }

  /// Finds a unit by its name
  AddRecipeIngredientUnit? _unitByName(String name) {
    final normalizedName = name.toLowerCase();
    for (final unit in widget.units) {
      if (unit.name.toLowerCase() == normalizedName) return unit;
    }
    return null;
  }

  /// Listener for text field changes
  void _onCustomTextChanged() {
    setState(() {});
  }
}

// Unit Picker Selection Class
class UnitPickerSelection {
  final String unitId;
  final String unitName;
  final bool isCustom;

  const UnitPickerSelection({
    required this.unitId,
    required this.unitName,
    required this.isCustom,
  });

  /// Creates a selection from a predefined unit
  factory UnitPickerSelection.fromList(AddRecipeIngredientUnit unit) {
    return UnitPickerSelection(
      unitId: unit.id,
      unitName: unit.name,
      isCustom: false,
    );
  }

  /// Creates a custom unit selection
  factory UnitPickerSelection.custom(String unitName) {
    return UnitPickerSelection(
      unitId: "",
      unitName: unitName,
      isCustom: true,
    );
  }
}
