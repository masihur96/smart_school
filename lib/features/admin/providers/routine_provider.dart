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
        
        final dynamic returnedData = response.data is Map ? (response.data['data'] ?? response.data) : response.data;
        final routineId = returnedData is Map ? (returnedData['_id'] ?? returnedData['id'])?.toString() : null;

        final newEntry = RoutineEntry(
          id: routineId,
          classId: entry.classId,
          schoolId: entry.schoolId,
          day: entry.day,
          startTime: entry.startTime,
          endTime: entry.endTime,
          subjectId: entry.subjectId,
          teacherId: entry.teacherId,
          roomNumber: entry.roomNumber,
        );

        // Add locally after successful API call
        addEntry(classId, sectionId, newEntry);
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

  Future<void> updateRoutineOnAPI(
    String classId,
    String sectionId,
    RoutineEntry entry,
  ) async {
    if (entry.id == null) throw Exception('Routine ID is required for update');
    log('Attempting to update routine in API: id=${entry.id}');
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final payload = entry.toJson();
      log('Performing PUT request to ${APIPath.createRoutine}/${entry.id} with payload: $payload');

      final response = await DataProvider().performRequest(
        'PUT',
        '${APIPath.createRoutine}/${entry.id}',
        data: payload,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        log('Successfully updated routine on server');
        // Update locally
        final key = '${classId}_$sectionId';
        final entries = _state[key] ?? [];
        final index = entries.indexWhere((e) => e.id == entry.id);
        if (index != -1) {
          final newEntries = [...entries];
          newEntries[index] = entry;
          _state = {..._state, key: newEntries};
        }
        notifyListeners();
      } else {
        log('Error updating routine: ${response?.statusCode} - ${response?.data}');
        throw Exception('Failed to update routine: ${response?.data}');
      }
    } catch (e) {
      log("Error in updateRoutineOnAPI: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeRoutineFromAPI(
    String classId,
    String sectionId,
    String routineId,
  ) async {
    log('Attempting to remove routine from API: id=$routineId');
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      log('Performing DELETE request to ${APIPath.createRoutine}/$routineId');
      final response = await DataProvider().performRequest(
        'DELETE',
        '${APIPath.createRoutine}/$routineId',
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 204)) {
        log('Successfully deleted routine on server');
        // Remove locally
        final key = '${classId}_$sectionId';
        final entries = _state[key] ?? [];
        final index = entries.indexWhere((e) => e.id == routineId);
        if (index != -1) {
          final newEntries = [...entries];
          newEntries.removeAt(index);
          _state = {..._state, key: newEntries};
        }
        notifyListeners();
      } else {
        log('Error deleting routine: ${response?.statusCode} - ${response?.data}');
        throw Exception('Failed to delete routine: ${response?.data}');
      }
    } catch (e) {
      log("Error in removeRoutineFromAPI: $e");
      rethrow;
    } finally {
      _isLoading = false;
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
