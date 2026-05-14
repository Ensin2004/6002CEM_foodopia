import 'package:flutter/material.dart';

import '../../../../core/widgets/buttons/primary_button.dart';

class ExploreEmptyState extends StatelessWidget {
  final VoidCallback onExploreNow;

  const ExploreEmptyState({super.key, required this.onExploreNow});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Image.asset('assets/images/empty_page.png'),
          ),
          const SizedBox(height: 18),
          Text(
            'Whoops!\nIt looks empty...',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(height: 1.05),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore recipes from community and follow them to see them here!',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            onPressed: onExploreNow,
            text: 'Explore Now',
            verticalPadding: 13,
          ),
        ],
      ),
    );
  }
}
