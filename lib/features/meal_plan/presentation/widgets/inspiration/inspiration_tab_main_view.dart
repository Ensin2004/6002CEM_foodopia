import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../app/routers/router_args.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../domain/entities/meal_plan_inspiration_input.dart';
import '../../../domain/entities/meal_plan_dashboard.dart';
import '../../../domain/entities/add_meal_ai_plan.dart';
import '../../viewmodel/meal_plan_viewmodel.dart';

const _quickInspirationItems = [
  MealPlanQuickInspiration(
    title: 'What can I cook with what I have?',
    subtitle: 'Use ingredients you already have.',
    imagePath: 'assets/images/inspiration_what_can_i_cook_with_what_i_have.png',
  ),
  MealPlanQuickInspiration(
    title: 'Surprise me!',
    subtitle: 'Get AI-picked recipes for you.',
    imagePath: 'assets/images/inspiration_surprise_me.png',
  ),
  MealPlanQuickInspiration(
    title: 'Healthy Ideas',
    subtitle: 'Nutritious and balanced meals.',
    imagePath: 'assets/images/inspiration_healthy_ideas.png',
  ),
  MealPlanQuickInspiration(
    title: 'Quick & Easy',
    subtitle: 'Recipes you can make in no time.',
    imagePath: 'assets/images/inspiration_quick_and_easy.png',
  ),
  MealPlanQuickInspiration(
    title: 'Rainy Day Comfort',
    subtitle: 'Warm bowls and cozy meal ideas.',
    imagePath: 'assets/images/inspiration_rainy_day_comfort.png',
  ),
  MealPlanQuickInspiration(
    title: 'High Protein Picks',
    subtitle: 'Filling meals with simple prep.',
    imagePath: 'assets/images/inspiration_high_protein_picks.png',
  ),
];

class InspirationTabMainView extends StatelessWidget {
  final MealPlanDashboard dashboard;

  const InspirationTabMainView({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MealPlanViewModel>();
    final preferences = viewModel.effectivePreferences;
    final weather = dashboard.weather;

    return ExcludeSemantics(
      child: ListView(
        key: const PageStorageKey<String>('meal_plan_inspiration_tab'),
        addSemanticIndexes: false,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          _SmartInspirationBox(
            weather: weather,
            preferences: preferences,
            ingredientsLabel: viewModel.selectedIngredientsLabel,
            isWeatherLoading: viewModel.isWeatherLoading,
            isPreferencesLoading: viewModel.isPreferencesLoading,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Build your inspiration request',
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Tune the weather, ingredients and preferences before generating ideas.',
            style: context.text.bodyMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: AppSpacing.md),
          _WeatherInputCard(
            weather: weather,
            isLoading: viewModel.isWeatherLoading,
            errorMessage: viewModel.weatherErrorMessage,
            selectedCategoryId: viewModel.selectedWeatherCategoryId,
            onChanged: viewModel.selectWeatherCategory,
          ),
          const SizedBox(height: AppSpacing.md),
          _IngredientInputCard(viewModel: viewModel),
          const SizedBox(height: AppSpacing.md),
          _PreferenceInputCard(
            preferences: preferences,
            onExpand: () => _showPreferenceEditor(context, viewModel),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final weatherSnapshot = weather;
                final request = AddMealAiGenerationRequest(
                  planningDate: dashboard.selectedDate,
                  mealType: 'Breakfast',
                  weather: AddMealWeather(
                    temperature: weatherSnapshot?.currentTemp ?? 28,
                    condition:
                        weatherSnapshot?.condition ??
                        viewModel.selectedWeatherCategory.label,
                    summary:
                        weatherSnapshot?.summary ??
                        'Use the selected weather category.',
                  ),
                  preferences: AddMealPreferenceSnapshot(
                    diet: preferences.diet,
                    allergies: preferences.allergies,
                    dislikes: preferences.dislikes,
                  ),
                  ingredientsToInclude: viewModel.selectedIngredients
                      .map((item) => item.name)
                      .toList(),
                  ingredientsToAvoid: preferences.dislikes,
                  dishIncludes: const [],
                  dishAvoids: const [],
                  cookingTime: 30,
                  difficultyLevel: 1,
                  difficulty: 'Any',
                  servingCount: 1,
                  servingSize: '1 serving',
                );
                context.push(
                  AppRouter.generateAiMeal,
                  extra: GenerateAiMealArgs(
                    userId: viewModel.userId,
                    mealType: request.mealType,
                    initialRequest: request,
                    autoGenerate: true,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Get AI Recipe Ideas',
                style: context.text.labelLarge?.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Quick Inspiration',
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _QuickInspirationGrid(items: _quickInspirationItems),
        ],
      ),
    );
  }

  void _showPreferenceEditor(
    BuildContext context,
    MealPlanViewModel viewModel,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const _PreferenceEditorSheet(),
      ),
    );
  }
}

class _SmartInspirationBox extends StatelessWidget {
  final MealPlanWeather? weather;
  final MealPlanPreferenceSummary? preferences;
  final String ingredientsLabel;
  final bool isWeatherLoading;
  final bool isPreferencesLoading;

  const _SmartInspirationBox({
    required this.weather,
    required this.preferences,
    required this.ingredientsLabel,
    required this.isWeatherLoading,
    required this.isPreferencesLoading,
  });

  @override
  Widget build(BuildContext context) {
    final currentWeather = weather;
    final preferenceLabel = isPreferencesLoading
        ? 'Loading...'
        : preferences?.shortLabel ?? 'Not set';
    final weatherLabel = isWeatherLoading
        ? 'Loading...'
        : currentWeather == null
        ? 'Unavailable'
        : '${currentWeather.condition} - ${currentWeather.currentTemp}C';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 56,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tips_and_updates_outlined,
                  color: Color(0xFF8A6400),
                  size: 23,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart AI Inspiration',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get recipe ideas based on what you have, today\'s weather and your preferences.',
                      style: context.text.bodySmall?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
              _SmartChip(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              _SmartMetric(
                icon: Icons.shopping_basket_outlined,
                title: 'Ingredients',
                value: ingredientsLabel,
              ),
              const SizedBox(height: AppSpacing.xs),
              _SmartMetric(
                icon: Icons.wb_sunny_outlined,
                title: 'Weather',
                value: weatherLabel,
              ),
              const SizedBox(height: AppSpacing.xs),
              _SmartMetric(
                icon: Icons.favorite_border,
                title: 'Preferences',
                value: preferenceLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmartChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF8A6400), size: 14),
          const SizedBox(width: 4),
          Text(
            'Smart',
            style: context.text.bodySmall?.copyWith(
              color: const Color(0xFF8A6400),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SmartMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherInputCard extends StatelessWidget {
  final MealPlanWeather? weather;
  final bool isLoading;
  final String? errorMessage;
  final String selectedCategoryId;
  final ValueChanged<String> onChanged;

  const _WeatherInputCard({
    required this.weather,
    required this.isLoading,
    this.errorMessage,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentWeather = weather;
    final title = isLoading
        ? 'Loading weather'
        : currentWeather == null
        ? 'Weather unavailable'
        : '${currentWeather.condition} - ${currentWeather.currentTemp}C';
    final message =
        currentWeather?.summary ??
        errorMessage ??
        'Weather data will appear here.';

    return _InputCard(
      icon: Icons.wb_sunny_outlined,
      title: 'Weather',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedCategoryId,
            isExpanded: true,
            style: context.text.bodyMedium,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'sunny', child: Text('Sunny')),
              DropdownMenuItem(value: 'rainy', child: Text('Rainy')),
              DropdownMenuItem(value: 'windy', child: Text('Windy')),
              DropdownMenuItem(value: 'cloudy', child: Text('Cloudy')),
              DropdownMenuItem(value: 'hot', child: Text('Hot')),
              DropdownMenuItem(value: 'cool', child: Text('Cool')),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: context.text.bodyMedium),
          const SizedBox(height: 4),
          Text(
            message,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientInputCard extends StatelessWidget {
  final MealPlanViewModel viewModel;

  const _IngredientInputCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.selectedIngredients;

    return _InputCard(
      icon: Icons.shopping_cart_outlined,
      title: 'Add ingredients you have',
      onTap: () => _showIngredientSheet(context, viewModel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selected.isEmpty)
            Text(
              'Search foods or add a custom ingredient.',
              style: context.text.bodyMedium?.copyWith(height: 1.35),
            )
          else
            _IngredientChips(
              ingredients: selected,
              isSelected: (_) => true,
              onTap: viewModel.toggleIngredient,
            ),
          const SizedBox(height: AppSpacing.sm),
          _AddIngredientAction(
            label: selected.isEmpty ? 'Add ingredient' : 'Add another',
          ),
        ],
      ),
    );
  }

  void _showIngredientSheet(BuildContext context, MealPlanViewModel viewModel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const _IngredientPickerSheet(),
      ),
    );
  }
}

class _AddIngredientAction extends StatelessWidget {
  final String label;

  const _AddIngredientAction({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: context.text.labelLarge?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _PreferenceInputCard extends StatelessWidget {
  final MealPlanPreferenceSummary? preferences;
  final VoidCallback onExpand;

  const _PreferenceInputCard({
    required this.preferences,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final mealPreference = preferences?.diet ?? 'Any';
    final allergy = preferences?.allergies.isNotEmpty == true
        ? preferences!.allergies.first
        : 'Any';
    final dislike = preferences?.dislikes.isNotEmpty == true
        ? preferences!.dislikes.first
        : 'Any';

    return _InputCard(
      icon: Icons.room_service_outlined,
      title: 'Set your preferences',
      trailing: Icons.chevron_right,
      onTap: onExpand,
      child: Row(
        children: [
          Expanded(
            child: _PreferenceMetric(
              icon: Icons.restaurant_menu,
              title: 'Meal Pref.',
              value: mealPreference,
            ),
          ),
          Expanded(
            child: _PreferenceMetric(
              icon: Icons.warning_amber_outlined,
              title: 'Allergies',
              value: allergy,
            ),
          ),
          Expanded(
            child: _PreferenceMetric(
              icon: Icons.block,
              title: 'Dislikes',
              value: dislike,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _PreferenceMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final IconData? trailing;
  final VoidCallback? onTap;

  const _InputCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 21, color: const Color(0xFF8A6400)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (trailing != null)
                        Icon(
                          trailing,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientChips extends StatelessWidget {
  final List<MealPlanInspirationIngredient> ingredients;
  final bool Function(MealPlanInspirationIngredient ingredient) isSelected;
  final ValueChanged<MealPlanInspirationIngredient> onTap;

  const _IngredientChips({
    required this.ingredients,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final ingredient in ingredients)
          _MiniChoiceChip(
            label: ingredient.name,
            selected: isSelected(ingredient),
            onTap: () => onTap(ingredient),
          ),
      ],
    );
  }
}

class _MiniChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MiniChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF6F7F6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall?.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _IngredientPickerSheet extends StatefulWidget {
  const _IngredientPickerSheet();

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
    final viewModel = context.watch<MealPlanViewModel>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
            Text('Ingredients you have', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search or add custom ingredient',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: const Icon(Icons.search),
              ),
              onChanged: viewModel.searchIngredients,
              onSubmitted: viewModel.addCustomIngredient,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () {
                  viewModel.addCustomIngredient(_controller.text);
                  _controller.clear();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add typed ingredient'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                children: [
                  Text('Selected', style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (viewModel.selectedIngredients.isEmpty)
                    Text(
                      'No ingredients added yet.',
                      style: context.text.bodyMedium,
                    )
                  else
                    _IngredientChips(
                      ingredients: viewModel.selectedIngredients,
                      isSelected: (_) => true,
                      onTap: viewModel.toggleIngredient,
                    ),
                  Text('Search results', style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (viewModel.isIngredientSearching)
                    const LoadingDialog(
                      inline: true,
                      message: 'Searching ingredients...',
                    )
                  else if (_controller.text.trim().length < 2)
                    Text(
                      'Type at least 2 characters to search.',
                      style: context.text.bodyMedium,
                    )
                  else if (viewModel.ingredientSearchResults.isEmpty)
                    Center(
                      child: Image.asset(
                        'assets/images/empty_page.png',
                        height: 110,
                      ),
                    )
                  else
                    _IngredientChips(
                      ingredients: viewModel.ingredientSearchResults,
                      isSelected: (item) =>
                          viewModel.isIngredientSelected(item.name),
                      onTap: viewModel.toggleIngredient,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceEditorSheet extends StatefulWidget {
  const _PreferenceEditorSheet();

  @override
  State<_PreferenceEditorSheet> createState() => _PreferenceEditorSheetState();
}

class _PreferenceEditorSheetState extends State<_PreferenceEditorSheet> {
  final _allergyController = TextEditingController();
  final _dislikeController = TextEditingController();

  @override
  void dispose() {
    _allergyController.dispose();
    _dislikeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MealPlanViewModel>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
        child: ListView(
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
              'Set your preferences',
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Meal preference uses saved defaults. Allergies and dislikes can also come from search or custom input.',
              style: context.text.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PreferenceOptionSection(
              title: 'Meal preference',
              options: viewModel.dietOptions,
              selectedValues: {viewModel.overrideDiet},
              onSelected: viewModel.selectOverrideDiet,
            ),
            const SizedBox(height: AppSpacing.lg),
            _PreferenceSearchOptionSection(
              title: 'Allergies',
              options: viewModel.allergyOptions,
              selectedValues: viewModel.overrideAllergies.toSet(),
              onSelected: viewModel.toggleOverrideAllergy,
              controller: _allergyController,
              onSearch: viewModel.searchPreferenceFoods,
              onAddCustom: viewModel.addCustomOverrideAllergy,
              isSearching: viewModel.isPreferenceSearching,
              searchResults: viewModel.preferenceSearchResults,
            ),
            const SizedBox(height: AppSpacing.lg),
            _PreferenceSearchOptionSection(
              title: 'Dislikes',
              options: viewModel.dislikeOptions,
              selectedValues: viewModel.overrideDislikes.toSet(),
              onSelected: viewModel.toggleOverrideDislike,
              controller: _dislikeController,
              onSearch: viewModel.searchPreferenceFoods,
              onAddCustom: viewModel.addCustomOverrideDislike,
              isSearching: viewModel.isPreferenceSearching,
              searchResults: viewModel.preferenceSearchResults,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 48,
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
                child: Text(
                  'Done',
                  style: context.text.labelLarge?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceOptionSection extends StatelessWidget {
  final String title;
  final List<MealPlanPreferenceOption> options;
  final Set<String> selectedValues;
  final ValueChanged<String> onSelected;

  const _PreferenceOptionSection({
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (options.isEmpty)
          Text('No options available yet.', style: context.text.bodyMedium)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                _MiniChoiceChip(
                  label: option.name,
                  selected: selectedValues.contains(option.name),
                  onTap: () => onSelected(option.name),
                ),
            ],
          ),
      ],
    );
  }
}

class _PreferenceSearchOptionSection extends StatelessWidget {
  final String title;
  final List<MealPlanPreferenceOption> options;
  final Set<String> selectedValues;
  final ValueChanged<String> onSelected;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onAddCustom;
  final bool isSearching;
  final List<MealPlanInspirationIngredient> searchResults;

  const _PreferenceSearchOptionSection({
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onSelected,
    required this.controller,
    required this.onSearch,
    required this.onAddCustom,
    required this.isSearching,
    required this.searchResults,
  });

  @override
  Widget build(BuildContext context) {
    final query = controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreferenceOptionSection(
          title: title,
          options: options,
          selectedValues: selectedValues,
          onSelected: onSelected,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search or add custom ${title.toLowerCase()}',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              onPressed: () {
                onAddCustom(controller.text);
                controller.clear();
              },
              icon: const Icon(Icons.add),
            ),
          ),
          onChanged: onSearch,
          onSubmitted: onAddCustom,
        ),
        if (query.length >= 2) ...[
          const SizedBox(height: AppSpacing.sm),
          if (isSearching)
            const LoadingDialog(inline: true, message: 'Searching foods...')
          else if (searchResults.isEmpty)
            Text('No results found.', style: context.text.bodyMedium)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in searchResults)
                  _MiniChoiceChip(
                    label: item.name,
                    selected: selectedValues.contains(item.name),
                    onTap: () => onSelected(item.name),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}

class _QuickInspirationGrid extends StatelessWidget {
  final List<MealPlanQuickInspiration> items;

  const _QuickInspirationGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Image.asset('assets/images/empty_page.png', height: 140),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const spacing = AppSpacing.sm;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                height: 160,
                child: _QuickInspirationCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _QuickInspirationCard extends StatelessWidget {
  final MealPlanQuickInspiration item;

  const _QuickInspirationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Stack(
                children: [
                  Image.asset(
                    item.imagePath,
                    height: 64,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.textPrimary,
                        size: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(height: 1.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
