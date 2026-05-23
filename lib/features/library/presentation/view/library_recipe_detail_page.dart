import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/library_recipe.dart';
import '../viewmodel/library_recipe_detail_viewmodel.dart';

class LibraryRecipeDetailPage extends StatelessWidget {
  final String recipeId;

  const LibraryRecipeDetailPage({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryRecipeDetailViewModel(
        recipeId: recipeId,
        getRecipeDetailUseCase: sl(),
      ),
      child: const _LibraryRecipeDetailView(),
    );
  }
}

class _LibraryRecipeDetailView extends StatelessWidget {
  const _LibraryRecipeDetailView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryRecipeDetailViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Recipe Details',
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left),
        ),
      ),
      body: _DetailBody(viewModel: viewModel),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final LibraryRecipeDetailViewModel viewModel;

  const _DetailBody({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const LoadingDialog(message: 'Loading recipe...', inline: true);
    }

    final recipe = viewModel.recipe;
    final error = viewModel.errorMessage;
    if (recipe == null || error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error ?? 'Recipe unavailable',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
        ),
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _HeroImage(recipe: recipe),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.text.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'By ${recipe.author} - ${recipe.publishedAtLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: 14),
              _MetricRow(recipe: recipe),
              const SizedBox(height: 20),
              Text('About This Recipe', style: context.text.titleMedium),
              const SizedBox(height: 8),
              Text(
                recipe.description,
                style: context.text.bodyLarge?.copyWith(height: 1.35),
              ),
              const SizedBox(height: 18),
              _InfoLine(label: 'Categories', value: recipe.category),
              const SizedBox(height: 8),
              _InfoLine(label: 'Allergens', value: recipe.allergenInfo),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  final LibraryRecipe recipe;

  const _HeroImage({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final images = recipe.imagePaths == null || recipe.imagePaths!.isEmpty
        ? <String>[recipe.imagePath]
        : recipe.imagePaths!;

    return Stack(
      children: [
        ColoredBox(
          color: context.colors.surfaceContainerHighest,
          child: AspectRatio(
            aspectRatio: 1.55,
            child: _RecipeImage(path: images.first),
          ),
        ),
        if (recipe.isSelfPublished) ...[
          Positioned(
            left: 8,
            top: 8,
            child: _ImageActionButton(
              label: 'Edit',
              color: AppColors.textPrimary,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: _ImageActionButton(
              label: recipe.isPublished ? 'Private' : 'Publish',
              color: recipe.isPublished ? AppColors.error : AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final String label;
  final Color color;

  const _ImageActionButton({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: context.text.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final LibraryRecipe recipe;

  const _MetricRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.schedule,
            title: recipe.totalTime,
            subtitle: 'Time',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            icon: Icons.restaurant_menu,
            title: recipe.difficulty,
            subtitle: 'Difficulty',
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            icon: Icons.star,
            title: recipe.isPublished
                ? recipe.rating.toStringAsFixed(1)
                : 'No rating',
            subtitle: 'Rating',
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: context.text.bodyMedium,
        children: [
          TextSpan(
            text: '$label: ',
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _RecipeImage extends StatelessWidget {
  final String path;

  const _RecipeImage({required this.path});

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
