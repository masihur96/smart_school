import '../../../../models/school_models.dart';
import '../../../../services/database_service.dart';
import '../../domain/repositories/i_result_repository.dart';

class ResultRepositoryImpl implements IResultRepository {
  final MockDatabaseService _dbService;

  ResultRepositoryImpl(this._dbService);

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
      final index = _dbService.results.indexWhere((r) => r.examId == result.examId && r.studentId == result.studentId);
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
