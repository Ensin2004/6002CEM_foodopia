import 'dart:io';

import 'package:flutter/material.dart';
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
import '../../domain/usecases/get_add_recipe_setup_usecase.dart';
import '../../domain/usecases/save_add_recipe_basic_info_usecase.dart';
import '../viewmodel/add_recipe_basic_info_viewmodel.dart';
import '../widgets/add_more_button_small.dart';
import '../widgets/input_category_field.dart';
import '../widgets/recipe_difficulty_picker.dart';
import '../widgets/recipe_image_edit_sheet.dart';
import '../widgets/recipe_image_picker.dart';
import '../widgets/input_label.dart';
import '../widgets/input_text_field.dart';

class AddRecipeBasicInfoPage extends StatelessWidget {
  const AddRecipeBasicInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddRecipeBasicInfoViewModel(
        getSetupUseCase: sl<GetAddRecipeSetupUseCase>(),
        saveBasicInfoUseCase: sl<SaveAddRecipeBasicInfoUseCase>(),
      ),
      child: const _AddRecipeBasicInfoView(),
    );
  }
}

class _AddRecipeBasicInfoView extends StatefulWidget {
  const _AddRecipeBasicInfoView();

  @override
  State<_AddRecipeBasicInfoView> createState() =>
      _AddRecipeBasicInfoViewState();
}

class _AddRecipeBasicInfoViewState extends State<_AddRecipeBasicInfoView> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _images = [];
  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();

  final List<TextEditingController> _otherNameControllers = [
    TextEditingController(),
  ];

  final List<TextEditingController> _categoryControllers = [
    TextEditingController(),
  ];

  final List<FocusNode> _categoryFocusNodes = [FocusNode()];

  final List<TextEditingController> _allergenControllers = [
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    _recipeNameController.addListener(_refreshRequiredState);
    _prepTimeController.addListener(_refreshRequiredState);
    _servingsController.addListener(_refreshRequiredState);
    for (final controller in _categoryControllers) {
      controller.addListener(_refreshRequiredState);
    }
  }

  @override
  void dispose() {
    _recipeNameController.dispose();
    _prepTimeController.dispose();
    _servingsController.dispose();

    for (final controller in _otherNameControllers) {
      controller.dispose();
    }
    for (final controller in _categoryControllers) {
      controller.dispose();
    }
    for (final focusNode in _categoryFocusNodes) {
      focusNode.dispose();
    }
    for (final controller in _allergenControllers) {
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "New Recipe"),
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
                  AppSpacing.lg,
                ),

                children: [
                  // Recipe Image
                  InputLabel(text: "Recipe Image", isRequired: true),
                  const SizedBox(height: AppSpacing.sm),
                  RecipeImagePicker(
                    images: _images,
                    onPick: _pickImages,
                    onEdit: _showSelectedMediaSheet,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Recipe Name
                  InputLabel(text: "Recipe Name", isRequired: true),
                  const SizedBox(height: AppSpacing.sm),
                  InputTextField(
                    controller: _recipeNameController,
                    hint: "e.g. Classic Italian Basil Pesto Pasta",
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Other Name
                  InputLabel(text: "Other Name"),
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
                  InputLabel(text: "Category", isRequired: true),
                  const SizedBox(height: AppSpacing.sm),
                  ..._categoryControllers.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == _categoryControllers.length - 1
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: InputCategoryField(
                        controller: entry.value,
                        focusNode: _categoryFocusNodes[entry.key],
                        options: setup.categories,
                        onDelete: _categoryControllers.length > 1
                            ? () => _removeCategory(entry.key)
                            : null,
                      ),
                    );
                  }),
                  AddMoreButtonSmall(onPressed: _addCategory),
                  const SizedBox(height: AppSpacing.lg),

                  // Preparation Time
                  InputLabel(text: "Preparation Time", isRequired: true),
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
                  InputLabel(text: "Difficulty Level", isRequired: true),
                  const SizedBox(height: AppSpacing.sm),
                  RecipeDifficultyPicker(levels: setup.difficultyLevels),
                  const SizedBox(height: AppSpacing.lg),

                  // Servings
                  InputLabel(text: "Servings", isRequired: true),
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
                  InputLabel(text: "Allergen Info"),
                  const SizedBox(height: AppSpacing.sm),
                  ..._allergenControllers.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == _allergenControllers.length - 1
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: InputTextField(
                        controller: entry.value,
                        hint: "e.g. Nuts",
                        onDelete: _allergenControllers.length > 1
                            ? () => _removeAllergen(entry.key)
                            : null,
                      ),
                    );
                  }),
                  AddMoreButtonSmall(onPressed: _addAllergen),
                  const SizedBox(height: AppSpacing.lg),

                  // Next Button
                  PrimaryButton(
                    text: "Next",
                    isLoading: viewModel.isSaving,
                    onPressed:
                        viewModel.isSaving || !_isBasicInfoComplete(viewModel)
                        ? null
                        : () => _handleNext(context, viewModel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Image Picker Helper
  Future<void> _pickImages() async {
    final remainingSlots = 10 - _images.length;
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
    if (_images.isEmpty) {
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
            return SelectedMediaSheet(
              images: _images,
              onRemove: (index) {
                setState(() => _images.removeAt(index));
                setSheetState(() {});
                if (_images.isEmpty) {
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

  // Add Input Helper
  void _addOtherName() {
    setState(() => _otherNameControllers.add(TextEditingController()));
  }

  void _addCategory() {
    final controller = TextEditingController();
    controller.addListener(_refreshRequiredState);
    setState(() {
      _categoryControllers.add(controller);
      _categoryFocusNodes.add(FocusNode());
    });
  }

  void _addAllergen() {
    setState(() => _allergenControllers.add(TextEditingController()));
  }

  // Remove Input Helper
  void _removeOtherName(int index) {
    setState(() {
      final controller = _otherNameControllers.removeAt(index);
      controller.dispose();
    });
  }

  void _removeCategory(int index) {
    setState(() {
      final controller = _categoryControllers.removeAt(index);
      final focusNode = _categoryFocusNodes.removeAt(index);
      controller.removeListener(_refreshRequiredState);
      controller.dispose();
      focusNode.dispose();
    });
  }

  void _removeAllergen(int index) {
    setState(() {
      final controller = _allergenControllers.removeAt(index);
      controller.dispose();
    });
  }

  // Next Button Helper
  Future<void> _handleNext(
    BuildContext context,
    AddRecipeBasicInfoViewModel viewModel,
  ) async {
    final info = AddRecipeBasicInfo(
      mediaFiles: List<File>.unmodifiable(_images),
      recipeName: _recipeNameController.text.trim(),
      otherNames: _nonEmptyControllerValues(_otherNameControllers),
      categories: _nonEmptyControllerValues(_categoryControllers),
      preparationMinutes: int.tryParse(_prepTimeController.text.trim()) ?? 0,
      difficultyLevel: viewModel.difficultyLevel,
      servings: int.tryParse(_servingsController.text.trim()) ?? 0,
      allergens: _nonEmptyControllerValues(_allergenControllers),
    );

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

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recipe basic info saved."))
    );

    context.push(
      AppRouter.addRecipeIngredients,
      extra: AddRecipeIngredientsArgs(recipeId: viewModel.savedRecipeId!),
    );
  }

  List<String> _nonEmptyControllerValues(List<TextEditingController> values) {
    return values
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  bool _isBasicInfoComplete(AddRecipeBasicInfoViewModel viewModel) {
    return _images.isNotEmpty &&
        _recipeNameController.text.trim().isNotEmpty &&
        _nonEmptyControllerValues(_categoryControllers).isNotEmpty &&
        (int.tryParse(_prepTimeController.text.trim()) ?? 0) > 0 &&
        viewModel.difficultyLevel >= 1 &&
        viewModel.difficultyLevel <= 5 &&
        (int.tryParse(_servingsController.text.trim()) ?? 0) > 0;
  }

  void _refreshRequiredState() {
    if (!mounted) return;
    setState(() {});
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
