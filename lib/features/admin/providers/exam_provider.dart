import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../../../models/school_models.dart';
import '../../../services/notification_service.dart';

class ExamsNotifier extends ChangeNotifier {
  List<Exam> _state = [];
  bool _isLoading = false;

  List<Exam> get state => _state;
  bool get isLoading => _isLoading;

  ExamsNotifier() {
    _load();
  }

  Future<void> fetchExams() async {
    await _load();
  }

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();

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
        _state = data
            .map((e) => Exam.fromJson(e))
            .where((e) => !e.isDeleted)
            .toList();
      } else {
        log('Error fetching exams: ${response?.data}');
      }
    } catch (e) {
      log('Error fetching exams: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createExamWithAssignments({
    List<String> receiverUuids = const [],
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
          // Topic-based notification (for legacy FCM topic subscribers)
          NotificationService().triggerNotification(
            title: 'New Exam Published',
            body: 'Exam schedule for "$examName" is now available.',
            topic: 'exam',
            data: {'type': 'exam', 'id': examId},
          );

          // Individual notifications to all teachers & students
          if (receiverUuids.isNotEmpty) {
            NotificationService().sendBulkNotification(
              receiverUuids: receiverUuids,
              title: '📋 New Exam Published',
              message: 'Exam schedule for "$examName" is now available. Check the exam section for details.',
              additionalData: {'type': 'exam', 'id': examId},
            );
          }

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
        throw Exception(response?.data?['message'] ?? 'Failed to create exam');
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
    List<String> receiverUuids = const [],
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
        'assignments': assignments
            .map(
              (a) => {
                if (a.containsKey('id')) 'id': a['id'],
                'class_uid': a['class_uid'],
                'subject_uid': a['subject_uid'],
                'examiner_uid': a['examiner_uid'],
                'date': DateFormat('yyyy-MM-dd').format(a['date']),
                'syllabus': a['syllabus'],
              },
            )
            .toList(),
      };

      final response = await DataProvider().performRequest(
        'PUT',
        '${APIPath.createExam}/$examId',
        data: examData,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        log('Exam updated successfully');

        // Topic-based notification
        NotificationService().triggerNotification(
          title: 'Exam Schedule Updated',
          body: 'The schedule for "$examName" has been updated.',
          topic: 'exam',
          data: {'type': 'exam_update', 'id': examId},
        );

        // Individual notifications to all teachers & students
        if (receiverUuids.isNotEmpty) {
          NotificationService().sendBulkNotification(
            receiverUuids: receiverUuids,
            title: '📝 Exam Schedule Updated',
            message: 'The schedule for "$examName" has been updated. Please review the new details.',
            additionalData: {'type': 'exam_update', 'id': examId},
          );
        }

        await _load();
      } else {
        log('Error updating exam: ${response?.data}');
        throw Exception(response?.data?['message'] ?? 'Failed to update exam');
      }
    } catch (e) {
      log('Error updating exam: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteExam(String id) async {
    _isLoading = true;
    notifyListeners();

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
        return true;
      } else {
        log('Error deleting exam: ${response?.data}');
        return false;
      }
    } catch (e) {
      log('Error deleting exam: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> duplicateExam(String examId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'POST',
        '${APIPath.createExam}/$examId/duplicate',
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        log('Exam duplicated successfully');
        await _load();
        return true;
      } else {
        log('Error duplicating exam: ${response?.data}');
        return false;
      }
    } catch (e) {
      log('Error duplicating exam: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePublishStatus(
    String examId,
    bool isPublished, {
    String? examName,
    List<String> receiverUuids = const [],
  }) async {
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

        if (isPublished && examName != null) {
          // Legacy topic-based notification
          NotificationService().triggerNotification(
            title: '🎉 Exam Results Published',
            body: 'Results for "$examName" are now available.',
            topic: 'exam',
            data: {'type': 'exam_result', 'id': examId},
          );

          // Individual notifications to all teachers & students
          if (receiverUuids.isNotEmpty) {
            NotificationService().sendBulkNotification(
              receiverUuids: receiverUuids,
              title: '🎉 Exam Results Published',
              message: 'Results for "$examName" are now available.',
              additionalData: {'type': 'exam_result', 'id': examId},
            );
          }
        }
      } else {
        log('Error updating publish status: ${response?.data}');
      }
    } catch (e) {
      log('Error updating publish status: $e');
    }
  }

  /// Fetch existing marks for a specific exam/class/subject/section.
  /// Calls: GET /admin/marks/exam?examId=&classId=&subjectId=&sectionId=
  /// Returns a list of mark records (each has studentId, marksObtained, totalMarks).
  Future<List<Map<String, dynamic>>> fetchMarksForSubject({
    required String examId,
    required String classId,
    required String subjectId,
    String? sectionId,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final url =
          '${APIPath.adminMarksExam}?examId=$examId&classId=$classId&subjectId=$subjectId&sectionId=${sectionId ?? ''}';

      final response = await DataProvider().performRequest(
        'GET',
        url,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic raw = response.data;
        final List<dynamic> data = raw is List
            ? raw
            : (raw is Map ? (raw['data'] ?? raw['marks'] ?? []) : []);
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        log('Error fetching marks: ${response?.data}');
        return [];
      }
    } catch (e) {
      log('Error fetching marks for subject: $e');
      return [];
    }
  }

  Future<bool> submitMarks({
    required String examId,
    required String teacherId,
    required String schoolId,
    required List<Map<String, dynamic>> marks,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final data = {
        'examId': examId,
        'teacherId': teacherId,
        'schoolId': schoolId,
        'marks': marks,
      };

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.submitMarks,
        data: data,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        log('Marks submitted successfully');
        await _load();
        return true;
      } else {
        log('Error submitting marks: ${response?.data}');
        return false;
      }
    } catch (e) {
      log('Error submitting marks: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
