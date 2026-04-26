import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

// ============================================================================
// CLOUDINARY SERVICE
// ============================================================================
// Handles image uploads to Cloudinary for:
// - User profile pictures
// - Support/Help Center images
// - FAQ images
// - Rating/Feedback images
// ============================================================================

class CloudinaryService {
  // Private constructor to prevent instantiation
  CloudinaryService._();

  static String get _cloudName => EnvConfig.cloudinaryCloudName;
  static String get _userProfileUploadPreset => EnvConfig.userProfileUploadPreset;
  static String get _settingsUploadPreset => EnvConfig.settingsUploadPreset;

  /// Base URL for Cloudinary uploads
  static String _getUploadUrl() {
    return 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
  }

  /// Generic upload method
  static Future<String> _uploadImage(File imageFile, String uploadPreset) async {
    try {
      final uri = Uri.parse(_getUploadUrl());
      final request = http.MultipartRequest('POST', uri);

      // Add upload preset
      request.fields['upload_preset'] = uploadPreset;

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Send request
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final json = jsonDecode(responseData);
        return json['secure_url'];
      } else {
        final responseData = await response.stream.bytesToString();
        throw Exception('Upload failed (${response.statusCode}): $responseData');
      }
    } catch (e) {
      throw Exception('Cloudinary upload error: $e');
    }
  }

  /// Upload user profile image
  static Future<String> uploadUserProfileImage(File imageFile) async {
    return await _uploadImage(imageFile, _userProfileUploadPreset);
  }

  /// Upload settings-related images (help center, FAQ, ratings)
  static Future<String> uploadSettingsImage(File imageFile) async {
    return await _uploadImage(imageFile, _settingsUploadPreset);
  }

  // For backward compatibility with existing code
  static Future<String> uploadSupportImage(File imageFile) async {
    return await uploadSettingsImage(imageFile);
  }

  static Future<String> uploadFaqImage(File imageFile) async {
    return await uploadSettingsImage(imageFile);
  }

  static Future<String> uploadRatingImage(File imageFile) async {
    return await uploadSettingsImage(imageFile);
  }
}