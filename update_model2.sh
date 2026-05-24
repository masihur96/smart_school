sed -i '' -e 's/final String date;/final String date;\n  final String? subjectId;/' lib/features/teacher/data/models/teacher_dashboard_model.dart
sed -i '' -e 's/required this.date,/required this.date,\n    this.subjectId,/' lib/features/teacher/data/models/teacher_dashboard_model.dart
sed -i '' -e "s/date: json\['date'\] ?? '',/date: json['date'] ?? '',\n      subjectId: json['subjectId'],/" lib/features/teacher/data/models/teacher_dashboard_model.dart
