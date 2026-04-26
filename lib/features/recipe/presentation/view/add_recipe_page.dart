import 'package:flutter/material.dart';

class AddRecipePage extends StatelessWidget {
  const AddRecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Recipe'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Add Recipe', style: Theme.of(context).textTheme.headlineSmall),
            const Text('Create a new recipe'),
          ],
        ),
      ),
    );
  }
}