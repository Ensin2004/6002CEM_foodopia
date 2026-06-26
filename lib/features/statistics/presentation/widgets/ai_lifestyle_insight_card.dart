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
              height: 112,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _InsightShell(
            child: _ErrorContent(onViewDetail: onViewDetail),
          );
        }

        final insight = snapshot.data!;
        final scoreColor = _scoreColor(insight.score);

        return _InsightShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InsightDonut(score: insight.score, color: scoreColor),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'AI lifestyle insight',
                                style: context.text.titleSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Analysis period: ${insight.dateRangeLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _StatusPill(
                          label: _scoreLabel(insight.score),
                          color: scoreColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                insight.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _SimpleStatPill(
                    label: 'Meals',
                    value: insight.mealCount.toString(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _SimpleStatPill(
                    label: 'Days planned',
                    value: '${insight.plannedDays}/${insight.expectedDays}',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _SimpleStatPill(
                    label: 'Plant meals',
                    value: '${insight.plantForwardMeals}',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: 'View insight detail',
                    onPressed: onViewDetail,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    color: AppColors.primary,
                    visualDensity: VisualDensity.compact,
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
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InsightDonut extends StatelessWidget {
  final int score;
  final Color color;

  const _InsightDonut({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 66,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(66, 66),
            painter: _DonutPainter(
              progress: (score / 100).clamp(0.0, 1.0),
              color: color,
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
                'score',
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _DonutPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final backgroundPaint = Paint()
      ..color = const Color(0xFFEFF2EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      progress * 6.2832,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.text.bodySmall?.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SimpleStatPill extends StatelessWidget {
  final String label;
  final String value;

  const _SimpleStatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.48)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(
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
            'AI lifestyle insight will appear when meal plan data is available.',
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(onPressed: onViewDetail, child: const Text('View')),
      ],
    );
  }
}
