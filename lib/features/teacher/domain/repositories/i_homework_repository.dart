

import 'package:smart_school/models/school_models.dart';

abstract class IHomeworkRepository {
  Future<bool> submitHomework(Homework homework);
  Future<bool> submitAdminHomework(Homework homework);
  Future<bool> updateHomework(Homework homework);
  Future<bool> deleteHomework(String id);
  Future<List<Homework>> fetchHomework({
    String? classId,
    String? sectionId,
    String? subjectId,
  });
  Future<List<Homework>> fetchAdminHomework({
    String? classId,
    String? sectionId,
    String? subjectId,
    String? date,
    String? schoolId,
  });
  Future<Homework> fetchHomeworkDetails(String id);
  Future<bool> bulkUpdateStudentHomeworkStatus({
    required String homeworkId,
    required String status,
    String? comment,
  });
  Future<bool> updateSpecificStudentHomeworkStatus({
    required String homeworkId,
    required String studentId,
    required String status,
    String? comment,
  });
}
