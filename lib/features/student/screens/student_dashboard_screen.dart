import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:smart_school/features/profile/presentation/views/profile_screen.dart';
import 'package:smart_school/features/student/screens/student_routine_screen.dart';
import 'package:smart_school/features/student/screens/student_notice_screen.dart';
import 'package:smart_school/features/student/providers/student_attendance_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/user_model.dart';
import 'package:smart_school/features/student/providers/student_homework_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/providers/notice_provider.dart';
import '../../admin/providers/setup_provider.dart';
import '../../../core/widgets/notification_icon_button.dart';
import '../../../core/widgets/marquee_notice.dart';
import 'student_attendance_screen.dart';
import 'student_result_screen.dart';
import 'student_homework_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentAttendanceNotifier>().fetchAttendance();
      context.read<NoticesNotifier>().fetchNoticesFromAPI();
      final user = context.read<AuthNotifier>().user;
      if (user?.classId != null) {
        context.read<StudentHomeworkNotifier>().fetchHomework(user!.classId!);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Attendance';
      case 2:
        return 'Results';
      case 3:
        return 'Homework';
      case 4:
        return 'Notices';
      default:
        return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          const NotificationIconButton(),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
          _buildDashboardOverview(context),
          const StudentAttendanceScreen(hideAppBar: true),
          const StudentResultScreen(hideAppBar: true),
          const StudentHomeworkScreen(hideAppBar: true),
          const StudentNoticeScreen(isFromDrawer: false,),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Results',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Homework',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardOverview(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user),
          Consumer<NoticesNotifier>(
            builder: (context, noticeNotifier, child) {
              final notices = noticeNotifier.notices
                  .where((n) => n.classId == null || n.classId == user?.classId)
                  .toList();
              return MarqueeNotice(notices: notices);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAttendanceHighLight(context),
                const SizedBox(height: 24),
                _buildSectionHeader('School Notices', () {
                  setState(() => _selectedIndex = 4);
                }),
                const SizedBox(height: 12),
                _buildNoticeHighlight(context),
                const SizedBox(height: 24),
                _buildSectionHeader('Recent Homework', () {
                  setState(() => _selectedIndex = 3);
                }),
                const SizedBox(height: 12),
                _buildHomeworkHighlight(context, subjects),
                const SizedBox(height: 24),
                _buildSectionHeader('Quick Actions', null),
                const SizedBox(height: 12),
                _buildQuickActionsGrid(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back,',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.name ?? 'Student',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onMore) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        if (onMore != null)
          TextButton(
            onPressed: onMore,
            child: const Text('View All', style: TextStyle(color: Colors.green)),
          ),
      ],
    );
  }

  Widget _buildAttendanceHighLight(BuildContext context) {
    final attendanceNotifier = context.watch<StudentAttendanceNotifier>();
    final attendanceRecords = attendanceNotifier.attendanceRecords;
    final isLoading = attendanceNotifier.isLoading;

    if (isLoading) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalDays = attendanceRecords.length;
    final presentDays = attendanceRecords
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    final percentage = totalDays == 0 ? 0.0 : presentDays / totalDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 45.0,
            lineWidth: 10.0,
            animation: true,
            percent: percentage,
            center: Text(
              "${(percentage * 100).toInt()}%",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Colors.green,
            backgroundColor: Colors.green.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  totalDays == 0 
                      ? 'No attendance records found.' 
                      : 'You were present $presentDays out of $totalDays recorded days.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: const Text(
                    'Full Report →',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeHighlight(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    final notices = context
        .watch<NoticesNotifier>()
        .notices
        .where((n) => n.classId == null || n.classId == user?.classId)
        .toList();

    if (notices.isEmpty) {
      return _buildEmptyCard('No new notices');
    }

    final latest = notices.last;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = 4),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: latest.isImportant
                ? [Colors.red.shade800, Colors.red.shade500]
                : [Colors.indigo.shade800, Colors.indigo.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (latest.isImportant ? Colors.red : Colors.indigo).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          latest.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      if (latest.isImportant)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'URGENT',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    latest.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkHighlight(BuildContext context, List<Subject> subjects) {
    final user = context.watch<AuthNotifier>().user;
    if (user == null || user.classId == null || user.sectionId == null) {
      return _buildEmptyCard('Class info missing');
    }

    final homeworkList = context.watch<StudentHomeworkNotifier>().homeworkList;

    if (homeworkList.isEmpty) {
      return _buildEmptyCard('No pending homework');
    }

    final latest = homeworkList.last;
    final hwData = latest.homework;

    if (hwData == null) {
      return _buildEmptyCard('Homework data unavailable');
    }

    final subject = subjects
        .firstWhere(
          (s) => s.id == hwData.subjectId,
          orElse: () => Subject(id: '', name: 'Subject'),
        )
        .name;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                'Due: ${DateFormat('MMM d').format(hwData.dueDate)}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hwData.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hwData.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: latest.status == 'done'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  latest.status.toUpperCase(),
                  style: TextStyle(
                    color: latest.status == 'done' ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildQuickActionItem(
          Icons.calendar_month_rounded,
          'My Routine',
          Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRoutineScreen())),
        ),
        _buildQuickActionItem(
          Icons.emoji_events_rounded,
          'Exam Results',
          Colors.green,
          () => setState(() => _selectedIndex = 2),
        ),
        _buildQuickActionItem(
          Icons.library_books_rounded,
          'Material',
          Colors.blue,
          () {}, // Placeholder for future feature
        ),
        _buildQuickActionItem(
          Icons.contact_support_rounded,
          'Queries',
          Colors.teal,
          () {}, // Placeholder for future feature
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF2D3142),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
