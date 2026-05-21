import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/box/app_tip_box.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../../core/widgets/progress_bar/app_step_progress_bar.dart';
import '../../../domain/entities/add_meal_ai_plan.dart';
import '../../../domain/usecases/get_add_meal_ai_plan_usecase.dart';
import '../../viewmodel/generate_ai_meal_viewmodel.dart';

class GenerateAiMealPage extends StatelessWidget {
  final String userId;
  final String mealType;

  const GenerateAiMealPage({
    super.key,
    required this.userId,
    required this.mealType,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GenerateAiMealViewModel(
        userId: userId,
        mealType: mealType,
        getPlanUseCase: sl<GetAddMealAiPlanUseCase>(),
      ),
      child: const _GenerateAiMealView(),
    );
  }
}

class _GenerateAiMealView extends StatelessWidget {
  const _GenerateAiMealView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();

    if (viewModel.isLoading && viewModel.plan == null) {
      return const Scaffold(
        body: LoadingDialog(inline: true, message: 'Loading AI meal setup...'),
      );
    }

    final plan = viewModel.plan;
    if (plan == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Generate with AI',
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.chevron_left),
          ),
        ),
        body: _ErrorState(
          message: viewModel.errorMessage ?? 'Unable to load AI meal setup',
          onRetry: viewModel.loadPlan,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: viewModel.currentStep == 4
            ? 'Add to Meal Plan'
            : 'Generate with AI',
        leading: IconButton(
          onPressed: () {
            if (viewModel.currentStep > 1) {
              context.read<GenerateAiMealViewModel>().goToPreviousStep();
            } else {
              context.pop();
            }
          },
          icon: const Icon(Icons.chevron_left),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: AppStepProgressBar(
                totalSteps: 4,
                currentStep: viewModel.currentStep,
                labels: const ['Factor', 'AI Result', 'Instructions', 'Review'],
              ),
            ),
            Expanded(child: _StepBody(plan: plan)),
          ],
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  final AddMealAiPlan plan;

  const _StepBody({required this.plan});

  @override
  Widget build(BuildContext context) {
    final step = context.watch<GenerateAiMealViewModel>().currentStep;
    switch (step) {
      case 2:
        return _AiResultsStep(plan: plan);
      case 3:
        return const _InstructionsStep();
      case 4:
        return _ReviewStep(plan: plan);
      default:
        return _FactorStep(plan: plan);
    }
  }
}

class _FactorStep extends StatelessWidget {
  final AddMealAiPlan plan;

  const _FactorStep({required this.plan});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        const AppTipBox(
          title: 'Foodopia AI will suggest meal ideas',
          message:
              'Based on time of day, weather, ingredients you have, your preferences and dietary needs.',
          backgroundColor: Color(0xFFFFF8E1),
          iconColor: AppColors.secondary,
          icon: Icons.smart_toy_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _MiniInfoTile(
                icon: Icons.wb_sunny_outlined,
                label: 'Planning for',
                value: plan.mealType,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MiniInfoTile(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: DateFormat('EEE, d MMM yyyy').format(plan.planningDate),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Consider These Factors', style: context.text.titleMedium),
        const SizedBox(height: 2),
        Text(
          'AI will use these information to generate the best suggestions for you.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ExpandableFactorCard(
          icon: Icons.wb_cloudy_outlined,
          title: 'Weather',
          subtitle: '${plan.weather.condition} - ${plan.weather.temperature}C',
          selectedLabels: [plan.weather.summary],
          children: [_SelectedSummaryText(plan.weather.summary)],
        ),
        _ExpandableFactorCard(
          icon: Icons.shopping_cart_outlined,
          title: 'Ingredients to Include',
          subtitle: 'Enter ingredients you have and want AI to include.',
          selectedLabels: context
              .watch<GenerateAiMealViewModel>()
              .selectedIngredientsToInclude,
          children: [
            _InlineTextInput(
              hintText: 'e.g. eggs, chicken, oats, spinach ...',
              onChanged: context
                  .read<GenerateAiMealViewModel>()
                  .updateIngredientIncludeText,
            ),
          ],
        ),
        _MealPreferenceFactorCard(plan: plan),
        _ExpandableFactorCard(
          icon: Icons.block,
          title: 'Ingredients to Avoid',
          subtitle: 'Choose ingredients you want AI to avoid.',
          selectedLabels: context
              .watch<GenerateAiMealViewModel>()
              .selectedIngredientsToAvoid,
          children: [
            if (plan.preferences.dislikes.isNotEmpty) ...[
              _SectionLabel('From Settings'),
              const SizedBox(height: AppSpacing.xs),
              _ChipWrap(
                values: plan.preferences.dislikes,
                selectedValues: plan.preferences.dislikes,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _InlineTextInput(
              hintText: 'e.g. peanuts, seafood, mushrooms ...',
              onChanged: context
                  .read<GenerateAiMealViewModel>()
                  .updateIngredientAvoidText,
            ),
          ],
        ),
        _DishPreferenceFactorCard(plan: plan),
        const _CookingPreferenceFactorCard(),
        const SizedBox(height: AppSpacing.lg),
        _PrimaryActionButton(
          label: 'Generate Recipe',
          onPressed: context.read<GenerateAiMealViewModel>().goToResults,
        ),
      ],
    );
  }
}

class _MealPreferenceFactorCard extends StatelessWidget {
  final AddMealAiPlan plan;

  const _MealPreferenceFactorCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();
    const options = ['No Preference', 'Vegetarian', 'Low Carb', 'High Protein'];

    return _ExpandableFactorCard(
      icon: Icons.favorite,
      title: 'Meal Preferences',
      subtitle: 'Selected from Settings',
      selectedLabels: [viewModel.selectedMealPreference],
      children: [
        _ChipWrap(
          values: options,
          selectedValues: [viewModel.selectedMealPreference],
          onSelected: context
              .read<GenerateAiMealViewModel>()
              .selectMealPreference,
        ),
      ],
    );
  }
}

class _DishPreferenceFactorCard extends StatelessWidget {
  final AddMealAiPlan plan;

  const _DishPreferenceFactorCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();

    return _ExpandableFactorCard(
      icon: Icons.no_meals_outlined,
      title: 'Dish Preference',
      subtitle: 'Choose dish types AI should include or avoid.',
      selectedLabels: [
        ...viewModel.selectedDishIncludes,
        ...viewModel.selectedDishAvoids,
      ],
      children: [
        _SectionLabel('Include examples'),
        const SizedBox(height: AppSpacing.xs),
        _ChipWrap(values: plan.dishPreferences, selectedValues: const []),
        const SizedBox(height: AppSpacing.sm),
        _InlineTextInput(
          hintText: 'Type dish to include, e.g. grilled rice bowl',
          onChanged: context
              .read<GenerateAiMealViewModel>()
              .updateDishIncludeText,
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionLabel('Avoid examples'),
        const SizedBox(height: AppSpacing.xs),
        const _ChipWrap(
          values: ['Soup', 'Fried', 'Spicy', 'Oily', 'Creamy'],
          selectedValues: [],
          danger: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        _InlineTextInput(
          hintText: 'Type dish to avoid, e.g. spicy soup',
          onChanged: context
              .read<GenerateAiMealViewModel>()
              .updateDishAvoidText,
        ),
      ],
    );
  }
}

class _CookingPreferenceFactorCard extends StatelessWidget {
  const _CookingPreferenceFactorCard();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();
    final selectedLabels = [
      'Cooking: ${viewModel.selectedCookingTime}',
      'Difficulty: ${viewModel.selectedDifficulty}',
      'Serving: ${viewModel.selectedServingSize}',
    ];

    return _ExpandableFactorCard(
      icon: Icons.soup_kitchen_outlined,
      title: 'Cooking Preferences',
      subtitle: 'Cooking time, difficulty and serving size.',
      selectedLabels: selectedLabels,
      children: [
        _OptionGroup(
          title: 'Cooking Time',
          options: const ['Any', 'Under 15 mins', '15-30 mins', '30+ mins'],
          selected: viewModel.selectedCookingTime,
          onSelected: context.read<GenerateAiMealViewModel>().selectCookingTime,
        ),
        const SizedBox(height: AppSpacing.md),
        _OptionGroup(
          title: 'Difficulty',
          options: const ['Any', 'Easy', 'Medium', 'Hard'],
          selected: viewModel.selectedDifficulty,
          onSelected: context.read<GenerateAiMealViewModel>().selectDifficulty,
        ),
        const SizedBox(height: AppSpacing.md),
        _OptionGroup(
          title: 'Serving Size',
          options: const ['Any', '1 serving', '2 servings', '4 servings'],
          selected: viewModel.selectedServingSize,
          onSelected: context.read<GenerateAiMealViewModel>().selectServingSize,
        ),
      ],
    );
  }
}

class _AiResultsStep extends StatefulWidget {
  final AddMealAiPlan plan;

  const _AiResultsStep({required this.plan});

  @override
  State<_AiResultsStep> createState() => _AiResultsStepState();
}

class _AiResultsStepState extends State<_AiResultsStep>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              const AppTipBox(
                title: 'Foodopia AI will suggest meal ideas',
                message:
                    'Review matched recipes from your database or AI-created ideas before adding.',
                backgroundColor: Color(0xFFFFF8E1),
                iconColor: AppColors.secondary,
                icon: Icons.tips_and_updates_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _Pill(icon: Icons.wb_sunny_outlined, label: plan.mealType),
                  const SizedBox(width: AppSpacing.sm),
                  _Pill(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('d MMM yyyy').format(plan.planningDate),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const _Pill(icon: Icons.people_outline, label: '2 servings'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
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
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DatabaseRecipeResults(recipes: plan.topMatches),
              _AiCreatedRecipeResults(recipes: plan.aiIdeas),
            ],
          ),
        ),
      ],
    );
  }
}

class _DatabaseRecipeResults extends StatelessWidget {
  final List<AddMealAiRecipe> recipes;

  const _DatabaseRecipeResults({required this.recipes});

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return _NoDatabaseRecipes(
        onNext: context.read<GenerateAiMealViewModel>().goToNextStep,
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
        Text(
          'Top Matches from Recipe Database',
          style: context.text.titleMedium,
        ),
        Text(
          'Relevant recipes are found in our recipe database.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...recipes.map((recipe) => _RecipeResultCard(recipe: recipe)),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(onPressed: () {}, child: const Text('Show More')),
        const SizedBox(height: AppSpacing.lg),
        _PrimaryActionButton(
          label: 'Next',
          onPressed: context.read<GenerateAiMealViewModel>().goToNextStep,
        ),
      ],
    );
  }
}

class _AiCreatedRecipeResults extends StatelessWidget {
  final List<AddMealAiRecipe> recipes;

  const _AiCreatedRecipeResults({required this.recipes});

  @override
  Widget build(BuildContext context) {
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
        ...recipes.map((recipe) => _RecipeResultCard(recipe: recipe)),
        const SizedBox(height: AppSpacing.md),
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
              OutlinedButton(onPressed: () {}, child: const Text('Show More')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PrimaryActionButton(
          label: 'Next',
          onPressed: context.read<GenerateAiMealViewModel>().goToNextStep,
        ),
      ],
    );
  }
}

class _NoDatabaseRecipes extends StatelessWidget {
  final VoidCallback onNext;

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

class _InstructionsStep extends StatelessWidget {
  const _InstructionsStep();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Spacer(),
          Image.asset('assets/images/empty_page.png', height: 150),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Instructions will be added later',
            style: context.text.titleMedium,
          ),
          const Spacer(),
          _PrimaryActionButton(
            label: 'Next',
            onPressed: context.read<GenerateAiMealViewModel>().goToNextStep,
          ),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final AddMealAiPlan plan;

  const _ReviewStep({required this.plan});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();
    final selectedRecipes = viewModel.selectedRecipes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        _DateScroller(selectedDate: plan.planningDate),
        const SizedBox(height: AppSpacing.md),
        _FactorCard(
          icon: Icons.wb_sunny_outlined,
          title: '${plan.weather.condition} - ${plan.weather.temperature}C',
          subtitle: plan.weather.summary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Meals planned on ${DateFormat('EEE, d MMM').format(plan.planningDate)}',
          style: context.text.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _PlannedMealRows(mealType: plan.mealType),
        const SizedBox(height: AppSpacing.md),
        Text('Choose Meal', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _MealTypeChips(selected: plan.mealType),
        const SizedBox(height: AppSpacing.md),
        Text('Recipe Details', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (selectedRecipes.isEmpty)
          const _EmptySelectedRecipe()
        else
          ...selectedRecipes.map((recipe) => _ReviewRecipeCard(recipe: recipe)),
        const SizedBox(height: AppSpacing.lg),
        _PrimaryActionButton(
          label: 'Add to Meal Plan',
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.bodySmall),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableFactorCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> selectedLabels;
  final List<Widget> children;

  const _ExpandableFactorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selectedLabels,
    required this.children,
  });

  @override
  State<_ExpandableFactorCard> createState() => _ExpandableFactorCardState();
}

class _ExpandableFactorCardState extends State<_ExpandableFactorCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final labels = widget.selectedLabels
        .where((label) => label.trim().isNotEmpty)
        .toSet()
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(widget.icon, color: AppColors.textSecondary, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: context.text.titleMedium),
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: context.text.bodySmall),
                        if (labels.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _ChipWrap(values: labels, selectedValues: labels),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down, size: 18),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

class _InlineTextInput extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const _InlineTextInput({required this.hintText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      minLines: 1,
      maxLines: 2,
      style: context.text.bodySmall?.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: context.text.bodySmall?.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.65),
        ),
        suffixIcon: TextButton(
          onPressed: () {},
          child: Text(
            '+ Add',
            style: context.text.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _OptionGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _OptionGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(title),
        const SizedBox(height: AppSpacing.xs),
        _ChipWrap(
          values: options,
          selectedValues: [selected],
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> values;
  final List<String> selectedValues;
  final ValueChanged<String>? onSelected;
  final bool danger;

  const _ChipWrap({
    required this.values,
    required this.selectedValues,
    this.onSelected,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSet = selectedValues.toSet();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: values.map((value) {
        final selected = selectedSet.contains(value);
        return InkWell(
          onTap: onSelected == null ? null : () => onSelected!(value),
          borderRadius: BorderRadius.circular(12),
          child: _SmallChip(label: value, selected: selected, danger: danger),
        );
      }).toList(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.text.bodySmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SelectedSummaryText extends StatelessWidget {
  final String text;

  const _SelectedSummaryText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.text.bodySmall?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FactorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FactorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: context.text.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }
}

class _RecipeResultCard extends StatelessWidget {
  final AddMealAiRecipe recipe;

  const _RecipeResultCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();
    final selected = viewModel.isRecipeSelected(recipe.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  recipe.imagePath,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title, style: context.text.titleMedium),
                    Text(
                      '${recipe.durationLabel}   ${recipe.difficultyLabel}',
                      style: context.text.bodySmall,
                    ),
                    Text(recipe.description, style: context.text.bodySmall),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context
                    .read<GenerateAiMealViewModel>()
                    .toggleRecipe(recipe.id),
                icon: Icon(
                  selected ? Icons.bookmark : Icons.bookmark_border,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFAF1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why we recommend this:',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ...recipe.reasons.map(
                  (reason) => Text(
                    '- $reason',
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Customize'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context
                      .read<GenerateAiMealViewModel>()
                      .toggleRecipe(recipe.id),
                  child: Text(selected ? 'Selected' : 'Add to Plan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewRecipeCard extends StatelessWidget {
  final AddMealAiRecipe recipe;

  const _ReviewRecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              recipe.imagePath,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.title, style: context.text.titleMedium),
                Text(
                  '${recipe.durationLabel} | ${recipe.difficultyLabel} | ${recipe.servingLabel}',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(recipe.description, style: context.text.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _DateScroller extends StatelessWidget {
  final DateTime selectedDate;

  const _DateScroller({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final start = selectedDate.subtract(const Duration(days: 2));
    final days = List.generate(7, (index) => start.add(Duration(days: index)));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text('Choose Date', style: context.text.titleMedium),
              const Spacer(),
              Text(
                DateFormat('MMM yyyy').format(selectedDate),
                style: context.text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((date) {
              final selected = DateUtils.isSameDay(date, selectedDate);
              return Column(
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: selected
                        ? AppColors.primary
                        : Colors.transparent,
                    child: Text(
                      '${date.day}',
                      style: context.text.bodySmall?.copyWith(
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PlannedMealRows extends StatelessWidget {
  final String mealType;

  const _PlannedMealRows({required this.mealType});

  @override
  Widget build(BuildContext context) {
    const meals = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
      child: Column(
        children: meals.map((meal) {
          final isSelected = meal.toLowerCase() == mealType.toLowerCase();
          return ListTile(
            dense: true,
            leading: Icon(
              isSelected ? Icons.wb_sunny_outlined : Icons.restaurant_outlined,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            title: Text(meal, style: context.text.bodyMedium),
            subtitle: Text(
              isSelected
                  ? 'Selected AI recipe will be added here'
                  : 'No meal planned yet',
              style: context.text.bodySmall,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MealTypeChips extends StatelessWidget {
  final String selected;

  const _MealTypeChips({required this.selected});

  @override
  Widget build(BuildContext context) {
    const meals = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    return Row(
      children: meals.map((meal) {
        final active = meal.toLowerCase() == selected.toLowerCase();
        return Expanded(
          child: Container(
            height: 56,
            margin: const EdgeInsets.only(right: AppSpacing.xs),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFEAF7EC) : Colors.white,
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                meal,
                style: context.text.bodySmall?.copyWith(
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool danger;

  const _SmallChip({
    required this.label,
    this.selected = true,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = danger ? AppColors.error : AppColors.primary;
    final inactiveColor = danger
        ? AppColors.error.withValues(alpha: 0.08)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF7EC) : inactiveColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? activeColor.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: context.text.bodySmall?.copyWith(
          color: selected ? activeColor : AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        child: Text(
          label,
          style: context.text.labelLarge?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _EmptySelectedRecipe extends StatelessWidget {
  const _EmptySelectedRecipe();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Image.asset('assets/images/empty_page.png', height: 110),
          const SizedBox(height: AppSpacing.sm),
          Text('No recipe selected yet', style: context.text.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', height: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
