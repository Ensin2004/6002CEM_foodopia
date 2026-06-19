import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/help_center_issue.dart';

/// Header card shared by user and admin Help Center pages.
class HelpCenterHeroCard extends StatelessWidget {
  /// Main heading.
  final String title;

  /// Supporting text.
  final String message;

  /// Search input widget.
  final Widget searchField;

  /// Creates the Help Center hero card.
  const HelpCenterHeroCard({
    super.key,
    required this.title,
    required this.message,
    required this.searchField,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /* Shared hero keeps Help Center pages visually aligned.
       Search field is injected so each page controls its own state. */
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 22, 18, 14),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF8F0), Color(0xFFE2F4E9), Color(0xFFF4FBF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -4,
            top: 6,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/help_center.png',
                width: 132,
                height: 142,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 142),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero title.
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                // Hero message.
                Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.only(top: 164), child: searchField),
        ],
      ),
    );
  }
}

/// Search field shared by Help Center screens.
class HelpCenterSearchField extends StatelessWidget {
  /// Text editing controller.
  final TextEditingController controller;

  /// Current search query.
  final String searchQuery;

  /// Placeholder text.
  final String hintText;

  /// Search change callback.
  final ValueChanged<String> onChanged;

  /// Clear callback.
  final VoidCallback onClear;

  /// Creates the Help Center search field.
  const HelpCenterSearchField({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: theme.inputDecorationTheme.hintStyle?.copyWith(fontSize: 14),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          size: 22,
        ),
        suffixIcon: searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Filter chips and sort menu row shared by Help Center screens.
class HelpCenterFilterSortRow extends StatelessWidget {
  /// Selected status value.
  final String selectedStatus;

  /// Latest-first sort flag.
  final bool sortLatestFirst;

  /// Status change callback.
  final ValueChanged<String> onStatusSelected;

  /// Sort change callback.
  final ValueChanged<bool> onSortSelected;

  /// Creates the filter and sort row.
  const HelpCenterFilterSortRow({
    super.key,
    required this.selectedStatus,
    required this.sortLatestFirst,
    required this.onStatusSelected,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final label in const ['All', 'Open', 'Closed']) ...[
                    HelpCenterFilterChipButton(
                      label: label,
                      isSelected: selectedStatus == label,
                      onTap: () => onStatusSelected(label),
                    ),
                    if (label != 'Closed') const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          HelpCenterSortMenuButton(
            sortLatestFirst: sortLatestFirst,
            onSelected: onSortSelected,
          ),
        ],
      ),
    );
  }
}

/// Status badge for a Help Center ticket.
class HelpCenterStatusBadge extends StatelessWidget {
  /// Ticket issue.
  final HelpCenterIssue issue;

  /// Creates a status badge.
  const HelpCenterStatusBadge({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    final status = issue.normalizedStatus;
    final label = status == 'closed' ? 'Closed' : 'Open';
    final color = status == 'closed'
        ? const Color(0xFFE53935)
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty ticket state with dashed border.
class HelpCenterEmptyTicketsCard extends StatelessWidget {
  /// Empty state title.
  final String title;

  /// Empty state message.
  final String message;

  /// Creates an empty tickets card.
  const HelpCenterEmptyTicketsCard({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 24, 12, 6),
      child: CustomPaint(
        painter: const _DashedBorderPainter(
          color: Color(0xFFDDE3EA),
          radius: 18,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 30),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F0),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF81C991),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter chip button for Help Center status filtering.
class HelpCenterFilterChipButton extends StatelessWidget {
  /// Chip label.
  final String label;

  /// Selected state.
  final bool isSelected;

  /// Tap callback.
  final VoidCallback onTap;

  /// Creates a filter chip button.
  const HelpCenterFilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : const Color(0xFFE3E6EB),
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}

/// Sort menu button for Help Center tickets.
class HelpCenterSortMenuButton extends StatelessWidget {
  /// Latest-first state.
  final bool sortLatestFirst;

  /// Menu selection callback.
  final ValueChanged<bool> onSelected;

  /// Creates a sort menu button.
  const HelpCenterSortMenuButton({
    super.key,
    required this.sortLatestFirst,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<bool>(
      tooltip: 'Sort tickets',
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: true,
          child: Row(
            children: [
              Icon(
                Icons.check_rounded,
                size: 18,
                color: sortLatestFirst
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              const SizedBox(width: 8),
              const Text('Newest'),
            ],
          ),
        ),
        PopupMenuItem(
          value: false,
          child: Row(
            children: [
              Icon(
                Icons.check_rounded,
                size: 18,
                color: !sortLatestFirst
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              const SizedBox(width: 8),
              const Text('Oldest'),
            ],
          ),
        ),
      ],
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE3E6EB)),
        ),
        child: Icon(
          Icons.tune_rounded,
          color: theme.colorScheme.onSurface,
          size: 24,
        ),
      ),
    );
  }
}

/// Dashed border painter for empty Help Center states.
class _DashedBorderPainter extends CustomPainter {
  /// Border color.
  final Color color;

  /// Corner radius.
  final double radius;

  /// Creates a dashed border painter.
  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    // Dashed border paint.
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Rounded rectangle path.
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    // Dash segments along the path.
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashWidth = 7.0;
      const dashSpace = 6.0;

      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
