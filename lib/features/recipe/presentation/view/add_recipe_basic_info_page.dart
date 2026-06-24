import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:foodopia/core/theme/app_colors.dart';
import 'package:foodopia/features/recipe/presentation/widgets/basic_info/input_option_field.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/progress_bar/app_step_progress_bar.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../domain/entities/add_recipe_option.dart';
import '../../../meal_plan/domain/entities/add_meal_ai_plan.dart';
import '../../../meal_plan/domain/entities/meal_serving_amount.dart';
import '../../domain/usecases/get_add_recipe_setup_usecase.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';
import '../../domain/usecases/save_add_recipe_basic_info_usecase.dart';
import '../../domain/usecases/search_add_recipe_foods_usecase.dart';
import '../viewmodel/add_recipe_basic_info_viewmodel.dart';
import '../viewmodel/add_recipe_visibility_viewmodel.dart';
import '../widgets/basic_info/add_more_button_small.dart';
import '../widgets/discard_recipe_changes_dialog.dart';
import '../widgets/recipe_visibility_action_button.dart';
import '../widgets/basic_info/recipe_difficulty_picker.dart';
import '../widgets/basic_info/recipe_image_edit_sheet.dart';
import '../widgets/basic_info/recipe_image_picker.dart';
import '../widgets/label.dart';
import '../widgets/basic_info/input_text_field.dart';
import '../widgets/basic_info/recipe_option_picker_sheet.dart';
import '../widgets/recipe_error_dialog.dart';

/// Add recipe basic info page
/// For user to fill in the basic info of the recipe
class AddRecipeBasicInfoPage extends StatelessWidget {
  final String? recipeId;
  final bool returnToReview;
  final AddMealAiRecipe? initialAiRecipe;
  final AddMealAiGenerationRequest? initialAiRequest;
  final String? userId;
  final File? initialImageFile;
  final String? initialRecipeName;
  final String? initialRecipeDescription;
  final List<AddRecipeIngredient> initialGeneratedIngredients;
  final List<AddRecipeInstruction> initialGeneratedInstructions;
  final bool hideProgressBar;
  final bool hideAppBar;
  final ValueChanged<AddRecipeBasicInfo>? onAiDraftNext;

  const AddRecipeBasicInfoPage({
    super.key,
    this.recipeId,
    this.returnToReview = false,
    this.initialAiRecipe,
    this.initialAiRequest,
    this.userId,
    this.initialImageFile,
    this.initialRecipeName,
    this.initialRecipeDescription,
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
          create: (_) => AddRecipeBasicInfoViewModel(
            getSetupUseCase: sl<GetAddRecipeSetupUseCase>(),
            searchFoodsUseCase: sl<SearchAddRecipeFoodsUseCase>(),
            saveBasicInfoUseCase: sl<SaveAddRecipeBasicInfoUseCase>(),
            getReviewUseCase: sl<GetAddRecipeReviewUseCase>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AddRecipeVisibilityViewModel(updateVisibilityUseCase: sl()),
        ),
      ],
      child: _AddRecipeBasicInfoView(
        recipeId: recipeId,
        returnToReview: returnToReview,
        initialAiRecipe: initialAiRecipe,
        initialAiRequest: initialAiRequest,
        userId: userId,
        initialImageFile: initialImageFile,
        initialRecipeName: initialRecipeName,
        initialRecipeDescription: initialRecipeDescription,
        initialGeneratedIngredients: initialGeneratedIngredients,
        initialGeneratedInstructions: initialGeneratedInstructions,
        hideProgressBar: hideProgressBar,
        hideAppBar: hideAppBar,
        onAiDraftNext: onAiDraftNext,
      ),
    );
  }
}

/// Stateful widget of the add recipe basic info page.
class _AddRecipeBasicInfoView extends StatefulWidget {
  final String? recipeId;
  final bool returnToReview;
  final AddMealAiRecipe? initialAiRecipe;
  final AddMealAiGenerationRequest? initialAiRequest;
  final String? userId;
  final File? initialImageFile;
  final String? initialRecipeName;
  final String? initialRecipeDescription;
  final List<AddRecipeIngredient> initialGeneratedIngredients;
  final List<AddRecipeInstruction> initialGeneratedInstructions;
  final bool hideProgressBar;
  final bool hideAppBar;
  final ValueChanged<AddRecipeBasicInfo>? onAiDraftNext;

  const _AddRecipeBasicInfoView({
    this.recipeId,
    required this.returnToReview,
    this.initialAiRecipe,
    this.initialAiRequest,
    this.userId,
    this.initialImageFile,
    this.initialRecipeName,
    this.initialRecipeDescription,
    this.initialGeneratedIngredients = const [],
    this.initialGeneratedInstructions = const [],
    this.hideProgressBar = false,
    this.hideAppBar = false,
    this.onAiDraftNext,
  });

  @override
  State<_AddRecipeBasicInfoView> createState() =>
      _AddRecipeBasicInfoViewState();
}

class _AddRecipeBasicInfoViewState extends State<_AddRecipeBasicInfoView> {
  final List<File> _images = [];
  final List<String> _existingImageUrls = [];
  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();

  final List<TextEditingController> _otherNameControllers = [
    TextEditingController(),
  ];

  List<String> _selectedCategoryIds = [];
  List<String> _customCategories = [];
  List<String> _selectedAllergenIds = [];
  List<String> _customAllergens = [];
  String? _seededRecipeId;
  String? _requestedRecipeId;
  String? _initialFormSignature;
  bool _didSaveChanges = false;

  @override
  void initState() {
    super.initState();

    // If the recipe is AI-generated, pre-fill the fields from the AI content
    final recipe = widget.initialAiRecipe;
    if (recipe != null) {
      _recipeNameController.text = recipe.title;
      _descriptionController.text = recipe.description;
      _prepTimeController.text =
          RegExp(r'\d+').firstMatch(recipe.durationLabel)?.group(0) ?? '30';
      _servingsController.text = _servingText(
        _servingValueFromLabel(recipe.servingLabel),
      );
      _customCategories = [
        recipe.categoryName.trim(),
      ].where((value) => value.isNotEmpty).toList();
      final existingAiImage = _aiExistingImageUrlForSave(recipe);
      if (existingAiImage != null) {
        _existingImageUrls.add(existingAiImage);
      }
    }

    // Override with initial values if recipe is empty
    if (recipe == null) {
      _recipeNameController.text = widget.initialRecipeName?.trim() ?? '';
      _descriptionController.text =
          widget.initialRecipeDescription?.trim() ?? '';
    }

    // Default serving size is 1
    if (_servingsController.text.trim().isEmpty) {
      _servingsController.text = _servingText(1);
    }
    final initialImageFile = widget.initialImageFile;
    if (initialImageFile != null) {
      _images.add(initialImageFile);
    }

    // Listener to update state when changes made
    _recipeNameController.addListener(_refreshRequiredState);
    _descriptionController.addListener(_refreshRequiredState);
    _prepTimeController.addListener(_refreshRequiredState);
    _servingsController.addListener(_refreshRequiredState);
  }

  @override
  // Clean up to prevent memory leakage
  void dispose() {
    _recipeNameController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _servingsController.dispose();

    for (final controller in _otherNameControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddRecipeBasicInfoViewModel>();
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? 48.0
        : AppSpacing.lg;

    if (viewModel.isLoading) {
      return const _AddRecipePageLoading();
    }

    final setup = viewModel.setup;
    if (setup == null) {
      return _RecipeErrorState(message: viewModel.errorMessage);
    }

    // Auto select difficulty for AI recipes
    final aiRecipe = widget.initialAiRecipe;
    if (aiRecipe != null && viewModel.difficultyLevel == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        viewModel.selectDifficulty(_difficultyLevelFor(aiRecipe));
      });
    }

    // Load existing recipe data if in editing mode (recipeId exists)
    final recipeId = widget.recipeId;
    if (recipeId != null &&
        recipeId.trim().isNotEmpty &&
        viewModel.existingReview == null &&
        _requestedRecipeId != recipeId) {
      _requestedRecipeId = recipeId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AddRecipeBasicInfoViewModel>().loadExistingRecipe(
          recipeId,
        );
      });
      return const _AddRecipePageLoading();
    }

    // Seed form data from existing review
    final existingReview = viewModel.existingReview;
    if (existingReview != null && _seededRecipeId != existingReview.recipeId) {
      _seedFromReview(viewModel, setup.categories, setup.allergens);
    }

    // Capture initial form state for change detection
    _initialFormSignature ??= _formSignature(viewModel);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context, viewModel);
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
                  onPressed: () => _handleBack(context, viewModel),
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
                                recipeId: widget.recipeId ?? "",
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
                    currentStep: 1,
                    labels: [
                      "Basic Info",
                      "Ingredients",
                      "Instructions",
                      "Review",
                    ],
                  ),
                ),

              // Input Fields
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.sm,
                    horizontalPadding,
                    0,
                  ),

                  children: [
                    // Recipe Image
                    Label(text: "Recipe Image", isRequired: true),
                    const SizedBox(height: AppSpacing.sm),
                    if (_images.isEmpty &&
                        _existingImageUrls.isEmpty &&
                        widget.initialAiRecipe?.imageBase64?.isNotEmpty == true)
                      _AiRecipeImagePreview(
                        imageBase64: widget.initialAiRecipe!.imageBase64!,
                        onReplace: _pickMedia,
                      )
                    else
                      RecipeImagePicker(
                        images: _images,
                        existingImageUrls: _existingImageUrls,
                        onPick: _pickMedia,
                        onEdit: _showSelectedMediaSheet,
                      ),
                    const SizedBox(height: AppSpacing.lg),

                    // Recipe Name
                    Label(text: "Recipe Name", isRequired: true),
                    const SizedBox(height: AppSpacing.sm),
                    InputTextField(
                      controller: _recipeNameController,
                      hint: "e.g. Classic Italian Basil Pesto Pasta",
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Recipe Description
                    Label(text: "Recipe Description", isRequired: true),
                    const SizedBox(height: AppSpacing.sm),
                    InputTextField(
                      controller: _descriptionController,
                      hint: "Describe what makes this recipe delicious",
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Other Name
                    Label(text: "Other Name"),
                    const SizedBox(height: AppSpacing.sm),
                    ..._otherNameControllers.asMap().entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == _otherNameControllers.length - 1
                              ? 0
                              : AppSpacing.sm,
                        ),
                        child: InputTextField(
                          controller: entry.value,
                          hint: "e.g. Pesto alla Genovese",
                          onDelete: _otherNameControllers.length > 1
                              ? () => _removeOtherName(entry.key)
                              : null,
                        ),
                      );
                    }),
                    AddMoreButtonSmall(onPressed: _addOtherName),
                    const SizedBox(height: AppSpacing.lg),

                    // Category
                    Label(text: "Category", isRequired: true),
                    const SizedBox(height: AppSpacing.sm),
                    InputOptionField(
                      placeholder: "Select categories",
                      values: _selectedOptionValues(
                        options: setup.categories,
                        selectedIds: _selectedCategoryIds,
                        customOptions: _customCategories,
                      ),
                      onDelete: _removeCategorySelection,
                      onTap: () => _showCategorySheet(setup.categories),
                    ),
                    AddMoreButtonSmall(
                      onPressed: () => _showCategorySheet(setup.categories),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Preparation Time
                    Label(text: "Preparation Time", isRequired: true),
                    const SizedBox(height: AppSpacing.sm),
                    InputTextField(
                      controller: _prepTimeController,
                      hint: "e.g. 30",
                      keyboardType: TextInputType.number,
                      suffixText: "minutes",
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Difficulty Level
                    Label(text: "Difficulty Level", isRequired: true),
                    const SizedBox(height: AppSpacing.sm),
                    RecipeDifficultyPicker(levels: setup.difficultyLevels),
                    const SizedBox(height: AppSpacing.lg),

                    // Servings
                    Label(text: "Servings", isRequired: true),
                    const SizedBox(height: AppSpacing.sm),
                    _AddRecipeServingStepper(
                      value: _currentServings,
                      onChanged: _setServings,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Allergen Info
                    Label(text: "Allergen Info"),
                    const SizedBox(height: AppSpacing.sm),
                    InputOptionField(
                      placeholder: "Select allergens",
                      values: _selectedOptionValues(
                        options: setup.allergens,
                        selectedIds: _selectedAllergenIds,
                        customOptions: _customAllergens,
                      ),
                      onDelete: _removeAllergenSelection,
                      onTap: () => _showAllergenSheet(
                        setup.allergens,
                        viewModel.searchFoods,
                      ),
                    ),
                    AddMoreButtonSmall(
                      onPressed: () => _showAllergenSheet(
                        setup.allergens,
                        viewModel.searchFoods,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                  onPressed:
                      viewModel.isSaving || !_isBasicInfoComplete(viewModel)
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
  Future<void> _handleBack(
    BuildContext context,
    AddRecipeBasicInfoViewModel viewModel,
  ) async {
    // Pages without changes can leave immediately.
    if (!_hasUnsavedChanges(viewModel)) {
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
    final recipeId = widget.recipeId;
    // Edit-from-review returns directly to the review step.
    if (widget.returnToReview && recipeId != null && recipeId.isNotEmpty) {
      context.pushReplacement(
        AppRouter.addRecipeReview,
        extra: AddRecipeReviewArgs(recipeId: recipeId),
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

  /// Opens the file picker to select recipe images or short videos
  Future<void> _pickMedia() async {
    // Media selection stops after the recipe reaches the ten-item limit.
    final remainingSlots = 10 - _images.length - _existingImageUrls.length;
    if (remainingSlots <= 0) return;

    // File picker accepts recipe images and short recipe videos.
    final result = await fp.FilePicker.pickFiles(
      allowMultiple: true,
      type: fp.FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'heic',
        'heif',
        'mp4',
        'mov',
        'm4v',
        'avi',
        'webm',
      ],
    );
    if (result == null || result.files.isEmpty) return;

    // Selected paths are stored as local files until the save step uploads them.
    setState(() {
      _images.addAll(
        result.files
            .map((file) => file.path)
            .whereType<String>()
            .take(remainingSlots)
            .map((path) => File(path)),
      );
    });
  }

  /// Shows the media edit sheet for viewing/managing selected media
  Future<void> _showSelectedMediaSheet() async {
    // Empty media state opens the picker instead of the edit sheet.
    if (_images.isEmpty && _existingImageUrls.isEmpty) {
      await _pickMedia();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return RecipeImageEditSheet(
              images: _images,
              existingImageUrls: _existingImageUrls,
              // Removing the final media item closes the sheet automatically.
              onRemoveExisting: (index) {
                setState(() => _existingImageUrls.removeAt(index));
                setSheetState(() {});
                if (_images.isEmpty && _existingImageUrls.isEmpty) {
                  Navigator.of(sheetContext).pop();
                }
              },
              onRemove: (index) {
                setState(() => _images.removeAt(index));
                setSheetState(() {});
                if (_images.isEmpty && _existingImageUrls.isEmpty) {
                  Navigator.of(sheetContext).pop();
                }
              },
              onKeep: () => Navigator.of(sheetContext).pop(),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Category and Allergen Info Selection Methods
  // ============================================================

  /// Shows the category selection sheet
  Future<void> _showCategorySheet(List<AddRecipeOption> categories) async {
    final selection = await showModalBottomSheet<RecipeOptionPickerSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RecipeOptionPickerSheet(
        pickType: "Category",
        options: categories,
        selectedOptionIds: _selectedCategoryIds,
        selectedCustomOptions: _customCategories,
      ),
    );

    if (selection == null) return;
    setState(() {
      _selectedCategoryIds = selection.optionIds;
      _customCategories = selection.customOptions;
    });
  }

  /// Shows the allergen info selection sheet with usda food search capability
  Future<void> _showAllergenSheet(
    List<AddRecipeOption> allergens,
    SearchFoodsCallback searchFoods,
  ) async {
    final selection = await showModalBottomSheet<RecipeOptionPickerSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RecipeOptionPickerSheet(
        pickType: "Allergen",
        options: allergens,
        selectedOptionIds: _selectedAllergenIds,
        selectedCustomOptions: _customAllergens,
        // Enables searching foods from usda api
        onSearchFoods: searchFoods,
      ),
    );

    if (selection == null) return;
    setState(() {
      _selectedAllergenIds = selection.optionIds;
      _customAllergens = selection.customOptions;
    });
  }

  // ============================================================
  // Selection Helper Methods
  // ============================================================

  /// Combines selected options (predefined + custom) into a unified list
  List<SelectedRecipeOption> _selectedOptionValues({
    required List<AddRecipeOption> options,
    required List<String> selectedIds,
    required List<String> customOptions,
  }) {
    // Get the actual option objects for the selected IDs
    final optionValues = selectedIds
        .map((id) => _optionById(options: options, id: id))
        .whereType<AddRecipeOption>();

    // Combine and sort both predefined and custom options
    return ([
      ...optionValues.map(
        (option) => SelectedRecipeOption(
          id: option.id,
          name: option.name,
          isCustom: false,
        ),
      ),
      ...customOptions.map(
        (option) =>
            SelectedRecipeOption(id: option, name: option, isCustom: true),
      ),
    ]..sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    ));
  }

  /// Finds an option by ID from the options list
  AddRecipeOption? _optionById({
    required List<AddRecipeOption> options,
    required String id,
  }) {
    for (final option in options) {
      if (option.id == id) return option;
    }
    return null;
  }

  // ============================================================
  // Form Field Management Methods
  // ============================================================

  /// Adds a new field for other recipe name
  void _addOtherName() {
    setState(() => _otherNameControllers.add(TextEditingController()));
  }

  /// Removes a specific other name field by index
  void _removeOtherName(int index) {
    setState(() {
      final controller = _otherNameControllers.removeAt(index);
      controller.dispose();
    });
  }

  /// Removes a category selection (either predefined or custom)
  void _removeCategorySelection(SelectedRecipeOption option) {
    setState(() {
      if (option.isCustom) {
        _customCategories.remove(option.id);
      } else {
        _selectedCategoryIds.remove(option.id);
      }
    });
  }

  /// Removes an allergen info selection (either predefined or custom)
  void _removeAllergenSelection(SelectedRecipeOption option) {
    setState(() {
      if (option.isCustom) {
        _customAllergens.remove(option.id);
      } else {
        _selectedAllergenIds.remove(option.id);
      }
    });
  }

  // ============================================================
  // Main Action Methods
  // ============================================================

  /// Handles the next/save action
  Future<void> _handleNext(
    BuildContext context,
    AddRecipeBasicInfoViewModel viewModel,
  ) async {
    // AI image data is converted into a file or reusable image URL before saving.
    final aiImageFile = await _aiImageFileForSave();
    if (!context.mounted) return;
    final aiExistingImage = aiImageFile == null
        ? _aiExistingImageUrlForSave(widget.initialAiRecipe)
        : null;

    // Build the basic info object from form data
    final info = AddRecipeBasicInfo(
      recipeId: widget.recipeId,
      mediaFiles: List<File>.unmodifiable([
        ..._images,
        if (aiImageFile != null) aiImageFile,
      ]),
      existingMediaUrls: List<String>.unmodifiable([
        ..._existingImageUrls,
        if (aiExistingImage != null &&
            !_existingImageUrls.contains(aiExistingImage))
          aiExistingImage,
      ]),
      recipeName: _recipeNameController.text.trim(),
      description: _descriptionController.text.trim(),
      otherNames: _nonEmptyControllerValues(_otherNameControllers),
      categoryIds: List<String>.unmodifiable(_selectedCategoryIds),
      customCategories: List<String>.unmodifiable(_customCategories),
      preparationMinutes: int.tryParse(_prepTimeController.text.trim()) ?? 0,
      difficultyLevel: viewModel.difficultyLevel,
      servings: _currentServings,
      allergenIds: List<String>.unmodifiable(_selectedAllergenIds),
      customAllergens: List<String>.unmodifiable(_customAllergens),
      visibility: context.read<AddRecipeVisibilityViewModel>().visibility,
      isAiGenerated: widget.initialAiRecipe != null,
    );

    // AI draft mode passes basic info forward without saving a Firestore draft yet.
    if (widget.initialAiRecipe != null) {
      final onAiDraftNext = widget.onAiDraftNext;
      if (onAiDraftNext != null) {
        _didSaveChanges = true;
        onAiDraftNext(info);
        return;
      }
      context.push(
        AppRouter.addRecipeIngredients,
        extra: AddRecipeIngredientsArgs(
          recipeId: widget.recipeId ?? '',
          visibility: info.visibility,
          aiRecipe: widget.initialAiRecipe,
          aiRequest: widget.initialAiRequest,
          userId: widget.userId,
          aiDraftBasicInfo: info,
          initialGeneratedIngredients: widget.initialGeneratedIngredients,
          initialGeneratedInstructions: widget.initialGeneratedInstructions,
        ),
      );
      return;
    }

    // Manual flow saves basic information before opening the ingredient step.
    final success = await viewModel.saveBasicInfo(info);

    if (!context.mounted) return;
    if (!success) {
      await showRecipeErrorDialog(
        context: context,
        message: viewModel.errorMessage ?? "Unable to save recipe.",
      );
      return;
    }

    _didSaveChanges = true;

    // Editing from review returns to review after saving changes.
    if (widget.returnToReview) {
      context.pushReplacement(
        AppRouter.addRecipeReview,
        extra: AddRecipeReviewArgs(recipeId: viewModel.savedRecipeId!),
      );
      return;
    }

    // Navigate to ingredients step
    context.push(
      AppRouter.addRecipeIngredients,
      extra: AddRecipeIngredientsArgs(
        recipeId: viewModel.savedRecipeId!,
        visibility: context.read<AddRecipeVisibilityViewModel>().visibility,
        aiRecipe: widget.initialAiRecipe,
        aiRequest: widget.initialAiRequest,
        userId: widget.userId,
        initialGeneratedIngredients: widget.initialGeneratedIngredients,
        initialGeneratedInstructions: widget.initialGeneratedInstructions,
      ),
    );
  }

  // ============================================================
  // Serving Size Helper Methods
  // ============================================================

  /// Return current servings
  double get _currentServings {
    final value = double.tryParse(_servingsController.text.trim());
    return MealServingAmount.normalize(value ?? 1);
  }

  /// Set servings
  void _setServings(double value) {
    setState(() => _servingsController.text = _servingText(value));
  }

  /// Format and return servings in string format
  String _servingText(double value) {
    final normalized = MealServingAmount.normalize(value);
    return (normalized - normalized.round()).abs() < 0.001
        ? normalized.round().toString()
        : normalized.toString();
  }

  /// Parses serving value from a label string
  double _servingValueFromLabel(String label) {
    final fraction = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(label);
    if (fraction != null) {
      final numerator = double.tryParse(fraction.group(1) ?? '');
      final denominator = double.tryParse(fraction.group(2) ?? '');
      if (numerator != null && denominator != null && denominator > 0) {
        return MealServingAmount.normalize(numerator / denominator);
      }
    }
    final decimal = RegExp(r'\d+(?:\.\d+)?').firstMatch(label)?.group(0);
    return MealServingAmount.normalize(double.tryParse(decimal ?? '') ?? 1);
  }

  // ============================================================
  // AI Image Processing Methods
  // ============================================================

  /// Converts AI-generated image from base64 to a temporary File
  Future<File?> _aiImageFileForSave() async {
    // Only convert if user hasn't added any other images
    if (_images.isNotEmpty || _existingImageUrls.isNotEmpty) return null;

    final recipe = widget.initialAiRecipe;
    final encoded = recipe?.imageBase64;
    if (encoded == null || encoded.trim().isEmpty) return null;

    try {
      final payload = encoded.contains(',')
          ? encoded.substring(encoded.indexOf(',') + 1)
          : encoded;
      final bytes = base64Decode(payload);
      final safeId = (recipe?.id ?? 'ai_recipe').replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]+'),
        '_',
      );

      // Create a temporary file with a unique name
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'foodopia_${safeId}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  /// Gets the image URL from AI recipe if it's a valid external URL
  String? _aiExistingImageUrlForSave(AddMealAiRecipe? recipe) {
    if (recipe == null || recipe.imageBase64?.trim().isNotEmpty == true) {
      return null;
    }

    final imagePath = recipe.imagePath.trim();
    if (imagePath.isEmpty || imagePath.startsWith('assets/')) return null;
    if (imagePath == 'assets/images/meal1.png') return null;
    if (!imagePath.startsWith('http://') && !imagePath.startsWith('https://')) {
      return null;
    }

    return imagePath;
  }

  // ============================================================
  // Validation and Change Detection Methods
  // ============================================================

  /// Returns non-empty values from a list of text controllers
  List<String> _nonEmptyControllerValues(List<TextEditingController> values) {
    return values
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  /// Validates that all required fields are filled
  bool _isBasicInfoComplete(AddRecipeBasicInfoViewModel viewModel) {
    final hasImage =
        _images.isNotEmpty ||
        _existingImageUrls.isNotEmpty ||
        widget.initialAiRecipe != null;
    return hasImage &&
        _recipeNameController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        (_selectedCategoryIds.isNotEmpty || _customCategories.isNotEmpty) &&
        (int.tryParse(_prepTimeController.text.trim()) ?? 0) > 0 &&
        viewModel.difficultyLevel >= 1 &&
        viewModel.difficultyLevel <= 5 &&
        _currentServings >= MealServingAmount.min;
  }

  /// Maps AI difficulty label to numeric level (1-5)
  int _difficultyLevelFor(AddMealAiRecipe recipe) {
    final label = recipe.difficultyLabel.toLowerCase();
    if (label.contains('easy') || label.contains('beginner')) return 2;
    if (label.contains('medium') || label.contains('intermediate')) return 3;
    if (label.contains('hard') || label.contains('advanced')) return 4;
    return 1;
  }

  /// Triggers UI refresh when form state changes
  void _refreshRequiredState() {
    if (!mounted) return;
    setState(() {});
  }

  /// Checks if there are any unsaved changes
  bool _hasUnsavedChanges(AddRecipeBasicInfoViewModel viewModel) {
    return !_didSaveChanges &&
        _initialFormSignature != _formSignature(viewModel);
  }

  /// Creates a signature string representing the current form state (used for change detection)
  String _formSignature(AddRecipeBasicInfoViewModel viewModel) {
    return jsonEncode({
      'imageFiles': _images.map((image) => image.path).toList(),
      'existingImages': _existingImageUrls,
      'recipeName': _recipeNameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'prepTime': _prepTimeController.text.trim(),
      'servings': _servingsController.text.trim(),
      'otherNames': _nonEmptyControllerValues(_otherNameControllers),
      'categories': _selectedCategoryIds,
      'customCategories': _customCategories,
      'allergens': _selectedAllergenIds,
      'customAllergens': _customAllergens,
      'difficultyLevel': viewModel.difficultyLevel,
    });
  }

  // ============================================================
  // Review Loading Helper
  // ============================================================

  /// Seeds form data from an existing review (when editing a recipe)
  void _seedFromReview(
    AddRecipeBasicInfoViewModel viewModel,
    List<AddRecipeOption> categories,
    List<AddRecipeOption> allergens,
  ) {
    final review = viewModel.existingReview;
    if (review == null) return;

    _existingImageUrls
      ..clear()
      ..addAll(review.media.where((url) => url.trim().isNotEmpty));
    _recipeNameController.text = review.recipeName;
    _descriptionController.text = review.description;
    _prepTimeController.text = review.preparationMinutes.toString();
    _servingsController.text = _servingText(review.servings);

    for (final controller in _otherNameControllers) {
      controller.dispose();
    }
    _otherNameControllers
      ..clear()
      ..addAll(
        (review.otherNames.isEmpty ? [""] : review.otherNames).map(
          (name) => TextEditingController(text: name),
        ),
      );
    for (final controller in _otherNameControllers) {
      controller.addListener(_refreshRequiredState);
    }

    final categorySelection = _splitSavedOptions(
      savedNames: review.categories,
      options: categories,
    );
    _selectedCategoryIds = categorySelection.optionIds;
    _customCategories = categorySelection.customNames;

    final allergenSelection = _splitSavedOptions(
      savedNames: review.allergens,
      options: allergens,
    );
    _selectedAllergenIds = allergenSelection.optionIds;
    _customAllergens = allergenSelection.customNames;

    _seededRecipeId = review.recipeId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AddRecipeVisibilityViewModel>().seedVisibility(
        review.visibility,
      );
    });
  }

  /// Splits saved names into predefined option ids and custom names
  _SavedRecipeOption _splitSavedOptions({
    required List<String> savedNames,
    required List<AddRecipeOption> options,
  }) {
    final optionIds = <String>[];
    final customNames = <String>[];

    for (final name in savedNames) {
      final match = options.where(
        (option) => option.name.toLowerCase() == name.toLowerCase(),
      );
      if (match.isNotEmpty) {
        optionIds.add(match.first.id);
      } else if (name.trim().isNotEmpty) {
        customNames.add(name);
      }
    }

    return _SavedRecipeOption(optionIds: optionIds, customNames: customNames);
  }
}

// ============================================================
// Helper Widgets
// ============================================================

/// Shows an AI-generated recipe image preview with a replace action.
class _AiRecipeImagePreview extends StatelessWidget {
  final String imageBase64;
  final VoidCallback onReplace;

  const _AiRecipeImagePreview({
    required this.imageBase64,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.memory(
              base64Decode(_base64Payload(imageBase64)),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Image.asset(
                "assets/images/empty_page.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: FilledButton.icon(
              onPressed: onReplace,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Replace'),
            ),
          ),
        ],
      ),
    );
  }

  /// Extracts the base64 payload from a data URL
  String _base64Payload(String value) {
    final commaIndex = value.indexOf(',');
    return commaIndex >= 0 ? value.substring(commaIndex + 1) : value;
  }
}

/// A stepper widget for adjusting serving sizes with increment/decrement buttons.
class _AddRecipeServingStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _AddRecipeServingStepper({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = MealServingAmount.normalize(value);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Decrease servings',
            onPressed: normalized <= MealServingAmount.min
                ? null
                : () => onChanged(MealServingAmount.stepDown(normalized)),
            icon: const Icon(Icons.remove_rounded),
          ),
          Expanded(
            child: Text(
              MealServingAmount.format(normalized),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Increase servings',
            onPressed: normalized >= MealServingAmount.max
                ? null
                : () => onChanged(MealServingAmount.stepUp(normalized)),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Helper Data Classes
// ============================================================

// Saved Recipe Option Class
class _SavedRecipeOption {
  final List<String> optionIds;
  final List<String> customNames;

  const _SavedRecipeOption({
    required this.optionIds,
    required this.customNames,
  });
}

// Selected Recipe Option Class
class SelectedRecipeOption {
  final String id;
  final String name;
  final bool isCustom;

  const SelectedRecipeOption({
    required this.id,
    required this.name,
    required this.isCustom,
  });
}

// ============================================================
// Loading and Error Page
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

// Error Page
class _RecipeErrorState extends StatelessWidget {
  final String? message;
  const _RecipeErrorState({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/images/empty_page.png", height: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message ?? "Unable to load page",
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
