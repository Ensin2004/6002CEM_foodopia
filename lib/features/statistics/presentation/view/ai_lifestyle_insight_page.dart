import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/services/ai_lifestyle_insight_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/tabs/app_pill_segmented_control.dart';
import '../../domain/entities/ai_lifestyle_insight.dart';
import '../widgets/statistics_page_helpers.dart';

class AiLifestyleInsightPage extends StatefulWidget {
  const AiLifestyleInsightPage({super.key});

  @override
  State<AiLifestyleInsightPage> createState() => _AiLifestyleInsightPageState();
}

class _AiLifestyleInsightPageState extends State<AiLifestyleInsightPage> {
  AiLifestylePeriod _period = AiLifestylePeriod.weekly;
  late Future<AiLifestyleInsight> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AiLifestyleInsight> _load() {
    return sl<AiLifestyleInsightService>().getInsight(_period);
  }

  void _selectPeriod(int index) {
    setState(() {
      _period = AiLifestylePeriod.values[index];
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'AI Lifestyle Insight',
        leading: StatisticsBackButton(),
      ),
      body: FutureBuilder<AiLifestyleInsight>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingDialog(
              inline: true,
              message: 'Analysing lifestyle pattern...',
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              onRetry: () => setState(() => _future = _load()),
            );
          }

          final insight = snapshot.data;
          if (insight == null) {
            return _ErrorState(
              onRetry: () => setState(() => _future = _load()),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                AppPillSegmentedControl(
                  labels: const ['Daily', 'Weekly', 'Monthly'],
                  selectedIndex: _period.index,
                  onChanged: _selectPeriod,
                ),
                const SizedBox(height: AppSpacing.md),
                _InsightHeader(insight: insight),
                const SizedBox(height: AppSpacing.md),
                _ProgressSection(insight: insight),
                const SizedBox(height: AppSpacing.md),
                _NutritionGrid(insight: insight),
                const SizedBox(height: AppSpacing.md),
                _RecommendationSection(
                  recommendations: insight.recommendations,
                ),
                const SizedBox(height: AppSpacing.md),
                _MealsSection(meals: insight.meals),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InsightHeader extends StatelessWidget {
  final AiLifestyleInsight insight;

  const _InsightHeader({required this.insight});

  @override
  Widget build(BuildContext context) {
    final scoreColor = insight.score >= 75
        ? AppColors.primary
        : insight.score >= 45
        ? AppColors.secondary
        : AppColors.error;
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      insight.score.toString(),
                      style: context.text.headlineSmall?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'AI score',
                      style: context.text.bodySmall?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.dateRangeLabel,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.summary,
                      style: context.text.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aligned to: ${insight.mealPreferenceLabel}',
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  icon: Icons.restaurant_menu_outlined,
                  label: 'Meals',
                  value: insight.mealCount.toString(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricPill(
                  icon: Icons.calendar_month_outlined,
                  label: 'Planned',
                  value: '${insight.plannedDays}/${insight.expectedDays}d',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final AiLifestyleInsight insight;

  const _ProgressSection({required this.insight});

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.md),
          _ProgressLine(
            label: 'Calorie target',
            value:
                '${insight.averageDailyCalories.round()} / ${insight.targetCalories.round()} kcal',
            progress: insight.calorieProgress.clamp(0.0, 1.0),
            status: insight.calorieStatus,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          _ProgressLine(
            label: 'Planning consistency',
            value: '${(insight.planningConsistency * 100).round()}%',
            progress: insight.planningConsistency,
            status: 'Days with at least one planned meal',
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          _ProgressLine(
            label: 'Sustainable choices',
            value: '${(insight.sustainabilityProgress * 100).round()}%',
            progress: insight.sustainabilityProgress,
            status: insight.sustainabilityStatus,
            color: const Color(0xFF00897B),
          ),
        ],
      ),
    );
  }
}

class _NutritionGrid extends StatelessWidget {
  final AiLifestyleInsight insight;

  const _NutritionGrid({required this.insight});

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nutrition Review', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            insight.nutritionStatus,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.7,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _NutritionTile(
                'Calories',
                '${insight.totalCalories.round()} kcal',
              ),
              _NutritionTile('Protein', '${insight.proteinGrams.round()} g'),
              _NutritionTile('Carbs', '${insight.carbsGrams.round()} g'),
              _NutritionTile('Fat', '${insight.fatGrams.round()} g'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  final List<String> recommendations;

  const _RecommendationSection({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Recommendations', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.md),
          ...recommendations.asMap().entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == recommendations.length - 1
                    ? 0
                    : AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(entry.value, style: context.text.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealsSection extends StatelessWidget {
  final List<AiLifestyleMealSnapshot> meals;

  const _MealsSection({required this.meals});

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meals Analysed', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.md),
          if (meals.isEmpty)
            Text(
              'No planned meals in this period yet.',
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...meals.take(8).map((meal) => _MealRow(meal: meal)),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final AiLifestyleMealSnapshot meal;

  const _MealRow({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: meal.plantForward
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              meal.plantForward
                  ? Icons.eco_outlined
                  : Icons.restaurant_outlined,
              color: meal.plantForward
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 19,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  DateFormat('d MMM').format(meal.date),
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${meal.calories.round()} kcal',
            style: context.text.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final String status;
  final Color color;

  const _ProgressLine({
    required this.label,
    required this.value,
    required this.progress,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: context.text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFF0F0F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          status,
          style: context.text.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: context.text.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionTile extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Widget child;

  const _ReportCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insights_outlined,
              size: 42,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load AI lifestyle insight.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
