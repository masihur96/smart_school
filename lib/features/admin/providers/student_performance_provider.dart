import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../models/admin_dashboard_model.dart';

class StudentPerformanceProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _selectedMonth = DateTime.now().month;
  int get selectedMonth => _selectedMonth;

  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  List<StudentPerformance> _allPerformances = [];
  List<StudentPerformance> get allPerformances => _allPerformances;

  /// Top performing students sorted by combined score descending
  List<StudentPerformance> get topPerformers {
    final sorted = [..._allPerformances];
    sorted.sort((a, b) {
      final scoreA = (a.attendance.percentage +
              a.homework.percentage +
              a.exams.percentage) /
          3;
      final scoreB = (b.attendance.percentage +
              b.homework.percentage +
              b.exams.percentage) /
          3;
      return scoreB.compareTo(scoreA);
    });
    return sorted.take(5).toList();
  }

  String _filterSearch = '';
  String get filterSearch => _filterSearch;

  String? _filterClass;
  String? get filterClass => _filterClass;

  List<StudentPerformance> get filteredPerformances {
    var list = [..._allPerformances];

    // Sort by combined score
    list.sort((a, b) {
      final scoreA = (a.attendance.percentage +
              a.homework.percentage +
              a.exams.percentage) /
          3;
      final scoreB = (b.attendance.percentage +
              b.homework.percentage +
              b.exams.percentage) /
          3;
      return scoreB.compareTo(scoreA);
    });

    if (_filterSearch.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(_filterSearch.toLowerCase()))
          .toList();
    }

    if (_filterClass != null && _filterClass!.isNotEmpty) {
      list = list
          .where((p) => p.classInfo?.name == _filterClass)
          .toList();
    }

    return list;
  }

  List<String> get availableClasses {
    final classes = <String>{};
    for (final p in _allPerformances) {
      if (p.classInfo?.name != null) classes.add(p.classInfo!.name);
    }
    return classes.toList()..sort();
  }

  void setMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  void setSearch(String value) {
    _filterSearch = value;
    notifyListeners();
  }

  void setClassFilter(String? className) {
    _filterClass = className;
    notifyListeners();
  }

  void applyDateFilter() {
    fetchPerformances(month: _selectedMonth, year: _selectedYear);
  }

  Future<void> fetchPerformances({int? month, int? year}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final m = month ?? _selectedMonth;
      final y = year ?? _selectedYear;

      // First, fetch all students
      final studentsResponse = await DataProvider().performRequest(
        'GET',
        APIPath.fetchUsers,
        query: {
          'role': 'student',
          'limit': '200',
          'page': '1',
        },
        header: {'Authorization': 'Bearer $token'},
      );

      if (studentsResponse == null || studentsResponse.statusCode != 200) {
        _error = 'Failed to load student list';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final inner = studentsResponse.data is Map
          ? studentsResponse.data['data']
          : studentsResponse.data;

      final List<dynamic> studentData = inner is List
          ? inner
          : (inner is Map ? (inner['data'] as List<dynamic>? ?? []) : []);

      log('Fetched ${studentData.length} students for performance.');

      // For each student, fetch their performance
      final List<StudentPerformance> performances = [];

      // Parallel fetches in chunks of 5
      const chunkSize = 5;
      for (int i = 0; i < studentData.length; i += chunkSize) {
        final chunk = studentData.skip(i).take(chunkSize).toList();
        final futures = chunk.map((s) async {
          final sid = s['userId']?.toString() ?? s['id']?.toString() ?? '';
          if (sid.isEmpty) return null;

          try {
            final perfResponse = await DataProvider().performRequest(
              'GET',
              '${APIPath.baseUrl}/performance/student?studentId=$sid&month=$m&year=$y',
              header: {'Authorization': 'Bearer $token'},
            );

            if (perfResponse != null && perfResponse.statusCode == 200) {
              final data = perfResponse.data['data'];
              if (data != null) {
                return StudentPerformance.fromJson(data);
              }
            }
          } catch (e) {
            log('Error fetching performance for student $sid: $e');
          }
          return null;
        });

        final results = await Future.wait(futures);
        for (final r in results) {
          if (r != null) performances.add(r);
        }
      }

      _allPerformances = performances;
      _selectedMonth = m;
      _selectedYear = y;
      log('Fetched performance for ${performances.length} students.');
    } catch (e) {
      _error = 'Error loading student performance: $e';
      log('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
