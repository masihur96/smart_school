

import 'package:smart_school/features/teacher/data/datasources/homework_remote_datasource.dart';
import 'package:smart_school/features/teacher/domain/repositories/i_homework_repository.dart';
import 'package:smart_school/models/school_models.dart';

class HomeworkRepositoryImpl implements IHomeworkRepository {
  final HomeworkRemoteDataSource _remoteDataSource;

  HomeworkRepositoryImpl(this._remoteDataSource);

  @override
  Future<bool> submitHomework(Homework homework) async {
    return await _remoteDataSource.submitHomework(homework);
  }

  @override
  Future<bool> updateHomework(Homework homework) async {
    return await _remoteDataSource.updateHomework(homework);
  }

  @override
  Future<bool> deleteHomework(String id) async {
    return await _remoteDataSource.deleteHomework(id);
  }

  @override
  Future<List<Homework>> fetchHomework({
    String? classId,
    String? sectionId,
    String? subjectId,
  }) async {
    return await _remoteDataSource.fetchHomework(
      classId: classId,
      sectionId: sectionId,
      subjectId: subjectId,
    );
  }

  @override
  Future<Homework> fetchHomeworkDetails(String id) async {
    return await _remoteDataSource.fetchHomeworkDetails(id);
  }

  @override
  Future<bool> bulkUpdateStudentHomeworkStatus({
    required String homeworkId,
    required String status,
    String? comment,
  }) async {
    return await _remoteDataSource.bulkUpdateStudentHomeworkStatus(
      homeworkId: homeworkId,
      status: status,
      comment: comment,
    );
  }

  @override
  Future<bool> updateSpecificStudentHomeworkStatus({
    required String homeworkId,
    required String studentId,
    required String status,
    String? comment,
  }) async {
    return await _remoteDataSource.updateSpecificStudentHomeworkStatus(
      homeworkId: homeworkId,
      studentId: studentId,
      status: status,
      comment: comment,
    );
  }
}
