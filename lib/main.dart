import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/configs/route_generator.dart';
import 'package:smart_school/l10n/app_localizations.dart';

import 'configs/network/data_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/providers/exam_provider.dart';
import 'features/admin/providers/notice_provider.dart';
import 'features/admin/providers/marquee_provider.dart';
import 'features/admin/providers/routine_provider.dart';
import 'features/admin/providers/settings_provider.dart';
import 'features/admin/providers/setup_provider.dart';
import 'features/admin/providers/student_provider.dart';
import 'features/admin/providers/teacher_provider.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/change_password_usecase.dart';
import 'features/auth/domain/usecases/get_profile_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/student/providers/student_attendance_provider.dart';
import 'features/student/providers/student_homework_provider.dart';
import 'features/student/providers/student_result_provider.dart';
import 'features/student/providers/student_routine_provider.dart';
import 'features/student/providers/student_exam_provider.dart';
import 'features/super_admin/providers/pricing_notifier.dart';
import 'features/super_admin/providers/subscription_provider.dart';
import 'features/super_admin/providers/super_admin_dashboard_provider.dart';
import 'features/super_admin/providers/super_admin_school_provider.dart';
import 'features/super_admin/providers/trash_restore_provider.dart';
import 'features/teacher/data/datasources/homework_remote_datasource.dart';
import 'features/teacher/data/datasources/mark_entry_remote_datasource.dart';
import 'features/teacher/data/repositories/attendance_repository_impl.dart';
import 'features/teacher/data/repositories/homework_repository_impl.dart';
import 'features/teacher/data/repositories/result_repository_impl.dart';
import 'features/teacher/providers/attendance_provider.dart';
import 'features/teacher/providers/homework_provider.dart';
import 'features/teacher/providers/result_provider.dart';
import 'features/teacher/providers/teacher_attendance_provider.dart';
import 'features/teacher/providers/teacher_dashboard_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'firebase_options.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Push Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

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

  final homeworkRemoteDataSource = HomeworkRemoteDataSource(dataProvider);
  final homeworkRepository = HomeworkRepositoryImpl(homeworkRemoteDataSource);

  final markEntryRemoteDataSource = MarkEntryRemoteDataSource(dataProvider);
  final resultRepository = ResultRepositoryImpl(
    databaseService,
    markEntryRemoteDataSource,
  );

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
          create: (_) => HomeworkNotifier(
            databaseService,
            homeworkRepository: homeworkRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceNotifier(attendanceRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ResultsNotifier(resultRepository),
        ),
        ChangeNotifierProvider(create: (_) => StudentAttendanceNotifier()),
        ChangeNotifierProvider(create: (_) => StudentRoutineNotifier()),
        ChangeNotifierProvider(create: (_) => StudentHomeworkNotifier()),
        ChangeNotifierProvider(create: (_) => StudentResultNotifier()),
        ChangeNotifierProvider(create: (_) => StudentExamNotifier()),
        ChangeNotifierProvider(create: (_) => TeacherDashboardProvider()),
        ChangeNotifierProvider(create: (_) => TeacherAttendanceProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SuperAdminDashboardNotifier()),
        ChangeNotifierProvider(create: (_) => SuperAdminSchoolNotifier()),
        ChangeNotifierProvider(create: (_) => PricingNotifier()),
        ChangeNotifierProvider(create: (_) => SubscriptionNotifier()),
        ChangeNotifierProvider(create: (_) => TrashRestoreNotifier()),
        ChangeNotifierProvider(create: (_) => NotificationNotifier()),
        ChangeNotifierProvider(create: (_) => MarqueeProvider()),
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
      supportedLocales: const [Locale('en'), Locale('bn')],
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: RouteGenerator.splashRoute,
    );
  }
}
