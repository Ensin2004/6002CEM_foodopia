import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../domain/entities/add_recipe_ingredient_unit.dart';

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

class _UnitPickerSheetState extends State<IngredientUnitPickerSheet> {
  final TextEditingController _customUnitController = TextEditingController();
  AddRecipeIngredientUnit? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = _unitById(widget.selectedUnitId);
    _customUnitController.text = widget.selectedCustomUnit;
    _customUnitController.addListener(_onCustomTextChanged);
  }

  @override
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
                "Select Unit",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _customUnitController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: "Custom Unit",
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
              Expanded(
                child: widget.units.isEmpty || groupedUnits.isEmpty
                    ? Center(
                        child: Image.asset(
                          "assets/images/empty_page.png",
                          height: 120,
                        ),
                      )
                    : ListView(
                        children: groupedUnits.entries
                            .map(
                              (entry) => _UnitCategorySection(
                                categoryName: entry.key,
                                units: entry.value,
                                selectedUnitId: _selectedUnit?.id ?? "",
                                onSelected: (unit) {
                                  setState(() => _selectedUnit = unit);
                                },
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: _selectedUnit != null ? "Select Unit" : "Use Custom Unit",
                onPressed: _selectedUnit != null || query.isNotEmpty ? _submitSelection : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get Unit by ID
  AddRecipeIngredientUnit? _unitById(String id) {
    if (id.isEmpty) return null;
    for (final unit in widget.units) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  // Match, Group Helper
  List<AddRecipeIngredientUnit> _matchingUnits(String query) {
    if (query.isEmpty) return widget.units;
    final normalized = query.toLowerCase();
    return widget.units
        .where((unit) => unit.name.toLowerCase().contains(normalized))
        .toList();
  }

  Map<String, List<AddRecipeIngredientUnit>> _groupUnits(
    List<AddRecipeIngredientUnit> units,
  ) {
    final grouped = <String, List<AddRecipeIngredientUnit>>{};
    for (final unit in units) {
      grouped.putIfAbsent(unit.categoryName, () => []).add(unit);
    }
    return grouped;
  }

  // Submit Button Helper
  void _submitSelection() {
    if (_selectedUnit != null) {
      Navigator.of(context).pop(UnitPickerSelection.fromList(_selectedUnit!));
      return;
    }

    final customUnit = _customUnitController.text.trim();
    if (customUnit.isEmpty) return;
    Navigator.of(context).pop(UnitPickerSelection.custom(customUnit));
  }

  void _onCustomTextChanged() {
    if (_selectedUnit != null) {
      setState(() => _selectedUnit = null);
      return;
    }
    setState(() {});
  }
}

class _UnitCategorySection extends StatelessWidget {
  final String categoryName;
  final List<AddRecipeIngredientUnit> units;
  final String selectedUnitId;
  final ValueChanged<AddRecipeIngredientUnit> onSelected;

  const _UnitCategorySection({
    required this.categoryName,
    required this.units,
    required this.selectedUnitId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium,
            ),
          ),
          const Divider(color: AppColors.border),
          ...units.map((unit) {
            final selected = unit.id == selectedUnitId;
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
                onTap: () => onSelected(unit),
              ),
            );
          }),
        ],
      ),
    );
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

  factory UnitPickerSelection.fromList(AddRecipeIngredientUnit unit) {
    return UnitPickerSelection(
      unitId: unit.id,
      unitName: unit.name,
      isCustom: false,
    );
  }

  factory UnitPickerSelection.custom(String unitName) {
    return UnitPickerSelection(
        unitId: "",
        unitName: unitName,
        isCustom: true);
  }
}