part of '../../view/planning/generate_ai_meal_page.dart';

/// AI result step widgets for generated recipe choices.
///
/// Result selection state stays in the parent view model while cards stay visual.
class _AiResultsStep extends StatelessWidget {
  /// The meal plan data.
  final AddMealAiPlan plan;

  /// Creates a new AI results step instance.
  const _AiResultsStep({required this.plan});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    return Column(
      children: [
        // Header section.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              // Tip box.
              const AppTipBox(
                title: 'Foodopia AI will suggest meal ideas',
                message:
                    'Review AI-created ideas before customising or adding them to your meal plan.',
                backgroundColor: Color(0xFFFFF8E1),
                iconColor: AppColors.secondary,
                icon: Icons.tips_and_updates_outlined,
              ),
              const SizedBox(height: AppSpacing.md),

              // Filter pills.
              Row(
                children: [
                  _Pill(icon: Icons.wb_sunny_outlined, label: plan.mealType),
                  const SizedBox(width: AppSpacing.sm),
                  _Pill(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('d MMM yyyy').format(plan.planningDate),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Pill(
                    icon: Icons.people_outline,
                    label: viewModel.selectedServingSize,
                  ),
                ],
              ),
            ],
          ),
        ),

        // AI result content.
        Expanded(child: _AiCreatedRecipeResults(recipes: plan.aiIdeas)),
      ],
    );
  }
}

/// AI created recipe results view.
class _AiCreatedRecipeResults extends StatelessWidget {
  /// List of recipes.
  final List<AddMealAiRecipe> recipes;

  /// Creates a new AI created recipe results instance.
  const _AiCreatedRecipeResults({required this.recipes});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Show error state if no recipes.
    if (recipes.isEmpty) {
      return _ErrorState(
        message:
            viewModel.errorMessage ??
            'No AI ideas generated yet. Try generating again.',
        onRetry: viewModel.generateIdeas,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Text('AI-Created Ideas', style: context.text.titleMedium),
        Text(
          'AI has helped you create some ideas from your factors.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Recipe cards.
        ...recipes.map((recipe) => _RecipeResultCard(recipe: recipe)),
        const SizedBox(height: AppSpacing.md),

        // Generate more button.
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            border: Border.all(color: AppColors.secondary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Not satisfied with the results?',
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Let AI create more ideas based on your preferences.',
                style: context.text.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: viewModel.generateIdeas,
                child: const Text('Generate More'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Next button.
        _PrimaryActionButton(
          label: 'Next',
          onPressed: viewModel.selectedRecipes.isEmpty
              ? null
              : viewModel.goToNextStep,
        ),
      ],
    );
  }
}

/// Step 3: Instructions step.
