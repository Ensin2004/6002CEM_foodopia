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
import '../../../../core/widgets/cards/method_card.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/usecases/complete_add_recipe_usecase.dart';
import '../../domain/usecases/generate_add_recipe_from_video_usecase.dart';
import '../../domain/usecases/generate_add_recipe_ingredients_from_image_usecase.dart';
import '../../domain/usecases/save_add_recipe_basic_info_usecase.dart';
import '../../domain/usecases/save_add_recipe_ingredients_usecase.dart';
import '../../domain/usecases/save_add_recipe_instructions_usecase.dart';
import '../viewmodel/add_recipe_method_viewmodel.dart';
import '../widgets/add_recipe_image_source_sheet.dart';
import '../widgets/recipe_error_dialog.dart';

/// Add recipe choose method page
/// For user to choose which method to use to create the recipe
class AddRecipePage extends StatelessWidget {
  const AddRecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Set up view models with dependency injection
    return ChangeNotifierProvider(
      create: (_) => AddRecipeMethodViewModel(
        generateIngredientsFromImageUseCase:
            sl<GenerateAddRecipeIngredientsFromImageUseCase>(),
        generateFromVideoUseCase: sl<GenerateAddRecipeFromVideoUseCase>(),
        saveBasicInfoUseCase: sl<SaveAddRecipeBasicInfoUseCase>(),
        saveIngredientsUseCase: sl<SaveAddRecipeIngredientsUseCase>(),
        saveInstructionsUseCase: sl<SaveAddRecipeInstructionsUseCase>(),
        completeRecipeUseCase: sl<CompleteAddRecipeUseCase>(),
      ),
      child: const _AddRecipeChooseMethodView(),
    );
  }
}

/// Stateful widget of the add recipe choose method page.
class _AddRecipeChooseMethodView extends StatefulWidget {
  const _AddRecipeChooseMethodView();

  @override
  State<_AddRecipeChooseMethodView> createState() =>
      _AddRecipeChooseMethodViewState();
}

class _AddRecipeChooseMethodViewState extends State<_AddRecipeChooseMethodView> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? 48.0
        : AppSpacing.lg;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "New Recipe"),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ).copyWith(left: horizontalPadding, right: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How would you like to add your recipe?",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Method 1: Upload Image (AI recipe generation)
                    MethodCard(
                      icon: Icons.image_rounded,
                      title: "Upload Image",
                      subtitle:
                          "Upload a food image and let AI generate ingredients.",
                      onTap: () {
                        _handleUploadImage(context);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Method 2: Upload Video (AI recipe generation)
                    MethodCard(
                      icon: Icons.movie_creation_rounded,
                      title: "Upload Video",
                      subtitle: "Upload a video and let AI generate the recipe.",
                      onTap: () {
                        _handleUploadVideo(context);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Method 3: Create from Scratch (Manual entry)
                    MethodCard(
                      icon: Icons.edit_note_rounded,
                      title: "Create from Scratch",
                      subtitle: "Create your recipe step by step.",
                      onTap: () {
                        context.read<AddRecipeMethodViewModel>().selectMethod(
                          AddRecipeMethod.scratch,
                        );
                        context.push(AppRouter.addRecipeBasicInfo);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // Image Upload Flow
  // ============================================================

  /// Handles the image upload recipe generation flow
  Future<void> _handleUploadImage(BuildContext context) async {
    final viewModel = context.read<AddRecipeMethodViewModel>();
    viewModel.selectMethod(AddRecipeMethod.uploadImage);

    // Let user choose whether to take a photo or select one from gallery.
    final source = await showAddRecipeImageSourceSheet(context);
    if (!context.mounted || source == null) return;

    final image = await _imagePicker.pickImage(source: source);
    if (!context.mounted || image == null) return;

    // Loading dialog stays visible while AI extracts recipe details from the image.
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(
        message: "Generating ingredients...",
      ),
    );

    // Process the image through AI
    final imageFile = File(image.path);
    final success = await viewModel.generateIngredientsFromImage(imageFile);
    if (!context.mounted) return;
    rootNavigator.pop();

    if (!success) {
      await showRecipeErrorDialog(
        context: context,
        message: viewModel.errorMessage ??
            "Unable to generate ingredients from image.",
      );
      return;
    }

    // Generated image data seeds the manual basic info and ingredient steps.
    context.push(
      AppRouter.addRecipeBasicInfo,
      extra: AddRecipeBasicInfoArgs(
        initialImageFile: imageFile,
        initialRecipeName: viewModel.generatedImageRecipe?.recipeName,
        initialRecipeDescription:
            viewModel.generatedImageRecipe?.description,
        initialGeneratedIngredients: viewModel.generatedImageIngredients,
        initialGeneratedInstructions:
            viewModel.generatedImageRecipe?.instructions ?? const [],
      ),
    );
  }

  // ============================================================
  // Video Upload Flow
  // ============================================================

  /// Handles the video upload recipe generation flow
  Future<void> _handleUploadVideo(BuildContext context) async {
    final viewModel = context.read<AddRecipeMethodViewModel>();
    viewModel.selectMethod(AddRecipeMethod.uploadVideo);

    // Let user choose whether to record a video or select one from gallery.
    final source = await showAddRecipeImageSourceSheet(
      context,
      cameraLabel: 'Record Video',
      galleryLabel: 'Choose Video from Gallery',
    );
    if (!context.mounted || source == null) return;

    final video = await _imagePicker.pickVideo(source: source);
    if (!context.mounted || video == null) return;

    // Loading dialog stays visible while the video is converted into a saved draft.
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(),
    );

    // Process the video through AI
    final success = await viewModel.generateRecipeFromVideo(video.path);
    if (!context.mounted) return;
    rootNavigator.pop();

    if (!success) {
      await showRecipeErrorDialog(
        context: context,
        message: viewModel.errorMessage ?? "Unable to generate recipe from video.",
      );
      return;
    }

    // Video generation already saves the draft, so navigation jumps to review.
    context.pushReplacement(
      AppRouter.addRecipeReview,
      extra: AddRecipeReviewArgs(recipeId: viewModel.generatedRecipeId ?? ""),
    );
  }
}
