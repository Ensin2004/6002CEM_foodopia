import 'package:flutter/material.dart';

import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/admin_home_dashboard.dart';

/// Stat card widget for the admin home page.
/// Displays a metric with icon, value, title, and change indicator.
class AdminHomeStatCard extends StatelessWidget {
  /// The metric to display.
  final AdminMetric metric;

  /// Creates a new admin home stat card instance.
  const AdminHomeStatCard({
    super.key,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon.
          CircleAvatar(
            radius: 18,
            backgroundColor: metric.iconBackgroundColor,
            child: Icon(metric.icon, color: metric.iconColor, size: 18),
          ),
          const SizedBox(height: 10),

          // Value.
          Text(
            metric.value,
            textAlign: TextAlign.center,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),

          // Title.
          Text(
            metric.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 8),

          // Change indicator.
          Text(
            '↑ ${metric.change}',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),

          // Note.
          Text(
            metric.note,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}