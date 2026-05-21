import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';

class ReviewSectionRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onEdit;
  final List<Widget> children;

  const ReviewSectionRow({
    super.key,
    required this.icon,
    required this.title,
    this.onEdit,
    required this.children,
  });

  @override
  State<ReviewSectionRow> createState() => _ReviewSectionRowState();
}

class _ReviewSectionRowState extends State<ReviewSectionRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            initiallyExpanded: false,
            onExpansionChanged: (expanded) {
              setState(() => _isExpanded = expanded);
            },
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            childrenPadding: EdgeInsets.zero,
            leading: Icon(
                widget.icon,
                color: _isExpanded ? AppColors.primary : Colors.black,
                size: 18,
            ),
            title: Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium?.copyWith(
                color: _isExpanded ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onEdit != null)
                  TextButton(onPressed: widget.onEdit, child: const Text("Edit")),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
            children: widget.children,
          ),
        ),
      ),
    );
  }
}