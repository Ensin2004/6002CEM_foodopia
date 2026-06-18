import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Service for sending Firebase Cloud Messaging (FCM) push notifications.
/// Uses server-side authentication with service account credentials.
class FcmSender {
  // Private constructor to prevent instantiation.
  FcmSender._();

  /// Singleton instance of the FCM sender.
  static final FcmSender instance = FcmSender._();

  // =========================================================================
  // CONSTANTS
  // =========================================================================

  /// Path to the service account JSON key file.
  static const String _serviceAccountAssetPath = 'assets/keys.json';

  /// OAuth scopes required for FCM.
  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  /// Reserved keys that need to be prefixed with 'x_'.
  static const Set<String> _reservedKeys = <String>{
    'from',
    'gcm',
    'google',
    'google.c.a.e',
    'google.c.fid',
    'google.c.sender.id',
    'aps',
  };

  // =========================================================================
  // AUTHENTICATION
  // =========================================================================

  /// Gets access credentials from the service account.
  Future<AccessCredentials> _getAccessCredentials() async {
    // Load the service account JSON.
    final jsonStr = await rootBundle.loadString(_serviceAccountAssetPath);

    // Parse credentials.
    final creds = ServiceAccountCredentials.fromJson(jsonStr);

    // Create an authenticated client.
    final client = await clientViaServiceAccount(creds, _scopes);

    // Get the access token.
    final access = client.credentials;

    // Close the client.
    client.close();

    return access;
  }

  /// Gets the project ID from the service account.
  Future<String> _getProjectId() async {
    // Load the service account JSON.
    final jsonStr = await rootBundle.loadString(_serviceAccountAssetPath);

    // Parse the JSON.
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;

    // Extract the project ID.
    final projectId = (map['project_id'] ?? '').toString();

    // Validate the project ID.
    if (projectId.isEmpty) {
      throw StateError('project_id missing from assets/keys.json.');
    }

    return projectId;
  }

  // =========================================================================
  // DATA SANITIZATION
  // =========================================================================

  /// Sanitizes data keys to avoid reserved keywords.
  Map<String, String> _sanitizeData(Map<String, dynamic>? data) {
    // Return empty map if no data.
    if (data == null) return const <String, String>{};

    // Create output map.
    final out = <String, String>{};

    // Process each key-value pair.
    data.forEach((key, value) {
      // Check if key is reserved.
      var safeKey = key.toString();

      // Prefix reserved keys with 'x_'.
      if (_reservedKeys.contains(safeKey) || safeKey.startsWith('google.')) {
        safeKey = 'x_$safeKey';
      }

      // Add to output.
      out[safeKey] = value?.toString() ?? '';
    });

    return out;
  }

  // =========================================================================
  // SEND NOTIFICATION
  // =========================================================================

  /// Sends a push notification to a device token.
  Future<bool> sendToToken({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Trim the token.
    final token = deviceToken.trim();

    // Return false if token is empty.
    if (token.isEmpty) return false;

    try {
      // Get access credentials.
      final access = await _getAccessCredentials();

      // Get project ID.
      final projectId = await _getProjectId();

      // Build the FCM endpoint URL.
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      // Build the payload.
      final payload = <String, dynamic>{
        'message': <String, dynamic>{
          'token': token,
          'notification': <String, String>{'title': title, 'body': body},
          'data': _sanitizeData(data),
          'android': <String, dynamic>{
            'priority': 'HIGH',
            'notification': <String, dynamic>{
              'channel_id': 'foodopia_social_notifications',
              'sound': 'default',
              if (data?['notificationId']?.toString().isNotEmpty == true)
                'tag': data!['notificationId'].toString(),
            },
          },
        },
      };

      // Send the request.
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${access.accessToken.data}',
        },
        body: jsonEncode(payload),
      );

      // Check response status.
      if (response.statusCode == 200) return true;

      // Log failure.
      debugPrint('[FCM] Send failed ${response.statusCode}: ${response.body}');
      return false;
    } catch (error, stackTrace) {
      // Log error.
      debugPrint('[FCM] Send error: $error\n$stackTrace');
      return false;
    }
  }
}