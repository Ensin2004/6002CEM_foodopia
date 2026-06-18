import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

/// Service for searching foods using the USDA Food Data Central API.
/// Provides food search, nutrient lookup, and name formatting.
class FoodSearchService {
  // =========================================================================
  // CONSTANTS
  // =========================================================================

  /// Preferred USDA data types for search results.
  /// Uses generic/foundational datasets first to avoid supermarket brand clutter.
  static const List<String> _preferredDataTypes = [
    'Foundation',
    'SR Legacy',
    'Survey (FNDDS)',
  ];

  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// HTTP client for making API requests.
  final http.Client client;

  /// USDA API key.
  final String apiKey;

  // =========================================================================
  // CACHES
  // =========================================================================

  /// Cache for food term search results.
  final Map<String, List<String>> _cache = {};

  /// Cache for USDA food search results.
  final Map<String, List<UsdaFoodSearchResult>> _usdaSearchCache = {};

  /// Cache for label nutrients by FDC ID.
  final Map<int, Map<String, dynamic>> _labelNutrientsCache = {};

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Creates a new food search service instance.
  FoodSearchService({required this.client, this.apiKey = EnvConfig.usdaApiKey});

  // =========================================================================
  // FOOD TERM SEARCH
  // =========================================================================

  /// Searches for food terms matching a query.
  Future<List<String>> searchFoodTerms(String query) async {
    // Trim and lowercase the query.
    final trimmed = query.trim().toLowerCase();

    // Avoid searching very short text because USDA results become too broad.
    if (trimmed.length < 2) return [];

    // Check cache.
    final cached = _cache[trimmed];
    if (cached != null) return cached;

    // Return empty if API key is missing.
    if (apiKey.trim().isEmpty) return [];

    // Collect unique terms.
    final terms = <String>{};

    // Search preferred USDA data types one by one.
    for (final dataType in _preferredDataTypes) {
      final foods = await _fetchFoods(trimmed, dataType: dataType);
      _addFoodNames(terms, foods);
      if (terms.length >= 10) break;
    }

    // Fallback to full search if no results found.
    if (terms.isEmpty) {
      final fallbackFoods = await _fetchFoods(trimmed);
      _addFoodNames(terms, fallbackFoods);
    }

    // Cache and return results.
    final results = terms.take(10).toList();
    _cache[trimmed] = results;
    return results;
  }

  // =========================================================================
  // USDA FOOD SEARCH
  // =========================================================================

  /// Searches for USDA foods matching a query.
  Future<List<UsdaFoodSearchResult>> searchUsdaFoods(String query) async {
    // Trim and lowercase the query.
    final trimmed = query.trim().toLowerCase();

    // Avoid searching very short text.
    if (trimmed.length < 2) return [];

    // Check cache.
    final cached = _usdaSearchCache[trimmed];
    if (cached != null) return cached;

    // Return empty if API key is missing.
    if (apiKey.trim().isEmpty) return [];

    // Collect results.
    final results = <UsdaFoodSearchResult>[];

    // Search preferred USDA data types one by one.
    for (final dataType in _preferredDataTypes) {
      final foods = await _fetchFoods(trimmed, dataType: dataType);
      _addUsdaFoodResults(results, foods);
      if (results.length >= 10) break;
    }

    // Fallback to full search if no results found.
    if (results.isEmpty) {
      final fallbackFoods = await _fetchFoods(trimmed);
      _addUsdaFoodResults(results, fallbackFoods);
    }

    // Cache and return results.
    final limitedResults = results.take(10).toList();
    _usdaSearchCache[trimmed] = limitedResults;
    return limitedResults;
  }

  // =========================================================================
  // USDA LABEL NUTRIENTS
  // =========================================================================

  /// Retrieves label nutrients for a food by FDC ID.
  Future<Map<String, dynamic>?> getUsdaLabelNutrients(int fdcId) async {
    // Check cache.
    final cached = _labelNutrientsCache[fdcId];
    if (cached != null) return cached;

    // Return null if API key is missing.
    if (apiKey.trim().isEmpty) return null;

    // Build the API URL.
    final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/food/$fdcId', {
      'api_key': apiKey,
    });

    try {
      // Make the request.
      final response = await client
          .get(
        uri,
        headers: const {
          'User-Agent': 'Foodopia/1.0 (recipe ingredient nutrients)',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 6));

      // Handle error response.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      // Parse the response.
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      // Extract label nutrients.
      final labelNutrients = _cleanMap(decoded['labelNutrients']);
      if (labelNutrients.isEmpty) return null;

      // Cache and return.
      _labelNutrientsCache[fdcId] = labelNutrients;
      return labelNutrients;
    } catch (_) {
      // Return null on error.
      return null;
    }
  }

  // =========================================================================
  // PRIVATE API HELPERS
  // =========================================================================

  /// Fetches foods from the USDA API.
  Future<List<Map<String, dynamic>>> _fetchFoods(
      String query, {
        String? dataType,
      }) async {
    // Build query parameters.
    final queryParameters = <String, dynamic>{
      'api_key': apiKey,
      'query': query,
      'pageSize': '25',
    };

    // Add data type filter if provided.
    if (dataType != null) {
      queryParameters['dataType'] = dataType;
    }

    // Build the URL.
    final uri = Uri.https(
      'api.nal.usda.gov',
      '/fdc/v1/foods/search',
      queryParameters,
    );

    try {
      // Make the request.
      final response = await client
          .get(
        uri,
        headers: const {
          'User-Agent': 'Foodopia/1.0 (food preference search)',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 6));

      // Treat failed responses as empty.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      // Parse the response.
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return const [];

      // Extract foods list.
      final foods = decoded['foods'] is List ? decoded['foods'] as List : [];
      return foods.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      // Network, timeout, or JSON errors should not block the user flow.
      return const [];
    }
  }

  // =========================================================================
  // PRIVATE DATA HELPERS
  // =========================================================================

  /// Adds food names from a list to a set.
  void _addFoodNames(Set<String> terms, List<Map<String, dynamic>> foods) {
    for (final food in foods) {
      _addFoodName(terms: terms, value: food['description']);
    }
  }

  /// Adds a single food name to a set.
  void _addFoodName({required Set<String> terms, required dynamic value}) {
    // Skip non-string values.
    if (value is! String) return;

    // Format the food name.
    final formatted = _formatFoodName(value);
    if (formatted.isEmpty) return;

    // Check for duplicates ignoring case.
    final existing = terms.any(
          (term) => term.toLowerCase() == formatted.toLowerCase(),
    );

    // Add if not exists.
    if (!existing) {
      terms.add(formatted);
    }
  }

  /// Adds USDA food results to a list.
  void _addUsdaFoodResults(
      List<UsdaFoodSearchResult> results,
      List<Map<String, dynamic>> foods,
      ) {
    for (final food in foods) {
      // Extract FDC ID and name.
      final fdcId = food['fdcId'];
      final rawName = food['description'];

      // Skip invalid entries.
      if (fdcId is! int || rawName is! String) continue;

      // Format the name.
      final formatted = _formatFoodName(rawName);
      if (formatted.isEmpty) continue;

      // Check for duplicates.
      final exists = results.any((result) {
        return result.fdcId == fdcId ||
            result.name.toLowerCase() == formatted.toLowerCase();
      });
      if (exists) continue;

      // Add to results.
      results.add(UsdaFoodSearchResult(fdcId: fdcId, name: formatted));
    }
  }

  // =========================================================================
  // PRIVATE FORMATTING HELPERS
  // =========================================================================

  /// Formats a raw USDA food name for display.
  String _formatFoodName(String raw) {
    // USDA descriptions often look like "Milk, whole, 3.25% milkfat".
    // Use the first part so the chip label stays short and readable.
    final firstName = raw.split(',').first;

    // Clean up the name.
    final cleaned = firstName.replaceAll('-', ' ').replaceAll('_', ' ').trim();

    // Skip empty or unusually long names.
    if (cleaned.isEmpty || cleaned.length > 60) return '';

    // Convert to title case for display.
    return cleaned
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
      if (word.length == 1) return word.toUpperCase();
      return '${word[0].toUpperCase()}${word.substring(1)}';
    })
        .join(' ');
  }

  // =========================================================================
  // PRIVATE DATA CLEANING HELPERS
  // =========================================================================

  /// Cleans a map by removing null and empty values.
  Map<String, dynamic> _cleanMap(dynamic value) {
    // Return empty map if not a map.
    if (value is! Map) return const {};

    // Clean each entry.
    final clean = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key?.toString();
      if (key == null || key.isEmpty) continue;
      final cleanValue = _cleanValue(entry.value);
      if (cleanValue != null) clean[key] = cleanValue;
    }

    return clean;
  }

  /// Cleans a value recursively.
  dynamic _cleanValue(dynamic value) {
    // Return primitive values as-is.
    if (value == null || value is num || value is String || value is bool) {
      return value;
    }

    // Recursively clean maps.
    if (value is Map) return _cleanMap(value);

    // Recursively clean lists.
    if (value is List) {
      return value
          .map(_cleanValue)
          .where((item) => item != null)
          .toList(growable: false);
    }

    // Convert everything else to string.
    return value.toString();
  }
}

/// USDA food search result containing FDC ID and name.
class UsdaFoodSearchResult {
  /// USDA Food Data Central ID.
  final int fdcId;

  /// Formatted food name.
  final String name;

  /// Creates a new USDA food search result.
  const UsdaFoodSearchResult({required this.fdcId, required this.name});
}