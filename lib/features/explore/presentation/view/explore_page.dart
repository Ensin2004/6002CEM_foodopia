import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Explore', style: Theme.of(context).textTheme.headlineSmall),
          const Text('Discover new recipes'),
        ],
      ),
    );
  }
}