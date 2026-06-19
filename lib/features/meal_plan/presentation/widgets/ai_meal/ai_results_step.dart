part of '../../view/planning/generate_ai_meal_page.dart';

/// AI result step widgets for generated and database recipe choices.
///
/// Result selection state stays in the parent view model while cards stay visual.
class _AiResultsStep extends StatefulWidget {
  /// The meal plan data.
  final AddMealAiPlan plan;

  /// Creates a new AI results step instance.
  const _AiResultsStep({required this.plan});

  @override
  State<_AiResultsStep> createState() => _AiResultsStepState();
}

/// State for the AI results step.
class _AiResultsStepState extends State<_AiResultsStep>
    with SingleTickerProviderStateMixin {
  /// Tab controller for switching between database and AI results.
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the view model.
    final showDatabase = context
        .read<GenerateAiMealViewModel>()
        .showDatabaseResults;

    // Determine expected tab length.
    final expectedLength = showDatabase ? 2 : 1;

    // Skip if controller already has correct length.
    if (_tabController?.length == expectedLength) return;

    // Dispose old controller and create new one.
    _tabController?.dispose();
    _tabController = TabController(length: expectedLength, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Get the plan.
    final plan = widget.plan;

    // Determine if database results should be shown.
    final showDatabase = viewModel.showDatabaseResults;

    // Get the tab controller.
    final tabController = _tabController;

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
              if (showDatabase)
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

              // Tab bar for switching views.
              if (showDatabase && tabController != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: context.text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    tabs: const [
                      Tab(text: 'Recipe Database'),
                      Tab(text: 'AI Ideas'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Tab content.
        Expanded(
          child: showDatabase && tabController != null
              ? TabBarView(
                  controller: tabController,
                  children: [
                    _DatabaseRecipeResults(recipes: plan.topMatches),
                    _AiCreatedRecipeResults(recipes: plan.aiIdeas),
                  ],
                )
              : _AiCreatedRecipeResults(recipes: plan.aiIdeas),
        ),
      ],
    );
  }
}

/// Database recipe results view.
class _DatabaseRecipeResults extends StatelessWidget {
  /// List of recipes.
  final List<AddMealAiRecipe> recipes;

  /// Creates a new database recipe results instance.
  const _DatabaseRecipeResults({required this.recipes});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Show empty state if no recipes.
    if (recipes.isEmpty) {
      return _NoDatabaseRecipes(onNext: viewModel.goToNextStep);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Text(
          'Top Matches from Recipe Database',
          style: context.text.titleMedium,
        ),
        Text(
          'Relevant recipes are found in your recipe database.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...recipes.map((recipe) => _RecipeResultCard(recipe: recipe)),
        const SizedBox(height: AppSpacing.lg),
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

/// Empty state for database recipes.
class _NoDatabaseRecipes extends StatelessWidget {
  /// Callback for next button.
  final VoidCallback onNext;

  /// Creates a new no database recipes instance.
  const _NoDatabaseRecipes({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Image.asset('assets/images/empty_page.png', height: 140),
        const SizedBox(height: AppSpacing.md),
        Text(
          'No matching recipes found',
          textAlign: TextAlign.center,
          style: context.text.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'There are no database recipes matching these factors yet. Try the AI Ideas tab for generated suggestions.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xl),
        _PrimaryActionButton(label: 'Next', onPressed: onNext),
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
