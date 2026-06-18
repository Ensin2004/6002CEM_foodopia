import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

/// Service for finding ingredient images from Unsplash.
class UnsplashIngredientImageService {
  final http.Client client;
  final String unsplashAccessKey;
  final Map<String, String?> _cache = {};

  UnsplashIngredientImageService({
    required this.client,
    this.unsplashAccessKey = EnvConfig.unsplashAccessKey,
  });

  /// Searches Unsplash by ingredient name and returns one public image URL.
  Future<String?> findIngredientImageUrl(String ingredientName) async {
    final query = ingredientName.trim().toLowerCase();
    if (query.length < 2) return null;

    if (_cache.containsKey(query)) return _cache[query];

    final imageUrl = await _findUnsplashImageUrl(query);
    _cache[query] = imageUrl;
    _logImageLookup(
      query,
      imageUrl == null ? 'no unsplash image found' : 'unsplash image found',
    );
    return imageUrl;
  }

  Future<String?> _findUnsplashImageUrl(String query) async {
    if (unsplashAccessKey.trim().isEmpty) {
      _logImageLookup(query, 'unsplash key is empty');
      return null;
    }

    final uri = Uri.https('api.unsplash.com', '/search/photos', {
      'client_id': unsplashAccessKey,
      'query': query,
      'per_page': '1',
      'orientation': 'squarish',
      'content_filter': 'high',
    });

    try {
      final response = await client
          .get(
            uri,
            headers: const {
              'User-Agent': 'Foodopia/1.0 (ingredient image search)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _logImageLookup(query, 'unsplash status ${response.statusCode}');
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final results = decoded['results'];
      if (results is! List || results.isEmpty) {
        _logImageLookup(query, 'unsplash returned no results');
        return null;
      }

      final first = results.first;
      if (first is! Map<String, dynamic>) return null;

      final urls = first['urls'];
      if (urls is! Map) return null;

      final smallUrl = urls['small']?.toString().trim() ?? '';
      if (smallUrl.isNotEmpty) return smallUrl;

      final regularUrl = urls['regular']?.toString().trim() ?? '';
      return regularUrl.isEmpty ? null : regularUrl;
    } catch (_) {
      _logImageLookup(query, 'unsplash request failed');
      return null;
    }
  }

  void _logImageLookup(String query, String message) {
    developer.log('$message for "$query"', name: 'FoodopiaIngredientImages');
  }
}
