

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
    String? subjectId,
  }) async {
    return await _remoteDataSource.fetchHomework(
      classId: classId,
      subjectId: subjectId,
    );
  }
}
