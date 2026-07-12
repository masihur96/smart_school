import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../models/admin_dashboard_model.dart';

class TeacherPerformanceProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _selectedMonth = DateTime.now().month;
  int get selectedMonth => _selectedMonth;

  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  // All raw performances loaded from API
  List<TeacherPerformance> _allPerformances = [];
  List<TeacherPerformance> get allPerformances => _allPerformances;

  // UI-only filters (do NOT re-fetch from API)
  String _filterSearch = '';
  String get filterSearch => _filterSearch;

  String? _filterDesignation;
  String? get filterDesignation => _filterDesignation;

  // Selected teacher for individual detail view
  TeacherPerformance? _selectedTeacher;
  TeacherPerformance? get selectedTeacher => _selectedTeacher;

  // Performances sorted best→worst (descending score)
  List<TeacherPerformance> get sortedByBest {
    final sorted = [..._allPerformances];
    sorted.sort((a, b) => _score(b).compareTo(_score(a)));
    return sorted;
  }

  // Filtered + sorted list used in the full screen
  List<TeacherPerformance> get filteredPerformances {
    var list = sortedByBest;

    if (_filterSearch.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(_filterSearch.toLowerCase()))
          .toList();
    }

    if (_filterDesignation != null && _filterDesignation!.isNotEmpty) {
      list = list.where((p) => p.designation == _filterDesignation).toList();
    }

    return list;
  }

  List<String> get availableDesignations {
    final designations = <String>{};
    for (final p in _allPerformances) {
      if (p.designation.isNotEmpty) designations.add(p.designation);
    }
    return designations.toList()..sort();
  }

  // All teacher names for dropdown search
  List<String> get teacherNames =>
      _allPerformances.map((p) => p.name).toList()..sort();

  double _score(TeacherPerformance p) =>
      (p.attendance.percentage + p.homework.percentage) / 2;

  // ── UI filter setters (no re-fetch) ────────────────────────────────────

  void setSearch(String value) {
    _filterSearch = value;
    notifyListeners();
  }

  void setDesignationFilter(String? designation) {
    _filterDesignation = designation;
    notifyListeners();
  }

  void selectTeacherByName(String? name) {
    if (name == null) {
      _selectedTeacher = null;
    } else {
      _selectedTeacher = _allPerformances.firstWhere(
        (p) => p.name == name,
        orElse: () => _allPerformances.first,
      );
    }
    notifyListeners();
  }

  void clearSelectedTeacher() {
    _selectedTeacher = null;
    notifyListeners();
  }

  // ── API fetch triggered by month/year change ────────────────────────────

  /// Fetch with new month & year — updates provider state then re-fetches.
  Future<void> fetchForMonth(int month, int year) async {
    _selectedMonth = month;
    _selectedYear = year;
    _selectedTeacher = null; // reset individual selection on date change
    _filterSearch = '';
    _filterDesignation = null;
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

      // Fetch all teacher performances in one call by omitting teacherId
      // Notice using api path: APIPath.baseUrl + /performance/teacher
      final response = await DataProvider().performRequest(
        'GET',
        '${APIPath.baseUrl}/performance/teacher?month=$m&year=$y',
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
            .map((d) => TeacherPerformance.fromJson(d as Map<String, dynamic>))
            .toList();
        log('Fetched performance for ${_allPerformances.length} teachers in bulk.');
      } else {
        _allPerformances = [];
      }
    } catch (e) {
      _error = 'Error loading teacher performance: $e';
      log('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
