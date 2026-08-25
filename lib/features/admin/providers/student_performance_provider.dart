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

  int _selectedMonth = 2;
  int get selectedMonth => _selectedMonth;

  int _selectedYear = 2026;
  int get selectedYear => _selectedYear;

  // All raw performances loaded from API
  List<StudentPerformance> _allPerformances = [];
  List<StudentPerformance> get allPerformances => _allPerformances;

  // UI-only filters (do NOT re-fetch from API)
  String _filterSearch = '';
  String get filterSearch => _filterSearch;

  String? _filterClass;
  String? get filterClass => _filterClass;

  String? _filterSection;
  String? get filterSection => _filterSection;

  // Selected student for individual detail view
  StudentPerformance? _selectedStudent;
  StudentPerformance? get selectedStudent => _selectedStudent;

  // Performances sorted best→worst (descending score)
  List<StudentPerformance> get sortedByBest {
    final sorted = [..._allPerformances];
    sorted.sort((a, b) => _score(b).compareTo(_score(a)));
    return sorted;
  }

  // Filtered + sorted list used in the full screen
  List<StudentPerformance> get filteredPerformances {
    var list = sortedByBest;

    if (_filterSearch.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(_filterSearch.toLowerCase()))
          .toList();
    }

    if (_filterClass != null && _filterClass!.isNotEmpty) {
      list = list.where((p) => p.classInfo?.name == _filterClass).toList();
    }

    if (_filterSection != null && _filterSection!.isNotEmpty) {
      list = list.where((p) => p.section?.name == _filterSection).toList();
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

  List<String> get availableSections {
    final sections = <String>{};
    for (final p in _allPerformances) {
      if (_filterClass != null && p.classInfo?.name != _filterClass) {
        continue;
      }
      if (p.section?.name != null) sections.add(p.section!.name);
    }
    return sections.toList()..sort();
  }

  // All student names for dropdown search
  List<String> get studentNames =>
      _allPerformances.map((p) => p.name).toList()..sort();

  double _score(StudentPerformance p) {
    double total = 0;
    int count = 0;
    // Only include attendance if working days were tracked
    if (p.attendance.totalWorkingDays > 0) {
      total += p.attendance.percentage;
      count++;
    }
    // Only include homework if assignments were given
    if (p.homework.totalAssigned > 0) {
      total += p.homework.percentage;
      count++;
    }
    // Only include exams if there were marks to evaluate
    if (p.exams.totalMaximumMarks > 0) {
      total += p.exams.percentage;
      count++;
    }
    return count > 0 ? total / count : 0;
  }

  // ── UI filter setters (no re-fetch) ────────────────────────────────────

  void setSearch(String value) {
    _filterSearch = value;
    notifyListeners();
  }

  void setClassFilter(String? className) {
    _filterClass = className;
    _filterSection = null; // Reset section when class changes
    notifyListeners();
  }

  void setSectionFilter(String? sectionName) {
    _filterSection = sectionName;
    notifyListeners();
  }

  void selectStudentByName(String? name) {
    if (name == null) {
      _selectedStudent = null;
    } else {
      _selectedStudent = _allPerformances.firstWhere(
        (p) => p.name == name,
        orElse: () => _allPerformances.first,
      );
    }
    notifyListeners();
  }

  void clearSelectedStudent() {
    _selectedStudent = null;
    notifyListeners();
  }

  // ── API fetch triggered by month/year change ────────────────────────────

  /// Fetch with new month & year — updates provider state then re-fetches.
  Future<void> fetchForMonth(int month, int year) async {
    _selectedMonth = month;
    _selectedYear = year;
    _selectedStudent = null; // reset individual selection on date change
    _filterSearch = '';
    _filterClass = null;
    _filterSection = null;
    await fetchPerformances();
  }

  Future<void> fetchPerformances() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final m = _selectedMonth;
      final y = _selectedYear;

      // Fetch all student performances in one call by omitting studentId
      final response = await DataProvider().performRequest(
        'GET',
        '${APIPath.baseUrl}/performance/student?month=$m&year=$y',
        header: {'Authorization': 'Bearer $token'},
      );

      if (response == null || response.statusCode != 200) {
        _error = 'Failed to load performance data';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = response.data['data'];
      if (data is List) {
        _allPerformances = data
            .map((d) => StudentPerformance.fromJson(d as Map<String, dynamic>))
            .toList();
        log('Fetched performance for ${_allPerformances.length} students in bulk.');
      } else {
        _allPerformances = [];
      }
    } catch (e) {
      _error = 'Error loading student performance: $e';
      log('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
