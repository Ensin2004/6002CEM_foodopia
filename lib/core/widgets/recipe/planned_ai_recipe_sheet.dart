import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_extension.dart';
import '../images/app_remote_or_asset_image.dart';

/// Lightweight recipe detail data for AI-generated planned meals.
class PlannedAiRecipePreview {
  /// Display title.
  final String title;

  /// Description or summary.
  final String description;

  /// Duration label.
  final String durationLabel;

  /// Serving size label.
  final String servingLabel;

  /// Difficulty label.
  final String difficultyLabel;

  /// Image path or URL.
  final String imagePath;

  /// Ingredient display rows.
  final List<String> ingredients;

  /// Instruction display rows.
  final List<String> instructions;

  /// Creates AI recipe preview data.
  const PlannedAiRecipePreview({
    required this.title,
    this.description = '',
    this.durationLabel = '',
    this.servingLabel = '',
    this.difficultyLabel = '',
    this.imagePath = '',
    this.ingredients = const [],
    this.instructions = const [],
  });

  /// Whether there is enough AI context to show a useful detail sheet.
  bool get hasDetails =>
      description.trim().isNotEmpty ||
      ingredients.isNotEmpty ||
      instructions.isNotEmpty;
}

/// Opens a bottom sheet with details for an AI-generated planned meal.
Future<void> showPlannedAiRecipeSheet(
  BuildContext context,
  PlannedAiRecipePreview recipe,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _PlannedAiRecipeSheet(recipe: recipe),
  );
}

class _PlannedAiRecipeSheet extends StatelessWidget {
  final PlannedAiRecipePreview recipe;

  const _PlannedAiRecipeSheet({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppRemoteOrAssetImage(
                  imagePath: recipe.imagePath.isEmpty
                      ? 'assets/images/meal1.png'
                      : recipe.imagePath,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(recipe.title, style: context.text.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (recipe.durationLabel.isNotEmpty)
                    _InfoChip(label: recipe.durationLabel),
                  if (recipe.servingLabel.isNotEmpty)
                    _InfoChip(label: recipe.servingLabel),
                  if (recipe.difficultyLabel.isNotEmpty)
                    _InfoChip(label: recipe.difficultyLabel),
                ],
              ),
              if (recipe.description.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(recipe.description, style: context.text.bodyMedium),
              ],
              if (recipe.ingredients.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Ingredients', style: context.text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                ...recipe.ingredients.map((item) => _DetailLine(text: item)),
              ],
              if (recipe.instructions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Instructions', style: context.text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                ...recipe.instructions.indexed.map(
                  (entry) => _DetailLine(text: '${entry.$1 + 1}. ${entry.$2}'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String text;

  const _DetailLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: context.text.bodyMedium),
    );
  }
}
