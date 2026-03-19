import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../models/school_models.dart';

// Key format: classId_sectionId
class RoutineNotifier extends ChangeNotifier {
  Map<String, List<RoutineEntry>> _state = {};
  bool _isLoading = false;

  Map<String, List<RoutineEntry>> get state => _state;
  bool get isLoading => _isLoading;

  void addEntry(String classId, String sectionId, RoutineEntry entry) {
    log('Adding entry locally: classId=$classId, sectionId=$sectionId');
    final key = '${classId}_$sectionId';
    final currentEntries = _state[key] ?? [];
    _state = {
      ..._state,
      key: [...currentEntries, entry],
    };
    notifyListeners();
  }

  Future<void> addRoutineToAPI(
    String classId,
    String sectionId,
    RoutineEntry entry,
  ) async {
    log('Attempting to add routine to API: classId=$classId, sectionId=$sectionId');
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        log('Error: No auth token found');
        throw Exception('No auth token found');
      }

      final payload = entry.toJson();
      log('Performing POST request to ${APIPath.createRoutine} with payload: $payload');

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.createRoutine,
        data: payload,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        log('Successfully created routine on server. Status: ${response.statusCode}');
        // Add locally after successful API call
        addEntry(classId, sectionId, entry);
      } else {
        log('Error creating routine: ${response?.statusCode} - ${response?.data}');
        throw Exception('Failed to create routine: ${response?.data}');
      }
    } catch (e) {
      log("Error in addRoutineToAPI: $e");
      rethrow;
    } finally {
      _isLoading = false;
      log('addRoutineToAPI execution finished');
      notifyListeners();
    }
  }

  void removeEntry(String classId, String sectionId, int index) {
    log('Removing entry locally: classId=$classId, sectionId=$sectionId, index=$index');
    final key = '${classId}_$sectionId';
    final currentEntries = _state[key] ?? [];
    if (index >= 0 && index < currentEntries.length) {
      final newList = [...currentEntries];
      newList.removeAt(index);
      _state = {..._state, key: newList};
      notifyListeners();
    }
  }

  List<RoutineEntry> getRoutine(String classId, String sectionId) {
    return _state['${classId}_$sectionId'] ?? [];
  }
}
