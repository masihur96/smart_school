import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../../../models/school_models.dart';

class StudentRoutineNotifier extends ChangeNotifier {
  List<RoutineEntry> _routineEntries = [];
  bool _isLoading = false;
  String? _error;

  List<RoutineEntry> get routineEntries => _routineEntries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRoutine(String classId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();


    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.studentRoutine,
        query: {'classId': classId},
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List data = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);
        
        _routineEntries = data.map((json) => RoutineEntry.fromJson(json)).toList();
        log('Fetched ${_routineEntries.length} student routine entries for class $classId');
      } else {
        _error = 'Failed to fetch routine: ${response?.statusCode}';
        log('Error fetching student routine: ${response?.data}');
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception fetching student routine: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
