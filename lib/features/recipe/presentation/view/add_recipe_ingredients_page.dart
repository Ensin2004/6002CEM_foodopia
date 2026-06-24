import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:foodopia/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:foodopia/features/recipe/presentation/widgets/ingredients/input_ingredient_field.dart';
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
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_ingredient_unit.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../../meal_plan/domain/entities/add_meal_ai_plan.dart';
import '../../domain/usecases/get_add_recipe_food_nutrients_usecase.dart';
import '../../domain/usecases/get_add_recipe_ingredient_image_usecase.dart';
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
import '../widgets/recipe_error_dialog.dart';
import '../widgets/recipe_visibility_action_button.dart';

/// Add recipe ingredients page
/// For user to fill in the ingredients of the recipe
class AddRecipeIngredientsPage extends StatelessWidget {
  final String recipeId;
  final String initialVisibility;
  final bool returnToReview;
  final AddMealAiRecipe? initialAiRecipe;
  final AddMealAiGenerationRequest? initialAiRequest;
  final String? userId;
  final AddRecipeBasicInfo? aiDraftBasicInfo;
  final List<AddRecipeIngredient> initialGeneratedIngredients;
  final List<AddRecipeInstruction> initialGeneratedInstructions;
  final bool hideProgressBar;
  final bool hideAppBar;
  final ValueChanged<List<AddRecipeIngredient>>? onAiDraftNext;

  const AddRecipeIngredientsPage({
    super.key,
    required this.recipeId,
    this.initialVisibility = "private",
    this.returnToReview = false,
    this.initialAiRecipe,
    this.initialAiRequest,
    this.userId,
    this.aiDraftBasicInfo,
    this.initialGeneratedIngredients = const [],
    this.initialGeneratedInstructions = const [],
    this.hideProgressBar = false,
    this.hideAppBar = false,
    this.onAiDraftNext,
  });

  @override
  Widget build(BuildContext context) {
    // Set up view models with dependency injection
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AddRecipeIngredientsViewModel(
            getIngredientUnitsUseCase: sl<GetAddRecipeIngredientUnitsUseCase>(),
            searchFoodsUseCase: sl<SearchAddRecipeFoodsUseCase>(),
            getFoodNutrientsUseCase: sl<GetAddRecipeFoodNutrientsUseCase>(),
            getIngredientImageUseCase: sl<GetAddRecipeIngredientImageUseCase>(),
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
        initialAiRecipe: initialAiRecipe,
        initialAiRequest: initialAiRequest,
        userId: userId,
        aiDraftBasicInfo: aiDraftBasicInfo,
        initialGeneratedIngredients: initialGeneratedIngredients,
        initialGeneratedInstructions: initialGeneratedInstructions,
        hideProgressBar: hideProgressBar,
        hideAppBar: hideAppBar,
        onAiDraftNext: onAiDraftNext,
      ),
    );
  }
}

/// Stateful widget of the add recipe ingredients page.
class _AddRecipeIngredientsView extends StatefulWidget {
  final String recipeId;
  final bool returnToReview;
  final AddMealAiRecipe? initialAiRecipe;
  final AddMealAiGenerationRequest? initialAiRequest;
  final String? userId;
  final AddRecipeBasicInfo? aiDraftBasicInfo;
  final List<AddRecipeIngredient> initialGeneratedIngredients;
  final List<AddRecipeInstruction> initialGeneratedInstructions;
  final bool hideProgressBar;
  final bool hideAppBar;
  final ValueChanged<List<AddRecipeIngredient>>? onAiDraftNext;

  const _AddRecipeIngredientsView({
    required this.recipeId,
    required this.returnToReview,
    this.initialAiRecipe,
    this.initialAiRequest,
    this.userId,
    this.aiDraftBasicInfo,
    this.initialGeneratedIngredients = const [],
    this.initialGeneratedInstructions = const [],
    this.hideProgressBar = false,
    this.hideAppBar = false,
    this.onAiDraftNext,
  });

  @override
  State<_AddRecipeIngredientsView> createState() =>
      _AddRecipeIngredientsViewState();
}

class _AddRecipeIngredientsViewState extends State<_AddRecipeIngredientsView> {
  late final List<IngredientRowState> _rows;
  String? _seededRecipeId;
  String? _requestedRecipeId;
  String? _initialFormSignature;
  bool _didSaveChanges = false;
  bool _didRequestAiIngredientImages = false;
  bool _didResolveGeneratedUnits = false;

  @override
  void initState() {
    super.initState();

    // In ingredient is already available from other sources, initialize it
    final aiIngredients = widget.initialAiRecipe?.ingredients ?? const [];
    final generatedIngredients = widget.initialGeneratedIngredients;
    _rows = aiIngredients.isNotEmpty
        ? aiIngredients.map(IngredientRowState.fromAiIngredient).toList()
        : generatedIngredients.isNotEmpty
        ? generatedIngredients
              .map(
                (ingredient) => IngredientRowState.fromIngredient(
                  ingredient,
                  units: const [],
                ),
              )
              .toList()
        : [IngredientRowState()];

    // Listener to update state when changes made
    for (final row in _rows) {
      row.addListener(_refreshFormState);
    }
  }

  @override
  // Clean up to prevent memory leakage
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
      return const _AddRecipePageLoading();
    }

    // Resolve unit names for generated ingredients once units are loaded
    if (widget.initialGeneratedIngredients.isNotEmpty &&
        !_didResolveGeneratedUnits) {
      _didResolveGeneratedUnits = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _resolveGeneratedUnitNames(viewModel.units);
      });
    }

    // Load existing recipe data if in editing mode (recipeId exists)
    if (widget.initialAiRecipe == null &&
        widget.initialGeneratedIngredients.isEmpty &&
        viewModel.existingReview == null &&
        _requestedRecipeId != widget.recipeId) {
      _requestedRecipeId = widget.recipeId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AddRecipeIngredientsViewModel>().loadExistingRecipe(
          widget.recipeId,
        );
      });
      return const _AddRecipePageLoading();
    }

    // Seed form data from existing review
    final existingReview = viewModel.existingReview;
    if (existingReview != null && _seededRecipeId != existingReview.recipeId) {
      _seedFromReview(viewModel);
    }

    // Fetch images for AI-generated ingredients
    if (widget.initialAiRecipe != null && !_didRequestAiIngredientImages) {
      _didRequestAiIngredientImages = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchMissingIngredientImages(viewModel);
      });
    }

    // Capture initial form state for change detection
    _initialFormSignature ??= _formSignature();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        appBar: widget.hideAppBar
            ? null
            : CustomAppBar(
                title: widget.initialAiRecipe == null
                    ? "New Recipe"
                    : "Customize AI Recipe",
                leading: IconButton(
                  onPressed: () => _handleBack(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                actions: [
                  Consumer<AddRecipeVisibilityViewModel>(
                    builder: (context, visibilityViewModel, _) {
                      return RecipeVisibilityActionButton(
                        visibility: visibilityViewModel.visibility,
                        isSaving: visibilityViewModel.isSaving,
                        onChanged: (value) => confirmRecipeVisibilityChange(
                          context: context,
                          currentVisibility: visibilityViewModel.visibility,
                          nextVisibility: value,
                          onConfirmed: (visibility) =>
                              visibilityViewModel.updateVisibility(
                                recipeId: widget.recipeId,
                                value: visibility,
                              ),
                          errorMessage: () => visibilityViewModel.errorMessage,
                        ),
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
              if (!widget.hideProgressBar)
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

                    // Add Ingredient Button
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

              // Bottom Action Button
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.lg,
                  horizontalPadding,
                  AppSpacing.lg,
                ),
                child: PrimaryButton(
                  text: widget.initialAiRecipe != null
                      ? "Next"
                      : widget.returnToReview
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

  // ============================================================
  // Navigation and Flow Control Methods
  // ============================================================

  /// Handle back action
  Future<void> _handleBack(BuildContext context) async {
    // Pages without changes can leave immediately.
    if (!_hasUnsavedChanges()) {
      _leaveEditPage(context);
      return;
    }

    // Unsaved edits require confirmation before navigation continues.
    final discard = await confirmDiscardRecipeChanges(context);
    if (!context.mounted || !discard) return;
    _leaveEditPage(context);
  }

  /// Handle leave action
  void _leaveEditPage(BuildContext context) {
    // Edit-from-review returns directly to the review step.
    if (widget.returnToReview) {
      context.pushReplacement(
        AppRouter.addRecipeReview,
        extra: AddRecipeReviewArgs(recipeId: widget.recipeId),
      );
      return;
    }

    // Returns to previous page
    if (context.canPop()) {
      context.pop();
    }
  }

  // ============================================================
  // Image Handling Methods
  // ============================================================

  /// Opens the file picker to select an image for a specific ingredient
  Future<void> _pickIngredientImage(IngredientRowState row) async {
    final image = await _pickImageFile();
    if (image == null) return;
    setState(() => row.imageFile = image);
  }

  /// Fetches missing images for AI-generated ingredients
  Future<void> _fetchMissingIngredientImages(
    AddRecipeIngredientsViewModel viewModel,
  ) async {
    // Iterate through all rows and fetch images for those without one
    for (final row in List<IngredientRowState>.of(_rows)) {
      final ingredientName = row.nameController.text.trim();
      if (ingredientName.isEmpty ||
          row.imageFile != null ||
          row.existingImageUrl != null) {
        continue;
      }

      // Fetch image from Unsplash API
      final imageUrl = await viewModel.getIngredientImageUrl(ingredientName);
      if (!mounted || imageUrl == null) continue;

      // Image result is ignored if the row changed while the lookup was running.
      final currentName = row.nameController.text.trim();
      if (currentName != ingredientName ||
          row.imageFile != null ||
          row.existingImageUrl != null) {
        continue;
      }

      setState(() => row.existingImageUrl = imageUrl);
    }
  }

  /// Picks a single image file for an ingredient
  Future<File?> _pickImageFile() async {
    final result = await fp.FilePicker.pickFiles(
      allowMultiple: false,
      type: fp.FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
    );
    final path = result?.files.firstOrNull?.path;
    return path == null ? null : File(path);
  }

  // ============================================================
  // Unit-Related Methods
  // ============================================================

  // Resolves unit names for generated ingredients once units are loaded
  void _resolveGeneratedUnitNames(List<AddRecipeIngredientUnit> units) {
    var changed = false;
    for (final row in _rows) {
      // Skip if already has a custom unit or unit name
      if (row.isCustomUnit || row.unitName.trim().isNotEmpty) continue;
      // Find the unit name by ID
      final unitName = IngredientRowState.unitNameById(units, row.unitId);
      if (unitName.isEmpty) continue;
      row.unitName = unitName;
      changed = true;
    }
    if (changed) setState(() {});
  }

  // ============================================================
  // Ingredient Name Selection Methods
  // ============================================================

  /// Shows the ingredient name selection sheet with usda food search capability
  Future<void> _showIngredientNameSheet({
    required IngredientRowState row,
    required AddRecipeIngredientsViewModel viewModel,
  }) async {
    // Name picker can return a custom name or a USDA food selection.
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
        // Enables searching foods from usda api
        onSearchFoods: viewModel.searchFoods,
      ),
    );

    if (selected == null) return;
    if (!mounted) return;

    // USDA nutrients and Unsplash image lookup run after a name is selected.
    Map<String, dynamic>? nutrients;
    String? ingredientImageUrl;
    if (selected.name.trim().isNotEmpty) {
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LoadingDialog(),
      );
      final imageUrlFuture = viewModel.getIngredientImageUrl(selected.name);
      if (!selected.isCustom && selected.usdaId != null) {
        nutrients = await viewModel.getFoodNutrients(selected.usdaId!);
      }
      ingredientImageUrl = await imageUrlFuture;
      if (mounted) rootNavigator.pop();
    }

    if (!mounted) return;
    setState(() {
      // New ingredient names reset category analysis so AI can recalculate it later.
      row.nameController.text = selected.name;
      row.usdaId = selected.usdaId;
      row.usdaNutrients = selected.isCustom ? null : nutrients;
      if (ingredientImageUrl != null) {
        row.existingImageUrl = ingredientImageUrl;
      }
      row.ingredientCategoryId = null;
      row.markAnalysisCurrent();
    });
  }

  // ============================================================
  // Unit Selection Methods
  // ============================================================

  /// Shows the unit selection sheet
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

  // ============================================================
  // Row Management Methods
  // ============================================================

  /// Adds a new empty ingredient row
  void _addRow() {
    // New rows listen for controller changes so save availability updates live.
    final row = IngredientRowState();
    row.addListener(_refreshFormState);
    setState(() => _rows.add(row));
  }

  /// Removes an ingredient row by index
  void _removeRow(int index) {
    setState(() {
      // The final row is cleared instead of removed to keep one editable row visible.
      if (_rows.length == 1) {
        _rows[index].clear();
        return;
      }
      final row = _rows.removeAt(index);
      row.dispose();
    });
  }

  /// Reorders ingredient rows (drag-and-drop)
  void _reorderRows(int oldIndex, int newIndex) {
    setState(() {
      // Flutter reorder callbacks need index adjustment when moving downward.
      if (newIndex > oldIndex) newIndex -= 1;
      final row = _rows.removeAt(oldIndex);
      _rows.insert(newIndex, row);
    });
  }

  // ============================================================
  // Main Action Methods
  // ============================================================

  /// Handles the next/save action
  Future<void> _handleNext(
    BuildContext context,
    AddRecipeIngredientsViewModel viewModel,
  ) async {
    if (widget.initialAiRecipe != null) {
      // AI draft mode passes ingredients forward without saving Firestore data yet.
      final onAiDraftNext = widget.onAiDraftNext;
      if (onAiDraftNext != null) {
        _didSaveChanges = true;
        onAiDraftNext(_completedIngredients);
        return;
      }
      context.push(
        AppRouter.addRecipeInstructions,
        extra: AddRecipeInstructionsArgs(
          recipeId: widget.recipeId,
          visibility: context.read<AddRecipeVisibilityViewModel>().visibility,
          aiRecipe: widget.initialAiRecipe,
          aiRequest: widget.initialAiRequest,
          userId: widget.userId,
          aiDraftBasicInfo: widget.aiDraftBasicInfo,
          aiDraftIngredients: _completedIngredients,
          initialGeneratedInstructions: widget.initialGeneratedInstructions,
        ),
      );
      return;
    }

    // Manual flow saves completed ingredient rows before opening the instruction step.
    final success = await viewModel.saveIngredients(
      recipeId: widget.recipeId,
      ingredients: _completedIngredients,
    );

    if (!context.mounted) return;
    if (!success) {
      await showRecipeErrorDialog(
        context: context,
        message: viewModel.errorMessage ?? "Unable to save ingredients.",
      );
      return;
    }

    _didSaveChanges = true;

    // Editing from review returns to review after saving changes.
    if (widget.returnToReview) {
      context.pushReplacement(
        AppRouter.addRecipeReview,
        extra: AddRecipeReviewArgs(recipeId: widget.recipeId),
      );
      return;
    }

    // Navigate to instructions step
    context.push(
      AppRouter.addRecipeInstructions,
      extra: AddRecipeInstructionsArgs(
        recipeId: widget.recipeId,
        visibility: context.read<AddRecipeVisibilityViewModel>().visibility,
        aiRecipe: widget.initialAiRecipe,
        aiRequest: widget.initialAiRequest,
        userId: widget.userId,
        initialGeneratedInstructions: widget.initialGeneratedInstructions,
      ),
    );
  }

  // ============================================================
  // Validation and Utility Methods
  // ============================================================

  /// Builds a list of complete ingredients for saving
  List<AddRecipeIngredient> get _completedIngredients {
    // Only include rows that are fully filled out
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
            usdaNutrients: row.hasAnalysisInputChanged
                ? null
                : row.usdaNutrients,
            ingredientCategoryId: row.hasAnalysisInputChanged
                ? null
                : row.ingredientCategoryId,
          ),
        )
        .toList();
  }

  /// Validates that the form can be saved
  /// Saving requires at least one complete row and no partial row.
  bool get _canSave {
    final hasCompleteRow = _rows.any((row) => row.isComplete);
    final hasPartialRow = _rows.any((row) => row.isPartial);
    return hasCompleteRow && !hasPartialRow;
  }

  /// Triggers UI refresh when form state changes
  void _refreshFormState() {
    if (!mounted) return;
    setState(() {});
  }

  /// Checks if there are any unsaved changes
  bool _hasUnsavedChanges() {
    return !_didSaveChanges && _initialFormSignature != _formSignature();
  }

  /// Creates a signature string representing the current form state (used for change detection)
  String _formSignature() {
    return _rows
        .map(
          (row) => [
            row.nameController.text.trim(),
            row.amountController.text.trim(),
            row.imageFile?.path ?? '',
            row.existingImageUrl ?? '',
            row.unitId,
            row.unitName,
            row.isCustomUnit.toString(),
            row.usdaId?.toString() ?? '',
            row.ingredientCategoryId ?? '',
          ].join('|'),
        )
        .join('::');
  }

  // ============================================================
  // Review Loading Helper
  // ============================================================

  /// Seeds form data from an existing review (when editing a recipe)
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
            row.ingredientCategoryId = item.ingredientCategoryId;
            row.markAnalysisCurrent();
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

  /// Finds a unit by name
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

// ============================================================
// Helper Data Classes
// ============================================================

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
  String? ingredientCategoryId;
  String? _analysisSignature;

  IngredientRowState();

  /// Creates a row from an AI-generated ingredient
  factory IngredientRowState.fromAiIngredient(AddMealAiIngredient ingredient) {
    final row = IngredientRowState();
    row.nameController.text = ingredient.name;
    row.amountController.text = ingredient.amount.toString();
    row.unitName = ingredient.unit;
    row.isCustomUnit = true;
    return row;
  }

  /// Creates a row from an existing ingredient entity
  factory IngredientRowState.fromIngredient(
    AddRecipeIngredient ingredient, {
    required List<AddRecipeIngredientUnit> units,
  }) {
    final row = IngredientRowState();
    row.nameController.text = ingredient.name;
    row.amountController.text = _displayAmount(ingredient.amount);
    row.imageFile = ingredient.imageFile;
    row.existingImageUrl = ingredient.existingImageUrl;
    row.unitId = ingredient.unitId;
    row.isCustomUnit = ingredient.unitId.trim().isEmpty;
    row.unitName = row.isCustomUnit
        ? ingredient.customUnit
        : unitNameById(units, ingredient.unitId);
    row.usdaId = ingredient.usdaId;
    row.usdaNutrients = ingredient.usdaNutrients;
    row.ingredientCategoryId = ingredient.ingredientCategoryId;
    row.markAnalysisCurrent();
    return row;
  }

  /// Get the display name for the unit
  String get unitDisplayName => unitName;

  /// Get the value to save for the unit (ID or custom name)
  String get unitValueForSave => isCustomUnit ? unitName : unitId;

  /// Check whether the ingredient input has changed
  bool get hasAnalysisInputChanged {
    return _analysisSignature != null && _analysisSignature != _inputSignature;
  }

  /// Check whether the ingredient row is complete and valid
  bool get isComplete {
    return nameController.text.trim().isNotEmpty &&
        (double.tryParse(amountController.text.trim()) ?? 0) > 0 &&
        unitValueForSave.trim().isNotEmpty;
  }

  /// Check whether the row has some content but is not complete
  bool get isPartial {
    final hasContent =
        nameController.text.trim().isNotEmpty ||
        amountController.text.trim().isNotEmpty ||
        unitValueForSave.trim().isNotEmpty ||
        imageFile != null ||
        existingImageUrl != null;
    return hasContent && !isComplete;
  }

  /// Adds a listener for form state changes
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    nameController.addListener(listener);
    amountController.addListener(listener);
  }

  /// Clears all data from the row
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
    ingredientCategoryId = null;
    _analysisSignature = null;
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Marks the current input state as analyzed
  void markAnalysisCurrent() {
    _analysisSignature = _inputSignature;
  }

  /// Generates a signature of the current input state for change detection
  String get _inputSignature {
    return [
      nameController.text.trim().toLowerCase(),
      amountController.text.trim(),
      unitValueForSave.trim().toLowerCase(),
    ].join('|');
  }

  /// Cleans up resources and removes listeners
  void dispose() {
    for (final listener in _listeners) {
      nameController.removeListener(listener);
      amountController.removeListener(listener);
    }
    nameController.dispose();
    amountController.dispose();
  }

  /// Formats a double amount for display
  static String _displayAmount(double amount) {
    if (amount % 1 == 0) return amount.toInt().toString();
    return amount.toString();
  }

  /// Finds a unit name by its ID
  static String unitNameById(
    List<AddRecipeIngredientUnit> units,
    String unitId,
  ) {
    for (final unit in units) {
      if (unit.id == unitId) return unit.name;
    }
    return '';
  }
}

// ============================================================
// Loading Page
// ============================================================

// Loading Page
class _AddRecipePageLoading extends StatelessWidget {
  const _AddRecipePageLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingDialog(message: "Loading...", inline: true),
    );
  }
}
