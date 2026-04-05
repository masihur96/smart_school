import 'dart:developer';
import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/models/school_models.dart';

class MarkEntryRemoteDataSource {
  final DataProvider _dataProvider;

  MarkEntryRemoteDataSource(this._dataProvider);

  Future<String> _getToken() async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No authentication token found');
    return token;
  }

  /// GET /teacher/assignments/exams
  Future<List<Exam>> getTeacherExams() async {
    final token = await _getToken();
    final url = '${APIPath.teacherAssignment}/exams';
    log('Fetching teacher exams: $url');

    final response = await _dataProvider.performRequest(
      'GET',
      url,
      header: {'Authorization': 'Bearer $token'},
    );

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      final dynamic rawData = response.data;
      final List data = rawData is List
          ? rawData
          : (rawData is Map ? (rawData['data'] ?? []) : []);
      log('Teacher exams count: ${data.length}');
      return data.map((json) => Exam.fromJson(json)).toList();
    } else {
      throw Exception(
          response.data?['message'] ?? 'Failed to fetch teacher exams');
    }
  }

  /// GET /teacher/assignments/exams/{examId}/classes
  Future<List<TeacherAssignmentClass>> getExamClasses(String examId) async {
    final token = await _getToken();
    final url = '${APIPath.teacherAssignment}/exams/$examId/classes';
    log('Fetching exam classes: $url');

    final response = await _dataProvider.performRequest(
      'GET',
      url,
      header: {'Authorization': 'Bearer $token'},
    );

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      final dynamic rawData = response.data;
      final List data = rawData is List
          ? rawData
          : (rawData is Map ? (rawData['data'] ?? []) : []);
      log('Exam classes count: ${data.length}');
      return data
          .map((json) => TeacherAssignmentClass.fromJson(json))
          .toList();
    } else {
      throw Exception(
          response.data?['message'] ?? 'Failed to fetch classes for exam');
    }
  }

  /// GET /teacher/assignments/exams/{examId}/classes/{classId}/students
  Future<List<TeacherAssignmentStudent>> getClassStudents(
      String examId, String classId) async {
    final token = await _getToken();
    final url =
        '${APIPath.teacherAssignment}/exams/$examId/classes/$classId/students';
    log('Fetching class students: $url');

    final response = await _dataProvider.performRequest(
      'GET',
      url,
      header: {'Authorization': 'Bearer $token'},
    );

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      final dynamic rawData = response.data;
      final List data = rawData is List
          ? rawData
          : (rawData is Map ? (rawData['data'] ?? []) : []);
      log('Class students count: ${data.length}');
      return data
          .map((json) => TeacherAssignmentStudent.fromJson(json))
          .toList();
    } else {
      throw Exception(
          response.data?['message'] ?? 'Failed to fetch students for class');
    }
  }

  /// GET /teacher/assignments/exams/{examId}/classes/{classId}/students/{studentId}/subjects
  Future<List<TeacherAssignmentSubject>> getStudentSubjects(
      String examId, String classId, String studentId) async {
    final token = await _getToken();
    final url =
        '${APIPath.teacherAssignment}/exams/$examId/classes/$classId/students/$studentId/subjects';
    log('Fetching student subjects: $url');

    final response = await _dataProvider.performRequest(
      'GET',
      url,
      header: {'Authorization': 'Bearer $token'},
    );

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      final dynamic rawData = response.data;
      final List data = rawData is List
          ? rawData
          : (rawData is Map ? (rawData['data'] ?? []) : []);
      log('Student subjects count: ${data.length}');
      return data
          .map((json) => TeacherAssignmentSubject.fromJson(json))
          .toList();
    } else {
      throw Exception(
          response.data?['message'] ?? 'Failed to fetch subjects for student');
    }
  }

  /// POST /teacher/marks
  Future<void> submitMarks({
    required String examId,
    required String teacherId,
    required String schoolId,
    required List<Map<String, dynamic>> marks,
  }) async {
    final token = await _getToken();

    final payload = {
      'examId': examId,
      'teacherId': teacherId,
      'schoolId': schoolId,
      'marks': marks,
    };

    log('Submitting marks payload: $payload');

    final response = await _dataProvider.performRequest(
      'POST',
      APIPath.teacherMarks,
      data: payload,
      header: {'Authorization': 'Bearer $token'},
    );

    log('Submit marks response: ${response?.statusCode} - ${response?.data}');

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode! < 200 || response.statusCode! >= 300) {
      final message =
          response.data?['message'] ?? 'Failed to submit marks';
      throw Exception(message);
    }
  }
}
