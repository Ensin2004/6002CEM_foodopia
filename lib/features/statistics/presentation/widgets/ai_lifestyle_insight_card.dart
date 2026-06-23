import 'package:flutter/material.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/services/ai_lifestyle_insight_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/ai_lifestyle_insight.dart';

class AiLifestyleInsightCard extends StatelessWidget {
  final VoidCallback onViewDetail;

  const AiLifestyleInsightCard({super.key, required this.onViewDetail});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AiLifestyleInsight>(
      future: sl<AiLifestyleInsightService>().getInsight(
        AiLifestylePeriod.weekly,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _InsightShell(
            child: SizedBox(
              height: 118,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        if (snapshot.hasError) {
          return _InsightShell(
            child: _ErrorContent(onViewDetail: onViewDetail),
          );
        }

        final insight = snapshot.data;
        if (insight == null) {
          return _InsightShell(
            child: _ErrorContent(onViewDetail: onViewDetail),
          );
        }

        return _InsightShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScoreBadge(score: insight.score),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Lifestyle Insight',
                          style: context.text.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                    child: _MiniMetric(
                      label: 'Avg calories',
                      value: insight.hasMealData
                          ? insight.averageDailyCalories.round().toString()
                          : '-',
                    ),
                  ),
                  Expanded(
                    child: _MiniMetric(
                      label: 'Preference',
                      value: insight.mealPreferenceLabel,
                    ),
                  ),
                  Expanded(
                    child: _MiniMetric(
                      label: 'Planned',
                      value: '${insight.plannedDays}/${insight.expectedDays}d',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      insight.recommendations.first,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: onViewDetail,
                    icon: const Icon(Icons.insights_outlined, size: 17),
                    label: const Text('View Detail'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InsightShell extends StatelessWidget {
  final Widget child;

  const _InsightShell({required this.child});

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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 75
        ? AppColors.primary
        : score >= 45
        ? AppColors.secondary
        : AppColors.error;
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            score.toString(),
            style: context.text.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'AI score',
            style: context.text.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
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
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final VoidCallback onViewDetail;

  const _ErrorContent({required this.onViewDetail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.insights_outlined, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'AI lifestyle insight is ready when meal plan data is available.',
            style: context.text.bodySmall,
          ),
        ),
        TextButton(onPressed: onViewDetail, child: const Text('View Detail')),
      ],
    );
  }
}
