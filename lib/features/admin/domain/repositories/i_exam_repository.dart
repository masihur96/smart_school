import '../../../../models/school_models.dart';

abstract class IExamRepository {
  Future<List<Exam>> getExams();
  Future<List<Exam>> getExamsForTeacher(String teacherId);
  Future<List<Exam>> getExamsForClass(String classId, String sectionId);
  Future<void> addExam(Exam exam);
  Future<void> updateExam(Exam exam);
  Future<void> deleteExam(String id);
  Future<void> publishResult(String examId);
}
