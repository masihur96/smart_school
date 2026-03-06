import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/teacher_model.dart';
import '../../../services/database_service.dart';
import 'student_provider.dart';

final teachersProvider = NotifierProvider<TeachersNotifier, List<Teacher>>(() {
  return TeachersNotifier();
});

class TeachersNotifier extends Notifier<List<Teacher>> {
  late final MockDatabaseService _dbService;

  @override
  List<Teacher> build() {
    _dbService = ref.watch(databaseServiceProvider);
    return _dbService.teachers;
  }

  void addTeacher(Teacher teacher) {
    _dbService.teachers.add(teacher);
    state = [..._dbService.teachers];
  }

  void updateTeacher(Teacher teacher) {
    final index = _dbService.teachers.indexWhere((t) => t.userId == teacher.userId);
    if (index != -1) {
      _dbService.teachers[index] = teacher;
      state = [..._dbService.teachers];
    }
  }

  void removeTeacher(String userId) {
    _dbService.teachers.removeWhere((t) => t.userId == userId);
    state = [..._dbService.teachers];
  }
}
