import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/tabs/app_pill_segmented_control.dart';
import '../../../../core/widgets/tabs/app_segmented_tabs.dart';
import '../../domain/entities/explore_recipe.dart';
import '../viewmodel/explore_recipe_detail_viewmodel.dart';

class ExploreRecipeDetailPage extends StatelessWidget {
  final String recipeId;

  const ExploreRecipeDetailPage({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExploreRecipeDetailViewModel(
        recipeId: recipeId,
        getRecipeDetailUseCase: sl(),
      ),
      child: const _ExploreRecipeDetailView(),
    );
  }
}

class _ExploreRecipeDetailView extends StatefulWidget {
  const _ExploreRecipeDetailView();

  @override
  State<_ExploreRecipeDetailView> createState() =>
      _ExploreRecipeDetailViewState();
}

class _ExploreRecipeDetailViewState extends State<_ExploreRecipeDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ExploreRecipeDetailTab.values.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    context.read<ExploreRecipeDetailViewModel>().selectTab(
      ExploreRecipeDetailTab.values[_tabController.index],
    );
  }

  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Coming soon')),
      );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExploreRecipeDetailViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Recipe Details',
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left),
        ),
        actions: [
          IconButton(
            onPressed: _showComingSoonMessage,
            icon: const Icon(Icons.bookmark_border),
          ),
        ],
      ),
      body: _DetailBody(
        viewModel: viewModel,
        tabController: _tabController,
        onComingSoonTap: _showComingSoonMessage,
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final TabController tabController;
  final VoidCallback onComingSoonTap;

  const _DetailBody({
    required this.viewModel,
    required this.tabController,
    required this.onComingSoonTap,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const LoadingDialog(message: 'Loading recipe...', inline: true);
    }

    final error = viewModel.errorMessage;
    final recipe = viewModel.recipe;
    if (error != null || recipe == null) {
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
      padding: EdgeInsets.zero,
      children: [
        _HeroImage(recipe: recipe),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _RecipeHeader(recipe: recipe),
        ),
        _TopTabs(tabController: tabController),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: _SelectedTabContent(
            viewModel: viewModel,
            recipe: recipe,
            onComingSoonTap: onComingSoonTap,
          ),
        ),
      ],
    );
  }
}

class _HeroImage extends StatefulWidget {
  final ExploreRecipe recipe;

  const _HeroImage({required this.recipe});

  @override
  State<_HeroImage> createState() => _HeroImageState();
}

class _HeroImageState extends State<_HeroImage> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recipeImages = widget.recipe.imagePaths;
    final images = recipeImages == null || recipeImages.isEmpty
        ? <String>[widget.recipe.imagePath]
        : recipeImages;

    return Stack(
      children: [
        ColoredBox(
          color: colors.surfaceContainerHighest,
          child: AspectRatio(
            aspectRatio: 1.55,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return Image.asset(
                  images[index],
                  width: double.infinity,
                  fit: BoxFit.contain,
                );
              },
            ),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${images.length}',
              style: context.text.bodySmall?.copyWith(
                color: colors.surface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecipeHeader extends StatelessWidget {
  final ExploreRecipe recipe;

  const _RecipeHeader({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'By ${recipe.author} - 2 hrs ago',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.schedule,
                color: context.colors.primary,
                title: recipe.totalTime,
                subtitle: 'Time',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.restaurant_menu,
                color: AppColors.error,
                title: recipe.difficulty,
                subtitle: 'Difficulty',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.star,
                color: AppColors.secondary,
                title: recipe.rating.toStringAsFixed(1),
                subtitle: 'Rating',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _MetricTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color, size: 20),
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
                  style: textTheme.labelLarge,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTabs extends StatelessWidget {
  final TabController tabController;

  const _TopTabs({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return AppSegmentedTabs(
      controller: tabController,
      tabs: ExploreRecipeDetailTab.values.map(_detailTabLabel).toList(),
      margin: const EdgeInsets.only(top: 12),
      isScrollable: false,
    );
  }
}

class _SelectedTabContent extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;

  const _SelectedTabContent({
    required this.viewModel,
    required this.recipe,
    required this.onComingSoonTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewModel.selectedTab) {
      case ExploreRecipeDetailTab.recipe:
        return _RecipeTab(
          viewModel: viewModel,
          recipe: recipe,
          onComingSoonTap: onComingSoonTap,
        );
      case ExploreRecipeDetailTab.nutrition:
        return _NutritionTab(
          recipe: recipe,
          onServingTap: onComingSoonTap,
        );
      case ExploreRecipeDetailTab.community:
        return _CommunityTab(
          viewModel: viewModel,
          recipe: recipe,
          onComingSoonTap: onComingSoonTap,
        );
    }
  }
}

class _RecipeTab extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;

  const _RecipeTab({
    required this.viewModel,
    required this.recipe,
    required this.onComingSoonTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About This Recipe', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(recipe.description, style: textTheme.bodyMedium),
        const SizedBox(height: 14),
        Text('Category', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(recipe.category, style: textTheme.bodyMedium),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('Allergen Info', style: textTheme.titleMedium),
            const SizedBox(width: 4),
            const Icon(Icons.warning_amber, size: 15, color: AppColors.error),
          ],
        ),
        const SizedBox(height: 6),
        Text(recipe.allergenInfo, style: textTheme.bodyMedium),
        const SizedBox(height: 14),
        AppPillSegmentedControl(
          labels: const ['Ingredients', 'Instructions'],
          selectedIndex: ExploreRecipeMethodTab.values.indexOf(
            viewModel.selectedMethodTab,
          ),
          onChanged: (index) => viewModel.selectMethodTab(
            ExploreRecipeMethodTab.values[index],
          ),
        ),
        const SizedBox(height: 16),
        if (viewModel.selectedMethodTab == ExploreRecipeMethodTab.ingredients)
          _IngredientsList(recipe: recipe, onUnitTap: onComingSoonTap)
        else
          _InstructionsList(recipe: recipe),
      ],
    );
  }
}

class _IngredientsList extends StatelessWidget {
  final ExploreRecipe recipe;
  final VoidCallback onUnitTap;

  const _IngredientsList({required this.recipe, required this.onUnitTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingredients List', style: textTheme.titleMedium),
        Text('${recipe.ingredients.length} items', style: textTheme.bodyMedium),
        const SizedBox(height: 10),
        ...recipe.ingredients.map((ingredient) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.onSurface.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    ingredient.imagePath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ingredient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                      Text(ingredient.calories, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onUnitTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 86,
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ingredient.amount,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        PrimaryButton(
          onPressed: () {},
          text: 'Start Cooking',
          verticalPadding: 14,
        ),
      ],
    );
  }
}

class _InstructionsList extends StatelessWidget {
  final ExploreRecipe recipe;

  const _InstructionsList({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recipe.instructionSections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: textTheme.titleMedium?.copyWith(
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(height: 8),
              ...section.steps.asMap().entries.map((entry) {
                final stepIndex = entry.key;
                final step = entry.value;
                final isLast = stepIndex == section.steps.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InstructionTimelineMarker(
                        showLine: !isLast,
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          step.imagePath,
                          width: 42,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.title, style: textTheme.labelLarge),
                            Text(
                              step.description,
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InstructionTimelineMarker extends StatelessWidget {
  final bool showLine;

  const _InstructionTimelineMarker({
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 24,
      height: 82,
      child: Column(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: colors.primary,
          ),
          if (showLine)
            const Expanded(
              child: _DottedTimelineLine(),
            ),
        ],
      ),
    );
  }
}

class _DottedTimelineLine extends StatelessWidget {
  const _DottedTimelineLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedTimelineLinePainter(color: context.colors.primary),
      child: const SizedBox(width: 1, height: double.infinity),
    );
  }
}

class _DottedTimelineLinePainter extends CustomPainter {
  final Color color;

  const _DottedTimelineLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashHeight = 3.0;
    const gap = 4.0;
    final x = size.width / 2;

    double y = 4;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedTimelineLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _NutritionTab extends StatelessWidget {
  final ExploreRecipe recipe;
  final VoidCallback onServingTap;

  const _NutritionTab({
    required this.recipe,
    required this.onServingTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final nutrition = recipe.nutrition;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NutritionPanel(
          child: Column(
            children: [
              Row(
                children: [
                  Text('Nutrition Summary', style: textTheme.titleMedium),
                  const Spacer(),
                  InkWell(
                    onTap: onServingTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Per serving', style: textTheme.bodySmall),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 118,
                    height: 118,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size.square(118),
                          painter: _MacroRingPainter(
                            carbs: nutrition.carbsGrams,
                            protein: nutrition.proteinGrams,
                            fat: nutrition.fatGrams,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${nutrition.calories}',
                              style: textTheme.headlineSmall,
                            ),
                            Text('kcal', style: textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        _MacroRow(
                          label: 'Carbohydrate',
                          grams: nutrition.carbsGrams,
                          color: AppColors.primary,
                        ),
                        _MacroRow(
                          label: 'Protein',
                          grams: nutrition.proteinGrams,
                          color: AppColors.error,
                        ),
                        _MacroRow(
                          label: 'Fat',
                          grams: nutrition.fatGrams,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _NutritionPanel(
          child: Column(
            children: [
              Row(
                children: [
                  Text('Ingredients Breakdown', style: textTheme.titleMedium),
                  const Spacer(),
                  Text(
                    'See all',
                    style: textTheme.bodySmall?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...recipe.ingredients.map(
                (ingredient) => _IngredientNutritionRow(
                  ingredient: ingredient,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NutritionPanel extends StatelessWidget {
  final Widget child;

  const _NutritionPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final int grams;
  final Color color;

  const _MacroRow({required this.label, required this.grams, required this.color});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final value = (grams / 40).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: value,
                  color: color,
                  backgroundColor: AppColors.background,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 44,
                child: Text(
                  '${(value * 100).round()}%',
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '${grams}g',
                  style: textTheme.labelLarge,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  final int carbs;
  final int protein;
  final int fat;

  const _MacroRingPainter({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final rect = Offset.zero & size;
    final total = (carbs + protein + fat).toDouble();
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.background;

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -1.5708,
      6.2832,
      false,
      backgroundPaint,
    );

    if (total <= 0) return;

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    var startAngle = -1.5708;
    const gapAngle = 0.08;
    final segments = [
      _MacroRingSegment(value: carbs, color: AppColors.primary),
      _MacroRingSegment(value: protein, color: AppColors.error),
      _MacroRingSegment(value: fat, color: AppColors.secondary),
    ];

    for (final segment in segments) {
      final sweep = (segment.value / total) * 6.2832;
      segmentPaint.color = segment.color;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        (sweep - gapAngle).clamp(0.0, 6.2832).toDouble(),
        false,
        segmentPaint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter oldDelegate) {
    return oldDelegate.carbs != carbs ||
        oldDelegate.protein != protein ||
        oldDelegate.fat != fat;
  }
}

class _MacroRingSegment {
  final int value;
  final Color color;

  const _MacroRingSegment({required this.value, required this.color});
}

class _IngredientNutritionRow extends StatelessWidget {
  final ExploreIngredient ingredient;

  const _IngredientNutritionRow({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              ingredient.imagePath,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ingredient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ingredient.calories,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: ingredient.nutritionPercent,
                  color: context.colors.primary,
                  backgroundColor: AppColors.background,
                  minHeight: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTab extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;

  const _CommunityTab({
    required this.viewModel,
    required this.recipe,
    required this.onComingSoonTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final relatedRecipes = recipe.relatedRecipes.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Creator', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(backgroundImage: AssetImage(recipe.authorAvatarPath)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.author, style: textTheme.titleMedium),
                  Text(
                    recipe.community.authorBio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 30,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.primary,
                  side: BorderSide(color: context.colors.primary),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Follow'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Related Recipes', style: textTheme.titleMedium),
            const Spacer(),
            TextButton(
              onPressed: onComingSoonTap,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: relatedRecipes.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == relatedRecipes.length - 1 ? 0 : 10,
                ),
                child: Container(
                  height: 138,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ColoredBox(
                            color: context.colors.surfaceContainerHighest,
                            child: Image.asset(
                              item.imagePath,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        AppPillSegmentedControl(
          labels: const ['Ratings', 'Comments'],
          selectedIndex: ExploreCommunityTab.values.indexOf(
            viewModel.selectedCommunityTab,
          ),
          onChanged: (index) => viewModel.selectCommunityTab(
            ExploreCommunityTab.values[index],
          ),
        ),
        const SizedBox(height: 14),
        if (viewModel.selectedCommunityTab == ExploreCommunityTab.ratings)
          _RatingsPanel(recipe: recipe, onComingSoonTap: onComingSoonTap)
        else
          _CommentsPanel(
            recipe: recipe,
            onComingSoonTap: onComingSoonTap,
          ),
      ],
    );
  }
}

class _RatingsPanel extends StatelessWidget {
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;

  const _RatingsPanel({
    required this.recipe,
    required this.onComingSoonTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 94,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      recipe.rating.toStringAsFixed(1),
                      style: textTheme.headlineSmall,
                    ),
                    const _RatingStars(size: 22, rating: 5),
                    Text(
                      '(${recipe.ratingCount} ratings)',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 110, color: AppColors.border),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: recipe.community.ratingBreakdown.map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Row(
                              children: [
                                Text('${row.stars}', style: textTheme.bodySmall),
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: AppColors.secondary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: row.count / recipe.ratingCount,
                              color: context.colors.primary,
                              backgroundColor: AppColors.background,
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            child: Text('${row.count}', style: textTheme.bodySmall),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _RateRecipeCard(onComingSoonTap: onComingSoonTap),
        const SizedBox(height: 12),
        _ViewRatingsCard(
          reviews: recipe.community.reviews,
          onFilterTap: onComingSoonTap,
        ),
      ],
    );
  }
}

class _RateRecipeCard extends StatelessWidget {
  final VoidCallback onComingSoonTap;

  const _RateRecipeCard({required this.onComingSoonTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate this Recipe', style: textTheme.titleMedium),
          Text('Tap a star to rate', style: textTheme.bodySmall),
          const SizedBox(height: 10),
          InkWell(
            onTap: onComingSoonTap,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                5,
                (_) => const Icon(
                  Icons.star_border,
                  color: AppColors.secondary,
                  size: 34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewRatingsCard extends StatelessWidget {
  final List<ExploreReview> reviews;
  final VoidCallback onFilterTap;

  const _ViewRatingsCard({
    required this.reviews,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('View Ratings', style: textTheme.titleMedium),
              const Spacer(),
              InkWell(
                onTap: onFilterTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text('All', style: textTheme.bodySmall),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...reviews.map((review) => _ReviewTile(review: review)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ExploreReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(backgroundImage: AssetImage(review.avatarPath)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.author, style: textTheme.labelLarge),
                  Text(review.timeAgo, style: textTheme.bodySmall),
                ],
              ),
            ),
            SizedBox(
              width: 92,
              child: _RatingStars(size: 18, rating: review.rating),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final double size;
  final double rating;

  const _RatingStars({required this.size, required this.rating});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final isFilled = index < rating.round();
          return Icon(
            Icons.star,
            size: size,
            color: isFilled ? AppColors.secondary : AppColors.border,
          );
        }),
      ),
    );
  }
}

class _CommentsPanel extends StatelessWidget {
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;

  const _CommentsPanel({
    required this.recipe,
    required this.onComingSoonTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${recipe.community.comments.length} Comments',
                style: textTheme.titleMedium,
              ),
              const Spacer(),
              _SmallDropdownButton(label: 'All', onTap: onComingSoonTap),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage(
                  recipe.community.comments.first.avatarPath,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onComingSoonTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 42,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Add a comment.....',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...recipe.community.comments.map((comment) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 18, backgroundImage: AssetImage(comment.avatarPath)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment.author, style: textTheme.labelLarge),
                        Text(comment.timeAgo, style: textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(comment.content, style: textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('${comment.likes}', style: textTheme.bodySmall),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.thumb_up,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 16),
                            Text('Reply', style: textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SmallDropdownButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SmallDropdownButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(label, style: context.text.bodySmall),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

String _detailTabLabel(ExploreRecipeDetailTab tab) {
  switch (tab) {
    case ExploreRecipeDetailTab.recipe:
      return 'Recipe';
    case ExploreRecipeDetailTab.nutrition:
      return 'Nutrition';
    case ExploreRecipeDetailTab.community:
      return 'Community';
  }
}
