import 'dart:developer';
import 'package:flutter/material.dart';
import '../domain/entities/attendance.dart';
import '../domain/repositories/i_attendance_repository.dart';
import '../../../core/utils/storage_service.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../models/school_models.dart';
import '../../../services/notification_service.dart';

class AttendanceNotifier extends ChangeNotifier {
  final IAttendanceRepository _repository;
  List<AttendanceEntity> _state = [];
  bool _isLoading = false;
  AttendanceOverview? _overviewSummary;

  AttendanceNotifier(this._repository) {
    _load(DateTime.now());
  }

  List<AttendanceEntity> get state => _state;
  bool get isLoading => _isLoading;
  AttendanceOverview? get overviewSummary => _overviewSummary;

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
    String? sectionId,
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
        if (sectionId != null && sectionId.isNotEmpty) "sectionId": sectionId,
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
        // Trigger notification
        NotificationService().triggerNotification(
          title: 'Attendance Submitted',
          body: 'Attendance for class ${classId} has been submitted on ${dateString}.',
          topic: 'class_${classId}',
          data: {
            'type': 'attendance',
            'classId': classId,
            'sectionId': sectionId,
            'date': dateString,
          },
        );
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
  AttendanceStatus _parseStatus(dynamic status) {
    if (status == null) return AttendanceStatus.present;
    final statusStr = status.toString().toLowerCase();
    return AttendanceStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusStr,
      orElse: () => AttendanceStatus.present,
    );
  }

  Future<void> fetchAttendanceFromAPI({
    required String classId,
    String? sectionId,
    required DateTime date,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final query = <String, dynamic>{
        'classId': classId,
        'date': dateString,
      };
      if (sectionId != null && sectionId.isNotEmpty) {
        query['sectionId'] = sectionId;
      }

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.submitAttendance,
        query: query,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        log("Attendance Response:: ${response.data}");
        final rawData = response.data['data'];
        final List<AttendanceEntity> fetchedRecords = [];

        if (rawData is List) {
          for (var item in rawData) {
            if (item is Map) {
              if (item.containsKey('records') && item['records'] is List) {
                // Nested records case (e.g. daily documentation)
                final docDateStr = item['date']?.toString() ?? '';
                final docDate = DateTime.tryParse(docDateStr) ?? date;
                final docTakenBy = item['takenBy']?.toString() ?? '';
                final recordsRaw = List<Map<String, dynamic>>.from(item['records']);
                for (var r in recordsRaw) {
                  fetchedRecords.add(AttendanceEntity(
                    id: r['id']?.toString() ?? '',
                    studentId: r['studentId']?.toString() ?? '',
                    date: docDate,
                    status: _parseStatus(r['status']),
                    takenBy: docTakenBy,
                  ));
                }
              } else {
                // Flat record case (individual record)
                final recDateStr = item['date']?.toString() ?? '';
                final recDate = DateTime.tryParse(recDateStr) ?? date;
                fetchedRecords.add(AttendanceEntity(
                  id: item['id']?.toString() ?? '',
                  studentId: item['studentId']?.toString() ?? '',
                  date: recDate,
                  status: _parseStatus(item['status']),
                  takenBy: item['takenBy']?.toString() ?? '',
                ));
              }
            }
          }
        } else if (rawData is Map) {
          // Single record object
          if (rawData.containsKey('records') && rawData['records'] is List) {
            final docDateStr = rawData['date']?.toString() ?? '';
            final docDate = DateTime.tryParse(docDateStr) ?? date;
            final docTakenBy = rawData['takenBy']?.toString() ?? '';
            final recordsRaw = List<Map<String, dynamic>>.from(rawData['records']);
            for (var r in recordsRaw) {
              fetchedRecords.add(AttendanceEntity(
                id: r['id']?.toString() ?? '',
                studentId: r['studentId']?.toString() ?? '',
                date: docDate,
                status: _parseStatus(r['status']),
                takenBy: docTakenBy,
              ));
            }
          }
        }

        // Update state for this date
        _state.removeWhere((r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day);
        _state.addAll(fetchedRecords);
        log('Fetched ${fetchedRecords.length} attendance records for $dateString');
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
        final List<AttendanceEntity> fetchedRecords = [];

        if (data is List) {
          for (var item in data) {
            if (item is Map) {
              if (item.containsKey('records') && item['records'] is List) {
                // Document with multiple records
                final docDateStr = item['date']?.toString() ?? '';
                final docDate = DateTime.tryParse(docDateStr) ?? DateTime.now();
                final docTakenBy = item['takenBy']?.toString() ?? '';
                final recordsRaw = List<Map<String, dynamic>>.from(item['records']);
                for (var r in recordsRaw) {
                  fetchedRecords.add(AttendanceEntity(
                    id: r['id']?.toString() ?? '',
                    studentId: r['studentId']?.toString() ?? '',
                    date: docDate,
                    status: _parseStatus(r['status']),
                    takenBy: docTakenBy,
                  ));
                }
              } else {
                // Individual record
                final recDateStr = item['date']?.toString() ?? '';
                final recDate = DateTime.tryParse(recDateStr) ?? DateTime.now();
                fetchedRecords.add(AttendanceEntity(
                  id: item['id']?.toString() ?? '',
                  studentId: item['studentId']?.toString() ?? '',
                  date: recDate,
                  status: _parseStatus(item['status']),
                  takenBy: item['takenBy']?.toString() ?? '',
                ));
              }
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

  Future<void> fetchAttendanceOverview({int? year, int? month}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final now = DateTime.now();
      final qYear = year ?? now.year;
      final qMonth = month ?? now.month;

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.attendanceOverview,
        query: {
          'year': qYear.toString(),
          'month': qMonth.toString(),
        },
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          _overviewSummary = AttendanceOverview.fromJson(data);
          log('Fetched attendance overview for $qMonth/$qYear');
        }
      }
    } catch (e) {
      log('Error fetching attendance overview: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
