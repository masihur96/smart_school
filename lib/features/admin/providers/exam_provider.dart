import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../../../configs/network/data_provider.dart';
import '../../../models/school_models.dart';

class ExamsNotifier extends ChangeNotifier {
  List<Exam> _state = [];
  bool _isLoading = false;

  List<Exam> get state => _state;
  bool get isLoading => _isLoading;

  ExamsNotifier() {
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.createExam,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic raw = response.data;
        final List<dynamic> data = raw is List
            ? raw
            : (raw is Map ? (raw['data'] ?? raw['exams'] ?? []) : []);
        _state = data.map((e) => Exam.fromJson(e)).toList();
      } else {
        log('Error fetching exams: ${response?.data}');
      }
    } catch (e) {
      log('Error fetching exams: $e');
    }
    notifyListeners();
  }

  Future<void> createExamOnAPI({
    required String examName,
    required String classUid,
    required String subjectUid,
    required String examinerUid,
    required DateTime date,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final data = {
        'exam_name': examName,
        'class_uid': classUid,
        'subject_uid': subjectUid,
        'examiner_uid': examinerUid,
        'date': DateFormat('yyyy-MM-dd').format(date),
      };

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.createExam,
        data: data,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        log('Exam created successfully');
        await _load();
      } else {
        log('Error creating exam: ${response?.data}');
        throw Exception(
          response?.data?['message'] ?? 'Failed to create exam',
        );
      }
    } catch (e) {
      log('Error creating exam: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExam(String id) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'DELETE',
        '${APIPath.createExam}/$id',
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 204)) {
        await _load();
      } else {
        log('Error deleting exam: ${response?.data}');
      }
    } catch (e) {
      log('Error deleting exam: $e');
    }
  }

  Future<void> publishResult(String examId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'PUT',
        '${APIPath.createExam}/$examId/publish',
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        await _load();
      } else {
        log('Error publishing result: ${response?.data}');
      }
    } catch (e) {
      log('Error publishing result: $e');
    }
  }
}
