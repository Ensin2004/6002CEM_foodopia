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

/// Service for uploading images to Cloudinary.
/// Handles different resource types with appropriate upload presets.
class CloudinaryService {
  // Private constructor to prevent instantiation.
  CloudinaryService._();

  // =========================================================================
  // CONFIGURATION GETTERS
  // =========================================================================

  /// Cloudinary cloud name.
  static String get _cloudName => EnvConfig.cloudinaryCloudName;

  /// Upload preset for user profile images.
  static String get _userProfileUploadPreset => EnvConfig.userProfileUploadPreset;

  /// Upload preset for settings images.
  static String get _settingsUploadPreset => EnvConfig.settingsUploadPreset;

  /// Upload preset for recipe images.
  static String get _recipeUploadPreset => EnvConfig.recipeUploadPreset;

  /// Upload preset for ingredient images.
  static String get _ingredientUploadPreset => EnvConfig.ingredientUploadPreset;

  /// Upload preset for instruction images.
  static String get _instructionUploadPreset => EnvConfig.instructionUploadPreset;

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Builds the Cloudinary upload URL for a resource type.
  static String _getUploadUrl({String resourceType = 'image'}) {
    return 'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload';
  }

  /// Validates that the Cloudinary configuration is present.
  static void _validateConfig(String uploadPreset) {
    if (_cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary configuration is missing. Run Flutter with '
            '--dart-define-from-file=.env',
      );
    }
  }

  // =========================================================================
  // GENERIC UPLOAD
  // =========================================================================

  /// Generic upload method for files.
  static Future<String> _uploadFile(
      File imageFile,
      String uploadPreset, {
        String resourceType = 'image',
      }) async {
    try {
      // Validate configuration.
      _validateConfig(uploadPreset);

      // Runs the guarded operation that can throw.
      final uri = Uri.parse(_getUploadUrl(resourceType: resourceType));

      // Create the multipart request.
      final request = http.MultipartRequest('POST', uri);

      // Add upload preset.
      request.fields['upload_preset'] = uploadPreset;

      // Add the image file.
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Send request.
      final response = await request.send();

      // Handle response.
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

  // =========================================================================
  // PUBLIC UPLOAD METHODS
  // =========================================================================

  /// Upload user profile image.
  static Future<String> uploadUserProfileImage(File imageFile) async {
    /// Handles the upload image operation.
    return await _uploadFile(imageFile, _userProfileUploadPreset);
  }

  /// Upload settings-related images (help center, FAQ, ratings).
  static Future<String> uploadSettingsImage(File imageFile) async {
    /// Handles the upload image operation.
    return await _uploadFile(imageFile, _settingsUploadPreset);
  }

  /// Upload recipe image and video.
  static Future<String> uploadRecipeImage(File imageFile) async {
    /// Handles the upload image operation.
    return await _uploadFile(imageFile, _recipeUploadPreset, resourceType: 'auto');
  }

  /// Upload ingredient image.
  static Future<String> uploadIngredientImage(File imageFile) async {
    /// Handles the upload image operation.
    return await _uploadFile(imageFile, _ingredientUploadPreset);
  }

  /// Upload instruction image.
  static Future<String> uploadInstructionImage(File imageFile) async {
    /// Handles the upload image operation.
    return await _uploadFile(imageFile, _instructionUploadPreset);
  }

  // =========================================================================
  // BACKWARD COMPATIBILITY
  // =========================================================================

  /// For backward compatibility with existing code.
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