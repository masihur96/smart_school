import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/configs/custom_size.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/screens/class_detail_screen.dart';
import 'package:smart_school/features/profile/presentation/views/profile_screen.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/user_model.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/marquee_notice.dart';
import '../../../core/widgets/notification_icon_button.dart';
import '../../admin/providers/marquee_provider.dart';
import '../../admin/providers/notice_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/teacher_dashboard_model.dart';
import '../providers/teacher_dashboard_provider.dart';
import 'homework_management_screen.dart';
import 'mark_entry_screen.dart';
import 'teacher_attendance_screen.dart';
import 'teacher_self_attendance_detail_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now);
      final apiDateStr = DateFormat('yyyy-MM-dd').format(now);
      context.read<TeacherDashboardProvider>().fetchTeacherDashboard();
      context.read<TeacherDashboardProvider>().fetchTodayClasses(dayName);
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
        return l10n.teacherDashboard;
      case 1:
        return l10n.attendance;
      case 2:
        return l10n.markEntry;
      case 3:
        return l10n.homework;
      default:
        return l10n.teacherDashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;

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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getTitle(l10n),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                user?.school?.name ?? 'School Name',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.primaryTeacher,
          foregroundColor: Colors.white,
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
            _buildDashboardOverview(
              context,
              user?.name ?? 'Teacher',
              user!,
              l10n,
            ),
            const TeacherAttendanceScreen(hideAppBar: true),
            const MarkEntryScreen(hideAppBar: true),
            const HomeworkManagementScreen(hideAppBar: true),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.green.shade700,
            unselectedItemColor: Colors.grey.shade500,

            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard),
                label: l10n.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.check_circle_outline),
                activeIcon: const Icon(Icons.check_circle),
                label: l10n.attendance,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.assignment_turned_in_outlined),
                activeIcon: const Icon(Icons.assignment_turned_in),
                label: l10n.marks,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.assignment_outlined),
                activeIcon: const Icon(Icons.assignment),
                label: l10n.homework,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardOverview(
    BuildContext context,
    String name,
    User user,
    AppLocalizations l10n,
  ) {
    final provider = context.watch<TeacherDashboardProvider>();
    final data = provider.dashboardData;
    final classes = provider.todayClasses
        .where((c) => c.teacherId == user.id)
        .toList();
    classes.sort((a, b) => a.startTime.compareTo(b.startTime));

    return RefreshIndicator(
      onRefresh: () => provider.fetchTeacherDashboard(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernHeader(context, name, classes.length, user, l10n),
            if (data?.marqueeData != null)
              MarqueeNotice(customText: data!.marqueeData!.text),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("My ${l10n.attendance}", onSeeAll: () {}),
                  _buildAttendanceSection(context, data, l10n),
                  const SizedBox(height: 24),
                  if (data?.myClassAttendStudents.isNotEmpty ?? false) ...[
                    _buildSectionHeader(l10n.attendance, onSeeAll: () {}),
                    const SizedBox(height: 12),
                    ...data!.myClassAttendStudents.map((stats) => _buildClassPerformanceCard(context, stats)),
                    const SizedBox(height: 24),
                  ],
                  if (classes.isNotEmpty) ...[
                    _buildSectionHeader(l10n.scheduleToday, onSeeAll: () {}),
                    const SizedBox(height: 12),
                    ...classes.map((c) => _buildClassCard(context, c)),
                    const SizedBox(height: 24),
                  ],
                  _buildExamsSection(context, l10n),
                  const SizedBox(height: 24),
                  if (data?.mySubmittedHomework.isNotEmpty ?? false) ...[
                    _buildSectionHeader(l10n.recentHomework, onSeeAll: () => setState(() => _selectedIndex = 3)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: data!.mySubmittedHomework.length,
                        itemBuilder: (context, index) => _buildHomeworkCard(context, data.mySubmittedHomework[index]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (data?.recentNotice.isNotEmpty ?? false) ...[
                    _buildSectionHeader(l10n.notices, onSeeAll: () {}),
                    const SizedBox(height: 12),
                    ...data!.recentNotice.take(3).map((notice) => _buildNoticeCard(context, notice)),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    l10n.quickActions,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActionsGrid(context, l10n),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All', // Use l10n if available
              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }


  Widget _buildModernHeader(
    BuildContext context,
    String name,
    int count,
    User user,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryTeacher,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: const Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      user.designation ?? 'General Teacher',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),


        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
      ],
    );
  }

  Widget _buildAttendanceSection(BuildContext context, TeacherDashboardData? data, AppLocalizations l10n) {
    final status = data?.attendanceStatus;
    final isClockedIn = status?.status == 'clock-in';
    final isClockedOut = status?.status == 'clock-out';
    final record = status?.record;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isClockedIn ? Colors.orange.shade50 : (isClockedOut ? Colors.green.shade50 : Colors.blue.shade50),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isClockedIn ? Icons.timer : (isClockedOut ? Icons.task_alt : Icons.location_history),
                  color: isClockedIn ? Colors.orange : (isClockedOut ? Colors.green : Colors.blue),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isClockedIn
                          ? 'Shift In Progress'
                          : (isClockedOut ? 'Shift Completed' : 'Not Started Yet'),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMM dd').format(DateTime.now()),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _performSelfAttendance(context, context.read<AuthNotifier>().user, l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isClockedIn ? Colors.orange : (isClockedOut ? Colors.green.shade50 : AppColors.primaryTeacher),
                  foregroundColor: isClockedOut ? Colors.green : Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  isClockedIn ? l10n.clockOut : (isClockedOut ? 'Update' : l10n.clockIn),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                _buildTimeInfo(
                  'IN TIME',
                  status?.clockInTime ?? '--:--',
                  Colors.green,
                  Icons.login_rounded,
                ),
                Container(
                  height: 30,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  color: Colors.grey.shade300,
                ),
                _buildTimeInfo(
                  'OUT TIME',
                  status?.clockOutTime ?? '--:--',
                  Colors.red,
                  Icons.logout_rounded,
                ),
                const Spacer(),
                if (record != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          FutureBuilder<String>(
                            future: context.read<TeacherDashboardProvider>().getAddressFromLatLng(record.lat, record.lon),
                            builder: (context, snapshot) {
                              return ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 100),
                                child: Text(
                                  snapshot.data ?? 'Locating...',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.distanceFromCenter.toInt()}m away',
                        style: TextStyle(
                          color: record.distanceFromCenter > 100 ? Colors.orange : Colors.green.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (data?.myAttendanceList.isNotEmpty ?? false) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(height: 1, thickness: 0.8),
            ),
            const Text(
              'Recent History',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: data!.myAttendanceList.length,
                itemBuilder: (context, index) {
                  final att = data.myAttendanceList[index];
                  final date = DateTime.parse(att.date);
                  final isClockOut = att.status == 'clock-out';

                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isClockOut ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isClockOut ? Colors.green.shade100 : Colors.orange.shade100,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('dd MMM').format(date),
                              style: TextStyle(
                                color: isClockOut ? Colors.green.shade800 : Colors.orange.shade800,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isClockOut ? Icons.check_circle : Icons.login,
                              size: 14,
                              color: isClockOut ? Colors.green.shade600 : Colors.orange.shade600,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildHistoryTime('In', att.startTime ?? att.time),
                            const SizedBox(width: 8),
                            _buildHistoryTime('Out', att.endTime ?? '--:--'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 10, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 80,
                              child: FutureBuilder<String>(
                                future: context.read<TeacherDashboardProvider>().getAddressFromLatLng(att.lat, att.lon),
                                builder: (context, snapshot) {
                                  return Text(
                                    snapshot.data ?? '...',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${att.distanceFromCenter.toInt()}m)',
                              style: TextStyle(
                                color: att.distanceFromCenter > 100 ? Colors.orange.shade700 : Colors.green.shade700,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }


  Widget _buildHistoryTime(String type, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildClassPerformanceCard(BuildContext context, MyClassAttendStudent stats) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: stats.attendanceRate / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      stats.attendanceRate > 80 ? Colors.green : (stats.attendanceRate > 50 ? Colors.orange : Colors.red),
                    ),
                  ),
                ),
                Text(
                  '${stats.attendanceRate.toInt()}%',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.classInfo?.name ?? 'Class',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${stats.present} Present / ${stats.total} Total',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(BuildContext context, Homework homework) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  homework.subjectInfo?.name ?? 'Subject',
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                homework.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Class: ${homework.classInfo?.name ?? "--"}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Due: ${DateFormat('dd MMM').format(homework.dueDate)}',
                style: const TextStyle(fontSize: 10, color: Colors.red),
              ),
              const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(BuildContext context, Notice notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notice.isImportant ? Colors.amber.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: notice.isImportant ? Colors.amber.shade200 : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (notice.isImportant)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.priority_high, color: Colors.amber, size: 16),
                ),
              Expanded(
                child: Text(
                  notice.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'New', // Logic for new label
                style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            notice.content,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(notice.postedBy ?? 'Admin', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const Spacer(),
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              const Text('Today', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }


  Future<void> _performSelfAttendance(
    BuildContext context,
    User? user,
    AppLocalizations l10n,
  ) async {
    if (user == null ||
        user.lat == null ||
        user.lon == null ||
        user.radius == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.locationNotConfigured)));
      return;
    }

    try {
      // 1. Check/Request permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied.'),
            ),
          );
        }
        return;
      }

      // 2. Get current position
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fetching current location...')),
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Calculate distance
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        user.lat!,
        user.lon!,
      );
      print(user.radius);
      print(user.lat);
      print(user.lon);
      print(position.latitude);
      print(position.longitude);

      if (distanceInMeters <= user.radius!) {
        // 4. Submit attendance
        if (mounted) {
          context
              .read<TeacherDashboardProvider>()
              .submitSelfAttendance(position.latitude, position.longitude)
              .then((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.attendanceMarkedSuccessfully),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              })
              .catchError((e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.submissionFailed}: $e')),
                  );
                }
              });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.outOfRange} (${distanceInMeters.toStringAsFixed(0)}m away). Allowed radius: ${user.radius}m',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    }
  }

  Widget _buildClassCard(BuildContext context, RoutineEntry classInfo) {
    final classNameText =
        classInfo.classEntity?.name ?? 'Class ${classInfo.classId}';
    final sectionNameText = classInfo.sectionEntity?.name != null
        ? ' - ${classInfo.sectionEntity!.name}'
        : '';
    final className = '$classNameText$sectionNameText';
    final subjectName =
        classInfo.subjectEntity?.name ?? 'Subject ${classInfo.subjectId}';

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassDetailScreen(
                subjectID: classInfo.subjectId ?? "",
                classRoom: classInfo.classEntity!,
                sectionId: classInfo.sectionId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.book, color: Colors.blue.shade700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      className,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subjectName),
                    if (classInfo.teacherEntity != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            classInfo.teacherEntity!.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "${classInfo.startTime.split(':').take(2).join(':')} - ${classInfo.endTime.split(':').take(2).join(':')}",
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamsSection(BuildContext context, AppLocalizations l10n) {
    final provider = context.watch<TeacherDashboardProvider>();
    final allExams = provider.exams;

    // Filter exams to show only running or upcoming
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final exams = allExams.where((exam) {
      if (exam.endDate != null) {
        final end = DateTime(
          exam.endDate!.year,
          exam.endDate!.month,
          exam.endDate!.day,
        );
        return end.isAfter(today) || end.isAtSameMomentAs(today);
      } else if (exam.startDate != null) {
        final start = DateTime(
          exam.startDate!.year,
          exam.startDate!.month,
          exam.startDate!.day,
        );
        return start.isAfter(today) || start.isAtSameMomentAs(today);
      }
      return true; // if no dates specified, keep it
    }).toList();

    if (provider.isLoading && exams.isEmpty) {
      return const SizedBox(); // don't show while loading
    }
    if (exams.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.upcomingExams,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (exams.length > 2)
              TextButton(onPressed: () {}, child: Text(l10n.viewAll)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              return _buildExamCard(context, exam);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExamCard(BuildContext context, Exam exam) {
    final assignmentsCount = exam.assignments.length;
    final startDateStr = exam.startDate != null
        ? DateFormat('MMM dd, yyyy').format(exam.startDate!)
        : 'N/A';

    return Container(
      width: screenSize(context, .88),
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.deepPurple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.assignment_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exam.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        exam.isPublished ? 'Published' : 'Upcoming',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  exam.description ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starts On',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          startDateStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        _showExamRoutinesDialog(context, exam);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 14,
                              color: Colors.deepPurple.shade900,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$assignmentsCount Routines',
                              style: TextStyle(
                                color: Colors.deepPurple.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExamRoutinesDialog(BuildContext context, Exam exam) {
    showDialog(
      context: context,
      builder: (context) {
        return ExamRoutinesDialog(exam: exam);
      },
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, AppLocalizations l10n) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildActionGridItem(
          context,
          l10n.attendance,
          Icons.how_to_reg,
          Colors.blue,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
        _buildActionGridItem(
          context,
          l10n.markEntry,
          Icons.grade,
          Colors.indigo,
          onTap: () => setState(() => _selectedIndex = 2),
        ),
        _buildActionGridItem(
          context,
          l10n.homework,
          Icons.menu_book,
          Colors.orange,
          onTap: () => setState(() => _selectedIndex = 3),
        ),
        _buildActionGridItem(
          context,
          l10n.results, // Using results as report
          Icons.bar_chart,
          Colors.purple,
          onTap: () {}, // Future: Add reports screen
        ),
      ],
    );
  }

  Widget _buildActionGridItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return Card(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load classes: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, color: Colors.blueGrey.shade300, size: 48),
          const SizedBox(height: 16),
          Text(
            'No classes scheduled for today',
            style: TextStyle(
              color: Colors.blueGrey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ExamRoutinesDialog extends StatelessWidget {
  final Exam exam;

  const ExamRoutinesDialog({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    if (exam.assignments.isEmpty) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No routines assigned yet.'),
        ),
      );
    }

    final Map<String, List<ExamAssignment>> grouped = {};
    for (var a in exam.assignments) {
      grouped.putIfAbsent(a.className, () => []).add(a);
    }

    final classNames = grouped.keys.toList();
    classNames.sort((a, b) {
      final order = [
        'Play',
        'Nursery',
        'One',
        'Two',
        'Three',
        'Four',
        'Five',
        'Six',
        'Seven',
        'Eight',
        'Nine',
        'Ten',
      ];
      final indexA = order.indexOf(a);
      final indexB = order.indexOf(b);
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      return a.compareTo(b);
    });

    return DefaultTabController(
      length: classNames.length,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 650, maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade600,
                      Colors.deepPurple.shade900,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.event_note,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Exam Routines',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  exam.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: classNames
                          .map((c) => Tab(text: 'Class $c'))
                          .toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: classNames.map((className) {
                    final assignments = grouped[className]!;
                    assignments.sort((a, b) => a.date.compareTo(b.date));

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: assignments.length,
                      itemBuilder: (context, index) {
                        final assignment = assignments[index];
                        final dateStr = DateFormat(
                          'EEEE, MMM dd',
                        ).format(assignment.date);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.purple.shade50,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.book,
                                        size: 24,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            assignment.subjectName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              color: Colors.purple.shade700,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      size: 18,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Examiner: ',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        assignment.examinerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (assignment.syllabus != null &&
                                    assignment.syllabus!.isNotEmpty &&
                                    assignment.syllabus != "N/A") ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.menu_book,
                                        size: 18,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Syllabus: ',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          assignment.syllabus!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.purple.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
