sed -i '' -e 's/final String date;/final String date;\n  final Subject? subjectInfo;/' lib/features/teacher/data/models/teacher_dashboard_model.dart
sed -i '' -e 's/required this.date,/required this.date,\n    this.subjectInfo,/' lib/features/teacher/data/models/teacher_dashboard_model.dart
sed -i '' -e "s/date: json\['date'\] ?? '',/date: json['date'] ?? '',\n      subjectInfo: json['subjectInfo'] != null ? Subject.fromJson(json['subjectInfo']) : null,/" lib/features/teacher/data/models/teacher_dashboard_model.dart
