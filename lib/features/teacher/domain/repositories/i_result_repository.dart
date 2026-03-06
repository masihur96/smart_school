import '../../../../models/school_models.dart';

abstract class IResultRepository {
  Future<List<Result>> getResultsForExam(String examId);
  Future<List<Result>> getResultsForStudent(String studentId);
  Future<void> saveResults(List<Result> results);
  Future<void> updateResult(Result result);
}
