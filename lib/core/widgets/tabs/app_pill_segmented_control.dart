import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/theme_extension.dart';

/// Pill-style segmented control with animated selection.
/// Used for tab-like selection in a compact horizontal layout.
class AppPillSegmentedControl extends StatelessWidget {
  /// Labels for each segment.
  final List<String> labels;

  /// Index of the selected segment.
  final int selectedIndex;

  /// Callback when a segment is selected.
  final ValueChanged<int> onChanged;

  /// Creates a new app pill segmented control instance.
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
        // Constants.
        const gap = 6.0;
        const minSegmentWidth = 112.0;

        final segmentWidths = labels
            .map(
              (label) => (label.length * 9.0 + 32).clamp(
                minSegmentWidth,
                double.infinity,
              ).toDouble(),
            )
            .toList();
        final contentWidth =
            segmentWidths.fold<double>(0, (total, width) => total + width) +
            (labels.length - 1) * gap;

        // Determine if scrolling is needed.
        final shouldScroll = contentWidth > constraints.maxWidth;

        // Build segments.
        final children = labels.asMap().entries.map((entry) {
          final index = entry.key;
          final isSelected = selectedIndex == index;

          // Segment content.
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

          // Calculate segment width.
          final segmentWidth = segmentWidths[index];

          return shouldScroll
              ? SizedBox(width: segmentWidth, child: segment)
              : Expanded(child: segment);
        }).toList();

        // Build the container.
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
                  child: SizedBox(
                    width: contentWidth,
                    child: Row(children: _withGaps(children, gap)),
                  ),
                )
              : Row(children: _withGaps(children, gap)),
        );
      },
    );
  }

  /// Adds gaps between children.
  List<Widget> _withGaps(List<Widget> children, double gap) {
    final spaced = <Widget>[];

    for (var index = 0; index < children.length; index++) {
      if (index > 0) spaced.add(SizedBox(width: gap));
      spaced.add(children[index]);
    }

    return spaced;
  }
}
