import '../../../../models/school_models.dart';
import '../../../../services/database_service.dart';
import '../../domain/repositories/i_exam_repository.dart';

class ExamRepositoryImpl implements IExamRepository {
  final DatabaseService _dbService;

  ExamRepositoryImpl(this._dbService);

  @override
  Future<List<Exam>> getExams() async {
    return _dbService.exams;
  }

  @override
  Future<List<Exam>> getExamsForTeacher(String teacherId) async {
    return _dbService.exams.where((e) => e.teacherId == teacherId).toList();
  }

  @override
  Future<List<Exam>> getExamsForClass(String classId, String sectionId) async {
    return _dbService.exams.where((e) => e.classId == classId && e.sectionId == sectionId).toList();
  }

  @override
  Future<void> addExam(Exam exam) async {
    _dbService.exams.add(exam);
  }

  @override
  Future<void> updateExam(Exam exam) async {
    final index = _dbService.exams.indexWhere((e) => e.id == exam.id);
    if (index != -1) {
      _dbService.exams[index] = exam;
    }
  }

  @override
  Future<void> deleteExam(String id) async {
    _dbService.exams.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> publishResult(String examId) async {
    final index = _dbService.exams.indexWhere((e) => e.id == examId);
    if (index != -1) {
      final oldExam = _dbService.exams[index];
      _dbService.exams[index] = Exam(
        id: oldExam.id,
        name: oldExam.name,
        subjectId: oldExam.subjectId,
        teacherId: oldExam.teacherId,
        classId: oldExam.classId,
        sectionId: oldExam.sectionId,
        dateTime: oldExam.dateTime,
        isPublished: true,
      );
    }
  }
}
