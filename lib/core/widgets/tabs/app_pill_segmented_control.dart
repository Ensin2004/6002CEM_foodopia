import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/theme_extension.dart';

class AppPillSegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AppPillSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        const minSegmentWidth = 112.0;
        final estimatedWidth = labels.fold<double>(
          0,
          (total, label) =>
              total +
              (label.length * 8.5).clamp(minSegmentWidth, double.infinity),
        );
        final shouldScroll =
            estimatedWidth + (labels.length - 1) * gap > constraints.maxWidth;

        final children = labels.asMap().entries.map((entry) {
          final index = entry.key;
          final isSelected = selectedIndex == index;
          final segment = InkWell(
            onTap: () => onChanged(index),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.value,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: context.text.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );

          final segmentWidth = (entry.value.length * 8.5).clamp(
            minSegmentWidth,
            double.infinity,
          );

          return shouldScroll
              ? SizedBox(width: segmentWidth, child: segment)
              : Expanded(child: segment);
        }).toList();

        return Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: shouldScroll
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _withGaps(children, gap)),
                )
              : Row(children: _withGaps(children, gap)),
        );
      },
    );
  }

  List<Widget> _withGaps(List<Widget> children, double gap) {
    final spaced = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) spaced.add(SizedBox(width: gap));
      spaced.add(children[index]);
    }
    return spaced;
  }
}
