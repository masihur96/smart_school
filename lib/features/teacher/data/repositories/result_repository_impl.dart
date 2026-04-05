import 'package:smart_school/features/teacher/data/datasources/mark_entry_remote_datasource.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/services/database_service.dart';
import '../../domain/repositories/i_result_repository.dart';

class ResultRepositoryImpl implements IResultRepository {
  final DatabaseService _dbService;
  final MarkEntryRemoteDataSource _remoteDataSource;

  ResultRepositoryImpl(this._dbService, this._remoteDataSource);

  // ─── New API-backed methods ───────────────────────────────────────────────

  @override
  Future<List<Exam>> getTeacherExams() => _remoteDataSource.getTeacherExams();

  @override
  Future<List<TeacherAssignmentClass>> getExamClasses(String examId) =>
      _remoteDataSource.getExamClasses(examId);

  @override
  Future<List<TeacherAssignmentStudent>> getClassStudents(
          String examId, String classId) =>
      _remoteDataSource.getClassStudents(examId, classId);

  @override
  Future<List<TeacherAssignmentSubject>> getStudentSubjects(
          String examId, String classId, String studentId) =>
      _remoteDataSource.getStudentSubjects(examId, classId, studentId);

  @override
  Future<void> submitMarks({
    required String examId,
    required String teacherId,
    required String schoolId,
    required List<Map<String, dynamic>> marks,
  }) =>
      _remoteDataSource.submitMarks(
        examId: examId,
        teacherId: teacherId,
        schoolId: schoolId,
        marks: marks,
      );

  // ─── Legacy in-memory methods ─────────────────────────────────────────────

  @override
  Future<List<Result>> getResultsForExam(String examId) async {
    return _dbService.results.where((r) => r.examId == examId).toList();
  }

  @override
  Future<List<Result>> getResultsForStudent(String studentId) async {
    return _dbService.results.where((r) => r.studentId == studentId).toList();
  }

  @override
  Future<void> saveResults(List<Result> results) async {
    for (var result in results) {
      final index = _dbService.results.indexWhere(
        (r) => r.examId == result.examId && r.studentId == result.studentId,
      );
      if (index != -1) {
        _dbService.results[index] = result;
      } else {
        _dbService.results.add(result);
      }
    }
  }

  @override
  Future<void> updateResult(Result result) async {
    final index = _dbService.results.indexWhere((r) => r.id == result.id);
    if (index != -1) {
      _dbService.results[index] = result;
    }
  }
}
