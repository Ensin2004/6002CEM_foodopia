import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Home', style: Theme.of(context).textTheme.headlineSmall),
          const Text('Welcome to Foodopia!'),
        ],
      ),
    );
  }
}