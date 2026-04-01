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
  Future<void> fetchAttendanceFromAPI({
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
        List<Map<String, dynamic>> recordsRaw = [];
        String takenBy = '';

        if (data is List && data.isNotEmpty) {
          final firstDoc = data.first;
          if (firstDoc != null) {
            recordsRaw = List<Map<String, dynamic>>.from(firstDoc['records'] ?? []);
            takenBy = firstDoc['takenBy']?.toString() ?? '';
          }
        } else if (data is Map) {
          recordsRaw = List<Map<String, dynamic>>.from(data['records'] ?? []);
          takenBy = data['takenBy']?.toString() ?? '';
        }

        // Convert raw records to AttendanceEntity and update state
        final List<AttendanceEntity> fetchedRecords = recordsRaw.map((r) {
          return AttendanceEntity(
            id: '', // Backend might not provide individual record IDs
            studentId: r['studentId']?.toString() ?? '',
            date: date,
            status: AttendanceStatus.values.firstWhere(
              (e) => e.name == r['status'],
              orElse: () => AttendanceStatus.absent,
            ),
            takenBy: takenBy,
          );
        }).toList();

        // Update state for this date
        _state.removeWhere((r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day);
        _state.addAll(fetchedRecords);
      }
    } catch (e) {
      log('Error fetching attendance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSchoolWideAttendance(String schoolId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.submitAttendance,
        query: {'schoolId': schoolId},
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data['data'];
        List<dynamic> allRecords = [];
        if (data is List) {
          allRecords = data;
        } else if (data is Map && data['data'] is List) {
          allRecords = data['data'];
        }

        final List<AttendanceEntity> fetchedRecords = [];
        for (var doc in allRecords) {
          if (doc is Map) {
            final dateStr = doc['date']?.toString() ?? '';
            final date = DateTime.tryParse(dateStr) ?? DateTime.now();
            final takenBy = doc['takenBy']?.toString() ?? '';
            final recordsRaw = List<Map<String, dynamic>>.from(doc['records'] ?? []);

            for (var r in recordsRaw) {
              fetchedRecords.add(AttendanceEntity(
                id: '',
                studentId: r['studentId']?.toString() ?? '',
                date: date,
                status: AttendanceStatus.values.firstWhere(
                  (e) => e.name == r['status'],
                  orElse: () => AttendanceStatus.absent,
                ),
                takenBy: takenBy,
              ));
            }
          }
        }

        // Replace state with latest school-wide records
        _state = fetchedRecords;
        log('Fetched ${fetchedRecords.length} school-wide attendance records');
      }
    } catch (e) {
      log('Error fetching school-wide attendance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
