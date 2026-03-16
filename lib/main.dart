import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import 'configs/network/data_provider.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';

void main() {
  final databaseService = DatabaseService();
  final dataProvider = DataProvider();
  
  // Auth dependencies
  final authRemoteDataSource = AuthRemoteDataSource(dataProvider);
  final authRepository = AuthRepositoryImpl(authRemoteDataSource);
  final loginUseCase = LoginUseCase(authRepository);
  final registerUseCase = RegisterUseCase(authRepository);

  final authNotifier = AuthNotifier(
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
  );

  final router = getRouter(authNotifier);

  final attendanceRepository = AttendanceRepositoryImpl(databaseService);
  final resultRepository = ResultRepositoryImpl(databaseService);
  final examRepository = ExamRepositoryImpl(databaseService);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: databaseService),
        Provider.value(value: dataProvider),
        ChangeNotifierProvider.value(value: authNotifier),
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
      child: MyApp(router: router),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {

    return MaterialApp.router(
      title: 'Smart School',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
