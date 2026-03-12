import 'package:flutter/material.dart';
import '../../../services/database_service.dart';
import '../../../models/school_models.dart';

class NoticesNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  List<Notice> _notices = [];

  NoticesNotifier(this._dbService) {
    _notices = [..._dbService.notices];
  }

  List<Notice> get notices => _notices;

  void addNotice(Notice notice) {
    _dbService.notices.add(notice);
    _notices = [..._dbService.notices];
    notifyListeners();
  }

  void removeNotice(String id) {
    _dbService.notices.removeWhere((n) => n.id == id);
    _notices = [..._dbService.notices];
    notifyListeners();
  }
}
