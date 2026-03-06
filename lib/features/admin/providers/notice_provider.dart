import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_school/services/database_service.dart';
import '../../../models/school_models.dart';
import 'student_provider.dart';

final noticesProvider = NotifierProvider<NoticesNotifier, List<Notice>>(() {
  return NoticesNotifier();
});

class NoticesNotifier extends Notifier<List<Notice>> {
  late final MockDatabaseService _dbService;

  @override
  List<Notice> build() {
    _dbService = ref.watch(databaseServiceProvider);
    return [..._dbService.notices];
  }

  void addNotice(Notice notice) {
    _dbService.notices.add(notice);
    state = [..._dbService.notices];
  }

  void removeNotice(String id) {
    _dbService.notices.removeWhere((n) => n.id == id);
    state = [..._dbService.notices];
  }
}
