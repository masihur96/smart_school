import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/school_models.dart';

// Key format: classId_sectionId
final routineProvider = NotifierProvider<RoutineNotifier, Map<String, List<RoutineEntry>>>(() {
  return RoutineNotifier();
});

class RoutineNotifier extends Notifier<Map<String, List<RoutineEntry>>> {
  @override
  Map<String, List<RoutineEntry>> build() {
    return {};
  }

  void addEntry(String classId, String sectionId, RoutineEntry entry) {
    final key = '${classId}_$sectionId';
    final currentEntries = state[key] ?? [];
    state = {
      ...state,
      key: [...currentEntries, entry],
    };
  }

  void removeEntry(String classId, String sectionId, int index) {
    final key = '${classId}_$sectionId';
    final currentEntries = state[key] ?? [];
    if (index >= 0 && index < currentEntries.length) {
      final newList = [...currentEntries];
      newList.removeAt(index);
      state = {
        ...state,
        key: newList,
      };
    }
  }

  List<RoutineEntry> getRoutine(String classId, String sectionId) {
    return state['${classId}_$sectionId'] ?? [];
  }
}
