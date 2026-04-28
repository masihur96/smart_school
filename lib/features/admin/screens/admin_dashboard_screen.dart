import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/screens/add_edit_marquee_screen.dart';
import 'package:smart_school/features/admin/screens/add_edit_student_screen.dart';
import 'package:smart_school/features/admin/screens/add_edit_teacher_screen.dart';
import 'package:smart_school/features/admin/screens/routine_management_screen.dart'
    hide SizedBox;
import 'package:smart_school/features/admin/screens/setup_screen.dart';
import 'package:smart_school/features/admin/screens/teacher_management_screen.dart';
import 'package:smart_school/features/profile/presentation/views/profile_screen.dart';
import 'package:smart_school/l10n/app_localizations.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/notification_icon_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teacher/domain/entities/attendance.dart';
import '../../teacher/providers/attendance_provider.dart';
import '../../teacher/screens/teacher_self_attendance_detail_screen.dart';
import '../providers/notice_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/student_provider.dart';
import '../providers/teacher_provider.dart';
import 'exam_management_screen.dart';
import 'notice_management_screen.dart';
import 'student_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  String? _selectedClassId;
  final int _currentYear = DateTime.now().year;
  final int _currentMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final schoolId = context.read<AuthNotifier>().user?.schoolId;

        if (schoolId != null) {
          context.read<AttendanceNotifier>().fetchAttendanceOverview(
            year: _currentYear,
            month: _currentMonth,
          );
          context.read<StudentsNotifier>().fetchStudents();
          context.read<TeachersNotifier>().fetchTeachers();
          context.read<ClassSetupNotifier>().fetchClasses(schoolId);
          context.read<NoticesNotifier>().fetchNoticesFromAPI();
        }
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle(AppLocalizations l10n) {
    switch (_selectedIndex) {
      case 0:
        return l10n.adminDashboard;
      case 1:
        return l10n.studentManagement;
      case 2:
        return l10n.examManagement;
      case 3:
        return l10n.schoolNotices;
      default:
        return l10n.adminDashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceRecords = context.watch<AttendanceNotifier>().state;
    final studentCount = context.watch<StudentsNotifier>().totalCount;
    final teacherCount = context.watch<TeachersNotifier>().totalCount;
    final classCount = context.watch<ClassSetupNotifier>().classes.length;
    final noticeCount = context.watch<NoticesNotifier>().notices.length;

    final isStudentsLoading = context.watch<StudentsNotifier>().isLoading;
    final isTeachersLoading = context.watch<TeachersNotifier>().isLoading;
    final isClassesLoading = context.watch<ClassSetupNotifier>().isLoading;
    final isNoticesLoading = context.watch<NoticesNotifier>().isLoading;
    final authNotifier = context.watch<AuthNotifier>();
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.exitApp),
            content: Text(l10n.exitAppConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.no),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.yes),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTitle(l10n)),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          actions: [
            const NotificationIconButton(),
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: const AppDrawer(),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboardOverview(
              attendanceRecords,
              authNotifier: authNotifier,
              studentCount: studentCount,
              teacherCount: teacherCount,
              classCount: classCount,
              noticeCount: noticeCount,
              isStudentsLoading: isStudentsLoading,
              isTeachersLoading: isTeachersLoading,
              isClassesLoading: isClassesLoading,
              isNoticesLoading: isNoticesLoading,
              l10n: l10n,
            ),
            const StudentManagementScreen(hideAppBar: true),
            const ExamManagementScreen(hideAppBar: true),
            const NoticeManagementScreen(hideAppBar: true),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people),
              label: l10n.students,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_turned_in),
              label: l10n.exams,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.announcement),
              label: l10n.notices,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardOverview(
    List<AttendanceEntity> attendanceRecords, {
    required AuthNotifier authNotifier,
    required int studentCount,
    required int teacherCount,
    required int classCount,
    required int noticeCount,
    required bool isStudentsLoading,
    required bool isTeachersLoading,
    required bool isClassesLoading,
    required bool isNoticesLoading,
    required AppLocalizations l10n,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubscriptionCard(authNotifier, l10n),
          Text(
            l10n.schoolOverview,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
            children: [
              _buildStatCard(
                context,
                l10n.totalStudents,
                isStudentsLoading ? '...' : studentCount.toString(),
                Icons.people,
                Colors.blue,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _buildStatCard(
                context,
                l10n.totalTeachers,
                isTeachersLoading ? '...' : teacherCount.toString(),
                Icons.person,
                Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherManagementScreen(),
                    ),
                  );
                },
              ),
              _buildStatCard(
                context,
                l10n.totalClasses,
                isClassesLoading ? '...' : classCount.toString(),
                Icons.class_,
                Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SetupScreen()),
                  );
                },
              ),
              _buildStatCard(
                context,
                l10n.activeNotices,
                isNoticesLoading ? '...' : noticeCount.toString(),
                Icons.announcement,
                Colors.red,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.attendanceOverview,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              _buildClassFilter(l10n),
            ],
          ),
          const SizedBox(height: 16),
          _buildEnhancedAttendanceOverview(l10n),
          const SizedBox(height: 24),
          Text(
            l10n.quickActions,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            context,
            l10n.addStudent,
            Icons.person_add,
            Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditStudentScreen()),
              );
            },
          ),
          _buildActionTile(
            context,
            l10n.addTeacher,
            Icons.group_add,
            Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditTeacherScreen()),
              );
            },
          ),
          _buildActionTile(
            context,
            l10n.postNotice,
            Icons.post_add,
            Colors.red,
            onTap: () => setState(() => _selectedIndex = 3),
          ),
          _buildActionTile(
            context,
            l10n.manageRoutine,
            Icons.calendar_month,
            Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RoutineManagementScreen()),
              );
            },
          ),
          _buildActionTile(
            context,
            l10n.teacherAttendance,
            Icons.how_to_reg,
            Colors.green,
            onTap: () {
              final schoolId =
                  context.read<AuthNotifier>().user?.schoolId ?? '';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TeacherSelfAttendanceDetailScreen(schoolId: schoolId),
                ),
              );
            },
          ),
          _buildActionTile(
            context,
            l10n.marqueeMessage,
            Icons.campaign_outlined,
            Colors.redAccent,
            onTap: () {
              final schoolId =
                  context.read<AuthNotifier>().user?.schoolId ?? '';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditMarqueeScreen(schoolId: schoolId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildClassFilter(AppLocalizations l10n) {
    final overview = context.watch<AttendanceNotifier>().overviewSummary;
    if (overview == null || overview.data.isEmpty)
      return const SizedBox.shrink();

    final classes = overview.data;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedClassId,
          hint: Text(l10n.allClasses, style: const TextStyle(fontSize: 13)),
          style: const TextStyle(
            color: Colors.purple,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.allClasses)),
            ...classes.map(
              (c) =>
                  DropdownMenuItem(value: c.classId, child: Text(c.className)),
            ),
          ],
          onChanged: (val) {
            setState(() {
              _selectedClassId = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedAttendanceOverview(AppLocalizations l10n) {
    final attendanceNotifier = context.watch<AttendanceNotifier>();
    final overview = attendanceNotifier.overviewSummary;
    final isLoading = attendanceNotifier.isLoading;

    if (isLoading && overview == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (overview == null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
        child: _buildChartPlaceholder(),
      );
    }

    // Determine what to show based on filter
    final bool isAllClasses = _selectedClassId == null;
    final String currentTitle = isAllClasses
        ? '${_getMonthName(overview.month)} ${overview.year}'
        : overview.data
              .firstWhere((c) => c.classId == _selectedClassId)
              .className;

    final int present = isAllClasses
        ? overview.grandTotalPresent
        : overview.data
              .firstWhere((c) => c.classId == _selectedClassId)
              .totalPresent;

    final int absent = isAllClasses
        ? overview.grandTotalAbsent
        : overview.data
              .firstWhere((c) => c.classId == _selectedClassId)
              .totalAbsent;

    final int leave = isAllClasses
        ? overview.grandTotalLeave
        : overview.data
              .firstWhere((c) => c.classId == _selectedClassId)
              .totalLeave;

    final double percentage = isAllClasses
        ? overview.overallAttendancePercentage
        : overview.data
              .firstWhere((c) => c.classId == _selectedClassId)
              .attendancePercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    Text(
                      isAllClasses
                          ? l10n.schoolPerformance
                          : l10n.classPerformance,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMonthStatItem(
                  l10n.present,
                  present.toString(),
                  const Color(0xFF7C3AED),
                ),
                _buildMonthStatItem(
                  l10n.absent,
                  absent.toString(),
                  const Color(0xFFEF4444),
                ),
                _buildMonthStatItem(
                  l10n.leave,
                  leave.toString(),
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
            // We could still show class-wise progress bars if "All Classes" is selected
            if (isAllClasses && overview.data.length > 1) ...[
              const SizedBox(height: 24),
              Text(
                l10n.classBreakdown,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ...overview.data
                  .take(5)
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                c.className,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                '${c.attendancePercentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: c.attendancePercentage / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                c.attendancePercentage > 80
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildSubscriptionCard(AuthNotifier auth, AppLocalizations l10n) {
    final sub = auth.adminSubscription;
    if (sub == null) return const SizedBox.shrink();

    final isValid = auth.isSubscriptionValid;
    final planName = sub.pricingPlan?.name ?? 'No Plan';
    final expiryDate = DateTime.tryParse(sub.endDate);
    final formattedDate = expiryDate != null
        ? DateFormat('MMM dd, yyyy').format(expiryDate)
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isValid
              ? [Colors.purple.shade700, Colors.purple.shade400]
              : [Colors.red.shade700, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isValid ? Colors.purple : Colors.red).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isValid ? Icons.star : Icons.error_outline,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${sub.lastStudentCount} / ${sub.pricingPlan?.maxStudents ?? '∞'} ${l10n.studentsLabel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isValid
                      ? 'Valid until $formattedDate'
                      : 'Expired on $formattedDate',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isValid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.active,
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _buildChartPlaceholder() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.bar_chart_rounded,
        size: 48,
        color: Colors.purple.withOpacity(0.2),
      ),
      const SizedBox(height: 12),
      Text(
        'No attendance data found',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
