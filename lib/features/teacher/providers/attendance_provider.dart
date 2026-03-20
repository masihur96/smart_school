import 'dart:developer';
import 'package:flutter/material.dart';
import '../domain/entities/attendance.dart';
import '../domain/repositories/i_attendance_repository.dart';
import '../../../core/utils/storage_service.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../models/school_models.dart';

class AttendanceNotifier extends ChangeNotifier {
  final IAttendanceRepository _repository;
  List<AttendanceEntity> _state = [];
  bool _isLoading = false;

  AttendanceNotifier(this._repository) {
    _load(DateTime.now());
  }

  List<AttendanceEntity> get state => _state;
  bool get isLoading => _isLoading;

  Future<void> _load(DateTime date) async {
    _state = await _repository.getAttendanceForDate(date);
    notifyListeners();
  }

  Future<void> loadAll() async {
    _state = await _repository.getAllAttendance();
    notifyListeners();
  }

  Future<void> saveAttendance(List<AttendanceEntity> records) async {
    await _repository.saveAttendance(records);
    if (records.isNotEmpty) {
      await _load(records.first.date);
    }
  }

  List<AttendanceEntity> getRecordsForDate(DateTime date) {
    return _state
        .where(
          (r) =>
              r.date.year == date.year &&
              r.date.month == date.month &&
              r.date.day == date.day,
        )
        .toList();
  }

  Future<bool> submitAttendanceToAPI({
    required DateTime date,
    required String takenBy,
    required String classId,
    required Map<String, AttendanceStatus> attendanceMap,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final records = attendanceMap.entries.map((e) => {
            "studentId": e.key,
            "status": e.value.name,
          }).toList();

      final data = {
        "date": dateString,
        "takenBy": takenBy,
        "classId": classId,
        "records": records,
      };

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.submitAttendance,
        data: data,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        log('Successfully submitted attendance');
        return true;
      } else {
        log('Error submitting attendance: ${response?.data}');
        return false;
      }
    } catch (e) {
      log('Error submitting attendance: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<List<Map<String, dynamic>>> fetchAttendanceFromAPI({
    required String classId,
    required DateTime date,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.submitAttendance,
        query: {
          'classId': classId,
          'date': dateString,
        },
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data['data'];
        
        if (data is List && data.isNotEmpty) {
          // If it's a list, take the first attendance document
          final firstDoc = data.first;
          if (firstDoc != null && firstDoc['records'] != null) {
            return List<Map<String, dynamic>>.from(firstDoc['records']);
          }
        } else if (data is Map && data['records'] != null) {
          // In case the backend returns a single object
          return List<Map<String, dynamic>>.from(data['records']);
        }
      }
      return [];
    } catch (e) {
      log('Error fetching attendance: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
