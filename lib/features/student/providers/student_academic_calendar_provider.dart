import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/features/admin/models/academic_calendar_model.dart';

class StudentAcademicCalendarProvider extends ChangeNotifier {
  static const String fallbackStudentToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4NmQwODM2OC0yZjliLTRkMGItYmNlMi0wM2NkMTkwMmQxOGUiLCJyb2xlIjoidGVhY2hlciIsInNjaG9vbElkIjoiMjlmMDVlZGItOGUwYi00MzRjLWE0NzEtYWE3NzYzMDhhMWMxIiwiY2xhc3NJZHMiOlsiYWU0NDk4MWYtZmVkNC00MWRlLWE1NmQtZDFiOTI4Yjg1YWJiIiwiOTYyZGJlNDUtNzI4OS00ZjViLWE2NWUtYjYzZjE4NWJiOTkzIl0sInNlY3Rpb25JZHMiOlsiZWZkNDRhMTMtMzg1Ni00MDY2LWE5NGItYTdiY2ZmNmJhN2UyIiwiZTFkMzZhN2EtNzRiMy00MWQxLTkyZTgtYzU5Y2VkZTk2ZjI2Il0sImlhdCI6MTc5MjI3MDE0MCwiZXhwIjoxNzkyMzU2NTQwfQ.o9AK2M0vXyK_Sc6OOx1xsaMUws2tyCdw_wMkrn9TuGY';

  static const String fallbackSchoolId =
      '29f05edb-8e0b-434c-a471-aa776308a1c1';

  final DataProvider _dataProvider = DataProvider();

  List<AcademicCalendarEvent> _events = [];
  List<AcademicCalendarEvent> _upcomingEvents = [];
  bool _isLoading = false;
  bool _isLoadingUpcoming = false;
  String? _error;

  // Filter state
  int? _filterYear;
  int? _filterMonth;
  String? _filterStartDate;
  String? _filterEndDate;
  bool? _filterIsHoliday;
  String? _filterAcademicYear;
  String? _filterTerm;
  String? _filterClassId;
  String? _filterCategory;
  String _searchQuery = '';

  List<AcademicCalendarEvent> get events => _events;
  List<AcademicCalendarEvent> get upcomingEvents => _upcomingEvents;
  bool get isLoading => _isLoading;
  bool get isLoadingUpcoming => _isLoadingUpcoming;
  String? get error => _error;

  int? get filterYear => _filterYear;
  int? get filterMonth => _filterMonth;
  String? get filterStartDate => _filterStartDate;
  String? get filterEndDate => _filterEndDate;
  bool? get filterIsHoliday => _filterIsHoliday;
  String? get filterAcademicYear => _filterAcademicYear;
  String? get filterTerm => _filterTerm;
  String? get filterClassId => _filterClassId;
  String? get filterCategory => _filterCategory;
  String get searchQuery => _searchQuery;

  bool get hasActiveFilters =>
      _filterYear != null ||
      _filterMonth != null ||
      (_filterStartDate != null && _filterStartDate!.isNotEmpty) ||
      (_filterEndDate != null && _filterEndDate!.isNotEmpty) ||
      _filterIsHoliday != null ||
      (_filterAcademicYear != null && _filterAcademicYear!.isNotEmpty) ||
      (_filterTerm != null && _filterTerm!.isNotEmpty) ||
      (_filterClassId != null && _filterClassId!.isNotEmpty) ||
      (_filterCategory != null && _filterCategory!.isNotEmpty) ||
      _searchQuery.isNotEmpty;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool _isValidUuid(String? val) {
    if (val == null) return false;
    return _uuidRegex.hasMatch(val.trim());
  }

  Future<String> _getAuthToken() async {
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      return token;
    }
    return fallbackStudentToken;
  }

  // ── Fetch Student Academic Calendar ─────────────────────────────────────────
  Future<void> fetchEvents({
    int? year,
    int? month,
    String? startDate,
    String? endDate,
    bool? isHoliday,
    String? academicYear,
    String? term,
    String? classId,
    String? schoolId,
    String? category,
    bool syncFilters = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (syncFilters) {
      _filterYear = year;
      _filterMonth = month;
      _filterStartDate = startDate;
      _filterEndDate = endDate;
      _filterIsHoliday = isHoliday;
      _filterAcademicYear = academicYear;
      _filterTerm = term;
      _filterClassId = classId;
      if (category != null) _filterCategory = category;
    }

    try {
      final token = await _getAuthToken();

      final Map<String, dynamic> query = {};
      if (year != null) query['year'] = year.toString();
      if (month != null) query['month'] = month.toString();
      if (startDate != null && startDate.isNotEmpty) {
        query['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        query['endDate'] = endDate;
      }
      if (isHoliday != null) query['isHoliday'] = isHoliday.toString();
      if (academicYear != null && academicYear.isNotEmpty) {
        query['academicYear'] = academicYear;
      }
      if (term != null && term.isNotEmpty) query['term'] = term;

      // Only pass classId and schoolId if they are valid UUIDs
      if (_isValidUuid(classId)) {
        query['classId'] = classId!.trim();
      }
      if (_isValidUuid(schoolId)) {
        query['schoolId'] = schoolId!.trim();
      }

      log('StudentAcademicCalendarProvider: GET ${APIPath.studentAcademicCalendar} query: $query');

      final response = await _dataProvider.performRequest(
        'GET',
        APIPath.studentAcademicCalendar,
        query: query.isEmpty ? null : query,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic raw = response.data;
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map && raw['data'] is List) {
          list = raw['data'] as List<dynamic>;
        }

        _events = list
            .whereType<Map<String, dynamic>>()
            .map((e) => AcademicCalendarEvent.fromJson(e))
            .toList();

        _events.sort((a, b) => a.startDate.compareTo(b.startDate));
        log('StudentAcademicCalendarProvider: fetched ${_events.length} events');
      } else {
        _error = response?.data?['message']?.toString() ??
            'Failed to load academic calendar events';
        log('StudentAcademicCalendarProvider: fetch error: ${response?.data}');
      }
    } catch (e) {
      log('StudentAcademicCalendarProvider: exception: $e');
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch Upcoming Academic Calendar ────────────────────────────────────────
  Future<void> fetchUpcomingEvents({int limit = 10, bool force = false}) async {
    if (!force && _upcomingEvents.isNotEmpty) return;

    _isLoadingUpcoming = true;
    notifyListeners();

    try {
      final token = await _getAuthToken();
      final url = '${APIPath.studentUpcomingAcademicCalendar}?limit=$limit';

      log('StudentAcademicCalendarProvider: GET $url');

      final response = await _dataProvider.performRequest(
        'GET',
        url,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic raw = response.data;
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map && raw['data'] is List) {
          list = raw['data'] as List<dynamic>;
        }

        _upcomingEvents = list
            .whereType<Map<String, dynamic>>()
            .map((e) => AcademicCalendarEvent.fromJson(e))
            .toList();

        _upcomingEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
        log('StudentAcademicCalendarProvider: fetched ${_upcomingEvents.length} upcoming events');
      } else {
        log('StudentAcademicCalendarProvider: upcoming fetch error: ${response?.data}');
      }
    } catch (e) {
      log('StudentAcademicCalendarProvider: upcoming exception: $e');
    } finally {
      _isLoadingUpcoming = false;
      notifyListeners();
    }
  }

  // ── Apply Curl Preset ───────────────────────────────────────────────────────
  Future<void> applyCurlPreset({String? schoolId, String? classId}) async {
    await fetchEvents(
      year: 2026,
      month: 5,
      startDate: '2026-01-01',
      endDate: '2026-12-31',
      isHoliday: true,
      academicYear: '2026-2027',
      term: 'First Term',
      classId: _isValidUuid(classId) ? classId : null,
      schoolId: _isValidUuid(schoolId) ? schoolId : fallbackSchoolId,
    );
  }

  // ── Clear Filters ───────────────────────────────────────────────────────────
  Future<void> clearFilters() async {
    _filterYear = null;
    _filterMonth = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _filterIsHoliday = null;
    _filterAcademicYear = null;
    _filterTerm = null;
    _filterClassId = null;
    _filterCategory = null;
    _searchQuery = '';
    await fetchEvents(syncFilters: false);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  // ── Filtered Events Getter ──────────────────────────────────────────────────
  List<AcademicCalendarEvent> get filteredEvents {
    return _events.where((event) {
      if (_filterCategory != null &&
          _filterCategory!.isNotEmpty &&
          _filterCategory!.toUpperCase() != 'ALL') {
        if (event.category.toUpperCase() != _filterCategory!.toUpperCase()) {
          return false;
        }
      }

      if (_filterIsHoliday != null) {
        if (event.isHoliday != _filterIsHoliday) return false;
      }

      if (_filterAcademicYear != null &&
          _filterAcademicYear!.isNotEmpty &&
          _filterAcademicYear!.toUpperCase() != 'ALL') {
        if (event.academicYear != null &&
            event.academicYear!.toLowerCase() !=
                _filterAcademicYear!.toLowerCase()) {
          return false;
        }
      }

      if (_filterTerm != null &&
          _filterTerm!.isNotEmpty &&
          _filterTerm!.toUpperCase() != 'ALL') {
        if (event.term != null &&
            event.term!.toLowerCase() != _filterTerm!.toLowerCase()) {
          return false;
        }
      }

      if (_filterClassId != null && _filterClassId!.isNotEmpty) {
        if (event.classIds.isNotEmpty &&
            !event.classIds.contains(_filterClassId)) {
          return false;
        }
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final inTitle = event.title.toLowerCase().contains(q);
        final inDesc = (event.description ?? '').toLowerCase().contains(q);
        final inLoc = (event.location ?? '').toLowerCase().contains(q);
        final inAudience = event.targetAudience.toLowerCase().contains(q);
        if (!inTitle && !inDesc && !inLoc && !inAudience) return false;
      }

      return true;
    }).toList();
  }

  List<AcademicCalendarEvent> getEventsForDay(DateTime day) {
    return filteredEvents.where((e) => e.occursOn(day)).toList();
  }
}
