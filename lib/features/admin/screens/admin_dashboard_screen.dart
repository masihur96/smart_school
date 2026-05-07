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
import '../models/admin_dashboard_model.dart';
import '../providers/admin_dashboard_provider.dart';

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
          context.read<AdminDashboardProvider>().fetchDashboardData();
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
            _buildDashboardOverview(l10n, authNotifier),
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


  Widget _buildDashboardOverview(AppLocalizations l10n, AuthNotifier authNotifier) {
    return Consumer<AdminDashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.dashboardData == null) {
          return const Center(child: CircularProgressIndicator(color: Colors.purple));
        }

        if (provider.error != null && provider.dashboardData == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchDashboardData(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                  child: Text('Retry'),
                )
              ],
            ),
          );
        }

        final data = provider.dashboardData;
        if (data == null) return const SizedBox.shrink();

        return RefreshIndicator(
          onRefresh: () => provider.fetchDashboardData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubscriptionCard(authNotifier, l10n),
                _buildSectionTitle(l10n.schoolOverview),
                const SizedBox(height: 16),
                _buildStatsOverview(data),
                const SizedBox(height: 24),
                _buildSectionTitle(l10n.attendanceOverview),
                const SizedBox(height: 16),
                _buildAttendanceCards(data),
                const SizedBox(height: 24),
                if (data.recentHomework.isNotEmpty) ...[
                  _buildSectionTitle('Recent Homework'),
                  const SizedBox(height: 12),
                  _buildRecentHomework(data.recentHomework),
                  const SizedBox(height: 24),
                ],
                if (data.currentExam.isNotEmpty) ...[
                  _buildSectionTitle('Current Exams'),
                  const SizedBox(height: 12),
                  _buildCurrentExams(data.currentExam),
                  const SizedBox(height: 24),
                ],
                if (data.recentNotice.isNotEmpty) ...[
                  _buildSectionTitle('Recent Notices'),
                  const SizedBox(height: 12),
                  _buildRecentNotices(data.recentNotice),
                  const SizedBox(height: 24),
                ],
                _buildSectionTitle(l10n.quickActions),
                const SizedBox(height: 16),
                _buildQuickActions(l10n),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E1B4B),
      ),
    );
  }

  Widget _buildStatsOverview(AdminDashboardData data) {
    return Row(
      children: [
        Expanded(
          child: _buildGradientStatCard(
            title: 'Total Students',
            value: data.attendStudent.totalStudents.toString(),
            icon: Icons.people_outline,
            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGradientStatCard(
            title: 'Total Teachers',
            value: data.attendTeacher.totalTeachers.toString(),
            icon: Icons.person_outline,
            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCards(AdminDashboardData data) {
    return Column(
      children: [
        _buildAttendanceDetailCard(
          title: 'Student Attendance',
          date: data.attendStudent.date,
          total: data.attendStudent.totalStudents,
          present: data.attendStudent.present,
          absent: data.attendStudent.absent,
          rate: data.attendStudent.attendanceRate,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildAttendanceDetailCard(
          title: 'Teacher Attendance',
          date: data.attendTeacher.date,
          total: data.attendTeacher.totalTeachers,
          present: data.attendTeacher.present,
          absent: data.attendTeacher.absent,
          rate: data.attendTeacher.attendanceRate,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAttendanceDetailCard({
    required String title,
    required String date,
    required int total,
    required int present,
    required int absent,
    required double rate,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: $date',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAttendanceStatItem('Total', total.toString(), Colors.grey[700]!),
              _buildAttendanceStatItem('Present', present.toString(), Colors.green),
              _buildAttendanceStatItem('Absent', absent.toString(), Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? (present / total) : 0,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 75 ? Colors.green : (rate >= 50 ? Colors.orange : Colors.red),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAttendanceStatItem(String label, String value, Color color) {
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
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHomework(List<RecentHomework> homeworkList) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeworkList.length,
        itemBuilder: (context, index) {
          final hw = homeworkList[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${hw.className} - ${hw.sectionName}',
                        style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      hw.dueDate,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  hw.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  hw.subjectName,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const Spacer(),
                Text(
                  hw.description,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentExams(List<CurrentExam> exams) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final exam = exams[index];
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.assignment_turned_in, color: Colors.white, size: 28),
                const Spacer(),
                Text(
                  exam.examName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${exam.startDate} to ${exam.endDate}',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentNotices(List<RecentNotice> notices) {
    return Column(
      children: notices.map((notice) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notice.isImportent ? Colors.red.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notice.isImportent ? Icons.priority_high : Icons.notifications_none,
                  color: notice.isImportent ? Colors.red : Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notice.content,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'For: ${notice.targetAudience}',
                          style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          notice.createdAt.split('T').first,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildActionCard(
          l10n.addStudent,
          Icons.person_add,
          Colors.blue,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditStudentScreen())),
        ),
        _buildActionCard(
          l10n.addTeacher,
          Icons.group_add,
          Colors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditTeacherScreen())),
        ),
        _buildActionCard(
          l10n.postNotice,
          Icons.post_add,
          Colors.red,
          () => setState(() => _selectedIndex = 3),
        ),
        _buildActionCard(
          l10n.manageRoutine,
          Icons.calendar_month,
          Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutineManagementScreen())),
        ),
        _buildActionCard(
          l10n.teacherAttendance,
          Icons.how_to_reg,
          Colors.green,
          () {
            final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
            Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherSelfAttendanceDetailScreen(schoolId: schoolId)));
          },
        ),
        _buildActionCard(
          l10n.marqueeMessage,
          Icons.campaign_outlined,
          Colors.redAccent,
          () {
            final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditMarqueeScreen(schoolId: schoolId)));
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(AuthNotifier auth, AppLocalizations l10n) {
    final sub = auth.adminSubscription;
    if (sub == null) return const SizedBox.shrink();

    final isValid = auth.isSubscriptionValid;
    final planName = sub.pricingPlan?.name ?? 'No Plan';
    final expiryDate = DateTime.tryParse(sub.endDate);
    final formattedDate = expiryDate != null ? DateFormat('MMM dd, yyyy').format(expiryDate) : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isValid ? [Colors.purple.shade700, Colors.purple.shade400] : [Colors.red.shade700, Colors.red.shade400],
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
            child: Icon(isValid ? Icons.star : Icons.error_outline, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(planName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${sub.lastStudentCount} / ${sub.pricingPlan?.maxStudents ?? '∞'} ${l10n.studentsLabel}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(isValid ? 'Valid until $formattedDate' : 'Expired on $formattedDate', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
              ],
            ),
          ),
          if (isValid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text(l10n.active, style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
