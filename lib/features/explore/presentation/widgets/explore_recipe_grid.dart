import 'package:flutter/material.dart';

import '../../domain/entities/explore_recipe.dart';
import 'explore_recipe_card.dart';

// Builds a scrollable grid of recipe cards with interactive callbacks
class ExploreRecipeGridView extends StatelessWidget {
  // List of recipe entities to display in the grid
  final List<ExploreRecipe> recipes;
  // Callback when comment action is triggered on a recipe
  final ValueChanged<ExploreRecipe> onCommentTap;
  // Callback when favourite action is triggered, passing recipe ID
  final ValueChanged<String> onFavouriteTap;
  // Callback when image is long-pressed for additional actions
  final ValueChanged<ExploreRecipe> onImageLongPress;
  // Callback when a recipe card is tapped for navigation
  final ValueChanged<ExploreRecipe> onRecipeTap;
  // Set of recipe IDs that should appear disabled/uninteractive
  final Set<String> disabledRecipeIds;
  // Internal padding around the entire grid
  final EdgeInsetsGeometry padding;

  const ExploreRecipeGridView({
    super.key,
    required this.recipes,
    required this.onCommentTap,
    required this.onFavouriteTap,
    required this.onImageLongPress,
    required this.onRecipeTap,
    this.disabledRecipeIds = const {},
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 24),
  });

  @override
  Widget build(BuildContext context) {
    // Determines available screen width for responsive column count
    final width = MediaQuery.sizeOf(context).width;

    return GridView.builder(
      padding: padding,
      // Dismisses keyboard when scrolling to improve touch interaction
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      // Enables scrolling even when content fits the viewport
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: _recipeGridDelegate(width),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return _ExploreRecipeGridItem(
          recipe: recipes[index],
          onCommentTap: onCommentTap,
          // Checks if current recipe ID exists in the disabled set
          disabled: disabledRecipeIds.contains(recipes[index].id),
          onFavouriteTap: onFavouriteTap,
          onImageLongPress: onImageLongPress,
          onRecipeTap: onRecipeTap,
        );
      },
    );
  }
}

// Provides a sliver-based grid for use in CustomScrollView or NestedScrollView
class ExploreRecipeSliverGrid extends StatelessWidget {
  // List of recipe entities to display in the sliver grid
  final List<ExploreRecipe> recipes;
  // Callback when comment action is triggered on a recipe
  final ValueChanged<ExploreRecipe> onCommentTap;
  // Callback when favourite action is triggered, passing recipe ID
  final ValueChanged<String> onFavouriteTap;
  // Callback when image is long-pressed for additional actions
  final ValueChanged<ExploreRecipe> onImageLongPress;
  // Callback when a recipe card is tapped for navigation
  final ValueChanged<ExploreRecipe> onRecipeTap;
  // Set of recipe IDs that should appear disabled/uninteractive
  final Set<String> disabledRecipeIds;
  // Internal padding around the sliver grid content
  final EdgeInsetsGeometry padding;

  const ExploreRecipeSliverGrid({
    super.key,
    required this.recipes,
    required this.onCommentTap,
    required this.onFavouriteTap,
    required this.onImageLongPress,
    required this.onRecipeTap,
    this.disabledRecipeIds = const {},
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    // Retrieves screen width for responsive grid column calculation
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
            // Evaluates whether this specific recipe should be disabled
            disabled: disabledRecipeIds.contains(recipes[index].id),
            onFavouriteTap: onFavouriteTap,
            onImageLongPress: onImageLongPress,
            onRecipeTap: onRecipeTap,
          );
        },
      ),
    );
  }
}

// Internal widget that wraps a recipe card with all configured callbacks
class _ExploreRecipeGridItem extends StatelessWidget {
  // The recipe entity data for this grid item
  final ExploreRecipe recipe;
  // Callback for comment action on this specific recipe
  final ValueChanged<ExploreRecipe> onCommentTap;
  // Callback for favourite action on this specific recipe
  final ValueChanged<String> onFavouriteTap;
  // Callback for image long-press on this specific recipe
  final ValueChanged<ExploreRecipe> onImageLongPress;
  // Callback for tap navigation on this specific recipe
  final ValueChanged<ExploreRecipe> onRecipeTap;
  // Flag indicating whether this item should be non-interactive
  final bool disabled;

  const _ExploreRecipeGridItem({
    required this.recipe,
    required this.onCommentTap,
    required this.onFavouriteTap,
    required this.onImageLongPress,
    required this.onRecipeTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ExploreRecipeCard(
      recipe: recipe,
      // Wraps comment callback with the current recipe instance
      onComingSoonTap: () => onCommentTap(recipe),
      // Wraps favourite callback with the current recipe ID
      onFavouriteTap: () => onFavouriteTap(recipe.id),
      // Wraps long-press callback with the current recipe instance
      onImageLongPress: () => onImageLongPress(recipe),
      // Conditionally provides tap callback only when not disabled
      onTap: disabled ? null : () => onRecipeTap(recipe),
      disabled: disabled,
    );
  }
}

// Creates a grid delegate with responsive column count based on available width
SliverGridDelegateWithFixedCrossAxisCount _recipeGridDelegate(double width) {
  // Determines number of columns based on screen width breakpoints
  final crossAxisCount = width >= 900
      ? 4
      : width >= 600
      ? 3
      : 2;

  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    // Horizontal spacing between grid items
    crossAxisSpacing: 12,
    // Vertical spacing between grid items
    mainAxisSpacing: 12,
    // Fixed height for each grid item, adjusted for smaller screens
    mainAxisExtent: width < 380 ? 258 : 282,
  );
}