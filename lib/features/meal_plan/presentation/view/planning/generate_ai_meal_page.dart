import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../app/routers/app_router.dart';
import '../../../../../app/routers/router_args.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/box/app_tip_box.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../../core/widgets/progress_bar/app_step_progress_bar.dart';
import '../../../domain/entities/add_meal_ai_plan.dart';
import '../../../domain/entities/meal_plan_inspiration_input.dart';
import '../../../domain/usecases/generate_ai_meal_ideas_usecase.dart';
import '../../../domain/usecases/get_add_meal_ai_plan_usecase.dart';
import '../../../domain/usecases/get_meal_plan_default_ingredients_usecase.dart';
import '../../../domain/usecases/get_meal_plan_inspiration_options_usecase.dart';
import '../../../domain/usecases/get_meal_categories_usecase.dart';
import '../../../domain/usecases/save_ai_meal_plan_usecase.dart';
import '../../../domain/usecases/search_meal_plan_ingredients_usecase.dart';
import '../../viewmodel/generate_ai_meal_viewmodel.dart';

class GenerateAiMealPage extends StatelessWidget {
  final String userId;
  final String mealType;
  final String? mealCategoryId;
  final DateTime? selectedDate;
  final AddMealAiGenerationRequest? initialRequest;
  final bool autoGenerate;

  const GenerateAiMealPage({
    super.key,
    required this.userId,
    required this.mealType,
    this.mealCategoryId,
    this.selectedDate,
    this.initialRequest,
    this.autoGenerate = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GenerateAiMealViewModel(
        userId: userId,
        mealType: mealType,
        mealCategoryId: mealCategoryId,
        selectedDate: selectedDate,
        initialRequest: initialRequest,
        autoGenerate: autoGenerate,
        getPlanUseCase: sl<GetAddMealAiPlanUseCase>(),
        generateIdeasUseCase: sl<GenerateAiMealIdeasUseCase>(),
        getMealCategoriesUseCase: sl<GetMealCategoriesUseCase>(),
        saveAiMealPlanUseCase: sl<SaveAiMealPlanUseCase>(),
        getDefaultIngredientsUseCase:
            sl<GetMealPlanDefaultIngredientsUseCase>(),
        getInspirationOptionsUseCase:
            sl<GetMealPlanInspirationOptionsUseCase>(),
        searchIngredientsUseCase: sl<SearchMealPlanIngredientsUseCase>(),
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
        title: !viewModel.showDatabaseResults
            ? 'Inspiration'
            : viewModel.currentStep == 4
            ? 'Add to Meal Plan'
            : 'Generate with AI',
        leading: IconButton(
          onPressed: () {
            if (!viewModel.showDatabaseResults) {
              context.pop();
            } else if (viewModel.currentStep > 1) {
              context.read<GenerateAiMealViewModel>().goToPreviousStep();
            } else {
              context.pop();
            }
          },
          icon: const Icon(Icons.chevron_left),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                if (viewModel.showDatabaseResults)
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
                      labels: const [
                        'Factor',
                        'AI Result',
                        'Instructions',
                        'Review',
                      ],
                    ),
                  ),
                Expanded(child: _StepBody(plan: plan)),
              ],
            ),
          ),
          if (viewModel.isGenerating) ...[
            const Positioned.fill(child: ColoredBox(color: Colors.white)),
            const Positioned.fill(
              child: LoadingDialog(
                message: 'Generating AI recipes and images...',
              ),
            ),
          ],
        ],
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
        const _WeatherFactorCard(),
        const _IngredientFactorCard(
          type: _IngredientFactorType.include,
          icon: Icons.shopping_cart_outlined,
          title: 'Ingredients to Include',
          subtitle: 'Search USDA foods or add ingredients AI should include.',
        ),
        _MealPreferenceFactorCard(plan: plan),
        const _IngredientFactorCard(
          type: _IngredientFactorType.avoid,
          icon: Icons.block,
          title: 'Ingredients to Avoid',
          subtitle: 'Dislikes from settings are selected by default.',
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

class _WeatherFactorCard extends StatelessWidget {
  const _WeatherFactorCard();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();
    final weather = viewModel.selectedWeatherSnapshot;

    return _ExpandableFactorCard(
      icon: Icons.wb_cloudy_outlined,
      title: 'Weather',
      subtitle: '${weather.condition} - ${weather.temperature}C',
      selectedLabels: [weather.summary],
      children: [
        DropdownButtonFormField<String>(
          initialValue: viewModel.selectedWeatherCategoryId,
          isExpanded: true,
          style: context.text.bodyMedium,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          items: [
            for (final category in viewModel.weatherCategories)
              DropdownMenuItem(value: category.id, child: Text(category.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              context.read<GenerateAiMealViewModel>().selectWeatherCategory(
                value,
              );
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _SelectedSummaryText(weather.summary),
      ],
    );
  }
}

enum _IngredientFactorType { include, avoid }

class _IngredientFactorCard extends StatelessWidget {
  final _IngredientFactorType type;
  final IconData icon;
  final String title;
  final String subtitle;

  const _IngredientFactorCard({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();
    final selected = type == _IngredientFactorType.include
        ? viewModel.selectedIngredientsToInclude
        : viewModel.selectedIngredientsToAvoid;

    return _ExpandableFactorCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      selectedLabels: selected,
      children: [
        _IngredientPreviewPanel(
          type: type,
          selected: selected,
          defaultValues: type == _IngredientFactorType.include
              ? viewModel.defaultIngredientsToInclude
              : viewModel.defaultIngredientsToAvoid,
          onRemove: type == _IngredientFactorType.include
              ? context
                    .read<GenerateAiMealViewModel>()
                    .toggleIngredientToInclude
              : context.read<GenerateAiMealViewModel>().toggleIngredientToAvoid,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: _AddFactorAction(
            label: selected.isEmpty ? 'Add ingredient' : 'Edit ingredients',
            onTap: () => _showIngredientSheet(context, type),
          ),
        ),
      ],
    );
  }

  void _showIngredientSheet(BuildContext context, _IngredientFactorType type) {
    final viewModel = context.read<GenerateAiMealViewModel>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: _IngredientPickerSheet(type: type),
      ),
    );
  }
}

class _AddFactorAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddFactorAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: context.text.labelLarge?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientPreviewPanel extends StatelessWidget {
  final _IngredientFactorType type;
  final List<String> selected;
  final List<String> defaultValues;
  final ValueChanged<String> onRemove;

  const _IngredientPreviewPanel({
    required this.type,
    required this.selected,
    required this.defaultValues,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isAvoid = type == _IngredientFactorType.avoid;
    final selectedSet = selected.map((item) => item.toLowerCase()).toSet();
    final inactiveDefaults = defaultValues
        .where((item) => !selectedSet.contains(item.toLowerCase()))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAvoid
                    ? Icons.shield_outlined
                    : Icons.shopping_basket_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  isAvoid
                      ? 'Selected for AI to avoid'
                      : 'Selected for AI to include',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CountBadge(count: selected.length),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (selected.isEmpty)
            Text(
              isAvoid
                  ? 'No allergies or dislikes selected for this request.'
                  : 'No ingredients selected for this request.',
              style: context.text.bodySmall,
            )
          else
            _RemovableChipWrap(
              values: selected,
              danger: isAvoid,
              onRemove: onRemove,
            ),
          if (inactiveDefaults.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Deselected defaults: ${inactiveDefaults.take(3).join(', ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: context.text.bodySmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RemovableChipWrap extends StatelessWidget {
  final List<String> values;
  final bool danger;
  final ValueChanged<String> onRemove;

  const _RemovableChipWrap({
    required this.values,
    required this.danger,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final value in values)
          InputChip(
            label: Text(value),
            onDeleted: () => onRemove(value),
            deleteIcon: const Icon(Icons.close, size: 16),
            visualDensity: VisualDensity.compact,
            backgroundColor: danger
                ? AppColors.error.withValues(alpha: 0.08)
                : AppColors.primary.withValues(alpha: 0.1),
            side: BorderSide(
              color: danger
                  ? AppColors.error.withValues(alpha: 0.25)
                  : AppColors.primary.withValues(alpha: 0.25),
            ),
            labelStyle: context.text.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _IngredientPickerSheet extends StatefulWidget {
  final _IngredientFactorType type;

  const _IngredientPickerSheet({required this.type});

  @override
  State<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<_IngredientPickerSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isAvoid = widget.type == _IngredientFactorType.avoid;
    final selected = isAvoid
        ? viewModel.selectedIngredientsToAvoid
        : viewModel.selectedIngredientsToInclude;
    final toggle = isAvoid
        ? viewModel.toggleIngredientToAvoid
        : viewModel.toggleIngredientToInclude;
    final addCustom = isAvoid
        ? viewModel.addIngredientToAvoid
        : viewModel.addIngredientToInclude;
    final query = _controller.text.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isAvoid ? 'Ingredients to avoid' : 'Ingredients to include',
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAvoid
                  ? 'Saved allergies and dislikes are selected for this request only.'
                  : 'Suggested ingredients are selected by default and can be adjusted.',
              style: context.text.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search USDA foods or add custom ingredient',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    addCustom(_controller.text);
                    _controller.clear();
                    viewModel.searchFoods('');
                  },
                  icon: const Icon(Icons.add),
                ),
              ),
              onChanged: viewModel.searchFoods,
              onSubmitted: addCustom,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                children: [
                  _IngredientSheetSection(
                    title: 'Selected',
                    icon: Icons.check_circle_outline,
                    child: selected.isEmpty
                        ? Text(
                            'No ingredients selected yet.',
                            style: context.text.bodyMedium,
                          )
                        : _ChipWrap(
                            values: selected,
                            selectedValues: selected,
                            danger: isAvoid,
                            onSelected: toggle,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isAvoid) ...[
                    _IngredientSheetSection(
                      title: 'From Settings',
                      icon: Icons.person_outline,
                      child: viewModel.savedIngredientsToAvoid.isEmpty
                          ? Text(
                              'No allergies or dislikes saved in settings.',
                              style: context.text.bodyMedium,
                            )
                          : _ChipWrap(
                              values: viewModel.savedIngredientsToAvoid,
                              selectedValues: selected,
                              danger: true,
                              onSelected: toggle,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _IngredientSheetSection(
                      title: 'Allergen defaults',
                      icon: Icons.warning_amber_outlined,
                      child: _ConfigOptionChips(
                        isLoading: viewModel.isFactorOptionsLoading,
                        emptyMessage: 'No allergens available yet.',
                        options: viewModel.allergyOptions,
                        selectedValues: selected,
                        danger: true,
                        onSelected: toggle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _IngredientSheetSection(
                      title: 'Dislike defaults',
                      icon: Icons.block,
                      child: _ConfigOptionChips(
                        isLoading: viewModel.isFactorOptionsLoading,
                        emptyMessage: 'No dislikes available yet.',
                        options: viewModel.dislikeOptions,
                        selectedValues: selected,
                        danger: true,
                        onSelected: toggle,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _IngredientSheetSection(
                    title: 'USDA search results',
                    icon: Icons.search,
                    child: viewModel.isFoodSearching
                        ? const LoadingDialog(
                            inline: true,
                            message: 'Searching foods...',
                          )
                        : query.length < 2
                        ? Text(
                            'Type at least 2 characters to search.',
                            style: context.text.bodyMedium,
                          )
                        : viewModel.foodSearchResults.isEmpty
                        ? Text(
                            'No results found.',
                            style: context.text.bodyMedium,
                          )
                        : _IngredientSearchResultChips(
                            ingredients: viewModel.foodSearchResults,
                            selectedValues: selected,
                            danger: isAvoid,
                            onSelected: (item) => toggle(item.name),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientSearchResultChips extends StatelessWidget {
  final List<MealPlanInspirationIngredient> ingredients;
  final List<String> selectedValues;
  final bool danger;
  final ValueChanged<MealPlanInspirationIngredient> onSelected;

  const _IngredientSearchResultChips({
    required this.ingredients,
    required this.selectedValues,
    required this.danger,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSet = selectedValues
        .map((item) => item.toLowerCase())
        .toSet();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final ingredient in ingredients)
          InkWell(
            onTap: () => onSelected(ingredient),
            borderRadius: BorderRadius.circular(12),
            child: _SmallChip(
              label: ingredient.name,
              selected: selectedSet.contains(ingredient.name.toLowerCase()),
              danger: danger,
            ),
          ),
      ],
    );
  }
}

class _IngredientSheetSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _IngredientSheetSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: const Color(0xFF8A6400)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _ConfigOptionChips extends StatelessWidget {
  final bool isLoading;
  final String emptyMessage;
  final List<MealPlanPreferenceOption> options;
  final List<String> selectedValues;
  final bool danger;
  final ValueChanged<String> onSelected;

  const _ConfigOptionChips({
    required this.isLoading,
    required this.emptyMessage,
    required this.options,
    required this.selectedValues,
    required this.danger,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingDialog(inline: true, message: 'Loading defaults...');
    }
    if (options.isEmpty) {
      return Text(emptyMessage, style: context.text.bodyMedium);
    }

    return _ChipWrap(
      values: options.map((item) => item.name).toList(),
      selectedValues: selectedValues,
      danger: danger,
      onSelected: onSelected,
    );
  }
}

class _MealPreferenceFactorCard extends StatelessWidget {
  final AddMealAiPlan plan;

  const _MealPreferenceFactorCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();
    final options = {
      ...viewModel.mealPreferenceOptions.map((item) => item.name),
      ...viewModel.selectedMealPreferences,
    }.toList();

    return _ExpandableFactorCard(
      icon: Icons.favorite,
      title: 'Meal Preferences',
      subtitle: 'Values from Settings can be adjusted for this request.',
      selectedLabels: viewModel.selectedMealPreferences.isEmpty
          ? const ['No Preference']
          : viewModel.selectedMealPreferences,
      children: [
        if (viewModel.isFactorOptionsLoading)
          const LoadingDialog(inline: true, message: 'Loading preferences...')
        else if (options.isEmpty)
          Text('No meal preferences available.', style: context.text.bodySmall)
        else
          _ChipWrap(
            values: options,
            selectedValues: viewModel.selectedMealPreferences,
            onSelected: context
                .read<GenerateAiMealViewModel>()
                .toggleMealPreference,
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
        _WordLimitedTextInput(
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
        _WordLimitedTextInput(
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
      'Cooking: ${viewModel.selectedCookingTime} mins',
      'Difficulty: ${viewModel.selectedDifficulty}',
      'Serving: ${viewModel.selectedServingSize}',
    ];

    return _ExpandableFactorCard(
      icon: Icons.soup_kitchen_outlined,
      title: 'Cooking Preferences',
      subtitle: 'Cooking time, difficulty and serving size.',
      selectedLabels: selectedLabels,
      children: [
        _CookingMinutesInput(
          minutes: viewModel.selectedCookingTime,
          onChanged: context.read<GenerateAiMealViewModel>().updateCookingTime,
        ),
        const SizedBox(height: AppSpacing.md),
        _DifficultyLevelPicker(
          selectedLevel: viewModel.selectedDifficultyLevel,
          onSelected: context.read<GenerateAiMealViewModel>().selectDifficulty,
        ),
        const SizedBox(height: AppSpacing.md),
        _ServingSizeInput(
          servings: viewModel.selectedServingCount,
          onChanged: context.read<GenerateAiMealViewModel>().selectServingSize,
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
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final showDatabase = context
        .read<GenerateAiMealViewModel>()
        .showDatabaseResults;
    final expectedLength = showDatabase ? 2 : 1;
    if (_tabController?.length == expectedLength) return;
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
    final viewModel = context.watch<GenerateAiMealViewModel>();
    final plan = widget.plan;
    final showDatabase = viewModel.showDatabaseResults;
    final tabController = _tabController;

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
                    'Review AI-created ideas before customising or adding them to your meal plan.',
                backgroundColor: Color(0xFFFFF8E1),
                iconColor: AppColors.secondary,
                icon: Icons.tips_and_updates_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
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
          'Relevant recipes are found in your recipe database.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...recipes.map((recipe) => _RecipeResultCard(recipe: recipe)),
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

class _AiCreatedRecipeResults extends StatelessWidget {
  final List<AddMealAiRecipe> recipes;

  const _AiCreatedRecipeResults({required this.recipes});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();
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
              OutlinedButton(
                onPressed: viewModel.generateIdeas,
                child: const Text('Generate More'),
              ),
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
        _DateScroller(
          selectedDate: viewModel.selectedDate,
          onSelected: viewModel.selectDate,
        ),
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
        _PlannedMealRows(
          mealType: viewModel.selectedMealCategory?.name ?? plan.mealType,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Choose Meal', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _MealTypeChips(
          selected: viewModel.selectedMealCategory?.name ?? plan.mealType,
          categories: viewModel.mealCategories,
          onSelected: viewModel.selectMealCategory,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Recipe Details', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (selectedRecipes.isEmpty)
          const _EmptySelectedRecipe()
        else
          ...selectedRecipes.map((recipe) => _ReviewRecipeCard(recipe: recipe)),
        const SizedBox(height: AppSpacing.lg),
        _PrimaryActionButton(
          label: viewModel.isSaving ? 'Adding...' : 'Add to Meal Plan',
          onPressed: viewModel.isSaving
              ? () {}
              : () async {
                  final success = await context
                      .read<GenerateAiMealViewModel>()
                      .saveSelectedRecipesToPlan();
                  if (!context.mounted) return;
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context
                                  .read<GenerateAiMealViewModel>()
                                  .errorMessage ??
                              'Unable to add meal plan.',
                        ),
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meal plan added.')),
                  );
                  context.go(
                    AppRouter.mealPlan,
                    extra: MealPlanArgs(
                      initialTabIndex: 0,
                      userId: viewModel.userId,
                    ),
                  );
                },
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: selectedRecipes.isEmpty
              ? null
              : () {
                  context.push(
                    AppRouter.addRecipeBasicInfo,
                    extra: AddRecipeBasicInfoArgs(
                      aiRecipe: selectedRecipes.first,
                      aiRequest: viewModel.generationRequest,
                      userId: viewModel.userId,
                    ),
                  );
                },
          child: const Text('Add to Recipe'),
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

class _WordLimitedTextInput extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const _WordLimitedTextInput({
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<_WordLimitedTextInput> createState() => _WordLimitedTextInputState();
}

class _WordLimitedTextInputState extends State<_WordLimitedTextInput> {
  static const _maxWords = 30;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = _wordCount(_controller.text);

    return TextField(
      controller: _controller,
      onChanged: (value) {
        final limited = _limitWords(value);
        if (limited != value) {
          _controller.value = TextEditingValue(
            text: limited,
            selection: TextSelection.collapsed(offset: limited.length),
          );
        }
        widget.onChanged(limited);
        setState(() {});
      },
      minLines: 1,
      maxLines: 3,
      style: context.text.bodySmall?.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hintText,
        helperText: '$count/$_maxWords words',
        hintStyle: context.text.bodySmall?.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.65),
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

  int _wordCount(String value) {
    return value.trim().isEmpty ? 0 : value.trim().split(RegExp(r'\s+')).length;
  }

  String _limitWords(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (value.trim().isEmpty || words.length <= _maxWords) return value;
    return words.take(_maxWords).join(' ');
  }
}

class _DifficultyLevelPicker extends StatelessWidget {
  final int selectedLevel;
  final ValueChanged<int> onSelected;

  const _DifficultyLevelPicker({
    required this.selectedLevel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const levels = ['Novice', 'Beginner', 'Intermediate', 'Advanced', 'Master'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Difficulty Level'),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: levels.asMap().entries.map((entry) {
              final levelValue = entry.key + 1;
              final selected = levelValue <= selectedLevel;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(levelValue),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        size: 24,
                        color: selected
                            ? AppColors.secondary
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          entry.value,
                          maxLines: 1,
                          style: context.text.bodySmall?.copyWith(
                            fontSize: 9,
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CookingMinutesInput extends StatelessWidget {
  final int minutes;
  final ValueChanged<String> onChanged;

  const _CookingMinutesInput({required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Cooking Time'),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          initialValue: minutes.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: context.text.bodySmall?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 30',
            suffixText: 'minutes',
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
        ),
      ],
    );
  }
}

class _ServingSizeInput extends StatelessWidget {
  final int servings;
  final ValueChanged<String> onChanged;

  const _ServingSizeInput({required this.servings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Servings'),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          initialValue: servings.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: context.text.bodySmall?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 1',
            suffixText: 'servings',
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
    final borderColor = selected ? AppColors.primary : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFFAF1) : Colors.white,
        border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _RecipeThumb(recipe: recipe, size: 68),
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
              if (selected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
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
                child: SecondaryButton(
                  onPressed: () {
                    context.read<GenerateAiMealViewModel>().toggleRecipe(
                      recipe.id,
                    );
                  },
                  text: selected ? 'Selected' : 'Select',
                  verticalPadding: 12,
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
            child: _RecipeThumb(recipe: recipe, size: 70),
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
  final ValueChanged<DateTime> onSelected;

  const _DateScroller({required this.selectedDate, required this.onSelected});

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
                  InkWell(
                    onTap: () => onSelected(date),
                    customBorder: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: selected
                          ? AppColors.primary
                          : Colors.transparent,
                      child: Text(
                        '${date.day}',
                        style: context.text.bodySmall?.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
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

class _RecipeThumb extends StatelessWidget {
  final AddMealAiRecipe recipe;
  final double size;

  const _RecipeThumb({required this.recipe, required this.size});

  @override
  Widget build(BuildContext context) {
    final imageBase64 = recipe.imageBase64;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      return Image.memory(
        base64Decode(imageBase64),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _assetImage(),
      );
    }
    return _assetImage();
  }

  Widget _assetImage() {
    return Image.asset(
      recipe.imagePath,
      width: size,
      height: size,
      fit: BoxFit.cover,
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
  final List<AddMealCategoryOption> categories;
  final ValueChanged<AddMealCategoryOption> onSelected;

  const _MealTypeChips({
    required this.selected,
    required this.categories,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final meals = categories.isEmpty
        ? const [
            AddMealCategoryOption(id: 'breakfast', name: 'Breakfast'),
            AddMealCategoryOption(id: 'lunch', name: 'Lunch'),
            AddMealCategoryOption(id: 'dinner', name: 'Dinner'),
            AddMealCategoryOption(id: 'snack', name: 'Snack'),
          ]
        : categories;
    return Row(
      children: meals.map((meal) {
        final active = meal.name.toLowerCase() == selected.toLowerCase();
        return Expanded(
          child: InkWell(
            onTap: () => onSelected(meal),
            borderRadius: BorderRadius.circular(8),
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
                  meal.name,
                  style: context.text.bodySmall?.copyWith(
                    color: active ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
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
    final selectedFill = danger
        ? AppColors.error.withValues(alpha: 0.08)
        : const Color(0xFFEAF7EC);
    final inactiveColor = danger
        ? AppColors.error.withValues(alpha: 0.035)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: selected ? selectedFill : inactiveColor,
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
