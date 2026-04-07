

import 'package:smart_school/models/school_models.dart';

abstract class IHomeworkRepository {
  Future<bool> submitHomework(Homework homework);
  Future<bool> updateHomework(Homework homework);
  Future<bool> deleteHomework(String id);
  Future<List<Homework>> fetchHomework({String? classId, String? sectionId, String? subjectId});
}
