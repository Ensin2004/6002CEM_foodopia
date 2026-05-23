import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:foodopia/features/recipe/presentation/widgets/basic_info/input_option_field.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
import '../../domain/entities/add_recipe_option.dart';
import '../../../meal_plan/domain/entities/add_meal_ai_plan.dart';
import '../../domain/usecases/get_add_recipe_setup_usecase.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';
import '../../domain/usecases/save_add_recipe_basic_info_usecase.dart';
import '../../domain/usecases/search_add_recipe_foods_usecase.dart';
import '../viewmodel/add_recipe_basic_info_viewmodel.dart';
import '../viewmodel/add_recipe_visibility_viewmodel.dart';
import '../widgets/basic_info/add_more_button_small.dart';
import '../widgets/recipe_visibility_action_button.dart';
import '../widgets/basic_info/recipe_difficulty_picker.dart';
import '../widgets/basic_info/recipe_image_edit_sheet.dart';
import '../widgets/basic_info/recipe_image_picker.dart';
import '../widgets/label.dart';
import '../widgets/basic_info/input_text_field.dart';
import '../widgets/basic_info/recipe_option_picker_sheet.dart';

class AddRecipeBasicInfoPage extends StatelessWidget {
  final String? recipeId;
  final bool returnToReview;
  final AddMealAiRecipe? initialAiRecipe;
  final AddMealAiGenerationRequest? initialAiRequest;
  final String? userId;

  const AddRecipeBasicInfoPage({
    super.key,
    this.recipeId,
    this.returnToReview = false,
    this.initialAiRecipe,
    this.initialAiRequest,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
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
      ),
    );
  }
}

class _AddRecipeBasicInfoView extends StatefulWidget {
  final String? recipeId;
  final bool returnToReview;
  final AddMealAiRecipe? initialAiRecipe;
  final AddMealAiGenerationRequest? initialAiRequest;
  final String? userId;

  const _AddRecipeBasicInfoView({
    this.recipeId,
    required this.returnToReview,
    this.initialAiRecipe,
    this.initialAiRequest,
    this.userId,
  });

  @override
  State<_AddRecipeBasicInfoView> createState() =>
      _AddRecipeBasicInfoViewState();
}

class _AddRecipeBasicInfoViewState extends State<_AddRecipeBasicInfoView> {
  final ImagePicker _imagePicker = ImagePicker();
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

  @override
  void initState() {
    super.initState();
    final recipe = widget.initialAiRecipe;
    if (recipe != null) {
      _recipeNameController.text = recipe.title;
      _descriptionController.text = recipe.description;
      _prepTimeController.text =
          RegExp(r'\d+').firstMatch(recipe.durationLabel)?.group(0) ?? '30';
      _servingsController.text =
          RegExp(r'\d+').firstMatch(recipe.servingLabel)?.group(0) ?? '1';
      _customCategories = [
        recipe.categoryName.trim(),
      ].where((value) => value.isNotEmpty).toList();
    }
    _recipeNameController.addListener(_refreshRequiredState);
    _descriptionController.addListener(_refreshRequiredState);
    _prepTimeController.addListener(_refreshRequiredState);
    _servingsController.addListener(_refreshRequiredState);
  }

  @override
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
      return const LoadingDialog();
    }

    final setup = viewModel.setup;
    if (setup == null) {
      return _RecipeErrorState(message: viewModel.errorMessage);
    }
    final aiRecipe = widget.initialAiRecipe;
    if (aiRecipe != null && viewModel.difficultyLevel == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        viewModel.selectDifficulty(_difficultyLevelFor(aiRecipe));
      });
    }

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
      return const LoadingDialog();
    }

    final existingReview = viewModel.existingReview;
    if (existingReview != null && _seededRecipeId != existingReview.recipeId) {
      _seedFromReview(viewModel, setup.categories, setup.allergens);
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: widget.initialAiRecipe == null
            ? "New Recipe"
            : "Customize AI Recipe",
        actions: [
          Consumer<AddRecipeVisibilityViewModel>(
            builder: (context, visibilityViewModel, _) {
              return RecipeVisibilityActionButton(
                visibility: visibilityViewModel.visibility,
                isSaving: visibilityViewModel.isSaving,
                onChanged: (value) => visibilityViewModel.updateVisibility(
                  recipeId: widget.recipeId ?? "",
                  value: value,
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
                labels: ["Basic Info", "Ingredients", "Instructions", "Review"],
              ),
            ),

            // Input Fields
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
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
                      onReplace: _pickImages,
                    )
                  else
                    RecipeImagePicker(
                      images: _images,
                      existingImageUrls: _existingImageUrls,
                      onPick: _pickImages,
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
                  InputTextField(
                    controller: _servingsController,
                    hint: "e.g. 1",
                    keyboardType: TextInputType.number,
                    suffixText: "servings",
                    textInputAction: TextInputAction.next,
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
    );
  }

  // Image Picker Helper
  Future<void> _pickImages() async {
    final remainingSlots = 10 - _images.length - _existingImageUrls.length;
    if (remainingSlots <= 0) return;

    final pickedImages = await _imagePicker.pickMultiImage();
    if (pickedImages.isEmpty) return;

    setState(() {
      _images.addAll(
        pickedImages.take(remainingSlots).map((image) => File(image.path)),
      );
    });
  }

  Future<void> _showSelectedMediaSheet() async {
    if (_images.isEmpty && _existingImageUrls.isEmpty) {
      await _pickImages();
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

  // Category Picker Helper
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

  // Allergen Picker Helper
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
        onSearchFoods: searchFoods,
      ),
    );

    if (selection == null) return;
    setState(() {
      _selectedAllergenIds = selection.optionIds;
      _customAllergens = selection.customOptions;
    });
  }

  // Select Option Helper
  List<SelectedRecipeOption> _selectedOptionValues({
    required List<AddRecipeOption> options,
    required List<String> selectedIds,
    required List<String> customOptions,
  }) {
    final optionValues = selectedIds
        .map((id) => _optionById(options: options, id: id))
        .whereType<AddRecipeOption>();

    return [
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
    ];
  }

  AddRecipeOption? _optionById({
    required List<AddRecipeOption> options,
    required String id,
  }) {
    for (final option in options) {
      if (option.id == id) return option;
    }
    return null;
  }

  // Add Input Helper
  void _addOtherName() {
    setState(() => _otherNameControllers.add(TextEditingController()));
  }

  // Remove Input Helper
  void _removeOtherName(int index) {
    setState(() {
      final controller = _otherNameControllers.removeAt(index);
      controller.dispose();
    });
  }

  void _removeCategorySelection(SelectedRecipeOption option) {
    setState(() {
      if (option.isCustom) {
        _customCategories.remove(option.id);
      } else {
        _selectedCategoryIds.remove(option.id);
      }
    });
  }

  void _removeAllergenSelection(SelectedRecipeOption option) {
    setState(() {
      if (option.isCustom) {
        _customAllergens.remove(option.id);
      } else {
        _selectedAllergenIds.remove(option.id);
      }
    });
  }

  // Next Button Helper
  Future<void> _handleNext(
    BuildContext context,
    AddRecipeBasicInfoViewModel viewModel,
  ) async {
    final info = AddRecipeBasicInfo(
      recipeId: widget.recipeId,
      mediaFiles: List<File>.unmodifiable(_images),
      existingMediaUrls: List<String>.unmodifiable(_existingImageUrls),
      recipeName: _recipeNameController.text.trim(),
      description: _descriptionController.text.trim(),
      otherNames: _nonEmptyControllerValues(_otherNameControllers),
      categoryIds: List<String>.unmodifiable(_selectedCategoryIds),
      customCategories: List<String>.unmodifiable(_customCategories),
      preparationMinutes: int.tryParse(_prepTimeController.text.trim()) ?? 0,
      difficultyLevel: viewModel.difficultyLevel,
      servings: int.tryParse(_servingsController.text.trim()) ?? 0,
      allergenIds: List<String>.unmodifiable(_selectedAllergenIds),
      customAllergens: List<String>.unmodifiable(_customAllergens),
      visibility: context.read<AddRecipeVisibilityViewModel>().visibility,
      isAiGenerated: widget.initialAiRecipe != null,
    );

    if (widget.initialAiRecipe != null) {
      context.push(
        AppRouter.addRecipeIngredients,
        extra: AddRecipeIngredientsArgs(
          recipeId: widget.recipeId ?? '',
          visibility: info.visibility,
          aiRecipe: widget.initialAiRecipe,
          aiRequest: widget.initialAiRequest,
          userId: widget.userId,
          aiDraftBasicInfo: info,
        ),
      );
      return;
    }

    final success = await viewModel.saveBasicInfo(info);

    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? "Unable to save recipe."),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Recipe basic info saved.")));

    if (widget.returnToReview) {
      context.pushReplacement(
        AppRouter.addRecipeReview,
        extra: AddRecipeReviewArgs(recipeId: viewModel.savedRecipeId!),
      );
      return;
    }

    context.push(
      AppRouter.addRecipeIngredients,
      extra: AddRecipeIngredientsArgs(
        recipeId: viewModel.savedRecipeId!,
        visibility: context.read<AddRecipeVisibilityViewModel>().visibility,
        aiRecipe: widget.initialAiRecipe,
        aiRequest: widget.initialAiRequest,
        userId: widget.userId,
      ),
    );
  }

  List<String> _nonEmptyControllerValues(List<TextEditingController> values) {
    return values
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

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
        (int.tryParse(_servingsController.text.trim()) ?? 0) > 0;
  }

  int _difficultyLevelFor(AddMealAiRecipe recipe) {
    final label = recipe.difficultyLabel.toLowerCase();
    if (label.contains('easy') || label.contains('beginner')) return 2;
    if (label.contains('medium') || label.contains('intermediate')) return 3;
    if (label.contains('hard') || label.contains('advanced')) return 4;
    return 1;
  }

  void _refreshRequiredState() {
    if (!mounted) return;
    setState(() {});
  }

  // Review Helper
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
    _servingsController.text = review.servings.toString();

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

// Saved Recipe Option Class
class _SavedRecipeOption {
  final List<String> optionIds;
  final List<String> customNames;

  const _SavedRecipeOption({
    required this.optionIds,
    required this.customNames,
  });
}

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
              base64Decode(imageBase64),
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
