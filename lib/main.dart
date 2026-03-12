import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/admin/providers/notice_provider.dart';
import 'features/admin/providers/student_provider.dart';
import 'features/admin/providers/setup_provider.dart';
import 'features/admin/providers/exam_provider.dart';
import 'features/admin/providers/teacher_provider.dart';
import 'features/admin/providers/routine_provider.dart';
import 'features/admin/data/repositories/exam_repository_impl.dart';
import 'features/teacher/providers/homework_provider.dart';
import 'features/teacher/providers/attendance_provider.dart';
import 'features/teacher/providers/result_provider.dart';
import 'features/teacher/data/repositories/attendance_repository_impl.dart';
import 'features/teacher/data/repositories/result_repository_impl.dart';
import 'services/database_service.dart';

void main() {
  final databaseService = DatabaseService();
  final attendanceRepository = AttendanceRepositoryImpl(databaseService);
  final resultRepository = ResultRepositoryImpl(databaseService);
  final examRepository = ExamRepositoryImpl(databaseService);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: databaseService),
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
        ChangeNotifierProvider(create: (_) => NoticesNotifier(databaseService)),
        ChangeNotifierProvider(create: (_) => StudentsNotifier(databaseService)),
        ChangeNotifierProvider(create: (_) => ClassSetupNotifier(databaseService)),
        ChangeNotifierProvider(create: (_) => SectionSetupNotifier(databaseService)),
        ChangeNotifierProvider(create: (_) => SubjectSetupNotifier(databaseService)),
        ChangeNotifierProvider(create: (_) => TeachersNotifier(databaseService)),
        ChangeNotifierProvider(create: (_) => RoutineNotifier()),
        ChangeNotifierProvider(create: (_) => ExamsNotifier(examRepository)),
        ChangeNotifierProvider(create: (_) => HomeworkNotifier(databaseService)),
        ChangeNotifierProvider(create: (_) => AttendanceNotifier(attendanceRepository)),
        ChangeNotifierProvider(create: (_) => ResultsNotifier(resultRepository)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);
    final router = getRouter(authNotifier);

    return MaterialApp.router(
      title: 'Smart School',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
