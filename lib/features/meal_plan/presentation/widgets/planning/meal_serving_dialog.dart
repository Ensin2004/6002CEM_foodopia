import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../domain/entities/meal_serving_amount.dart';

/// Dialog for choosing meal-plan serving size.
class MealServingDialog extends StatefulWidget {
  /// Initial selected serving amount.
  final double initialValue;

  /// Quick-pick serving amounts shown as chips.
  final List<double> presets;

  /// Whether serving values should be rounded to whole servings.
  final bool wholeServingsOnly;

  /// Creates a new serving-size dialog.
  const MealServingDialog({
    super.key,
    required this.initialValue,
    this.presets = MealServingAmount.presets,
    this.wholeServingsOnly = false,
  });

  /// Creates a serving-size dialog for AI generation serving counts.
  const MealServingDialog.wholeServings({
    super.key,
    required this.initialValue,
    this.presets = const [1, 2, 3, 4, 5, 6, 8, 10],
  }) : wholeServingsOnly = true;

  @override
  State<MealServingDialog> createState() => _MealServingDialogState();
}

class _MealServingDialogState extends State<MealServingDialog> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = _normalize(widget.initialValue);
  }

  double _normalize(double value) {
    final normalized = MealServingAmount.normalize(value);
    if (!widget.wholeServingsOnly) return normalized;
    return normalized
        .round()
        .clamp(1, MealServingAmount.max.toInt())
        .toDouble();
  }

  void _setValue(double value) {
    setState(() => _value = _normalize(value));
  }

  double _stepDown() {
    if (!widget.wholeServingsOnly) return MealServingAmount.stepDown(_value);
    return (_value - 1).clamp(1, MealServingAmount.max).toDouble();
  }

  double _stepUp() {
    if (!widget.wholeServingsOnly) return MealServingAmount.stepUp(_value);
    return (_value + 1).clamp(1, MealServingAmount.max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final minValue = widget.wholeServingsOnly ? 1 : MealServingAmount.min;
    final canDecrease = _value > minValue;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.room_service_outlined,
              color: AppColors.secondary,
              size: 21,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Serving Size',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calories will be shown for this amount.',
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Decrease serving size',
                    onPressed: canDecrease
                        ? () => _setValue(_stepDown())
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      MealServingAmount.format(_value),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Increase serving size',
                    onPressed: _value >= MealServingAmount.max
                        ? null
                        : () => _setValue(_stepUp()),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.presets.map((preset) {
              final normalizedPreset = _normalize(preset);
              final selected = (_value - normalizedPreset).abs() < 0.001;
              return ChoiceChip(
                label: Text(MealServingAmount.format(normalizedPreset)),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.primary.withValues(alpha: 0.16),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
                onSelected: (_) => _setValue(normalizedPreset),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
