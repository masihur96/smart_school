import 'dart:developer';

import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/models/school_models.dart';

class HomeworkRemoteDataSource {
  final DataProvider _dataProvider;

  HomeworkRemoteDataSource(this._dataProvider);

  Future<bool> submitHomework(Homework homework) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final payload = {
      'classId': homework.classId,
      'subjectId': homework.subjectId,
      'teacherId': homework.teacherId,
      'title': homework.title,
      'description': homework.description,
      'dueDate': homework.dueDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'sectionId': homework.sectionId,
      'schoolId': homework.schoolId,
    };

    // Note: The user's curl also has schoolId.
    // If the Homework model doesn't have it, we might need a DTO or fetch it from user profile.
    // For now, I'll assume the backend can handle it or we'll add it if needed.

    log('Submit homework payload: $payload');

    final response = await _dataProvider.performRequest(
      'POST',
      APIPath.submitHomeWork,
      data: payload,
      header: {'Authorization': 'Bearer $token'},
    );

    log(
      'Submit homework response: ${response?.statusCode} - ${response?.data}',
    );

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return true;
    } else {
      final message = response.data?['message'] ?? 'Failed to submit homework';
      throw Exception(message);
    }
  }

  Future<bool> updateHomework(Homework homework) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final payload = {
      'classId': homework.classId,
      'subjectId': homework.subjectId,
      'teacherId': homework.teacherId,
      'title': homework.title,
      'description': homework.description,
      'dueDate': homework.dueDate.toIso8601String().split('T')[0],
      'sectionId': homework.sectionId,
      'schoolId': homework.schoolId,
    };

    final response = await _dataProvider.performRequest(
      'PUT',
      '${APIPath.submitHomeWork}/${homework.id}',
      data: payload,
      header: {'Authorization': 'Bearer $token'},
    );

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }
    return response.statusCode! >= 200 && response.statusCode! < 300;
  }

  Future<bool> deleteHomework(String id) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await _dataProvider.performRequest(
      'DELETE',
      '${APIPath.submitHomeWork}/$id',
      header: {'Authorization': 'Bearer $token'},
    );

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }
    return response.statusCode! >= 200 && response.statusCode! < 300;
  }

  Future<List<Homework>> fetchHomework({
    String? classId,
    String? sectionId,
    String? subjectId,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No authentication token found');
    print("Fetch Homework query classId:: $classId");
    print("Fetch Homework query sectionId:: $sectionId");
    print("Fetch Homework query subjectId:: $subjectId");
    final query = <String, dynamic>{};
    if (classId != null && classId.isNotEmpty) query['classId'] = classId;
    if (sectionId != null && sectionId.isNotEmpty)
      query['sectionId'] = sectionId;
    if (subjectId != null && subjectId.isNotEmpty)
      query['subjectId'] = subjectId;

    print("Fetch Homework query:: $query");

    final response = await _dataProvider.performRequest(
      'GET',
      APIPath.submitHomeWork,
      query: query,
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
      return data.map((json) => Homework.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch homework');
    }
  }

  Future<Homework> fetchHomeworkDetails(String id) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await _dataProvider.performRequest(
      'GET',
      APIPath.homeworkDetails(id),
      header: {'Authorization': 'Bearer $token'},
    );

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> data =
          rawData is Map ? (rawData['data'] ?? rawData) : {};
      return Homework.fromJson(data);
    } else {
      throw Exception('Failed to fetch homework details');
    }
  }

  Future<bool> updateStudentHomeworkStatus({
    required String studentHomeworkId,
    required String status,
    String? comment,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final payload = {
      'status': status,
      if (comment != null) 'comment': comment,
    };

    final response = await _dataProvider.performRequest(
      'PATCH',
      APIPath.updateStudentHomework(studentHomeworkId),
      data: payload,
      header: {'Authorization': 'Bearer $token'},
    );

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    return response.statusCode! >= 200 && response.statusCode! < 300;
  }
}
