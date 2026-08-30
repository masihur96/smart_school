import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/configs/custom_size.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/widgets/zoomable_avatar.dart';
import 'package:smart_school/features/ai_tutor/screen/ai_tutor_chat_screen.dart';
import 'package:smart_school/features/profile/presentation/screens/profile_screen.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/user_model.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/marquee_notice.dart';
import '../../../core/widgets/notification_icon_button.dart';
import '../../academic_books/screens/academic_books_dashboard_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../data/models/student_dashboard_model.dart';
import '../providers/student_dashboard_provider.dart';
import 'student_attendance_screen.dart';
import 'student_homework_screen.dart';
import 'student_result_screen.dart';
import 'student_routine_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: ZoomDrawerController(),
      mainScreenTapClose: true,
      menuBackgroundColor: Colors.grey,
      style: DrawerStyle.defaultStyle,
      androidCloseOnBackTap: true,
      menuScreen: const AppDrawer(),
      mainScreen: const StudentDashboardContent(),
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

class StudentDashboardContent extends StatefulWidget {
  const StudentDashboardContent({super.key});

  @override
  State<StudentDashboardContent> createState() =>
      _StudentDashboardContentState();
}

class _StudentDashboardContentState extends State<StudentDashboardContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _visitedTabs = {0};

  int get _selectedIndex => _tabController.index;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() {
        _visitedTabs.add(_tabController.index);
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StudentDashboardProvider>();
      if (provider.dashboardData == null) {
        provider.fetchStudentDashboard();
      }
      if (mounted) {
        final notifProvider = context.read<NotificationNotifier>();
        if (notifProvider.notifications.isEmpty) {
          notifProvider.fetchNotifications();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTitle(AppLocalizations l10n) {
    switch (_selectedIndex) {
      case 0:
        return l10n.dashboard;
      case 1:
        return l10n.attendance;
      case 2:
        return l10n.results;
      case 3:
        return l10n.homework;
      default:
        return l10n.dashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
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
          leadingWidth: screenSize(context, .1),
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => ZoomDrawer.of(context)?.toggle(),
          ),
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Row(
              children: [
                ZoomableAvatar(
                  imageUrl: user?.avatar,
                  name: user?.name,
                  heroTag:
                      'teacher-dashboard-avatar-${user?.id ?? user?.name ?? 'me'}',
                  radius: 20,
                  backgroundColor: Colors.purple,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.name ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      user?.designation ?? 'School Name',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          centerTitle: false,
          elevation: 0,

          backgroundColor: AppColors.primaryStudent,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            NotificationIconButton(color: AppColors.primaryStudent),
            GestureDetector(
              onTap: () {
                _showAIDoctorDialog(context);
                // Navigate to profile screen
              },
              child: Lottie.asset(
                'assets/animation1.json',
                width: 60,
                fit: BoxFit.fill,
                repeat: true,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BottomBar(
          layout: BottomBarLayout(
            width: MediaQuery.of(context).size.width,
            offset: 10,
            borderRadius: BorderRadius.circular(28),
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
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryStudent,
            labelColor: AppColors.primaryStudent,
            unselectedLabelColor: isDark
                ? Colors.white54
                : Colors.grey.shade500,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            tabs: [
              Tab(icon: const Icon(Icons.dashboard_outlined), text: l10n.home),
              Tab(
                icon: const Icon(Icons.check_circle_outline),
                text: l10n.attendance,
              ),
              Tab(
                icon: const Icon(Icons.analytics_outlined),
                text: l10n.results,
              ),
              Tab(
                icon: const Icon(Icons.assignment_outlined),
                text: l10n.homework,
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDashboardOverview(context, user, l10n),
              if (_visitedTabs.contains(1))
                const StudentAttendanceScreen(hideAppBar: true)
              else
                const SizedBox(),
              if (_visitedTabs.contains(2))
                const StudentResultScreen(hideAppBar: true)
              else
                const SizedBox(),
              if (_visitedTabs.contains(3))
                const StudentHomeworkScreen(hideAppBar: true)
              else
                const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardOverview(
    BuildContext context,
    User? user,
    AppLocalizations l10n,
  ) {
    final provider = context.watch<StudentDashboardProvider>();
    final data = provider.dashboardData;

    if (provider.isLoading) {
      return _buildShimmerLoading(context, user, l10n);
    }

    if (provider.error != null && data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(provider.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchStudentDashboard(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryStudent,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchStudentDashboard(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            if (data?.marqueeData != null && data!.marqueeData!.text.isNotEmpty)
              MarqueeNotice(
                customText: data.marqueeData!.text,
                color: AppColors.primaryStudent,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    "My ${l10n.attendance}",
                    onSeeAll: () {
                      _tabController.animateTo(1);
                    },
                  ),
                  _buildAttendanceSection(context, data, l10n),
                  const SizedBox(height: 24),
                  if (data?.myRecentExamListWithResult.isNotEmpty ?? false) ...[
                    _buildSectionHeader(
                      l10n.exams,
                      onSeeAll: () => _tabController.animateTo(2),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: data!.myRecentExamListWithResult.length,
                        itemBuilder: (context, index) {
                          final examData =
                              data.myRecentExamListWithResult[index];
                          return _buildExamResultCard(context, examData);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (data?.recentHomework.isNotEmpty ?? false) ...[
                    _buildSectionHeader(
                      l10n.recentHomework,
                      onSeeAll: () => _tabController.animateTo(3),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: data!.recentHomework.length,
                        itemBuilder: (context, index) => _buildHomeworkCard(
                          context,
                          data.recentHomework[index],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (data?.myRecentNotice.isNotEmpty ?? false) ...[
                    _buildSectionHeader(
                      l10n.notices,
                      onSeeAll: () => _tabController.animateTo(3),
                    ),
                    const SizedBox(height: 12),
                    ...data!.myRecentNotice
                        .take(3)
                        .map((notice) => _buildNoticeCard(context, notice)),
                    const SizedBox(height: 24),
                  ],
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All', // Modify with l10n later if needed
              style: TextStyle(color: AppColors.primaryStudent),
            ),
          ),
      ],
    );
  }

  void _showAIDoctorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(.08),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/tutor.png', height: 90, width: 90),
              ),

              const SizedBox(height: 20),

              const Text(
                "AI Tutor",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                "Your smart learning companion",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 20),

              const Text(
                "Need help with homework, exam preparation, or understanding a topic? Ask questions anytime and get instant academic support.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.deepPurple,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(child: Text("Homework & Assignment Help")),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.deepPurple,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(child: Text("Exam & Quiz Preparation")),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.deepPurple,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(child: Text("Instant Answers & Explanations")),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text("Later"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiTutorChatScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Start"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSection(
    BuildContext context,
    StudentDashboardData? data,
    AppLocalizations l10n,
  ) {
    final records = data?.todayAttendanceStatus?.records ?? [];

    String status = 'not-marked';
    if (records.isNotEmpty) {
      bool anyAbsent = records.any((r) => r.status == 'absent');
      bool anyLate = records.any((r) => r.status == 'late');
      bool anyLeave = records.any((r) => r.status == 'leave');

      if (anyAbsent) {
        status = 'absent';
      } else if (anyLeave) {
        status = 'leave';
      } else if (anyLate) {
        status = 'late';
      } else {
        status = 'present';
      }
    }

    final isPresent = status == 'present';
    final isAbsent = status == 'absent';
    final isLeave = status == 'leave';
    final isLate = status == 'late';

    // Status mapping for color & icon
    IconData statusIcon = Icons.help_outline;
    Color statusColor = Colors.grey;
    if (isPresent) {
      statusIcon = Icons.task_alt;
      statusColor = Colors.green;
    } else if (isAbsent) {
      statusIcon = Icons.cancel_outlined;
      statusColor = Colors.red;
    } else if (isLeave) {
      statusIcon = Icons.beach_access;
      statusColor = Colors.orange;
    } else if (isLate) {
      statusIcon = Icons.access_time_filled;
      statusColor = Colors.orange.shade800;
    } else {
      statusIcon = Icons.access_time;
      statusColor = Colors.blue; // not marked
    }

    return Card(
      margin: const EdgeInsets.all(0.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Status',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('EEE, MMM dd').format(
                    DateTime.tryParse(
                          data?.todayAttendanceStatus?.date ?? '',
                        ) ??
                        DateTime.now(),
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (data?.myAttendanceList?.summary != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    l10n.present,
                    data!.myAttendanceList!.summary!.present.toString(),
                    Colors.green,
                  ),
                  _buildStatItem(
                    l10n.absent,
                    data.myAttendanceList!.summary!.absent.toString(),
                    Colors.red,
                  ),
                  _buildStatItem(
                    l10n.leave,
                    data.myAttendanceList!.summary!.leave.toString(),
                    Colors.orange,
                  ),
                  _buildStatItem(
                    'Rate',
                    '${data.myAttendanceList!.summary!.attendanceRate.toStringAsFixed(1)}%',
                    Colors.blue,
                  ),
                ],
              ),
            ],
            if (data?.myAttendanceList?.records.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 8),
              Text(
                'Recent Records',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: data!.myAttendanceList!.records.length,
                  itemBuilder: (context, index) {
                    final record = data.myAttendanceList!.records[index];
                    final isPresent = record.status == 'present';
                    final isLeave = record.status == 'leave';
                    final isLate = record.status == 'late';

                    Color recordColor = Colors.red;
                    IconData recordIcon = Icons.cancel;
                    if (isPresent) {
                      recordColor = Colors.green;
                      recordIcon = Icons.check_circle;
                    } else if (isLeave) {
                      recordColor = Colors.orange;
                      recordIcon = Icons.info;
                    } else if (isLate) {
                      recordColor = Colors.orange.shade800;
                      recordIcon = Icons.access_time_filled;
                    }

                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: recordColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: recordColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(recordIcon, color: recordColor, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  record.status.toUpperCase(),
                                  style: TextStyle(
                                    color: recordColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            record.subjectInfo?.name ?? 'Subject',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM dd, yyyy').format(
                              DateTime.tryParse(record.date) ?? DateTime.now(),
                            ),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeworkCard(BuildContext context, StudentHomework hwData) {
    var homework = hwData.homework;
    var subject = homework?.subjectInfo?.name ?? 'Subject';
    var isDone = hwData.status == 'done';

    return Card(
      margin: const EdgeInsets.only(right: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: screenSize(context, .75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subject,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hwData.status.toUpperCase(),
                      style: TextStyle(
                        color: isDone ? Colors.green : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                homework?.title ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                homework?.description ?? '',
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${homework?.dueDate != null ? DateFormat('dd MMM').format(homework!.dueDate) : "N/A"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamResultCard(
    BuildContext context,
    MyRecentExamWithResult examData,
  ) {
    if (examData.exam == null || examData.result == null)
      return const SizedBox();

    final exam = examData.exam!;
    final result = examData.result!;

    return Container(
      width: screenSize(context, .85),
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryStudent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.stars_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircularPercentIndicator(
                  radius: 40.0,
                  lineWidth: 8.0,
                  animation: true,
                  percent: result.percentage / 100,
                  center: Text(
                    "${result.percentage.toInt()}%",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: Colors.amber,
                  backgroundColor: Colors.white24,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        exam.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total Marks: ${result.totalObtained} / ${result.totalMax}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Grade: ${result.grade}',
                          style: TextStyle(
                            color: Colors.deepPurple.shade900,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(BuildContext context, Notice notice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.isImportant)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.priority_high,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                Expanded(
                  child: Text(
                    notice.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  notice.targetAudience ?? '',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
                Text(
                  notice.postedBy ?? 'Admin',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, AppLocalizations l10n) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionGridItem(
          context,
          l10n.myRoutine,
          Icons.calendar_month_rounded,
          Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentRoutineScreen()),
          ),
        ),
        _buildActionGridItem(
          context,
          l10n.examResults,
          Icons.emoji_events_rounded,
          Colors.green,
          onTap: () => _tabController.animateTo(2),
        ),
        _buildActionGridItem(
          context,
          l10n.material,
          Icons.library_books_rounded,
          Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AcademicBooksDashboardScreen(comeFrom: "student"),
            ),
          ),
        ),
        _buildActionGridItem(
          context,
          l10n.queries,
          Icons.contact_support_rounded,
          Colors.teal,
          onTap: () {},
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(
    BuildContext context,
    User? user,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Shimmer sweep colors
    final Color shimBase = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE0E0E0);
    final Color shimHighlight = isDark
        ? const Color(0xFF3D3D3D)
        : const Color(0xFFF5F5F5);
    // Block fill color
    final Color blockColor = isDark ? const Color(0xFF3A3A3A) : Colors.white;

    Widget sBox(double w, double h, {double r = 6}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return Shimmer.fromColors(
      baseColor: shimBase,
      highlightColor: shimHighlight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Header Mock
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
              child: Row(
                children: [
                  sBox(60, 60, r: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        sBox(120, 14),
                        const SizedBox(height: 8),
                        sBox(180, 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // My Attendance Header Mock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [sBox(140, 22), sBox(60, 16)],
                  ),
                  const SizedBox(height: 16),

                  // Attendance Section Mock
                  Container(
                    margin: const EdgeInsets.all(0.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              sBox(56, 56, r: 18),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    sBox(90, 12),
                                    const SizedBox(height: 6),
                                    sBox(110, 18),
                                  ],
                                ),
                              ),
                              sBox(80, 14),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sBox(40, 18),
                                  const SizedBox(height: 6),
                                  sBox(50, 10),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sBox(40, 18),
                                  const SizedBox(height: 6),
                                  sBox(50, 10),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sBox(40, 18),
                                  const SizedBox(height: 6),
                                  sBox(50, 10),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sBox(40, 18),
                                  const SizedBox(height: 6),
                                  sBox(50, 10),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          sBox(double.infinity, 1),
                          const SizedBox(height: 16),
                          sBox(120, 16),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 3,
                              itemBuilder: (context, index) => Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: blockColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        sBox(14, 14, r: 7),
                                        const SizedBox(width: 6),
                                        sBox(60, 12),
                                      ],
                                    ),
                                    const Spacer(),
                                    sBox(100, 14),
                                    const SizedBox(height: 6),
                                    sBox(80, 12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Exams Header Mock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [sBox(100, 22), sBox(60, 16)],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 2,
                      itemBuilder: (context, index) => Container(
                        width: screenSize(context, .85),
                        margin: const EdgeInsets.only(right: 16, bottom: 8),
                        decoration: BoxDecoration(
                          // color: blockColor,
                          border: BoxBorder.all(width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              sBox(80, 80, r: 40),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    sBox(120, 18),
                                    const SizedBox(height: 8),
                                    sBox(90, 14),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        sBox(40, 20),
                                        const SizedBox(width: 8),
                                        sBox(60, 14),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Homework Header Mock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [sBox(140, 22), sBox(60, 16)],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 2,
                      itemBuilder: (context, index) => Container(
                        width: screenSize(context, .75),
                        margin: const EdgeInsets.only(right: 16, bottom: 8),
                        decoration: BoxDecoration(
                          color: blockColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [sBox(80, 14), sBox(50, 20)],
                              ),
                              const SizedBox(height: 12),
                              sBox(160, 16),
                              const SizedBox(height: 8),
                              sBox(220, 14),
                              const Spacer(),
                              Row(
                                children: [
                                  sBox(12, 12, r: 6),
                                  const SizedBox(width: 4),
                                  sBox(80, 12),
                                ],
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
          ],
        ),
      ),
    );
  }
}
