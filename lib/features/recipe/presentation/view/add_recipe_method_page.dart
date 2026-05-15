import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/routers/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../viewmodel/add_recipe_method_viewmodel.dart';
import '../../../../core/widgets/cards/method_card.dart';

class AddRecipePage extends StatelessWidget {
  const AddRecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddRecipeMethodViewModel(),
      child: const _AddRecipeChooseMethodView(),
    );
  }
}

class _AddRecipeChooseMethodView extends StatelessWidget {
  const _AddRecipeChooseMethodView();

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
                      subtitle:
                          "Upload a video and let AI generate the recipe.",
                      onTap: () {
                        context.read<AddRecipeMethodViewModel>().selectMethod(
                          AddRecipeMethod.uploadVideo,
                        );
                        // TODO - Cojean
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Upload video is coming soon."),
                          ),
                        );
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
}
