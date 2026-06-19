import 'package:flutter/material.dart';

import '../../../meal_plan/domain/entities/meal_calorie_guidance.dart';
import '../../../meal_plan/domain/services/meal_calorie_guidance_service.dart';
import '../../domain/entities/explore_recipe.dart';
import 'explore_recipe_card.dart';

class ExploreRecipeGridView extends StatelessWidget {
  final List<ExploreRecipe> recipes;
  final ValueChanged<ExploreRecipe> onCommentTap;
  final ValueChanged<String> onFavouriteTap;
  final ValueChanged<ExploreRecipe> onImageLongPress;
  final ValueChanged<ExploreRecipe> onRecipeTap;
  final Set<String> disabledRecipeIds;
  final MealCalorieBudget? calorieBudget;
  final EdgeInsetsGeometry padding;

  const ExploreRecipeGridView({
    super.key,
    required this.recipes,
    required this.onCommentTap,
    required this.onFavouriteTap,
    required this.onImageLongPress,
    required this.onRecipeTap,
    this.disabledRecipeIds = const {},
    this.calorieBudget,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 24),
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return GridView.builder(
      padding: padding,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: _recipeGridDelegate(width),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return _ExploreRecipeGridItem(
          recipe: recipes[index],
          onCommentTap: onCommentTap,
          disabled: disabledRecipeIds.contains(recipes[index].id),
          onFavouriteTap: onFavouriteTap,
          onImageLongPress: onImageLongPress,
          onRecipeTap: onRecipeTap,
          calorieBudget: calorieBudget,
        );
      },
    );
  }
}

class ExploreRecipeSliverGrid extends StatelessWidget {
  final List<ExploreRecipe> recipes;
  final ValueChanged<ExploreRecipe> onCommentTap;
  final ValueChanged<String> onFavouriteTap;
  final ValueChanged<ExploreRecipe> onImageLongPress;
  final ValueChanged<ExploreRecipe> onRecipeTap;
  final Set<String> disabledRecipeIds;
  final MealCalorieBudget? calorieBudget;
  final EdgeInsetsGeometry padding;

  const ExploreRecipeSliverGrid({
    super.key,
    required this.recipes,
    required this.onCommentTap,
    required this.onFavouriteTap,
    required this.onImageLongPress,
    required this.onRecipeTap,
    this.disabledRecipeIds = const {},
    this.calorieBudget,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return SliverPadding(
      padding: padding,
      sliver: SliverGrid.builder(
        itemCount: recipes.length,
        gridDelegate: _recipeGridDelegate(width),
        itemBuilder: (context, index) {
          return _ExploreRecipeGridItem(
            recipe: recipes[index],
            onCommentTap: onCommentTap,
            disabled: disabledRecipeIds.contains(recipes[index].id),
            onFavouriteTap: onFavouriteTap,
            onImageLongPress: onImageLongPress,
            onRecipeTap: onRecipeTap,
            calorieBudget: calorieBudget,
          );
        },
      ),
    );
  }
}

class _ExploreRecipeGridItem extends StatelessWidget {
  final ExploreRecipe recipe;
  final ValueChanged<ExploreRecipe> onCommentTap;
  final ValueChanged<String> onFavouriteTap;
  final ValueChanged<ExploreRecipe> onImageLongPress;
  final ValueChanged<ExploreRecipe> onRecipeTap;
  final bool disabled;
  final MealCalorieBudget? calorieBudget;

  const _ExploreRecipeGridItem({
    required this.recipe,
    required this.onCommentTap,
    required this.onFavouriteTap,
    required this.onImageLongPress,
    required this.onRecipeTap,
    this.disabled = false,
    this.calorieBudget,
  });

  @override
  Widget build(BuildContext context) {
    return ExploreRecipeCard(
      recipe: recipe,
      onComingSoonTap: () => onCommentTap(recipe),
      onFavouriteTap: () => onFavouriteTap(recipe.id),
      onImageLongPress: () => onImageLongPress(recipe),
      onTap: disabled ? null : () => onRecipeTap(recipe),
      disabled: disabled,
      calorieGuidance: calorieBudget == null
          ? null
          : MealCalorieGuidanceService().evaluate(
              budget: calorieBudget!,
              mealCalories: recipe.nutrition.calories,
            ),
    );
  }
}

SliverGridDelegateWithFixedCrossAxisCount _recipeGridDelegate(double width) {
  final crossAxisCount = width >= 900
      ? 4
      : width >= 600
      ? 3
      : 2;

  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    mainAxisExtent: width < 380 ? 258 : 282,
  );
}
