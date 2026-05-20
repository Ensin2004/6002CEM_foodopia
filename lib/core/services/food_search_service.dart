import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

class FoodSearchService {
  // Prefer generic USDA food datasets first so allergy/dislike search does not
  // get crowded by branded supermarket products.
  static const List<String> _preferredDataTypes = [
    'Foundation',
    'SR Legacy',
    'Survey (FNDDS)',
  ];

  final http.Client client;
  final String apiKey;

  // Simple in-memory cache to avoid calling USDA repeatedly for the same query.
  final Map<String, List<String>> _cache = {};
  final Map<String, List<UsdaFoodSearchResult>> _usdaSearchCache = {};
  final Map<int, Map<String, dynamic>> _labelNutrientsCache = {};

  FoodSearchService({required this.client, this.apiKey = EnvConfig.usdaApiKey});

  Future<List<String>> searchFoodTerms(String query) async {
    final trimmed = query.trim().toLowerCase();

    // Avoid searching very short text because USDA results become too broad.
    if (trimmed.length < 2) return [];

    final cached = _cache[trimmed];
    if (cached != null) return cached;

    // If the API key is missing, fail quietly and show no search results.
    if (apiKey.trim().isEmpty) return [];

    final terms = <String>{};

    // Search preferred USDA data types one by one. GET requests work more
    // reliably when dataType is passed as a single value.
    for (final dataType in _preferredDataTypes) {
      final foods = await _fetchFoods(trimmed, dataType: dataType);
      _addFoodNames(terms, foods);
      if (terms.length >= 10) break;
    }

    // If no curated/generic USDA foods were found, try the full USDA search.
    if (terms.isEmpty) {
      final fallbackFoods = await _fetchFoods(trimmed);
      _addFoodNames(terms, fallbackFoods);
    }

    final results = terms.take(10).toList();
    _cache[trimmed] = results;
    return results;
  }

  Future<List<UsdaFoodSearchResult>> searchUsdaFoods(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.length < 2) return [];

    final cached = _usdaSearchCache[trimmed];
    if (cached != null) return cached;
    if (apiKey.trim().isEmpty) return [];

    final results = <UsdaFoodSearchResult>[];
    for (final dataType in _preferredDataTypes) {
      final foods = await _fetchFoods(trimmed, dataType: dataType);
      _addUsdaFoodResults(results, foods);
      if (results.length >= 10) break;
    }

    if (results.isEmpty) {
      final fallbackFoods = await _fetchFoods(trimmed);
      _addUsdaFoodResults(results, fallbackFoods);
    }

    final limitedResults = results.take(10).toList();
    _usdaSearchCache[trimmed] = limitedResults;
    return limitedResults;
  }

  Future<Map<String, dynamic>?> getUsdaLabelNutrients(int fdcId) async {
    final cached = _labelNutrientsCache[fdcId];
    if (cached != null) return cached;
    if (apiKey.trim().isEmpty) return null;

    final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/food/$fdcId', {
      'api_key': apiKey,
    });

    try {
      final response = await client
          .get(
            uri,
            headers: const {
              'User-Agent': 'Foodopia/1.0 (recipe ingredient nutrients)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final labelNutrients = _cleanMap(decoded['labelNutrients']);
      if (labelNutrients.isEmpty) return null;

      _labelNutrientsCache[fdcId] = labelNutrients;
      return labelNutrients;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFoods(
      String query, {
        String? dataType,
      }) async {
    final queryParameters = <String, dynamic>{
      'api_key': apiKey,
      'query': query,
      'pageSize': '25',
    };

    // Optional USDA category filter, for example "SR Legacy".
    if (dataType != null) {
      queryParameters['dataType'] = dataType;
    }

    final uri = Uri.https(
      'api.nal.usda.gov',
      '/fdc/v1/foods/search',
      queryParameters,
    );

    try {
      final response = await client
          .get(
        uri,
        headers: const {
          'User-Agent': 'Foodopia/1.0 (food preference search)',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 6));

      // Treat failed USDA responses as empty results instead of crashing setup.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return const [];

      final foods = decoded['foods'] is List ? decoded['foods'] as List : [];
      return foods.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      // Network, timeout, or JSON errors should not block the user flow.
      return const [];
    }
  }

  void _addFoodNames(Set<String> terms, List<Map<String, dynamic>> foods) {
    for (final food in foods) {
      _addFoodName(terms: terms, value: food['description']);
    }
  }

  void _addFoodName({required Set<String> terms, required dynamic value}) {
    if (value is! String) return;

    final formatted = _formatFoodName(value);
    if (formatted.isEmpty) return;

    // Keep results unique, ignoring letter case.
    final existing = terms.any(
          (term) => term.toLowerCase() == formatted.toLowerCase(),
    );

    if (!existing) {
      terms.add(formatted);
    }
  }

  void _addUsdaFoodResults(
      List<UsdaFoodSearchResult> results,
      List<Map<String, dynamic>> foods,
      ) {
    for (final food in foods) {
      final fdcId = food['fdcId'];
      final rawName = food['description'];
      if (fdcId is! int || rawName is! String) continue;

      final formatted = _formatFoodName(rawName);
      if (formatted.isEmpty) continue;

      final exists = results.any((result) {
        return result.fdcId == fdcId ||
            result.name.toLowerCase() == formatted.toLowerCase();
      });
      if (exists) continue;

      results.add(UsdaFoodSearchResult(fdcId: fdcId, name: formatted));
    }
  }

  String _formatFoodName(String raw) {
    // USDA descriptions often look like "Milk, whole, 3.25% milkfat".
    // Use the first part so the chip label stays short and readable.
    final firstName = raw.split(',').first;

    final cleaned = firstName.replaceAll('-', ' ').replaceAll('_', ' ').trim();

    // Skip empty or unusually long names because they do not work well as chips.
    if (cleaned.isEmpty || cleaned.length > 60) return '';

    // Convert the USDA text into simple title case for display.
    return cleaned
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
      if (word.length == 1) return word.toUpperCase();
      return '${word[0].toUpperCase()}${word.substring(1)}';
    })
        .join(' ');
  }

  Map<String, dynamic> _cleanMap(dynamic value) {
    if (value is! Map) return const {};

    final clean = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key?.toString();
      if (key == null || key.isEmpty) continue;
      final cleanValue = _cleanValue(entry.value);
      if (cleanValue != null) clean[key] = cleanValue;
    }
    return clean;
  }

  dynamic _cleanValue(dynamic value) {
    if (value == null || value is num || value is String || value is bool) {
      return value;
    }
    if (value is Map) return _cleanMap(value);
    if (value is List) {
      return value
          .map(_cleanValue)
          .where((item) => item != null)
          .toList(growable: false);
    }
    return value.toString();
  }
}

class UsdaFoodSearchResult {
  final int fdcId;
  final String name;

  const UsdaFoodSearchResult({required this.fdcId, required this.name});
}
