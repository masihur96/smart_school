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
        _state = data.map((e) => Exam.fromJson(e)).where((e) => !e.isDeleted).toList();
      } else {
        log('Error fetching exams: ${response?.data}');
      }
    } catch (e) {
      log('Error fetching exams: $e');
    }
    notifyListeners();
  }

  Future<void> createExamWithAssignments({
    required String examName,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> assignments,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final examData = {
        'exam_name': examName,
        'description': description,
        'start_date': DateFormat('yyyy-MM-dd').format(startDate),
        'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      };

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.createExam,
        data: examData,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        log('Exam created successfully');

        final dynamic respData = response.data;
        String examId = '';
        if (respData is Map) {
          if (respData.containsKey('data') && respData['data'] is Map) {
            examId = respData['data']['id'] ?? '';
          } else {
            examId = respData['id'] ?? '';
          }
        }
        
        if (examId.isNotEmpty) {
          for (final assign in assignments) {
            final assignData = {
              'class_uid': assign['class_uid'],
              'subject_uid': assign['subject_uid'],
              'examiner_uid': assign['examiner_uid'],
              'date': DateFormat('yyyy-MM-dd').format(assign['date']),
              'syllabus': assign['syllabus'],
            };
            await DataProvider().performRequest(
              'POST',
              '${APIPath.createExam}/$examId/assignments',
              data: assignData,
              header: {'Authorization': 'Bearer $token'},
            );
          }
        }

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

  Future<void> updateExamOnAPI({
    required String examId,
    required String examName,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> assignments,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final examData = {
        'exam_name': examName,
        'description': description,
        'start_date': DateFormat('yyyy-MM-dd').format(startDate),
        'end_date': DateFormat('yyyy-MM-dd').format(endDate),
        'assignments': assignments.map((a) => {
          if (a.containsKey('id')) 'id': a['id'],
          'class_uid': a['class_uid'],
          'subject_uid': a['subject_uid'],
          'examiner_uid': a['examiner_uid'],
          'date': DateFormat('yyyy-MM-dd').format(a['date']),
          'syllabus': a['syllabus'],
        }).toList(),
      };

      final response = await DataProvider().performRequest(
        'PUT',
        '${APIPath.createExam}/$examId',
        data: examData,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        log('Exam updated successfully');
        await _load();
      } else {
        log('Error updating exam: ${response?.data}');
        throw Exception(
          response?.data?['message'] ?? 'Failed to update exam',
        );
      }
    } catch (e) {
      log('Error updating exam: $e');
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

  Future<void> updatePublishStatus(String examId, bool isPublished) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'PUT',
        '${APIPath.createExam}/$examId',
        data: {'isPublished': isPublished},
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        await _load();
      } else {
        log('Error updating publish status: ${response?.data}');
      }
    } catch (e) {
      log('Error updating publish status: $e');
    }
  }
}
