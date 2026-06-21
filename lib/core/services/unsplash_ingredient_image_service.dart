import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

/// Service for finding ingredient images from Unsplash.
///
/// Handles the communication with Unsplash API to retrieve relevant images
/// for ingredient names. Implements caching to avoid redundant API calls
/// and provides logging for debugging image lookup operations.
class UnsplashIngredientImageService {
  final http.Client client;
  final String unsplashAccessKey;
  final Map<String, String?> _cache = {};

  UnsplashIngredientImageService({
    required this.client,
    this.unsplashAccessKey = EnvConfig.unsplashAccessKey,
  });

  /// Searches Unsplash by ingredient name and returns one public image URL.
  ///
  /// Takes an [ingredientName] string and returns a [Future] that completes
  /// with an optional image URL string. Returns null if no suitable image
  /// is found or if the lookup fails. The result is cached for future calls
  /// with the same ingredient name.
  Future<String?> findIngredientImageUrl(String ingredientName) async {
    // Normalize the ingredient name by trimming whitespace and converting to lowercase.
    final query = ingredientName.trim().toLowerCase();

    // Reject queries that are too short to produce meaningful search results.
    if (query.length < 2) return null;

    // Check the in-memory cache first to avoid unnecessary API calls.
    if (_cache.containsKey(query)) return _cache[query];

    // Perform the actual Unsplash search if not found in cache.
    final imageUrl = await _findUnsplashImageUrl(query);

    // Store the result in cache regardless of whether an image was found.
    _cache[query] = imageUrl;

    // Log the outcome of the image lookup operation for debugging purposes.
    _logImageLookup(
      query,
      imageUrl == null ? 'no unsplash image found' : 'unsplash image found',
    );
    return imageUrl;
  }

  /// Internal method that performs the actual Unsplash API request.
  ///
  /// Constructs the search request with appropriate parameters including
  /// content filtering and image orientation. Handles the HTTP response
  /// and extracts the image URL from the JSON response payload.
  Future<String?> _findUnsplashImageUrl(String query) async {
    // Verify that the Unsplash access key is configured and not empty.
    if (unsplashAccessKey.trim().isEmpty) {
      _logImageLookup(query, 'unsplash key is empty');
      return null;
    }

    // Build the HTTPS request URI with search parameters.
    // The 'squarish' orientation and 'high' content filter ensure quality results.
    final uri = Uri.https('api.unsplash.com', '/search/photos', {
      'client_id': unsplashAccessKey,
      'query': query,
      'per_page': '1',
      'orientation': 'squarish',
      'content_filter': 'high',
    });

    try {
      // Execute the GET request with a timeout to prevent hanging.
      final response = await client
          .get(
        uri,
        headers: const {
          'User-Agent': 'Foodopia/1.0 (ingredient image search)',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 6));

      // Check for unsuccessful HTTP status codes and log the failure.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _logImageLookup(query, 'unsplash status ${response.statusCode}');
        return null;
      }

      // Parse the JSON response body into a Map structure.
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      // Extract the results array from the response.
      final results = decoded['results'];
      if (results is! List || results.isEmpty) {
        _logImageLookup(query, 'unsplash returned no results');
        return null;
      }

      // Retrieve the first result from the list.
      final first = results.first;
      if (first is! Map<String, dynamic>) return null;

      // Navigate to the URLs object within the result.
      final urls = first['urls'];
      if (urls is! Map) return null;

      // Try to get the 'small' URL first as it's more efficient for display.
      final smallUrl = urls['small']?.toString().trim() ?? '';
      if (smallUrl.isNotEmpty) return smallUrl;

      // Fall back to 'regular' URL if 'small' is not available.
      final regularUrl = urls['regular']?.toString().trim() ?? '';
      return regularUrl.isEmpty ? null : regularUrl;
    } catch (_) {
      // Catch any exceptions (network errors, timeouts, parsing issues) and log them.
      _logImageLookup(query, 'unsplash request failed');
      return null;
    }
  }

  /// Logs the image lookup result for debugging and monitoring purposes.
  ///
  /// Uses the developer logging system to record the outcome of each
  /// ingredient image search attempt with a consistent logging name.
  void _logImageLookup(String query, String message) {
    developer.log('$message for "$query"', name: 'FoodopiaIngredientImages');
  }
}