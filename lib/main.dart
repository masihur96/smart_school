import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_school/configs/route_generator.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/admin/providers/notice_provider.dart';
import 'features/admin/providers/student_provider.dart';
import 'features/admin/providers/setup_provider.dart';
import 'features/admin/providers/exam_provider.dart';
import 'features/admin/providers/teacher_provider.dart';
import 'features/admin/providers/routine_provider.dart';
import 'features/admin/providers/settings_provider.dart';

import 'features/teacher/providers/homework_provider.dart';
import 'features/teacher/providers/attendance_provider.dart';
import 'features/teacher/providers/result_provider.dart';
import 'features/teacher/providers/teacher_dashboard_provider.dart';
import 'features/teacher/data/repositories/attendance_repository_impl.dart';
import 'features/teacher/data/repositories/result_repository_impl.dart';
import 'services/database_service.dart';
import 'configs/network/data_provider.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/get_profile_usecase.dart';
import 'features/auth/domain/usecases/change_password_usecase.dart';

void main() {
  final databaseService = DatabaseService();
  final dataProvider = DataProvider();

  // Auth dependencies
  final authRemoteDataSource = AuthRemoteDataSource(dataProvider);
  final authRepository = AuthRepositoryImpl(authRemoteDataSource);
  final loginUseCase = LoginUseCase(authRepository);
  final registerUseCase = RegisterUseCase(authRepository);
  final getProfileUseCase = GetProfileUseCase(authRepository);
  final changePasswordUseCase = ChangePasswordUseCase(authRepository);

  final authNotifier = AuthNotifier(
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
    getProfileUseCase: getProfileUseCase,
    changePasswordUseCase: changePasswordUseCase,
  );

  final attendanceRepository = AttendanceRepositoryImpl(databaseService);
  final resultRepository = ResultRepositoryImpl(databaseService);


  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: databaseService),
        Provider.value(value: dataProvider),
        ChangeNotifierProvider.value(value: authNotifier),
        ChangeNotifierProvider(create: (_) => NoticesNotifier(databaseService)),
        ChangeNotifierProvider(
          create: (_) => StudentsNotifier(databaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => ClassSetupNotifier(databaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => SectionSetupNotifier(databaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => SubjectSetupNotifier(databaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => TeachersNotifier(databaseService),
        ),
        ChangeNotifierProvider(create: (_) => RoutineNotifier()),
        ChangeNotifierProvider(create: (_) => ExamsNotifier()),
        ChangeNotifierProvider(
          create: (_) => HomeworkNotifier(databaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceNotifier(attendanceRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ResultsNotifier(resultRepository),
        ),
        ChangeNotifierProvider(create: (_) => TeacherDashboardProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Smart School',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('bn'),
      ],
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: RouteGenerator.splashRoute,
    );
  }
}
