import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/school_models.dart';
import '../../../services/database_service.dart';
import '../../admin/providers/student_provider.dart';

final homeworkProvider = NotifierProvider<HomeworkNotifier, List<Homework>>(() {
  return HomeworkNotifier();
});

class HomeworkNotifier extends Notifier<List<Homework>> {
  late final MockDatabaseService _dbService;

  @override
  List<Homework> build() {
    _dbService = ref.watch(databaseServiceProvider);
    return [..._dbService.homeworkRecords];
  }

  void addHomework(Homework homework) {
    _dbService.homeworkRecords.add(homework);
    state = [..._dbService.homeworkRecords];
  }

  void removeHomework(String id) {
    _dbService.homeworkRecords.removeWhere((h) => h.id == id);
    state = [..._dbService.homeworkRecords];
  }

  List<Homework> getHomeworkForTeacher(String teacherId) {
    return state.where((h) => h.teacherId == teacherId).toList();
  }
}
