import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/usecases/complete_add_recipe_usecase.dart';
import '../../domain/usecases/generate_add_recipe_from_video_usecase.dart';
import '../../domain/usecases/save_add_recipe_basic_info_usecase.dart';
import '../../domain/usecases/save_add_recipe_ingredients_usecase.dart';
import '../../domain/usecases/save_add_recipe_instructions_usecase.dart';
import '../viewmodel/add_recipe_method_viewmodel.dart';
import '../../../../core/widgets/cards/method_card.dart';

class AddRecipePage extends StatelessWidget {
  const AddRecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddRecipeMethodViewModel(
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

class _AddRecipeChooseMethodView extends StatefulWidget {
  const _AddRecipeChooseMethodView();

  @override
  State<_AddRecipeChooseMethodView> createState() => _AddRecipeChooseMethodViewState();
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
                    MethodCard(
                      icon: Icons.movie_creation_rounded,
                      title: "Upload Video",
                      subtitle: "Upload a video and let AI generate the recipe.",
                      onTap: () {
                        _handleUploadVideo(context);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
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

  // Upload Video Helper
  Future<void> _handleUploadVideo(BuildContext context) async {
    final viewModel = context.read<AddRecipeMethodViewModel>();
    viewModel.selectMethod(AddRecipeMethod.uploadVideo);
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (!context.mounted || video == null) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(),
    );

    final success = await viewModel.generateRecipeFromVideo(video.path);
    if (!context.mounted) return;
    rootNavigator.pop();

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ?? "Unable to generate recipe from video.",
          ),
        ),
      );
      return;
    }

    context.pushReplacement(
      AppRouter.addRecipeReview,
      extra: AddRecipeReviewArgs(recipeId: viewModel.generatedRecipeId ?? ""),
    );
  }
}
