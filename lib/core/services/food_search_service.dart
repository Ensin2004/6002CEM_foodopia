import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

class FoodSearchService {
  final http.Client client;
  final String apiKey;

  FoodSearchService({required this.client, this.apiKey = EnvConfig.usdaApiKey});

  Future<List<String>> searchFoodTerms(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.length < 2) return [];
    if (apiKey.trim().isEmpty) return [];

    final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
      'api_key': apiKey,
      'query': trimmed,
      'pageSize': '20',
    });

    final response = await client
        .get(
          uri,
          headers: const {
            'User-Agent': 'Foodopia/1.0 (food preference search)',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return [];
    }

    final data = decoded;
    final foods = data['foods'] is List ? data['foods'] as List : [];
    final terms = <String>{};

    for (final food in foods) {
      if (food is! Map<String, dynamic>) continue;
      _addFoodCategory(terms: terms, value: food['foodCategory']);
    }

    return terms.take(10).toList();
  }

  void _addFoodCategory({required Set<String> terms, required dynamic value}) {
    final label = switch (value) {
      String() => value,
      Map() => value['description']?.toString() ?? value['name']?.toString(),
      _ => null,
    };
    if (label == null) return;

    final formatted = _formatLabel(label);
    if (formatted.isEmpty) return;

    final existing = terms.any(
      (term) => term.toLowerCase() == formatted.toLowerCase(),
    );
    if (!existing) {
      terms.add(formatted);
    }
  }

  String _formatLabel(String raw) {
    final withoutLocale = raw.contains(':') ? raw.split(':').last : raw;
    final cleaned = withoutLocale
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .trim();
    if (cleaned.isEmpty || cleaned.length > 40) return '';

    return cleaned
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.length == 1) return word.toUpperCase();
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }
}
