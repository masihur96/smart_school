import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/features/admin/models/academic_calendar_model.dart';

class AcademicCalendarProvider extends ChangeNotifier {
  static const String fallbackToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkYTBjM2ZmZi1hZTU5LTQ2YTMtYTAzNy0xOWZhNjgwMDNjNmIiLCJyb2xlIjoiYWRtaW4iLCJzY2hvb2xJZCI6IjI5ZjA1ZWRiLThlMGItNDM0Yy1hNDcxLWFhNzc2MzA4YTFjMSIsImNsYXNzSWRzIjpbXSwic2VjdGlvbklkcyI6W10sImlhdCI6MTc5MjI2NDIwMiwiZXhwIjoxNzkyMzUwNjAyfQ.qsqOVg2U3L-_pw1O7LIwAsT-H9WKX0aQYU8Y8f1yuKs';
  static const String fallbackSchoolId =
      '29f05edb-8e0b-434c-a471-aa776308a1c1';

  final DataProvider _dataProvider = DataProvider();

  List<AcademicCalendarEvent> _events = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;

  // Filter state
  int? _filterYear;
  int? _filterMonth;
  String? _filterStartDate;
  String? _filterEndDate;
  bool? _filterIsHoliday;
  String? _filterAcademicYear;
  String? _filterTerm;
  String? _filterCategory;
  String _searchQuery = '';

  List<AcademicCalendarEvent> get events => _events;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;

  int? get filterYear => _filterYear;
  int? get filterMonth => _filterMonth;
  String? get filterStartDate => _filterStartDate;
  String? get filterEndDate => _filterEndDate;
  bool? get filterIsHoliday => _filterIsHoliday;
  String? get filterAcademicYear => _filterAcademicYear;
  String? get filterTerm => _filterTerm;
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
      (_filterCategory != null && _filterCategory!.isNotEmpty) ||
      _searchQuery.isNotEmpty;

  Future<String> _getAuthToken() async {
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      return token;
    }
    return fallbackToken;
  }

  // ── Fetch Academic Calendar Events ──────────────────────────────────────────
  Future<void> fetchEvents({
    int? year,
    int? month,
    String? startDate,
    String? endDate,
    bool? isHoliday,
    String? academicYear,
    String? term,
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
      if (category != null) _filterCategory = category;
    }

    try {
      final token = await _getAuthToken();

      final Map<String, dynamic> query = {};
      if (year != null) query['year'] = year.toString();
      if (month != null) query['month'] = month.toString();
      if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;
      if (isHoliday != null) query['isHoliday'] = isHoliday.toString();
      if (academicYear != null && academicYear.isNotEmpty) {
        query['academicYear'] = academicYear;
      }
      if (term != null && term.isNotEmpty) query['term'] = term;

      log('AcademicCalendarProvider: GET ${APIPath.academicCalendar} query: $query');

      final response = await _dataProvider.performRequest(
        'GET',
        APIPath.academicCalendar,
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

        // Sort events chronologically (newest first or start date ascending)
        _events.sort((a, b) => a.startDate.compareTo(b.startDate));
        log('AcademicCalendarProvider: fetched ${_events.length} events');
      } else {
        _error = response?.data?['message']?.toString() ??
            'Failed to load academic calendar events';
        log('AcademicCalendarProvider: fetch error: ${response?.data}');
      }
    } catch (e) {
      log('AcademicCalendarProvider: exception: $e');
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Apply Curl Preset ───────────────────────────────────────────────────────
  Future<void> applyCurlPreset() async {
    await fetchEvents(
      year: 2026,
      month: 5,
      startDate: '2026-01-01',
      endDate: '2026-12-31',
      isHoliday: true,
      academicYear: '2026-2027',
      term: 'First Term',
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

  // ── Create Event ────────────────────────────────────────────────────────────
  Future<bool> createEvent(
    AcademicCalendarEvent event, {
    String? schoolId,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();
      final targetSchoolId = (schoolId != null && schoolId.isNotEmpty)
          ? schoolId
          : fallbackSchoolId;

      final url = '${APIPath.academicCalendar}?schoolId=$targetSchoolId';
      final payload = event.toCreateJson();

      log('AcademicCalendarProvider: POST $url body: $payload');

      final response = await _dataProvider.performRequest(
        'POST',
        url,
        data: payload,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          final newEvent = AcademicCalendarEvent.fromJson(data);
          _events.add(newEvent);
          _events.sort((a, b) => a.startDate.compareTo(b.startDate));
        }
        return true;
      } else {
        _error = response?.data?['message']?.toString() ??
            'Failed to create academic calendar event';
        log('AcademicCalendarProvider: create error: ${response?.data}');
        return false;
      }
    } catch (e) {
      log('AcademicCalendarProvider: create exception: $e');
      _error = 'Error creating event: $e';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ── Update Event ────────────────────────────────────────────────────────────
  Future<bool> updateEvent(String id, Map<String, dynamic> payload) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();
      final url = APIPath.academicCalendarItem(id);

      log('AcademicCalendarProvider: PUT $url body: $payload');

      final response = await _dataProvider.performRequest(
        'PUT',
        url,
        data: payload,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          final updated = AcademicCalendarEvent.fromJson(data);
          final index = _events.indexWhere((e) => e.id == id);
          if (index != -1) {
            _events[index] = updated;
          }
          _events.sort((a, b) => a.startDate.compareTo(b.startDate));
        }
        return true;
      } else {
        _error = response?.data?['message']?.toString() ??
            'Failed to update academic calendar event';
        return false;
      }
    } catch (e) {
      _error = 'Error updating event: $e';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ── Delete Event ────────────────────────────────────────────────────────────
  Future<bool> deleteEvent(String id) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();
      final url = APIPath.academicCalendarItem(id);

      log('AcademicCalendarProvider: DELETE $url');

      final response = await _dataProvider.performRequest(
        'DELETE',
        url,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        _events.removeWhere((e) => e.id == id);
        return true;
      } else {
        _error = response?.data?['message']?.toString() ??
            'Failed to delete academic calendar event';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting event: $e';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ── Upload Attachment File ──────────────────────────────────────────────────
  Future<String?> uploadAttachment(File file) async {
    _isUploading = true;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      final token = await _getAuthToken();
      final fileName = file.path.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final dio = Dio(
        BaseOptions(
          sendTimeout: const Duration(minutes: 3),
          receiveTimeout: const Duration(minutes: 3),
        ),
      );

      final response = await dio.post(
        '${APIPath.baseUrl}/general/upload',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            _uploadProgress = sent / total;
            notifyListeners();
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final url = response.data['data']?['url']?.toString();
        log('AcademicCalendarProvider: uploaded attachment -> $url');
        return url;
      }
      return null;
    } catch (e) {
      log('AcademicCalendarProvider: upload error: $e');
      return null;
    } finally {
      _isUploading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  // ── Filtered Events Getter ──────────────────────────────────────────────────
  List<AcademicCalendarEvent> get filteredEvents {
    return _events.where((event) {
      // Category filter
      if (_filterCategory != null &&
          _filterCategory!.isNotEmpty &&
          _filterCategory!.toUpperCase() != 'ALL') {
        if (event.category.toUpperCase() != _filterCategory!.toUpperCase()) {
          return false;
        }
      }

      // Holiday filter
      if (_filterIsHoliday != null) {
        if (event.isHoliday != _filterIsHoliday) return false;
      }

      // Academic Year filter
      if (_filterAcademicYear != null &&
          _filterAcademicYear!.isNotEmpty &&
          _filterAcademicYear!.toUpperCase() != 'ALL') {
        if (event.academicYear != null &&
            event.academicYear!.toLowerCase() !=
                _filterAcademicYear!.toLowerCase()) {
          return false;
        }
      }

      // Term filter
      if (_filterTerm != null &&
          _filterTerm!.isNotEmpty &&
          _filterTerm!.toUpperCase() != 'ALL') {
        if (event.term != null &&
            event.term!.toLowerCase() != _filterTerm!.toLowerCase()) {
          return false;
        }
      }

      // Search query filter (title, description, location)
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

  // ── Events for specific day ─────────────────────────────────────────────────
  List<AcademicCalendarEvent> getEventsForDay(DateTime day) {
    return filteredEvents.where((e) => e.occursOn(day)).toList();
  }
}
