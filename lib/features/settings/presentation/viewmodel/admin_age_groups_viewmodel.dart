import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Admin state for adding and managing selectable age groups.
class AdminAgeGroupsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _ageGroups = [];

  AdminAgeGroupsViewModel({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    loadAgeGroups();
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get ageGroups => _ageGroups;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('app_config').doc('age_groups').collection('items');

  Future<void> loadAgeGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _collection.orderBy('sortOrder').get();
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
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveAgeGroup({
    String? id,
    required String name,
    required String description,
    required int sortOrder,
    required bool isActive,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Age group name cannot be empty';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {
        'name': trimmedName,
        'description': description.trim(),
        'sortOrder': sortOrder,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (id == null) {
        await _collection.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _collection.doc(id).update(data);
      }

      await loadAgeGroups();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reorderAgeGroups({
    required int oldIndex,
    required int newIndex,
  }) async {
    final items = List<Map<String, dynamic>>.from(_ageGroups);
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex < 0 || oldIndex >= items.length) return false;
    if (newIndex < 0 || newIndex >= items.length) return false;

    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex, movedItem);
    _ageGroups = [
      for (var i = 0; i < items.length; i++) {...items[i], 'sortOrder': i + 1},
    ];
    notifyListeners();

    try {
      final batch = _firestore.batch();
      for (var i = 0; i < _ageGroups.length; i++) {
        batch.update(_collection.doc(_ageGroups[i]['id'] as String), {
          'sortOrder': i + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      await loadAgeGroups();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAgeGroup(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _collection.doc(id).delete();
      await loadAgeGroups();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
