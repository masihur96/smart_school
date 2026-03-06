import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/school_models.dart';
import './student_provider.dart';
import '../domain/repositories/i_exam_repository.dart';
import '../data/repositories/exam_repository_impl.dart';

final examRepositoryProvider = Provider<IExamRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ExamRepositoryImpl(dbService);
});

final examsProvider = NotifierProvider<ExamsNotifier, List<Exam>>(() {
  return ExamsNotifier();
});

class ExamsNotifier extends Notifier<List<Exam>> {
  late final IExamRepository _repository;

  @override
  List<Exam> build() {
    _repository = ref.watch(examRepositoryProvider);
    _load();
    return [];
  }

  Future<void> _load() async {
    state = await _repository.getExams();
  }

  Future<void> addExam(Exam exam) async {
    await _repository.addExam(exam);
    await _load();
  }

  Future<void> updateExam(Exam exam) async {
    await _repository.updateExam(exam);
    await _load();
  }

  Future<void> deleteExam(String id) async {
    await _repository.deleteExam(id);
    await _load();
  }

  Future<void> publishResult(String examId) async {
    await _repository.publishResult(examId);
    await _load();
  }
}
