import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:foodopia/features/recipe/presentation/widgets/ingredients/input_ingredient_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/progress_bar/app_step_progress_bar.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_ingredient_unit.dart';
import '../../domain/usecases/get_add_recipe_food_nutrients_usecase.dart';
import '../../domain/usecases/get_add_recipe_ingredient_units_usecase.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';
import '../../domain/usecases/save_add_recipe_ingredients_usecase.dart';
import '../../domain/usecases/search_add_recipe_foods_usecase.dart';
import '../viewmodel/add_recipe_ingredients_viewmodel.dart';
import '../viewmodel/add_recipe_visibility_viewmodel.dart';
import '../widgets/discard_recipe_changes_dialog.dart';
import '../widgets/ingredients/ingredient_name_picker_sheet.dart';
import '../widgets/ingredients/ingredient_unit_picker_sheet.dart';
import '../widgets/label.dart';
import '../widgets/recipe_visibility_confirm_action.dart';

class AddRecipeIngredientsPage extends StatelessWidget {
  final String recipeId;
  final String initialVisibility;
  final bool returnToReview;

  const AddRecipeIngredientsPage({
    super.key,
    required this.recipeId,
    this.initialVisibility = "private",
    this.returnToReview = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AddRecipeIngredientsViewModel(
            getIngredientUnitsUseCase: sl<GetAddRecipeIngredientUnitsUseCase>(),
            searchFoodsUseCase: sl<SearchAddRecipeFoodsUseCase>(),
            getFoodNutrientsUseCase: sl<GetAddRecipeFoodNutrientsUseCase>(),
            saveIngredientsUseCase: sl<SaveAddRecipeIngredientsUseCase>(),
            getReviewUseCase: sl<GetAddRecipeReviewUseCase>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AddRecipeVisibilityViewModel(
            updateVisibilityUseCase: sl(),
            visibility: initialVisibility,
          ),
        ),
      ],
      child: _AddRecipeIngredientsView(
        recipeId: recipeId,
        returnToReview: returnToReview,
      ),
    );
  }
}

class _AddRecipeIngredientsView extends StatefulWidget {
  final String recipeId;
  final bool returnToReview;

  const _AddRecipeIngredientsView({
    required this.recipeId,
    required this.returnToReview,
  });

  @override
  State<_AddRecipeIngredientsView> createState() =>
      _AddRecipeIngredientsViewState();
}

class _AddRecipeIngredientsViewState extends State<_AddRecipeIngredientsView> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<IngredientRowState> _rows = [IngredientRowState()];
  String? _seededRecipeId;
  String? _requestedRecipeId;
  bool _allowPop = false;

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

    if (viewModel.isLoadingUnits) {
      return const LoadingDialog();
    }

    if (viewModel.existingReview == null &&
        _requestedRecipeId != widget.recipeId) {
      _requestedRecipeId = widget.recipeId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AddRecipeIngredientsViewModel>().loadExistingRecipe(
          widget.recipeId,
        );
      });
      return const LoadingDialog();
    }

    final existingReview = viewModel.existingReview;
    if (existingReview != null && _seededRecipeId != existingReview.recipeId) {
      _seedFromReview(viewModel);
    }

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: "New Recipe",
          leading: IconButton(
            onPressed: () => _handleBack(context),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            Consumer<AddRecipeVisibilityViewModel>(
              builder: (context, visibilityViewModel, _) {
                return RecipeVisibilityConfirmAction(
                  recipeId: widget.recipeId,
                  viewModel: visibilityViewModel,
                );
              },
            ),
          ],
        ),
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
                  labels: [
                    "Basic Info",
                    "Ingredients",
                    "Instructions",
                    "Review",
                  ],
                ),
              ),

              // Label, Tips
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
                    Label(text: "Ingredients", isRequired: true),
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
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    0,
                  ),
                  children: [
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                            onSelectName: () => _showIngredientNameSheet(
                              row: row,
                              viewModel: viewModel,
                            ),
                            onSelectUnit: () => _showUnitSheet(
                              row: row,
                              units: viewModel.units,
                            ),
                            onDelete: () => _removeRow(index),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: SecondaryButton(
                        text: "+  Add Ingredient",
                        onPressed: _addRow,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.lg,
                  horizontalPadding,
                  AppSpacing.lg,
                ),
                child: PrimaryButton(
                  text: widget.returnToReview
                      ? "Save & Review"
                      : "Save & Continue",
                  isLoading: viewModel.isSaving,
                  onPressed: viewModel.isSaving || !_canSave
                      ? null
                      : () => _handleNext(context, viewModel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleBack(BuildContext context) async {
    final shouldDiscard = await showDiscardRecipeChangesDialog(context);
    if (!mounted || !context.mounted || !shouldDiscard) return;
    setState(() => _allowPop = true);
    context.pop();
  }

  // Image Picker Helper
  Future<void> _pickIngredientImage(IngredientRowState row) async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => row.imageFile = File(image.path));
  }

  // Name Picker Helper
  Future<void> _showIngredientNameSheet({
    required IngredientRowState row,
    required AddRecipeIngredientsViewModel viewModel,
  }) async {
    final selected = await showModalBottomSheet<IngredientNamePickerSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => IngredientNamePickerSheet(
        selectedName: row.nameController.text.trim(),
        selectedUsdaId: row.usdaId,
        onSearchFoods: viewModel.searchFoods,
      ),
    );

    if (selected == null) return;
    if (!mounted) return;

    Map<String, dynamic>? nutrients;
    if (!selected.isCustom && selected.usdaId != null) {
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LoadingDialog(),
      );
      nutrients = await viewModel.getFoodNutrients(selected.usdaId!);
      if (mounted) rootNavigator.pop();
    }

    if (!mounted) return;
    setState(() {
      row.nameController.text = selected.name;
      row.usdaId = selected.usdaId;
      row.usdaNutrients = selected.isCustom ? null : nutrients;
    });
  }

  // Unit Picker Helper
  Future<void> _showUnitSheet({
    required IngredientRowState row,
    required List<AddRecipeIngredientUnit> units,
  }) async {
    final selected = await showModalBottomSheet<UnitPickerSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => IngredientUnitPickerSheet(
        units: units,
        selectedUnitId: row.unitId,
        selectedCustomUnit: row.isCustomUnit ? row.unitName : '',
      ),
    );

    if (selected == null) return;
    setState(() {
      row.unitId = selected.unitId;
      row.unitName = selected.unitName;
      row.isCustomUnit = selected.isCustom;
    });
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
          content: Text(
            viewModel.errorMessage ?? "Unable to save ingredients.",
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Recipe ingredients saved.")));

    if (widget.returnToReview) {
      setState(() => _allowPop = true);
      context.pop(true);
      return;
    }

    context.push(
      AppRouter.addRecipeInstructions,
      extra: AddRecipeInstructionsArgs(
        recipeId: widget.recipeId,
        visibility: context.read<AddRecipeVisibilityViewModel>().visibility,
      ),
    );
  }

  List<AddRecipeIngredient> get _completedIngredients {
    return _rows
        .where((row) => row.isComplete)
        .map(
          (row) => AddRecipeIngredient(
            name: row.nameController.text.trim(),
            imageFile: row.imageFile,
            existingImageUrl: row.existingImageUrl,
            amount: double.parse(row.amountController.text.trim()),
            unitId: row.isCustomUnit ? "" : row.unitId,
            customUnit: row.isCustomUnit ? row.unitName : "",
            usdaId: row.usdaId,
            usdaNutrients: row.usdaNutrients,
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

  // Review Helper
  void _seedFromReview(AddRecipeIngredientsViewModel viewModel) {
    final review = viewModel.existingReview;
    if (review == null) return;

    for (final row in _rows) {
      row.dispose();
    }
    _rows
      ..clear()
      ..addAll(
        (review.ingredients.isEmpty ? [null] : review.ingredients).map((item) {
          final row = IngredientRowState();
          if (item != null) {
            row.nameController.text = item.name;
            row.amountController.text = item.amount;
            row.existingImageUrl = item.image.trim().isEmpty
                ? null
                : item.image;
            final unit = _unitByName(viewModel.units, item.unit);
            if (unit == null) {
              row.unitName = item.unit;
              row.isCustomUnit = item.unit.trim().isNotEmpty;
            } else {
              row.unitId = unit.id;
              row.unitName = unit.name;
              row.isCustomUnit = false;
            }
            row.usdaId = item.usdaId;
            row.usdaNutrients = item.nutrients;
          }
          row.addListener(_refreshFormState);
          return row;
        }),
      );

    _seededRecipeId = review.recipeId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AddRecipeVisibilityViewModel>().seedVisibility(
        review.visibility,
      );
    });
  }

  AddRecipeIngredientUnit? _unitByName(
    List<AddRecipeIngredientUnit> units,
    String name,
  ) {
    for (final unit in units) {
      if (unit.name.toLowerCase() == name.toLowerCase()) {
        return unit;
      }
    }
    return null;
  }
}

// Ingredient Row State Class
class IngredientRowState {
  final String id = UniqueKey().toString();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final List<VoidCallback> _listeners = [];
  File? imageFile;
  String? existingImageUrl;
  String unitId = "";
  String unitName = "";
  bool isCustomUnit = false;
  int? usdaId;
  Map<String, dynamic>? usdaNutrients;

  String get unitDisplayName => unitName;

  String get unitValueForSave => isCustomUnit ? unitName : unitId;

  bool get isComplete {
    return nameController.text.trim().isNotEmpty &&
        (double.tryParse(amountController.text.trim()) ?? 0) > 0 &&
        unitValueForSave.trim().isNotEmpty;
  }

  bool get isPartial {
    final hasContent =
        nameController.text.trim().isNotEmpty ||
        amountController.text.trim().isNotEmpty ||
        unitValueForSave.trim().isNotEmpty ||
        imageFile != null ||
        existingImageUrl != null;
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
    existingImageUrl = null;
    unitId = "";
    unitName = "";
    isCustomUnit = false;
    usdaId = null;
    usdaNutrients = null;
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
