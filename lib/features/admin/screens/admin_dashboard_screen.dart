import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/configs/custom_size.dart';
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
import '../../../core/services/geocoding_service.dart';


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
                // _buildSectionTitle(l10n.schoolOverview),
                // const SizedBox(height: 16),
                // _buildStatsOverview(data),
                // const SizedBox(height: 24),
                _buildSectionTitle(l10n.attendanceOverview,SizedBox()),
                const SizedBox(height: 16),
                _buildAttendanceCards(data),
                const SizedBox(height: 24),
                if (data.recentHomework.isNotEmpty) ...[
                  _buildSectionTitle('Recent Homework',TextButton(onPressed: (){}, child: Text("View All"))),
                  const SizedBox(height: 12),
                  _buildRecentHomework(data.recentHomework),
                  const SizedBox(height: 24),
                ],
                if (data.currentExam.isNotEmpty) ...[
                  _buildSectionTitle('Current Exams',TextButton(onPressed: (){}, child: Text("View All"))),
                  const SizedBox(height: 12),
                  _buildCurrentExams(data.currentExam),
                  const SizedBox(height: 24),
                ],
                if (data.recentNotice.isNotEmpty) ...[
                  _buildSectionTitle('Recent Notices',TextButton(onPressed: (){}, child: Text("View All"))),
                  const SizedBox(height: 12),
                  _buildRecentNotices(data.recentNotice),
                  const SizedBox(height: 24),
                ],
                _buildSectionTitle(l10n.quickActions,SizedBox()),
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

  Widget _buildSectionTitle(String title, Widget trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1B4B),
          ),
        ),
        trailing
      ],
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
        _buildStudentAttendanceCard(data.attendStudent),
        const SizedBox(height: 16),
        _buildTeacherAttendanceCard(data.attendTeacher),
      ],
    );
  }

  Widget _buildStudentAttendanceCard(AttendStudent data) {
    const color = Colors.blue;
    final total = data.totalStudents;
    final present = data.present;
    final absent = data.absent;
    final rate = data.attendanceRate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group_outlined,
                    color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Attendance',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      data.date,
                      style:
                      TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: const TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),


          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatPill('Total', total.toString(),
                  Colors.grey[700]!, Icons.groups_rounded),
            _buildStatPill('Present', present.toString(),
                Colors.green, Icons.how_to_reg_rounded),
              _buildStatPill('Absent',  absent.toString(),
                  Colors.red, Icons.unpublished_rounded),
              _buildStatPill('Leave',  data.leave.toString(),
                  Colors.orange, Icons.time_to_leave_outlined),

            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? (present / total) : 0,
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 75 ? Colors.green : (rate >= 50 ? Colors.orange : Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherAttendanceCard(AttendTeacher data) {
    final total = data.totalTeachers;
    final present = data.present;
    final absent = data.absent;
    final rate = data.attendanceRate;
    final rateColor = rate >= 75
        ? const Color(0xFF10B981)
        : rate >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.how_to_reg_rounded,
                      color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teacher Attendance',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        data.date,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rateColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${rate.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: rateColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // ── Stats pills ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatPill('Total', total.toString(),
                    const Color(0xFF6B7280), Icons.groups_rounded),
                const SizedBox(width: 8),
                _buildStatPill('Present', present.toString(),
                    const Color(0xFF10B981), Icons.check_circle_outline),
                const SizedBox(width: 8),
                _buildStatPill('Absent', absent.toString(),
                    const Color(0xFFEF4444), Icons.cancel_outlined),
              ],
            ),
          ),

          // ── Progress bar ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total > 0 ? (present / total) : 0,
                minHeight: 6,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(rateColor),
              ),
            ),
          ),

          // ── Records horizontal scroll ────────────────────
          if (data.recentRecords.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 0, 8),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 13, color: Colors.purple),
                  const SizedBox(width: 5),
                  Text(
                    "Today's Records",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: screenSize(context, .3),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: data.recentRecords.length,
                itemBuilder: (context, index) {
                  final r = data.recentRecords[index];
                  final isClockedIn = r.status == 'clock-in';
                  final statusColor = isClockedIn
                      ? const Color(0xFF10B981)
                      : const Color(0xFF3B82F6);
                  final initial = r.teacherName.isNotEmpty
                      ? r.teacherName[0].toUpperCase()
                      : '?';
                  final inTime = r.startTime.length >= 5
                      ? r.startTime.substring(0, 5)
                      : r.startTime;
                  final outTime =
                      (r.endTime != null && r.endTime!.length >= 5)
                          ? r.endTime!.substring(0, 5)
                          : '--:--';
                  final lat =
                      double.tryParse(r.lat)?.toStringAsFixed(3) ?? r.lat;
                  final lon =
                      double.tryParse(r.lon)?.toStringAsFixed(3) ?? r.lon;

                  return Container(
                    width: 148,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.2),
                          width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar + status dot
                        Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),)

                              ],
                            ),

                            SizedBox(width: 5,),

                            // Name
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.teacherName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  r.designation.isNotEmpty
                                      ? r.designation
                                      : 'Teacher',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),


                          ],
                        ),
                        const SizedBox(height: 6),
                        // In / Out times
                        Row(
                          children: [
                            Icon(Icons.login_rounded,
                                size: 10, color: Colors.green[600]),
                            const SizedBox(width: 3),
                            Text(inTime,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600)),
                      Spacer(),
                            Icon(Icons.logout_rounded,
                                size: 10,
                                color: outTime == '--:--'
                                    ? Colors.grey
                                    : Colors.blue[600]),
                            const SizedBox(width: 3),
                            Text(outTime,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: outTime == '--:--'
                                        ? Colors.grey
                                        : Colors.blue[700],
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Location – reverse geocoded
                        FutureBuilder<String>(
                          future: GeocodingService().getPlaceName(r.lat, r.lon),
                          builder: (context, snapshot) {
                            final place = snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? '...'
                                : (snapshot.data ??
                                    '${double.tryParse(r.lat)?.toStringAsFixed(3) ?? r.lat}, '
                                    '${double.tryParse(r.lon)?.toStringAsFixed(3) ?? r.lon}');
                            return Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 10, color: Colors.grey[400]),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    place,
                                    style: TextStyle(
                                        fontSize: 9, color: Colors.grey[500]),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                      ],
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Center(
                child: Text(
                  'No records for today',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatPill(
      String label,
      String value,
      Color color,
      IconData icon,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        margin: const EdgeInsets.symmetric( horizontal: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(icon, size: 14, color: color),
            // const SizedBox(width: 4),

            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),

            const SizedBox(width: 4),

            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
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
