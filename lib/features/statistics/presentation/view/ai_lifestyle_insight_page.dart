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

          if (snapshot.hasError || snapshot.data == null) {
            return _ErrorState(
              onRetry: () => setState(() => _future = _load()),
            );
          }

          final insight = snapshot.data!;

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
                _OverviewSection(insight: insight, period: _period),
                const SizedBox(height: AppSpacing.md),
                _AnalysisBasisSection(insight: insight),
                const SizedBox(height: AppSpacing.md),
                _PlanningSection(insight: insight),
                const SizedBox(height: AppSpacing.md),
                _NutritionSection(insight: insight),
                const SizedBox(height: AppSpacing.md),
                _SustainabilitySection(insight: insight),
                const SizedBox(height: AppSpacing.md),
                _RecommendationSection(insight: insight),
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

class _OverviewSection extends StatelessWidget {
  final AiLifestyleInsight insight;
  final AiLifestylePeriod period;

  const _OverviewSection({required this.insight, required this.period});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(insight.score);

    return _SectionCard(
      aiExplanation: _overviewAiRead(insight, period),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.auto_awesome_outlined,
            title: '${_periodLabel(period)} lifestyle summary',
            subtitle: 'Analysis period: ${insight.dateRangeLabel}',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScoreBadge(score: insight.score, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  insight.summary,
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.38,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _QuickMetric(label: 'Meals', value: '${insight.mealCount}'),
              _QuickMetric(
                label: 'Daily avg',
                value: insight.hasMealData
                    ? '${insight.averageDailyCalories.round()} kcal'
                    : '-',
              ),
              _QuickMetric(
                label: 'Preference',
                value: insight.mealPreferenceLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalysisBasisSection extends StatelessWidget {
  final AiLifestyleInsight insight;

  const _AnalysisBasisSection({required this.insight});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      aiExplanation: _basisAiRead(insight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.event_note_outlined,
            title: 'What this analysis uses',
            subtitle:
                'This helps users understand where the insight came from.',
          ),
          const SizedBox(height: AppSpacing.md),
          _FactRow(label: 'Date range', value: insight.dateRangeLabel),
          _SoftDivider(),
          _FactRow(
            label: 'Planned meals found',
            value:
                '${insight.mealCount} meal${insight.mealCount == 1 ? '' : 's'} across ${insight.plannedDays} day${insight.plannedDays == 1 ? '' : 's'}',
          ),
          _SoftDivider(),
          _FactRow(
            label: 'Profile alignment',
            value: insight.mealPreferenceLabel,
          ),
        ],
      ),
    );
  }
}

class _PlanningSection extends StatelessWidget {
  final AiLifestyleInsight insight;

  const _PlanningSection({required this.insight});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      aiExplanation: _planningAiRead(insight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.calendar_month_outlined,
            title: 'Planning rhythm',
            subtitle: 'How consistently meals are planned in this period.',
          ),
          const SizedBox(height: AppSpacing.md),
          _ProgressInsight(
            label: 'Planning consistency',
            value: '${(insight.planningConsistency * 100).round()}%',
            progress: insight.planningConsistency,
            color: const Color(0xFF0277BD),
            description:
                '${insight.plannedDays} of ${insight.expectedDays} expected days include a planned meal.',
          ),
          const SizedBox(height: AppSpacing.md),
          _ProgressInsight(
            label: 'Calorie target',
            value:
                '${insight.averageDailyCalories.round()} / ${insight.targetCalories.round()} kcal',
            progress: insight.calorieProgress.clamp(0.0, 1.0),
            color: AppColors.primary,
            description: insight.calorieStatus,
          ),
        ],
      ),
    );
  }
}

class _NutritionSection extends StatelessWidget {
  final AiLifestyleInsight insight;

  const _NutritionSection({required this.insight});

  @override
  Widget build(BuildContext context) {
    final macroCalories =
        (insight.proteinGrams * 4) +
        (insight.carbsGrams * 4) +
        (insight.fatGrams * 9);
    final protein = macroCalories <= 0
        ? 0.0
        : (insight.proteinGrams * 4 / macroCalories).clamp(0.0, 1.0);
    final carbs = macroCalories <= 0
        ? 0.0
        : (insight.carbsGrams * 4 / macroCalories).clamp(0.0, 1.0);
    final fat = macroCalories <= 0
        ? 0.0
        : (insight.fatGrams * 9 / macroCalories).clamp(0.0, 1.0);

    return _SectionCard(
      aiExplanation: _nutritionAiRead(insight, protein, carbs, fat),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.monitor_heart_outlined,
            title: 'Nutrition balance',
            subtitle: insight.nutritionStatus,
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.85,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _NutrientTile(
                'Calories',
                '${insight.totalCalories.round()} kcal',
              ),
              _NutrientTile('Protein', '${insight.proteinGrams.round()} g'),
              _NutrientTile('Carbs', '${insight.carbsGrams.round()} g'),
              _NutrientTile('Fat', '${insight.fatGrams.round()} g'),
              _NutrientTile('Fiber', '${insight.fiberGrams.round()} g'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MacroStack(protein: protein, carbs: carbs, fat: fat),
        ],
      ),
    );
  }
}

class _SustainabilitySection extends StatelessWidget {
  final AiLifestyleInsight insight;

  const _SustainabilitySection({required this.insight});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      aiExplanation: _sustainabilityAiRead(insight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.eco_outlined,
            title: 'Lifestyle and sustainability',
            subtitle: 'Plant-forward and higher-impact choices found in meals.',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SignalPanel(
                  label: 'Plant-forward',
                  value: '${(insight.sustainabilityProgress * 100).round()}%',
                  description:
                      '${insight.plantForwardMeals} of ${insight.mealCount} meals',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SignalPanel(
                  label: 'Higher-impact',
                  value: insight.mealCount == 0
                      ? '0%'
                      : '${(insight.higherImpactMeals / insight.mealCount * 100).round()}%',
                  description: '${insight.higherImpactMeals} meals flagged',
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            insight.sustainabilityStatus,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  final AiLifestyleInsight insight;

  const _RecommendationSection({required this.insight});

  @override
  Widget build(BuildContext context) {
    final primaryRecommendation = insight.recommendations.first;
    final supportingRecommendations = insight.recommendations.skip(1).toList();

    return _SectionCard(
      aiExplanation: _recommendationAiRead(insight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.tips_and_updates_outlined,
            title: 'Recommended focus',
            subtitle: 'Small actions that can improve the next planning cycle.',
          ),
          const SizedBox(height: AppSpacing.md),
          _ObjectiveCard(
            recommendation: primaryRecommendation,
            insight: insight,
          ),
          if (supportingRecommendations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Supporting moves',
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...supportingRecommendations.asMap().entries.map(
              (entry) => _RecommendationItem(
                index: entry.key + 1,
                text: entry.value,
                isLast: entry.key == supportingRecommendations.length - 1,
              ),
            ),
          ],
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
    return _SectionCard(
      aiExplanation: _mealsAiRead(meals),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.restaurant_menu_outlined,
            title: 'Meals analysed',
            subtitle: meals.isEmpty
                ? 'No planned meals were found in this period.'
                : 'Meal dates and calories used for this insight.',
          ),
          if (meals.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...meals.take(8).map((meal) => _MealRow(meal: meal)),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatefulWidget {
  final Widget child;
  final String aiExplanation;

  const _SectionCard({required this.child, required this.aiExplanation});

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _showExplanation = false;

  void _toggleExplanation() {
    setState(() => _showExplanation = !_showExplanation);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.child,
          const SizedBox(height: AppSpacing.md),
          _AiExplainToggle(
            expanded: _showExplanation,
            onTap: _toggleExplanation,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _AiExplanationBox(text: widget.aiExplanation),
            crossFadeState: _showExplanation
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOut,
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

class _AiExplainToggle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _AiExplainToggle({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  expanded ? 'Hide AI explanation' : 'AI explains this section',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiExplanationBox extends StatelessWidget {
  final String text;

  const _AiExplanationBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.psychology_alt_outlined,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal AI read',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.42,
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

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  final Color color;

  const _ScoreBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: CircularProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              strokeWidth: 5,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                score.toString(),
                style: context.text.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                _scoreLabel(score),
                style: context.text.bodySmall?.copyWith(
                  color: color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickMetric extends StatelessWidget {
  final String label;
  final String value;

  const _QuickMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final String label;
  final String value;

  const _FactRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressInsight extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;
  final String description;

  const _ProgressInsight({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.description,
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
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F2F1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: context.text.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _NutrientTile extends StatelessWidget {
  final String label;
  final String value;

  const _NutrientTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroStack extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;

  const _MacroStack({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Macro calorie split',
          style: context.text.bodySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: (protein * 100).round().clamp(1, 100),
                  child: Container(color: AppColors.primary),
                ),
                Expanded(
                  flex: (carbs * 100).round().clamp(1, 100),
                  child: Container(color: const Color(0xFF0277BD)),
                ),
                Expanded(
                  flex: (fat * 100).round().clamp(1, 100),
                  child: Container(color: const Color(0xFF9A6A16)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _LegendDot(
              label: 'Protein ${(protein * 100).round()}%',
              color: AppColors.primary,
            ),
            _LegendDot(
              label: 'Carbs ${(carbs * 100).round()}%',
              color: const Color(0xFF0277BD),
            ),
            _LegendDot(
              label: 'Fat ${(fat * 100).round()}%',
              color: const Color(0xFF9A6A16),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignalPanel extends StatelessWidget {
  final String label;
  final String value;
  final String description;
  final Color color;

  const _SignalPanel({
    required this.label,
    required this.value,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: context.text.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  final String recommendation;
  final AiLifestyleInsight insight;

  const _ObjectiveCard({required this.recommendation, required this.insight});

  @override
  Widget build(BuildContext context) {
    final focusLabel = _focusLabel(insight);
    final confidence = _focusConfidence(insight);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary objective',
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      focusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _ConfidencePill(label: confidence),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            recommendation,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ObjectiveReason(insight: insight),
          const SizedBox(height: AppSpacing.md),
          _ObjectiveSteps(insight: insight),
        ],
      ),
    );
  }
}

class _ConfidencePill extends StatelessWidget {
  final String label;

  const _ConfidencePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: context.text.bodySmall?.copyWith(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ObjectiveReason extends StatelessWidget {
  final AiLifestyleInsight insight;

  const _ObjectiveReason({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _objectiveReason(insight),
        style: context.text.bodySmall?.copyWith(
          color: AppColors.textPrimary,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ObjectiveSteps extends StatelessWidget {
  final AiLifestyleInsight insight;

  const _ObjectiveSteps({required this.insight});

  @override
  Widget build(BuildContext context) {
    final steps = _objectiveSteps(insight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested next actions',
          style: context.text.bodySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...steps.asMap().entries.map(
          (entry) => Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == steps.length - 1 ? 0 : AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key + 1}.',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.value,
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationItem extends StatelessWidget {
  final int index;
  final String text;
  final bool isLast;

  const _RecommendationItem({
    required this.index,
    required this.text,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$index',
              style: context.text.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
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
    final tags = [
      if (meal.plantForward) 'plant-forward',
      if (meal.higherImpact) 'higher-impact',
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.restaurant_outlined,
              color: AppColors.textSecondary,
              size: 18,
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('d MMM yyyy').format(meal.date)} - ${meal.servings.toStringAsFixed(1)} serving${meal.servings == 1 ? '' : 's'}',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tags,
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${meal.calories.round()} kcal',
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _SoftDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(height: 1, color: AppColors.border.withValues(alpha: 0.7)),
    );
  }
}

Color _scoreColor(int score) {
  return score >= 75
      ? AppColors.primary
      : score >= 45
      ? const Color(0xFF9A6A16)
      : AppColors.error;
}

String _scoreLabel(int score) {
  if (score >= 80) return 'Strong';
  if (score >= 60) return 'Steady';
  if (score >= 40) return 'Needs focus';
  return 'Low';
}

String _periodLabel(AiLifestylePeriod period) {
  switch (period) {
    case AiLifestylePeriod.daily:
      return 'Daily';
    case AiLifestylePeriod.weekly:
      return 'Weekly';
    case AiLifestylePeriod.monthly:
      return 'Monthly';
  }
}

String _overviewAiRead(AiLifestyleInsight insight, AiLifestylePeriod period) {
  final periodLabel = _periodLabel(period).toLowerCase();
  final consistency = (insight.planningConsistency * 100).round();
  final plantForward = (insight.sustainabilityProgress * 100).round();
  final scoreMeaning = insight.score >= 75
      ? 'your routine is already in a healthy direction'
      : insight.score >= 45
      ? 'there is a usable routine, but it still has a clear gap'
      : 'the plan needs more meal data or more consistent coverage';
  return 'AI reads this $periodLabel period as ${_scoreLabel(insight.score).toLowerCase()} because your score is ${insight.score}/100. In plain language, $scoreMeaning. The main evidence is $consistency% planning consistency and $plantForward% plant-forward choices across ${insight.mealCount} planned meal${insight.mealCount == 1 ? '' : 's'}. This is compared with your ${insight.mealPreferenceLabel} profile, so the insight is judging fit to your own lifestyle pattern, not a generic diet standard.';
}

String _basisAiRead(AiLifestyleInsight insight) {
  if (!insight.hasMealData) {
    return 'AI could not find planned meals in ${insight.dateRangeLabel}. That means the report cannot confidently judge your habit, calories, or nutrition yet. The best next step is simple: add meals inside this date range first, then the insight will become more personal and more useful.';
  }
  final coverage = (insight.planningConsistency * 100).round();
  return 'AI used ${insight.mealCount} planned meal${insight.mealCount == 1 ? '' : 's'} from ${insight.dateRangeLabel}. Those meals cover ${insight.plannedDays} of ${insight.expectedDays} expected days, which gives a $coverage% coverage signal. This matters because a report based on more planned days is more reliable. If the coverage is low, treat the insight as an early read; if it is high, you can trust the pattern more.';
}

String _planningAiRead(AiLifestyleInsight insight) {
  final consistency = (insight.planningConsistency * 100).round();
  final caloriePercent = (insight.calorieProgress * 100).round();
  final calorieGap = (insight.averageDailyCalories - insight.targetCalories)
      .round();
  final gapText = calorieGap == 0
      ? 'right on target'
      : calorieGap > 0
      ? '$calorieGap kcal above target'
      : '${calorieGap.abs()} kcal below target';
  final planningMeaning = consistency >= 70
      ? 'You already have a stable planning rhythm, so the goal is to protect it and improve meal quality.'
      : 'Your biggest opportunity is consistency, because missing planned days makes nutrition and calorie guidance less reliable.';
  return 'AI sees your planning rhythm at $consistency%, meaning ${insight.plannedDays} out of ${insight.expectedDays} expected days have at least one planned meal. Your calorie alignment is $caloriePercent%, which is about $gapText on average. $planningMeaning For you, this section answers: am I planning often enough, and are those planned meals close to my target?';
}

String _nutritionAiRead(
  AiLifestyleInsight insight,
  double protein,
  double carbs,
  double fat,
) {
  final proteinPercent = (protein * 100).round();
  final carbsPercent = (carbs * 100).round();
  final fatPercent = (fat * 100).round();
  final balanceNote = proteinPercent < 15
      ? 'Protein looks relatively low, so adding a protein source could make the plan feel more complete.'
      : fatPercent > 40
      ? 'Fat takes a larger share, so portion size or ingredient swaps may help if calories feel high.'
      : 'The macro split looks usable, so the focus can shift to consistency and food variety.';
  return 'AI totals the planned meals as ${insight.totalCalories.round()} kcal: ${insight.proteinGrams.round()}g protein, ${insight.carbsGrams.round()}g carbs, ${insight.fatGrams.round()}g fat, and ${insight.fiberGrams.round()}g fiber. Converted into calorie share, the split is about $proteinPercent% protein, $carbsPercent% carbs, and $fatPercent% fat. $balanceNote This section helps you understand meal quality, not just calorie quantity.';
}

String _sustainabilityAiRead(AiLifestyleInsight insight) {
  final plantForward = insight.mealCount == 0
      ? 0
      : (insight.plantForwardMeals / insight.mealCount * 100).round();
  final higherImpact = insight.mealCount == 0
      ? 0
      : (insight.higherImpactMeals / insight.mealCount * 100).round();
  final lifestyleNote = plantForward >= 50
      ? 'You already have a good base of plant-forward meals.'
      : 'There is room to add more lighter or plant-forward meals without changing your whole routine.';
  return 'AI found $plantForward% plant-forward meals and $higherImpact% higher-impact meals in this period. $lifestyleNote This is not a pass/fail judgment; it is a pattern check. If you want a lighter routine, start by changing one repeated meal, not everything at once. That makes the improvement easier to keep.';
}

String _recommendationAiRead(AiLifestyleInsight insight) {
  final consistency = (insight.planningConsistency * 100).round();
  final calorieProgress = (insight.calorieProgress * 100).round();
  final plantForward = (insight.sustainabilityProgress * 100).round();
  return 'AI chooses this objective by comparing your main levers: $consistency% planning consistency, $calorieProgress% calorie alignment, and $plantForward% plant-forward choices. The focus is ${_focusLabel(insight).toLowerCase()} because improving this area should create the biggest visible improvement next period. Use this as your main goal, then treat the supporting moves as optional smaller adjustments.';
}

String _mealsAiRead(List<AiLifestyleMealSnapshot> meals) {
  if (meals.isEmpty) {
    return 'AI has no meal evidence for this period yet. Once meals are planned, this list becomes the audit trail behind the score, recommendations, and nutrition totals.';
  }
  final firstDate = DateFormat('d MMM yyyy').format(meals.first.date);
  final lastDate = DateFormat('d MMM yyyy').format(meals.last.date);
  return 'AI uses these meals as the evidence behind the report. The visible sample runs from $firstDate to $lastDate. Check this list when something feels wrong: if a meal is missing, has the wrong date, or has unusual calories, the score and recommendation may feel off. This section helps you verify the insight before acting on it.';
}

String _focusLabel(AiLifestyleInsight insight) {
  if (insight.planningConsistency < 0.65) return 'Build a steadier plan';
  if (insight.calorieProgress < 0.85) return 'Raise meal coverage';
  if (insight.calorieProgress > 1.15) return 'Tighten calorie balance';
  if (insight.sustainabilityProgress < 0.4) return 'Add lighter meal variety';
  return 'Protect the routine';
}

String _focusConfidence(AiLifestyleInsight insight) {
  if (insight.mealCount >= 8 || insight.plannedDays >= 5) return 'High signal';
  if (insight.mealCount >= 3) return 'Medium signal';
  return 'Early signal';
}

String _objectiveReason(AiLifestyleInsight insight) {
  final consistency = (insight.planningConsistency * 100).round();
  final calorieProgress = (insight.calorieProgress * 100).round();
  final plantForward = (insight.sustainabilityProgress * 100).round();
  return 'Why this is the focus: your current pattern shows $consistency% planning consistency, $calorieProgress% calorie alignment, and $plantForward% plant-forward choices. AI prioritizes the objective that can create the most visible improvement in the next period, instead of giving a generic healthy-eating tip.';
}

List<String> _objectiveSteps(AiLifestyleInsight insight) {
  if (insight.planningConsistency < 0.65) {
    return [
      'Plan one anchor meal for each unplanned day first; breakfast or dinner is easiest to repeat.',
      'Reuse one meal you already planned successfully so the next period starts with less effort.',
      'Check the plan after two days and fill only the missing meal times.',
    ];
  }
  if (insight.calorieProgress < 0.85) {
    return [
      'Add one balanced meal or snack to days that are below target.',
      'Prioritize protein and fiber so the extra calories improve meal quality, not just volume.',
      'Review the daily average again after adding meals to see whether it moves closer to target.',
    ];
  }
  if (insight.calorieProgress > 1.15) {
    return [
      'Look for the highest-calorie planned meal and reduce the portion or swap one ingredient.',
      'Keep protein steady while trimming heavy sauces, fried sides, or oversized starch portions.',
      'Use the next meal plan to bring the daily average closer to the target range.',
    ];
  }
  if (insight.sustainabilityProgress < 0.4) {
    return [
      'Add one plant-forward meal that still matches your preferred cuisine or comfort style.',
      'Use familiar proteins like tofu, beans, eggs, or legumes instead of changing the whole plan.',
      'Keep one favorite higher-impact meal so the change feels realistic.',
    ];
  }
  return [
    'Keep the same planning rhythm for the next period.',
    'Add variety only where the plan feels repetitive.',
    'Use recommendations as small refinements, not a full reset.',
  ];
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
