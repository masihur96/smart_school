import 'package:flutter/material.dart';
import '../../../models/school_models.dart';

// Key format: classId_sectionId
class RoutineNotifier extends ChangeNotifier {
  Map<String, List<RoutineEntry>> _state = {};

  Map<String, List<RoutineEntry>> get state => _state;

  void addEntry(String classId, String sectionId, RoutineEntry entry) {
    final key = '${classId}_$sectionId';
    final currentEntries = _state[key] ?? [];
    _state = {
      ..._state,
      key: [...currentEntries, entry],
    };
    notifyListeners();
  }

  void removeEntry(String classId, String sectionId, int index) {
    final key = '${classId}_$sectionId';
    final currentEntries = _state[key] ?? [];
    if (index >= 0 && index < currentEntries.length) {
      final newList = [...currentEntries];
      newList.removeAt(index);
      _state = {..._state, key: newList};
      notifyListeners();
    }
  }

  List<RoutineEntry> getRoutine(String classId, String sectionId) {
    return _state['${classId}_$sectionId'] ?? [];
  }
}
