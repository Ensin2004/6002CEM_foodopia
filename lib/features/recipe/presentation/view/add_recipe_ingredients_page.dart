import 'dart:io';

import 'package:flutter/material.dart';
import 'package:foodopia/features/recipe/presentation/widgets/input_ingredient_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/progress_bar/app_step_progress_bar.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/usecases/get_add_recipe_ingredient_units_usecase.dart';
import '../../domain/usecases/save_add_recipe_ingredients_usecase.dart';
import '../viewmodel/add_recipe_ingredients_viewmodel.dart';
import '../widgets/ingredient_unit_picker.dart';
import '../widgets/input_label.dart';

class AddRecipeIngredientsPage extends StatelessWidget {
  final String recipeId;

  const AddRecipeIngredientsPage({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddRecipeIngredientsViewModel(
        getIngredientUnitsUseCase: sl<GetAddRecipeIngredientUnitsUseCase>(),
        saveIngredientsUseCase: sl<SaveAddRecipeIngredientsUseCase>(),
      ),
      child: _AddRecipeIngredientsView(recipeId: recipeId),
    );
  }
}

class _AddRecipeIngredientsView extends StatefulWidget {
  final String recipeId;

  const _AddRecipeIngredientsView({required this.recipeId});

  @override
  State<_AddRecipeIngredientsView> createState() =>
      _AddRecipeIngredientsViewState();
}

class _AddRecipeIngredientsViewState extends State<_AddRecipeIngredientsView> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<IngredientRowState> _rows = [IngredientRowState()];

  @override
  void initState() {
    super.initState();
    for (final row in _rows) {
      row.addListener(_refreshFormState);
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddRecipeIngredientsViewModel>();
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? 48.0
        : AppSpacing.lg;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: "New Recipe"),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: AppStepProgressBar(
                totalSteps: 4,
                currentStep: 2,
                labels: ["Basic Info", "Ingredients", "Instructions", "Review"],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.sm,
                horizontalPadding,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputLabel(text: "Ingredients", isRequired: true),
                  const SizedBox(height: 2),
                  Text(
                    "Add all the ingredients for your recipe",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),

            // Input Fields
            Expanded(
              child: ReorderableListView.builder(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  0,
                ),
                buildDefaultDragHandles: false,
                itemCount: _rows.length,
                onReorder: _reorderRows,
                itemBuilder: (context, index) {
                  final row = _rows[index];
                  return Padding(
                    key: ValueKey(row.id),
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: InputIngredientField(
                      index: index,
                      row: row,
                      onPickImage: () => _pickIngredientImage(row),
                      onSelectUnit: () =>
                          _showUnitSheet(row: row, units: viewModel.units),
                      onDelete: () => _removeRow(index),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.lg,
                horizontalPadding,
                AppSpacing.sm,
              ),
              child: SecondaryButton(
                text: "+  Add Ingredient",
                onPressed: _addRow,
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.sm,
                horizontalPadding,
                AppSpacing.sm,
              ),
              child: PrimaryButton(
                text: "Next",
                isLoading: viewModel.isSaving,
                onPressed: viewModel.isSaving || !_canSave
                    ? null
                    : () => _handleNext(context, viewModel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Image Picker Helper
  Future<void> _pickIngredientImage(IngredientRowState row) async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => row.imageFile = File(image.path));
  }

  // Unit Picker Helper
  Future<void> _showUnitSheet({
    required IngredientRowState row,
    required List<String> units,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          UnitPickerSheet(units: units, selectedUnit: row.unit),
    );

    if (selected == null) return;
    setState(() => row.unit = selected);
  }

  // Add, Remove, Reorder Helper
  void _addRow() {
    final row = IngredientRowState();
    row.addListener(_refreshFormState);
    setState(() => _rows.add(row));
  }

  void _removeRow(int index) {
    setState(() {
      if (_rows.length == 1) {
        _rows[index].clear();
        return;
      }

      final row = _rows.removeAt(index);
      row.dispose();
    });
  }

  void _reorderRows(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final row = _rows.removeAt(oldIndex);
      _rows.insert(newIndex, row);
    });
  }

  // Next Button Helper
  Future<void> _handleNext(
    BuildContext context,
    AddRecipeIngredientsViewModel viewModel,
  ) async {
    final success = await viewModel.saveIngredients(
      recipeId: widget.recipeId,
      ingredients: _completedIngredients,
    );

    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? "Unable to save ingredients."),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ingredients saved. Instructions is next.")),
    );
  }

  List<AddRecipeIngredient> get _completedIngredients {
    return _rows
        .where((row) => row.isComplete)
        .map(
          (row) => AddRecipeIngredient(
            name: row.nameController.text.trim(),
            imageFile: row.imageFile,
            amount: double.parse(row.amountController.text.trim()),
            unit: row.unit,
          ),
        )
        .toList();
  }

  bool get _canSave {
    final hasCompleteRow = _rows.any((row) => row.isComplete);
    final hasPartialRow = _rows.any((row) => row.isPartial);
    return hasCompleteRow && !hasPartialRow;
  }

  void _refreshFormState() {
    if (!mounted) return;
    setState(() {});
  }
}

// Ingredient Row State Class
class IngredientRowState {
  final String id = UniqueKey().toString();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final List<VoidCallback> _listeners = [];
  File? imageFile;
  String unit = '';

  bool get isComplete {
    return nameController.text.trim().isNotEmpty &&
        (double.tryParse(amountController.text.trim()) ?? 0) > 0 &&
        unit.trim().isNotEmpty;
  }

  bool get isPartial {
    final hasContent =
        nameController.text.trim().isNotEmpty ||
        amountController.text.trim().isNotEmpty ||
        unit.trim().isNotEmpty ||
        imageFile != null;
    return hasContent && !isComplete;
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    nameController.addListener(listener);
    amountController.addListener(listener);
  }

  void clear() {
    nameController.clear();
    amountController.clear();
    imageFile = null;
    unit = '';
    for (final listener in _listeners) {
      listener();
    }
  }

  void dispose() {
    for (final listener in _listeners) {
      nameController.removeListener(listener);
      amountController.removeListener(listener);
    }
    nameController.dispose();
    amountController.dispose();
  }
}
