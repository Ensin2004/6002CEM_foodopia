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

  /// Handles the cloud name operation.
  static String get _cloudName => EnvConfig.cloudinaryCloudName;
  /// Handles the user profile upload preset operation.
  static String get _userProfileUploadPreset => EnvConfig.userProfileUploadPreset;
  /// Handles the settings upload preset operation.
  static String get _settingsUploadPreset => EnvConfig.settingsUploadPreset;
  /// Handles the recipe upload preset operation.
  static String get _recipeUploadPreset => EnvConfig.recipeUploadPreset;
  /// Handles the ingredient upload preset operation.
  static String get _ingredientUploadPreset => EnvConfig.ingredientUploadPreset;
  /// Handles the instruction upload preset operation.
  static String get _instructionUploadPreset => EnvConfig.recipeUploadPreset;

  /// Base URL for Cloudinary uploads
  static String _getUploadUrl() {
    return 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
  }

  static void _validateConfig(String uploadPreset) {
    if (_cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary configuration is missing. Run Flutter with '
        '--dart-define-from-file=.env',
      );
    }
  }

  /// Generic upload method
  static Future<String> _uploadImage(File imageFile, String uploadPreset) async {
    try {
      _validateConfig(uploadPreset);

      // Runs the guarded operation that can throw.
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
        /// Handles the exception operation.
        throw Exception('Upload failed (${response.statusCode}): $responseData');
      }
    } catch (e) {
      /// Handles the exception operation.
      throw Exception('Cloudinary upload error: $e');
    }
  }

  /// Upload user profile image
  static Future<String> uploadUserProfileImage(File imageFile) async {
    /// Handles the upload image operation.
    return await _uploadImage(imageFile, _userProfileUploadPreset);
  }

  /// Upload settings-related images (help center, FAQ, ratings)
  static Future<String> uploadSettingsImage(File imageFile) async {
    /// Handles the upload image operation.
    return await _uploadImage(imageFile, _settingsUploadPreset);
  }

  /// Upload recipe image and video
  static Future<String> uploadRecipeImage(File imageFile) async {
    /// Handles the upload image operation.
    return await _uploadImage(imageFile, _recipeUploadPreset);
  }

  /// Upload ingredient image
  static Future<String> uploadIngredientImage(File imageFile) async {
    /// Handles the upload image operation.
    return await _uploadImage(imageFile, _ingredientUploadPreset);
  }

  /// Upload instruction image
  static Future<String> uploadInstructionImage(File imageFile) async {
    /// Handles the upload image operation.
    return await _uploadImage(imageFile, _instructionUploadPreset);
  }

  // For backward compatibility with existing code
  static Future<String> uploadSupportImage(File imageFile) async {
    /// Runs the upload settings image operation.
    return await uploadSettingsImage(imageFile);
  }

  /// Runs the upload faq image operation.
  static Future<String> uploadFaqImage(File imageFile) async {
    /// Runs the upload settings image operation.
    return await uploadSettingsImage(imageFile);
  }

  /// Runs the upload rating image operation.
  static Future<String> uploadRatingImage(File imageFile) async {
    /// Runs the upload settings image operation.
    return await uploadSettingsImage(imageFile);
  }
}
