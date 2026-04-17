import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../../../models/school_models.dart';

class StudentExamNotifier extends ChangeNotifier {
  List<Exam> _exams = [];
  List<ExamAssignment> _routine = [];
  List<ExamAssignment> _syllabus = [];
  List<Result> _results = [];
  
  bool _isLoading = false;
  String? _error;

  List<Exam> get exams => _exams;
  List<ExamAssignment> get routine => _routine;
  List<ExamAssignment> get syllabus => _syllabus;
  List<Result> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchExams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.studentExams,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List data = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);
        
        _exams = data.map((json) => Exam.fromJson(json)).toList();
        log('Fetched ${_exams.length} student exams');
      } else {
        _error = 'Failed to fetch exams: ${response?.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception fetching student exams: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExamRoutine(String examId) async {
    _isLoading = true;
    _error = null;
    _routine = [];
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.studentExamRoutine(examId),
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List data = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);
        
        _routine = data.map((json) => ExamAssignment.fromJson(json)).toList();
      } else {
        _error = 'Failed to fetch routine';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExamSyllabus(String examId) async {
    _isLoading = true;
    _error = null;
    _syllabus = [];
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.studentExamSyllabus(examId),
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List data = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);
        
        _syllabus = data.map((json) => ExamAssignment.fromJson(json)).toList();
      } else {
        _error = 'Failed to fetch syllabus';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExamResults(String examId) async {
    _isLoading = true;
    _error = null;
    _results = [];
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.studentExamResults(examId),
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List data = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);
        
        _results = data.map((json) => Result.fromJson(json)).toList();
      } else {
        _error = 'Failed to fetch results';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
