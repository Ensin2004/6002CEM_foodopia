import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';

class InputLabel extends StatelessWidget {
  final String text;
  final bool isRequired;

  const InputLabel({super.key, required this.text, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        text: text,
        style: context.text.titleMedium,
        children: isRequired
            ? const [
                TextSpan(
                  text: " *",
                  style: TextStyle(color: AppColors.error),
                ),
              ]
            : [],
      ),
    );
  }
}
