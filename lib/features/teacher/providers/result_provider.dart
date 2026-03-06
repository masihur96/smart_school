import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/school_models.dart';
import '../../admin/providers/student_provider.dart';
import '../domain/repositories/i_result_repository.dart';
import '../data/repositories/result_repository_impl.dart';

final resultRepositoryProvider = Provider<IResultRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ResultRepositoryImpl(dbService);
});

final resultsProvider = NotifierProvider<ResultsNotifier, List<Result>>(() {
  return ResultsNotifier();
});

class ResultsNotifier extends Notifier<List<Result>> {
  late final IResultRepository _repository;

  @override
  List<Result> build() {
    _repository = ref.watch(resultRepositoryProvider);
    return [];
  }

  Future<void> loadResultsForExam(String examId) async {
    state = await _repository.getResultsForExam(examId);
  }

  Future<void> loadResultsForStudent(String studentId) async {
    state = await _repository.getResultsForStudent(studentId);
  }

  Future<void> saveResults(List<Result> results) async {
    await _repository.saveResults(results);
  }
}
