import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/school_models.dart';
import '../../../services/database_service.dart';
import 'student_provider.dart';

class ClassSetupNotifier extends Notifier<List<ClassRoom>> {
  late final MockDatabaseService _dbService;
  @override
  List<ClassRoom> build() {
    _dbService = ref.watch(databaseServiceProvider);
    return [..._dbService.classes];
  }
  void addClass(String name) {
    _dbService.classes.add(ClassRoom(id: DateTime.now().toString(), name: name));
    state = [..._dbService.classes];
  }
}

class SectionSetupNotifier extends Notifier<List<Section>> {
  late final MockDatabaseService _dbService;
  @override
  List<Section> build() {
    _dbService = ref.watch(databaseServiceProvider);
    return [..._dbService.sections];
  }
  void addSection(String classId, String name) {
    _dbService.sections.add(Section(id: DateTime.now().toString(), classId: classId, name: name));
    state = [..._dbService.sections];
  }
}

class SubjectSetupNotifier extends Notifier<List<Subject>> {
  late final MockDatabaseService _dbService;
  @override
  List<Subject> build() {
    _dbService = ref.watch(databaseServiceProvider);
    return [..._dbService.subjects];
  }
  void addSubject(String name) {
    _dbService.subjects.add(Subject(id: DateTime.now().toString(), name: name));
    state = [..._dbService.subjects];
  }
}

final classSetupProvider = NotifierProvider<ClassSetupNotifier, List<ClassRoom>>(() {
  return ClassSetupNotifier();
});

final sectionSetupProvider = NotifierProvider<SectionSetupNotifier, List<Section>>(() {
  return SectionSetupNotifier();
});

final subjectSetupProvider = NotifierProvider<SubjectSetupNotifier, List<Subject>>(() {
  return SubjectSetupNotifier();
});
