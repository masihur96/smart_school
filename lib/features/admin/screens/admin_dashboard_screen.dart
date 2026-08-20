import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/features/profile/presentation/screens/profile_screen.dart';

import 'add_edit_student_screen.dart';
import 'add_edit_teacher_screen.dart';
import 'package:smart_school/configs/custom_size.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/student_performance_provider.dart';
import 'package:smart_school/features/admin/providers/teacher_performance_provider.dart';
import 'package:smart_school/features/admin/screens/student_performance_screen.dart';
import 'package:smart_school/features/admin/screens/teacher_performance_screen.dart';


import 'package:smart_school/l10n/app_localizations.dart';

import '../../../core/services/geocoding_service.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/notification_icon_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../models/admin_dashboard_model.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/student_provider.dart';
import '../providers/teacher_provider.dart';
import 'admin_homework_management_screen.dart';
import 'exam_management_screen.dart';
import 'notice_management_screen.dart';
import 'student_attendance_management_screen.dart';
import 'student_management_screen.dart';
import 'teacher_attendance_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: ZoomDrawerController(),
      mainScreenTapClose: true,
      style: DrawerStyle.defaultStyle,
      androidCloseOnBackTap: true,
      menuScreen: const AppDrawer(),
      mainScreen: const AdminDashboardContent(),
      borderRadius: 24.0,
      showShadow: true,
       angle: 0.0,
      openCurve: Curves.fastOutSlowIn,
      closeCurve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 500),
      drawerShadowsBackgroundColor: Colors.grey.shade300,
      slideWidth: MediaQuery.of(context).size.width * 0.65,
    );
  }
}

class AdminDashboardContent extends StatefulWidget {
  const AdminDashboardContent({super.key});

  @override
  State<AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<AdminDashboardContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Tracks which tabs have been opened at least once for lazy init.
  final Set<int> _tabsInitialized = {0};

  /// Lazy-fetch guards — each performance section triggers its own
  /// provider fetch exactly once when it first becomes visible.
  bool _teacherPerfFetched = false;
  bool _studentPerfFetched = false;

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      if (_tabController.index == 2) {
        // Prevent selection of the dummy middle tab
        _tabController.index = _tabController.previousIndex;
        return;
      }
      setState(() {
        _tabsInitialized.add(_tabController.index);
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Only the two core calls on startup — no teacher/student perf here.
      context.read<AdminDashboardProvider>().fetchDashboardData();
      context.read<NotificationNotifier>().fetchNotifications();
      context.read<StudentsNotifier>().fetchStudents();
      context.read<TeachersNotifier>().fetchTeachers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _selectedIndex => _tabController.index;

  String _getTitle(AppLocalizations l10n) {
    final authNotifier = context.watch<AuthNotifier>();
    switch (_selectedIndex) {
      case 0:
        return authNotifier.user?.school?.name ?? l10n.studentManagement;
      case 1:
        return l10n.studentManagement;
      case 3:
        return l10n.examManagement;
      case 4:
        return l10n.schoolNotices;
      default:
        return l10n.adminDashboard;
    }
  }

  Color get _primaryColor => AppColors.primaryAdmin;

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          leadingWidth: screenSize(context, .15),
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => ZoomDrawer.of(context)?.toggle(),
          ),
          title: Text(
            _getTitle(l10n),
            style: const TextStyle(color: AppColors.white),
          ),
          iconTheme: const IconThemeData(color: AppColors.white),
          backgroundColor: AppColors.primaryAdmin,
          foregroundColor: Colors.white,
          actions: [
            NotificationIconButton(color: AppColors.primaryAdmin),
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
        body: BottomBar(
          layout: BottomBarLayout(
            width: MediaQuery.of(context).size.width,
            offset: 10,
            borderRadius: BorderRadius.circular(28),
            clip: Clip.none,
          ),
          theme: BottomBarThemeData(
            barDecoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: true),
          showIcon: false,
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDashboardOverview(l10n, authNotifier),
              _tabsInitialized.contains(1)
                  ? const StudentManagementScreen(hideAppBar: true)
                  : const SizedBox.shrink(),
              const SizedBox.shrink(), // Dummy for FAB gap
              _tabsInitialized.contains(3)
                  ? const ExamManagementScreen(hideAppBar: true)
                  : const SizedBox.shrink(),
              _tabsInitialized.contains(4)
                  ? const NoticeManagementScreen(hideAppBar: true)
                  : const SizedBox.shrink(),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: _primaryColor,
                labelColor: _primaryColor,
                unselectedLabelColor:
                    isDark ? Colors.white54 : Colors.grey.shade500,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                onTap: (index) {
                  if (index == 2) {
                    _tabController.index = _tabController.previousIndex;
                  }
                },
                tabs: [
                  Tab(icon: const Icon(Icons.dashboard_outlined), text: l10n.home),
                  Tab(icon: const Icon(Icons.people_outline), text: l10n.students),
                  const Tab(child: SizedBox(width: 48)), // Gap for FAB
                  Tab(
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    text: l10n.exams,
                  ),
                  Tab(
                    icon: const Icon(Icons.announcement_outlined),
                    text: l10n.notices,
                  ),
                ],
              ),
              Positioned(
                top: -16,
                child: Theme(
                  data: Theme.of(context).copyWith(useMaterial3: true),
                  child: PopupMenuButton<int>(
                    offset: const Offset(0, -110),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    icon: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAdmin,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                    onSelected: (value) {
                      if (value == 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddEditStudentScreen(),
                          ),
                        );
                      } else if (value == 1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddEditTeacherScreen(),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 0,
                        child: Row(
                          children: [
                            const Icon(Icons.person_add,
                                color: AppColors.primaryAdmin),
                            const SizedBox(width: 12),
                            Text(l10n.addStudent,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 1,
                        child: Row(
                          children: [
                            const Icon(Icons.person_add_alt_1,
                                color: AppColors.primaryAdmin),
                            const SizedBox(width: 12),
                            Text(l10n.addTeacher,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardOverview(
    AppLocalizations l10n,
    AuthNotifier authNotifier,
  ) {
    return Consumer<AdminDashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading ) {
          return _buildShimmerLoading(context);
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.retry),
                ),
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
                const SizedBox(height: 24),
                if (provider.monthlyAttendanceOverview != null) ...[
                  _buildMonthlyAttendanceChart(
                    provider.monthlyAttendanceOverview!,
                  ),
                  const SizedBox(height: 24),
                ],
                _buildAttendanceCards(data),
                const SizedBox(height: 24),
                if (data.recentHomework.isNotEmpty) ...[
                  _buildSectionTitle(
                    l10n.recentHomework,
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminHomeworkManagementScreen(),
                          ),
                        );
                      },
                      child: Text(l10n.viewAll),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentHomework(data.recentHomework),
                  const SizedBox(height: 24),
                ],
                if (data.currentExam.isNotEmpty) ...[
                  _buildSectionTitle(
                    l10n.currentExams,
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExamManagementScreen(),
                          ),
                        );
                      },
                      child: Text(l10n.viewAll),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCurrentExams(data.currentExam),
                  const SizedBox(height: 24),
                ],
                if (data.recentNotice.isNotEmpty) ...[
                  _buildSectionTitle(
                    l10n.recentNotices,
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NoticeManagementScreen(),
                          ),
                        );
                      },
                      child: Text(l10n.viewAll),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentNotices(data.recentNotice),
                  const SizedBox(height: 24),
                ],
                _buildTeacherPerformancePreview(context),
                const SizedBox(height: 24),
                _buildStudentPerformancePreview(context),
                const SizedBox(height: 24),
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing,
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
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGradientStatCard(
            title: 'Total Teachers',
            value: data.attendTeacher.totalTeachers.toString(),
            icon: Icons.person_outline,
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyAttendanceChart(MonthlyAttendanceOverview data) {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.data.length; i++) {
      spots.add(
        FlSpot(
          data.data[i].month.toDouble(),
          data.data[i].attendancePercentage,
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Attendance Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Year ${data.year}', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec',
                          ];
                          if (value.toInt() >= 1 && value.toInt() <= 12) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                months[value.toInt() - 1],
                                style: TextStyle(
                                  // color: Colors.grey[600],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              // color: Colors.grey[600],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 1,
                  maxX: 12,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.purple,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.3),
                            Colors.purple.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec',
                          ];
                          final monthStr = months[touchedSpot.x.toInt() - 1];
                          return LineTooltipItem(
                            '$monthStr\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '${touchedSpot.y.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
          ),
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

  List<_AdminClassStats> _getGroupedStats(
    List<StudentAttendanceRecord> records,
  ) {
    final Map<String, _AdminClassStats> map = {};
    for (var r in records) {
      if (!map.containsKey(r.className)) {
        map[r.className] = _AdminClassStats(
          className: r.className,
          records: [],
        );
      }
      map[r.className]!.records.add(r);
    }
    return map.values.toList();
  }

  Widget _buildStudentAttendanceCard(AttendStudent data) {
    final l10n = AppLocalizations.of(context)!;
    const color = Colors.blue;
    final total = data.totalStudents;
    final present = data.present;
    final absent = data.absent;
    final rate = data.attendanceRate;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentAttendanceManagementScreen(),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
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
                    child: const Icon(Icons.group_outlined, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.studentAttendance,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatDate(data.date),
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${rate.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatPill(
                    l10n.total,
                    total.toString(),
                    Colors.grey[700]!,
                    Icons.groups_rounded,
                  ),
                  _buildStatPill(
                    l10n.present,
                    present.toString(),
                    Colors.green,
                    Icons.how_to_reg_rounded,
                  ),
                  _buildStatPill(
                    l10n.absent,
                    absent.toString(),
                    Colors.red,
                    Icons.unpublished_rounded,
                  ),
                  _buildStatPill(
                    l10n.leave,
                    data.leave.toString(),
                    Colors.orange,
                    Icons.time_to_leave_outlined,
                  ),
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
                    rate >= 75
                        ? Colors.green
                        : (rate >= 50 ? Colors.orange : Colors.red),
                  ),
                ),
              ),

              // ── Student Records horizontal scroll ────────────
              if (data.data.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.class_outlined,
                        size: 13,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.classWiseRecords,
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
                  height: screenSize(context, .65),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: ScrollController(initialScrollOffset: 0),
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.zero,


                    itemCount: _getGroupedStats(data.data).length,
                    itemBuilder: (context, index) {
                      final stats = _getGroupedStats(data.data)[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: SizedBox(
                          width: screenSize(context, .9),
                          child: _AdminClassPerformanceCardWithSubjectDropdown(
                            stats: stats,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
                  child: Center(
                    child: Text(
                      l10n.noRecordsForToday,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String formatTime(String? dateTime) {
    if (dateTime == null) return '--:--';

    final date = DateTime.parse(dateTime).toLocal();

    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  Widget _buildTeacherAttendanceCard(AttendTeacher data) {
    final l10n = AppLocalizations.of(context)!;
    final total = data.totalTeachers;
    final present = data.present;
    final absent = data.absent;
    final rate = data.attendanceRate;
    final rateColor = rate >= 75
        ? const Color(0xFF10B981)
        : rate >= 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TeacherAttendanceManagementScreen(),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,

        child: Padding(
          padding: const EdgeInsets.all(10.0),
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
                      child: const Icon(Icons.how_to_reg_rounded, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.teacherAttendanceLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatDate(data.date),

                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: rateColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${rate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
                    _buildStatPill(
                      l10n.total,
                      total.toString(),
                      const Color(0xFF6B7280),
                      Icons.groups_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      l10n.present,
                      present.toString(),
                      const Color(0xFF10B981),
                      Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      l10n.absent,
                      absent.toString(),
                      const Color(0xFFEF4444),
                      Icons.cancel_outlined,
                    ),
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
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.todaysRecords,
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

                      final inTime = formatTime(r.startTime);
                      final outTime = formatTime(r.endTime);

                      return Container(
                        width: 148,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
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
                                        color: statusColor.withValues(
                                          alpha: 0.15,
                                        ),
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
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(width: 5),

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
                                          : l10n.teacher,
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
                                Icon(
                                  Icons.login_rounded,
                                  size: 10,
                                  color: Colors.green[600],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  inTime,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  Icons.logout_rounded,
                                  size: 10,
                                  color: outTime == '--:--'
                                      ? Colors.grey
                                      : Colors.blue[600],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  outTime,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: outTime == '--:--'
                                        ? Colors.grey
                                        : Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Location – reverse geocoded
                            FutureBuilder<String>(
                              future: GeocodingService().getPlaceName(
                                r.lat,
                                r.lon,
                              ),
                              builder: (context, snapshot) {
                                final place =
                                    snapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? '...'
                                    : (snapshot.data ??
                                          '${double.tryParse(r.lat)?.toStringAsFixed(3) ?? r.lat}, '
                                              '${double.tryParse(r.lon)?.toStringAsFixed(3) ?? r.lon}');
                                return Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 10,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        place,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey[500],
                                        ),
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
        ),
      ),
    );
  }

  Color _studentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return const Color(0xFF10B981);
      case 'absent':
        return const Color(0xFFEF4444);
      case 'leave':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _studentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle_outline_rounded;
      case 'absent':
        return Icons.cancel_outlined;
      case 'leave':
        return Icons.time_to_leave_outlined;
      default:
        return Icons.help_outline;
    }
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
        margin: const EdgeInsets.symmetric(horizontal: 3),
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),

            const SizedBox(width: 4),

            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
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
          return Card(
            margin: EdgeInsets.only(right: 5),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SizedBox(
                width: screenSize(context, .85),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${hw.className} - ${hw.sectionName}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          formatDate(hw.dueDate),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hw.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentExams(List<CurrentExam> exams) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final exam = exams[index];
          return Card(
            margin: const EdgeInsets.only(right: 5),

            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: screenSize(context, .85),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.assignment_turned_in, size: 28),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: exam.isPublished
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            exam.isPublished ? l10n.published : l10n.draft,
                            style: TextStyle(
                              color: exam.isPublished
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      exam.examName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exam.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.examDateRange(
                        formatDate(exam.startDate),
                        formatDate(exam.endDate),
                      ),
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String formatDate(String? utcDate) {
    if (utcDate == null || utcDate.isEmpty) {
      return '--';
    }

    final localDate = DateTime.parse(utcDate).toLocal();

    return DateFormat('dd MMM yyyy').format(localDate);
  }

  Widget _buildRecentNotices(List<RecentNotice> notices) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: notices.length,
        itemBuilder: (context, index) {
          final notice = notices[index];
          return Card(
            margin: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: screenSize(context, .9),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: notice.isImportent
                                ? Colors.red.withOpacity(0.1)
                                : Colors.purple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            notice.isImportent
                                ? Icons.priority_high
                                : Icons.notifications_none,
                            color: notice.isImportent
                                ? Colors.red
                                : Colors.purple,
                            size: 20,
                          ),
                        ),
                        if (notice.isImportent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.important,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      notice.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notice.content,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.forAudience(notice.targetAudience),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          formatDate(notice.createdAt),

                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Teacher Performance Preview (from Provider) ────────────────────────────────────────────────
  Widget _buildTeacherPerformancePreview(BuildContext context) {
    return Consumer<TeacherPerformanceProvider>(
      builder: (context, provider, _) {
        // Lazy fetch — trigger exactly once when this section first renders.
        if (!_teacherPerfFetched) {
          _teacherPerfFetched = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final now = DateTime.now();
            context.read<TeacherPerformanceProvider>().fetchForMonth(
              now.month,
              now.year,
            );
          });
        }

        if (provider.isLoading && provider.allPerformances.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                'Teacher Performance',
                const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final list = provider.filteredPerformances.take(10).toList();
        if (list.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Top Teachers (${_months[provider.selectedMonth - 1]})',
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherPerformanceScreen(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primaryAdmin,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130, // Fixed height for horizontal cards
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                clipBehavior: Clip.none,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildDashboardTeacherPerfCard(
                    list[index],
                    index + 1,
                    context,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardTeacherPerfCard(
    TeacherPerformance perf,
    int rank,
    BuildContext context,
  ) {
    final provider = context.read<TeacherPerformanceProvider>();
    // Calculate total score (average of the 2 percentages)
    final score = (perf.attendance.percentage + perf.homework.percentage) / 2;

    Color badgeColor;
    String badgeText;
    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700); // Gold
      badgeText = '🥇 1st';
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0); // Silver
      badgeText = '🥈 2nd';
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32); // Bronze
      badgeText = '🥉 3rd';
    } else {
      badgeColor = Colors.grey.shade300;
      badgeText = '#$rank';
    }

    return GestureDetector(
      onTap: () {
        provider.selectTeacherByName(perf.name);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeacherPerformanceScreen()),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Rank + Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: rank <= 3 ? null : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Text(
                      '${score.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Avatar + Name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryAdmin.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        perf.name.isNotEmpty ? perf.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryAdmin,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perf.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            perf.designation.isNotEmpty
                                ? perf.designation
                                : 'Teacher',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Mini progress bars
                Row(
                  children: [
                    Expanded(
                      child: _miniProgressBar(
                        'Att',
                        perf.attendance.percentage,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniProgressBar(
                        'HW',
                        perf.homework.percentage,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniProgressBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 4,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentPerformancePreview(BuildContext context) {
    return Consumer<StudentPerformanceProvider>(
      builder: (context, perfProvider, _) {
        // Lazy fetch — trigger exactly once when this section first renders.
        if (!_studentPerfFetched) {
          _studentPerfFetched = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final now = DateTime.now();
            context.read<StudentPerformanceProvider>().fetchForMonth(
              now.month,
              now.year,
            );
          });
        }

        if (perfProvider.isLoading && perfProvider.allPerformances.isEmpty) {
          return _buildPerformanceShimmer();
        } else if (perfProvider.error != null &&
            perfProvider.allPerformances.isEmpty) {
          return _buildPerformanceError(perfProvider);
        }

        final list = perfProvider.sortedByBest.take(10).toList();
        if (list.isEmpty) {
          return _buildPerformanceEmpty(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Top Students (${_months[perfProvider.selectedMonth - 1]})',
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentPerformanceScreen(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primaryAdmin,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130, // Fixed height matching teacher cards
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                clipBehavior: Clip.none,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildDashboardPerfCard(
                    context,
                    list[index],
                    index + 1,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Compact horizontal card for student performance dashboard scroll
  Widget _buildDashboardPerfCard(
    BuildContext context,
    StudentPerformance perf,
    int rank,
  ) {
    // Calculate total score (average of the 3 percentages)
    final score =
        (perf.attendance.percentage +
            perf.homework.percentage +
            perf.exams.percentage) /
        3;

    Color badgeColor;
    String badgeText;
    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700); // Gold
      badgeText = '🥇 1st';
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0); // Silver
      badgeText = '🥈 2nd';
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32); // Bronze
      badgeText = '🥉 3rd';
    } else {
      badgeColor = Colors.grey.shade300;
      badgeText = '#$rank';
    }

    String subtitle;
    if (perf.classInfo != null) {
      final sectionPart =
          perf.section != null ? ' - ${perf.section!.name}' : '';
      final rollPart =
          perf.rollNumber != null && perf.rollNumber!.isNotEmpty
              ? ' • Roll ${perf.rollNumber}'
              : '';
      subtitle = '${perf.classInfo!.name}$sectionPart$rollPart';
    } else if (perf.rollNumber != null && perf.rollNumber!.isNotEmpty) {
      subtitle = 'Roll ${perf.rollNumber}';
    } else {
      subtitle = 'Student';
    }

    return GestureDetector(
      onTap: () {
        // Pre-select student, then open full performance screen
        context.read<StudentPerformanceProvider>().selectStudentByName(
          perf.name,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentPerformanceScreen(),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Rank badge + Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: rank <= 3 ? null : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Text(
                      '${score.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Avatar + Student Name & Subtitle
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryAdmin.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        perf.name.isNotEmpty ? perf.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryAdmin,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perf.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Mini progress bars for Att, HW, Exam
                Row(
                  children: [
                    Expanded(
                      child: _miniProgressBar(
                        'Att',
                        perf.attendance.percentage,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _miniProgressBar(
                        'HW',
                        perf.homework.percentage,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _miniProgressBar(
                        'Exam',
                        perf.exams.percentage,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Top Students',
          const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Container(
              width: 240,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceError(StudentPerformanceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Failed to load performance',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => provider.fetchPerformances(),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceEmpty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.bar_chart, size: 36, color: Colors.grey.shade300),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No performance data',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "View All" to see the full report',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color shimBase =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8);
    final Color shimHighlight =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF8F8F8);

    // Card surface: slightly different from shimBase so it's visible as a card

    final Color cardBorder =
        isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE);

    // Line colour: the shimmer blocks that represent text / icons
    final Color lineColor =
        isDark ? const Color(0xFF3D3D3D) : const Color(0xFFDEDEDE);

    // A thin text-line placeholder — looks like a real font line
    Widget line(double w, {double h = 11, double r = 30}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: lineColor,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    // A solid block (avatar, icon, badge, progress bar)
    Widget block(double w, double h, {double r = 8}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: lineColor,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    // Card surface wrapper — no Flutter Card, so the background shimmers too
    Widget shimCard({
      required Widget child,
      EdgeInsetsGeometry padding = const EdgeInsets.all(16),
      double radius = 16,
    }) =>
        Container(
          decoration: BoxDecoration(

            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.25)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: padding,
          child: child,
        );

    return Shimmer.fromColors(
      baseColor: shimBase,
      highlightColor: shimHighlight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Subscription Card ──────────────────────────────
            shimCard(
              radius: 24,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  block(56, 56, r: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        line(160, h: 14),
                        const SizedBox(height: 10),
                        line(110, h: 11),
                        const SizedBox(height: 8),
                        line(130, h: 10),
                      ],
                    ),
                  ),
                  block(52, 28, r: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Student Attendance Card ────────────────────────
            shimCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      block(36, 36, r: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            line(150, h: 13),
                            const SizedBox(height: 7),
                            line(90, h: 10),
                          ],
                        ),
                      ),
                      block(50, 24, r: 20),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // 4 stat pills
                  Row(
                    children: List.generate(
                      4,
                      (_) => Expanded(
                        child: Container(
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: lineColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(child: line(44, h: 9)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Progress bar
                  block(double.infinity, 7, r: 20),
                  const SizedBox(height: 14),
                  // "Today's Records" label
                  Row(
                    children: [
                      block(13, 13, r: 6),
                      const SizedBox(width: 6),
                      line(100, h: 10),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Student mini-cards
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      itemBuilder: (_, __) => Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: lineColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            line(70, h: 10),
                            const SizedBox(height: 6),
                            line(50, h: 9),
                            const SizedBox(height: 6),
                            line(60, h: 9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Teacher Attendance Card ────────────────────────
            shimCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      block(36, 36, r: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            line(150, h: 13),
                            const SizedBox(height: 7),
                            line(90, h: 10),
                          ],
                        ),
                      ),
                      block(50, 24, r: 20),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // 3 stat pills
                  Row(
                    children: List.generate(
                      3,
                      (_) => Expanded(
                        child: Container(
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: lineColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(child: line(44, h: 9)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  block(double.infinity, 6, r: 20),
                  const SizedBox(height: 14),
                  // "Today's Records" label
                  Row(
                    children: [
                      block(13, 13, r: 6),
                      const SizedBox(width: 6),
                      line(100, h: 10),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Teacher mini-cards
                  SizedBox(
                    height: screenSize(context, .3),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      itemBuilder: (_, __) => Container(
                        width: 148,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: lineColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar + name + designation
                            Row(
                              children: [
                                block(32, 32, r: 16),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    line(70, h: 11),
                                    const SizedBox(height: 5),
                                    line(50, h: 9),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // In / Out time row
                            Row(
                              children: [
                                line(38, h: 9),
                                const Spacer(),
                                line(38, h: 9),
                              ],
                            ),
                            const SizedBox(height: 7),
                            // Location
                            line(100, h: 9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Recent Homework ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [line(150, h: 14), line(55, h: 11)],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (_, __) => Container(
                  width: screenSize(context, .85),
                  margin: const EdgeInsets.only(right: 8),
                  child: shimCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Class badge + due date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            block(80, 22, r: 8),
                            line(60, h: 9),
                          ],
                        ),
                        const SizedBox(height: 12),
                        line(200, h: 13), // title
                        const SizedBox(height: 8),
                        line(120, h: 10), // subject
                        const Spacer(),
                        line(double.infinity, h: 9), // description line 1
                        const SizedBox(height: 5),
                        line(180, h: 9), // description line 2
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Current Exams ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [line(120, h: 14), line(55, h: 11)],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (_, __) => Container(
                  width: screenSize(context, .85),
                  margin: const EdgeInsets.only(right: 8),
                  child: shimCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [block(28, 28, r: 6), block(70, 22, r: 12)],
                        ),
                        const Spacer(),
                        line(180, h: 14), // exam name
                        const SizedBox(height: 7),
                        line(140, h: 10), // description
                        const SizedBox(height: 7),
                        line(160, h: 10), // date range
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Recent Notices ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [line(130, h: 14), line(55, h: 11)],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (_, __) => Container(
                  width: screenSize(context, .9),
                  margin: const EdgeInsets.only(right: 14),
                  child: shimCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            block(40, 40, r: 20),
                            block(80, 22, r: 12),
                          ],
                        ),
                        const Spacer(),
                        line(200, h: 13), // title
                        const SizedBox(height: 7),
                        line(double.infinity, h: 10), // content line 1
                        const SizedBox(height: 5),
                        line(180, h: 10), // content line 2
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [line(90, h: 9), line(70, h: 9)],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

}

class _AdminClassStats {
  final String className;
  final List<StudentAttendanceRecord> records;

  int get present =>
      records.where((r) => r.status.toLowerCase() == 'present').length;
  int get absent =>
      records.where((r) => r.status.toLowerCase() == 'absent').length;
  int get leave =>
      records.where((r) => r.status.toLowerCase() == 'leave').length;
  int get late => records.where((r) => r.status.toLowerCase() == 'late').length;
  int get total => present + absent + leave + late;
  double get attendanceRate => total == 0 ? 0 : (present / total) * 100;

  _AdminClassStats({required this.className, required this.records});
}

class _AdminClassPerformanceCardWithSubjectDropdown extends StatefulWidget {
  final _AdminClassStats stats;
  const _AdminClassPerformanceCardWithSubjectDropdown({required this.stats});

  @override
  State<_AdminClassPerformanceCardWithSubjectDropdown> createState() =>
      _AdminClassPerformanceCardWithSubjectDropdownState();
}

class _AdminClassPerformanceCardWithSubjectDropdownState
    extends State<_AdminClassPerformanceCardWithSubjectDropdown> {
  // null means "All subjects"
  String? _selectedSubjectId;

  /// Collects unique subjects from all records in this class.
  /// Uses subjectName when available, falls back to subjectId as label.
  List<Map<String, String>> _getUniqueSubjects() {
    final Map<String, String> subjectsMap = {};
    for (final r in widget.stats.records) {
      if (r.subjectId != null) {
        subjectsMap[r.subjectId!] = r.subjectName ?? r.subjectId!;
      }
    }
    return subjectsMap.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList();
  }

  List<StudentAttendanceRecord> _getFilteredRecords() {
    // null = All subjects — deduplicate by studentId keeping most recent
    final source = _selectedSubjectId == null
        ? widget.stats.records
        : widget.stats.records
              .where((r) => r.subjectId == _selectedSubjectId)
              .toList();

    final Map<String, StudentAttendanceRecord> seen = {};
    final sorted = [...source]..sort((a, b) => b.date.compareTo(a.date));
    for (final r in sorted) {
      seen.putIfAbsent(r.studentId, () => r);
    }
    return seen.values.toList();
  }

  @override
  void initState() {
    super.initState();
    // Start with "All" (null) so all students are shown immediately
    _selectedSubjectId = null;
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final statusColor = stats.attendanceRate >= 75
        ? Colors.green
        : (stats.attendanceRate >= 50 ? Colors.orange : Colors.red);

    final subjects = _getUniqueSubjects();
    final displayRecords = _getFilteredRecords();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 65,
                          height: 65,
                          child: CircularProgressIndicator(
                            value: stats.attendanceRate / 100,
                            strokeWidth: 6,
                            backgroundColor: statusColor.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              statusColor,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${stats.attendanceRate.toInt()}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)!.rate,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  stats.className,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (subjects.isNotEmpty) ...[
                                Container(
                                  height: 32,
                                  constraints: const BoxConstraints(maxWidth: 80),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: _selectedSubjectId,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                      ),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedSubjectId = newValue;
                                        });
                                      },
                                      items: [
                                        DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text(
                                            AppLocalizations.of(context)!.all,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        ...subjects.map<DropdownMenuItem<String?>>(
                                              (subject) => DropdownMenuItem<String?>(
                                            value: subject['id'],
                                            child: Text(
                                              subject['name'] ?? '',
                                              style: const TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatItem(
                                AppLocalizations.of(context)!.total,
                                '${stats.total}',
                                Colors.grey.shade800,
                              ),
                              _buildStatItem(
                                AppLocalizations.of(context)!.present,
                                '${stats.present}',
                                Colors.green,
                              ),
                              _buildStatItem(
                                AppLocalizations.of(context)!.absent,
                                '${stats.absent}',
                                Colors.red,
                              ),
                              _buildStatItem(
                                AppLocalizations.of(context)!.leave,
                                '${stats.leave}',
                                Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: displayRecords.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 24,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context)!.noRecords,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: displayRecords.length,
                            itemBuilder: (context, index) {
                              return _buildStudentAvatarCard(
                                displayRecords[index],
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentAvatarCard(StudentAttendanceRecord record) {
    Color getStatusColor() {
      switch (record.status.toLowerCase()) {
        case 'present':
          return Colors.green;
        case 'absent':
          return Colors.red;
        case 'late':
          return Colors.orange;
        case 'leave':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    final color = getStatusColor();
    final firstLetter = record.studentName.isNotEmpty
        ? record.studentName[0]
        : '?';

    return Container(
      width: 65,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color.withOpacity(0.1),
                child: Text(
                  firstLetter.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            record.studentName,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
