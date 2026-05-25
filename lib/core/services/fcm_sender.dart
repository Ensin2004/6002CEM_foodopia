import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FcmSender {
  FcmSender._();

  static final FcmSender instance = FcmSender._();

  static const String _serviceAccountAssetPath = 'assets/keys.json';
  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/firebase.messaging',
  ];
  static const Set<String> _reservedKeys = <String>{
    'from',
    'gcm',
    'google',
    'google.c.a.e',
    'google.c.fid',
    'google.c.sender.id',
    'aps',
  };

  Future<AccessCredentials> _getAccessCredentials() async {
    final jsonStr = await rootBundle.loadString(_serviceAccountAssetPath);
    final creds = ServiceAccountCredentials.fromJson(jsonStr);
    final client = await clientViaServiceAccount(creds, _scopes);
    final access = client.credentials;
    client.close();
    return access;
  }

  Future<String> _getProjectId() async {
    final jsonStr = await rootBundle.loadString(_serviceAccountAssetPath);
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final projectId = (map['project_id'] ?? '').toString();
    if (projectId.isEmpty) {
      throw StateError('project_id missing from assets/keys.json.');
    }
    return projectId;
  }

  Map<String, String> _sanitizeData(Map<String, dynamic>? data) {
    if (data == null) return const <String, String>{};
    final out = <String, String>{};
    data.forEach((key, value) {
      var safeKey = key.toString();
      if (_reservedKeys.contains(safeKey) || safeKey.startsWith('google.')) {
        safeKey = 'x_$safeKey';
      }
      out[safeKey] = value?.toString() ?? '';
    });
    return out;
  }

  Future<bool> sendToToken({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final token = deviceToken.trim();
    if (token.isEmpty) return false;

    try {
      final access = await _getAccessCredentials();
      final projectId = await _getProjectId();
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );
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
            },
          },
        },
      };

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${access.accessToken.data}',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) return true;
      debugPrint('[FCM] Send failed ${response.statusCode}: ${response.body}');
      return false;
    } catch (error, stackTrace) {
      debugPrint('[FCM] Send error: $error\n$stackTrace');
      return false;
    }
  }
}
