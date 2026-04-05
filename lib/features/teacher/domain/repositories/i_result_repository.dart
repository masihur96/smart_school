import '../../../../models/school_models.dart';

abstract class IResultRepository {
  Future<List<Exam>> getTeacherExams();
  Future<List<TeacherAssignmentClass>> getExamClasses(String examId);
  Future<List<TeacherAssignmentStudent>> getClassStudents(
      String examId, String classId);
  Future<List<TeacherAssignmentSubject>> getStudentSubjects(
      String examId, String classId, String studentId);
  Future<void> submitMarks({
    required String examId,
    required String teacherId,
    required String schoolId,
    required List<Map<String, dynamic>> marks,
  });

  // Legacy methods (kept for compatibility)
  Future<List<Result>> getResultsForExam(String examId);
  Future<List<Result>> getResultsForStudent(String studentId);
  Future<void> saveResults(List<Result> results);
  Future<void> updateResult(Result result);
}
