import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/student_management_screen.dart';
import '../../features/admin/screens/add_edit_student_screen.dart';
import '../../features/admin/screens/teacher_management_screen.dart';
import '../../features/admin/screens/add_edit_teacher_screen.dart';
import '../../features/admin/screens/setup_screen.dart';
import '../../features/admin/screens/routine_management_screen.dart';
import '../../features/admin/screens/notice_management_screen.dart';
import '../../features/teacher/screens/teacher_dashboard_screen.dart';
import '../../features/teacher/screens/attendance_screen.dart';
import '../../features/teacher/screens/homework_management_screen.dart';
import '../../features/student/screens/student_dashboard_screen.dart';
import '../../features/student/screens/student_attendance_screen.dart';
import '../../features/student/screens/student_routine_screen.dart';
import '../../features/student/screens/student_homework_screen.dart';
import '../../features/student/screens/student_notice_screen.dart';
import '../../features/admin/screens/exam_management_screen.dart';
import '../../features/teacher/screens/mark_entry_screen.dart';
import '../../features/student/screens/student_result_screen.dart';
import '../../models/user_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        final role = authState.user!.role;
        switch (role) {
          case UserRole.admin:
            return '/admin';
          case UserRole.teacher:
            return '/teacher';
          case UserRole.student:
            return '/student';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'students',
            builder: (context, state) => const StudentManagementScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddEditStudentScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'teachers',
            builder: (context, state) => const TeacherManagementScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddEditTeacherScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'setup',
            builder: (context, state) => const SetupScreen(),
          ),
          GoRoute(
            path: 'routine',
            builder: (context, state) => const RoutineManagementScreen(),
          ),
          GoRoute(
            path: 'notices',
            builder: (context, state) => const NoticeManagementScreen(),
          ),
          GoRoute(
            path: 'exams',
            builder: (context, state) => const ExamManagementScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboardScreen(),
        routes: [
          GoRoute(
            path: 'attendance',
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: 'homework',
            builder: (context, state) => const HomeworkManagementScreen(),
          ),
          GoRoute(
            path: 'marks',
            builder: (context, state) => const MarkEntryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboardScreen(),
        routes: [
          GoRoute(
            path: 'attendance',
            builder: (context, state) => const StudentAttendanceScreen(),
          ),
          GoRoute(
            path: 'routine',
            builder: (context, state) => const StudentRoutineScreen(),
          ),
          GoRoute(
            path: 'homework',
            builder: (context, state) => const StudentHomeworkScreen(),
          ),
          GoRoute(
            path: 'notices',
            builder: (context, state) => const StudentNoticeScreen(),
          ),
          GoRoute(
            path: 'results',
            builder: (context, state) => const StudentResultScreen(),
          ),
        ],
      ),
    ],
  );
});
