import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Admin state for adding and managing selectable age groups.
/// Handles CRUD operations and reordering of age group options.
class AdminAgeGroupsViewModel extends ChangeNotifier {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// Firestore instance for database operations.
  final FirebaseFirestore _firestore;

  // =========================================================================
  // STATE
  // =========================================================================

  /// Whether data is loading.
  bool _isLoading = true;

  /// Whether saving is in progress.
  bool _isSaving = false;

  /// Error message from operations.
  String? _errorMessage;

  /// List of age groups with their data.
  List<Map<String, dynamic>> _ageGroups = [];

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Creates a new admin age groups view model instance.
  AdminAgeGroupsViewModel({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    // Load age groups on initialization.
    loadAgeGroups();
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// Whether data is loading.
  bool get isLoading => _isLoading;

  /// Whether saving is in progress.
  bool get isSaving => _isSaving;

  /// Error message from operations.
  String? get errorMessage => _errorMessage;

  /// List of age groups.
  List<Map<String, dynamic>> get ageGroups => _ageGroups;

  /// Reference to the age groups collection.
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('app_config').doc('age_groups').collection('items');

  // =========================================================================
  // LOAD
  // =========================================================================

  /// Loads age groups from Firestore.
  Future<void> loadAgeGroups() async {
    // Set loading state.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Query age groups ordered by sortOrder.
      final snapshot = await _collection.orderBy('sortOrder').get();

      // Map documents to maps.
      _ageGroups = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name']?.toString() ?? '',
          'description': data['description']?.toString() ?? '',
          'sortOrder': data['sortOrder'] is int ? data['sortOrder'] as int : 0,
          'isActive': data['isActive'] is bool
              ? data['isActive'] as bool
              : true,
        };
      }).toList();
    } catch (e) {
      // Handle error.
      _errorMessage = e.toString();
    }

    // Reset loading state.
    _isLoading = false;
    notifyListeners();
  }

  // =========================================================================
  // CREATE / UPDATE
  // =========================================================================

  /// Saves an age group (creates or updates).
  Future<bool> saveAgeGroup({
    String? id,
    required String name,
    required String description,
    required int sortOrder,
    required bool isActive,
  }) async {
    // Validate the name.
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Age group name cannot be empty';
      notifyListeners();
      return false;
    }

    // Set saving state.
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Prepare the data.
      final data = {
        'name': trimmedName,
        'description': description.trim(),
        'sortOrder': sortOrder,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create or update the document.
      if (id == null) {
        // Create new document.
        await _collection.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing document.
        await _collection.doc(id).update(data);
      }

      // Reload the list.
      await loadAgeGroups();

      // Reset saving state.
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Handle error.
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // =========================================================================
  // REORDER
  // =========================================================================

  /// Reorders age groups.
  Future<bool> reorderAgeGroups({
    required int oldIndex,
    required int newIndex,
  }) async {
    // Create a mutable copy of the list.
    final items = List<Map<String, dynamic>>.from(_ageGroups);

    // Adjust new index for removal.
    if (newIndex > oldIndex) newIndex -= 1;

    // Validate indices.
    if (oldIndex < 0 || oldIndex >= items.length) return false;
    if (newIndex < 0 || newIndex >= items.length) return false;

    // Reorder the list.
    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex, movedItem);

    // Update sort orders.
    _ageGroups = [
      for (var i = 0; i < items.length; i++) {...items[i], 'sortOrder': i + 1},
    ];

    // Notify listeners of optimistic update.
    notifyListeners();

    try {
      // Persist the new order to Firestore.
      final batch = _firestore.batch();

      // Update each document with its new sort order.
      for (var i = 0; i < _ageGroups.length; i++) {
        batch.update(_collection.doc(_ageGroups[i]['id'] as String), {
          'sortOrder': i + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit the batch.
      await batch.commit();
      return true;
    } catch (e) {
      // Handle error and revert.
      _errorMessage = e.toString();
      await loadAgeGroups();
      notifyListeners();
      return false;
    }
  }

  // =========================================================================
  // DELETE
  // =========================================================================

  /// Deletes an age group.
  Future<bool> deleteAgeGroup(String id) async {
    // Set saving state.
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delete the document.
      await _collection.doc(id).delete();

      // Reload the list.
      await loadAgeGroups();

      // Reset saving state.
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Handle error.
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}