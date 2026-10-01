import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/configs/custom_size.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/widgets/zoomable_avatar.dart';
import 'package:smart_school/features/ai_tutor/screen/ai_tutor_chat_screen.dart';
import 'package:smart_school/features/library/providers/library_book_provider.dart';
import 'package:smart_school/features/library/screens/book_detail_screen.dart';
import 'package:smart_school/features/library/screens/library_dashboard_screen.dart';
import 'package:smart_school/features/library/widgets/book_grid_card.dart';
import 'package:smart_school/features/online_class/presentation/screens/online_class_list_screen.dart';
import 'package:smart_school/features/online_class/providers/online_class_provider.dart';
import 'package:smart_school/features/profile/presentation/screens/profile_screen.dart';
import 'package:smart_school/features/teacher/screens/schedule_class_details.dart';
import 'package:smart_school/features/teacher/screens/teacher_notice_screen.dart';
import 'package:smart_school/features/teacher/screens/teacher_self_attendance_detail_screen.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/online_class_model.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/marquee_notice.dart';
import '../../../core/widgets/notification_icon_button.dart';
import '../../academic_books/screens/academic_books_dashboard_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../data/models/teacher_dashboard_model.dart';
import '../providers/teacher_dashboard_provider.dart';
import 'homework_management_screen.dart';
import 'teacher_attendance_screen.dart';
import 'teacher_exam_screen.dart';
import 'teacher_routine_screen.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: ZoomDrawerController(),
      mainScreenTapClose: true,
      style: DrawerStyle.defaultStyle,
      menuBackgroundColor: Colors.grey,
      androidCloseOnBackTap: true,
      menuScreen: const AppDrawer(),
      mainScreen: const TeacherDashboardContent(),
      borderRadius: 24.0,
      showShadow: true,
      angle: 0.0,
      openCurve: Curves.fastOutSlowIn,
      closeCurve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 200),
      drawerShadowsBackgroundColor: Colors.grey.shade300,
      slideWidth: MediaQuery.of(context).size.width * 0.65,
    );
  }
}

class TeacherDashboardContent extends StatefulWidget {
  const TeacherDashboardContent({super.key});

  @override
  State<TeacherDashboardContent> createState() =>
      _TeacherDashboardContentState();
}

class _TeacherDashboardContentState extends State<TeacherDashboardContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<bool> _visitedTabs = [true, false, false, false, false];
  final BottomBarController _bottomBarController = BottomBarController();

  int get _selectedIndex => _tabController.index;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      if (_tabController.index == 2) {
        _tabController.index = _tabController.previousIndex;
        return;
      }
      setState(() {
        _visitedTabs[_tabController.index] = true;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now);

      final provider = context.read<TeacherDashboardProvider>();
      if (provider.dashboardData == null) {
        provider.fetchTeacherDashboard();
      }
      if (provider.todayClasses.isEmpty) {
        provider.fetchTodayClasses(dayName);
      }
      if (mounted) {
        final notifProvider = context.read<NotificationNotifier>();
        if (notifProvider.notifications.isEmpty) {
          notifProvider.fetchNotifications();
        }

        final onlineClassProvider = context.read<OnlineClassProvider>();
        if (onlineClassProvider.onlineClasses.isEmpty) {
          onlineClassProvider.fetchOnlineClasses();
        }

        final libraryProvider = context.read<LibraryBookNotifier>();
        if (libraryProvider.books.isEmpty) {
          libraryProvider.fetchBooks();
        }
      }
    });
  }

  @override
  void dispose() {
    _bottomBarController.dispose();
    _tabController.dispose();
    super.dispose();
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
          leadingWidth: screenSize(context, .15),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.name ?? "",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        user?.designation ?? AppLocalizations.of(context)!.schoolName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.primaryTeacher,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white70),
          actions: [
            NotificationIconButton(color: AppColors.primaryTeacher),
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
          ],
        ),
        body: BottomBar(
          controller: _bottomBarController,
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
          scrollBehavior: BottomBarScrollBehavior(
            hideOnScroll: true,
            showAtStart: true,
            predicate: (notification) {
              if (notification.metrics.axis != Axis.vertical) return true;
              if (notification.metrics.pixels >= notification.metrics.maxScrollExtent) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _bottomBarController.isAttached && !_bottomBarController.isVisible) {
                    _bottomBarController.show();
                  }
                });
                return false;
              }
              return true;
            },
          ),
          showIcon: false,
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              user == null
                  ? const SizedBox()
                  : _buildDashboardOverview(context, user.name, user, l10n),
              _visitedTabs[1]
                  ? const TeacherAttendanceScreen(hideAppBar: true)
                  : const SizedBox(),
              const SizedBox.shrink(), // Dummy for FAB gap
              _visitedTabs[3]
                  ? const TeacherExamScreen(hideAppBar: true)
                  : const SizedBox(),
              _visitedTabs[4]
                  ? const HomeworkManagementScreen(hideAppBar: true)
                  : const SizedBox(),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryTeacher,
                labelColor: AppColors.primaryTeacher,
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
                onTap: (index) {
                  if (index == 2) {
                    _tabController.index = _tabController.previousIndex;
                  }
                },
                tabs: [
                  Tab(
                    icon: const Icon(Icons.dashboard_outlined),
                    text: l10n.home,
                  ),
                  Tab(
                    icon: const Icon(Icons.check_circle_outline),
                    text: l10n.attendance,
                  ),
                  const Tab(child: SizedBox(width: 48)), // Gap for FAB
                  Tab(icon: const Icon(Icons.quiz_outlined), text: l10n.exams),
                  Tab(
                    icon: const Icon(Icons.assignment_outlined),
                    text: l10n.homework,
                  ),
                ],
              ),
              Positioned(
                top: -16,
                child: Consumer<TeacherDashboardProvider>(
                  builder: (context, provider, _) {
                    final status = provider.dashboardData?.attendanceStatus;
                    final isClockedIn = status?.status == 'clock-in';
                    final isClockedOut = status?.status == 'clock-out';

                    return Theme(
                      data: Theme.of(context).copyWith(),
                      child: GestureDetector(
                        onTap: () => _performSelfAttendance(
                          context,
                          context.read<AuthNotifier>().user,
                          l10n,
                        ),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isClockedIn
                                ? Colors.orange
                                : (isClockedOut
                                      ? Colors.green.shade50
                                      : AppColors.primaryTeacher),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: isClockedOut
                                ? Border.all(
                                    color: Colors.green.shade200,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Icon(
                            isClockedIn
                                ? Icons.logout_outlined
                                : (isClockedOut
                                      ? Icons.update_outlined
                                      : Icons.login_outlined),
                            color: isClockedOut ? Colors.green : Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
    final onlineClassProvider = context.watch<OnlineClassProvider>();
    final libraryProvider = context.watch<LibraryBookNotifier>();

    final upcomingClasses = onlineClassProvider.onlineClasses
        .where(
          (c) => c.scheduledTime.isAfter(
            DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        )
        .toList();

    final availableBooks = libraryProvider.books
        .where((b) => b.isAvailable)
        .toList();

    final data = provider.dashboardData;
    final classes = provider.todayClasses
        .where((c) => c.teacherId == user.id)
        .toList();
    classes.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (provider.isLoading) {
      return _buildShimmerLoading(context, name, user, l10n);
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
              onPressed: () => provider.fetchTeacherDashboard(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeacher,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchTeacherDashboard(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              if (data?.marqueeData != null)
                MarqueeNotice(
                  customText: data!.marqueeData!.text,
                  color: AppColors.primaryTeacher,
                ),

              if (classes.isNotEmpty) ...[
                _buildSectionHeader(
                  l10n.scheduleToday,
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherRoutineScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ClassCardListView(
                  classes: classes,
                  buildCard: (ctx, entry) => _buildClassCard(ctx, entry),
                  isCurrentClass: _isCurrentClass,
                ),
                const SizedBox(height: 24),
              ],
              if (upcomingClasses.isNotEmpty) ...[
                _buildSectionHeader(
                  AppLocalizations.of(context)!.onlineClasses,
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const OnlineClassListScreen(isAdminOrTeacher: true),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: upcomingClasses.length > 5
                        ? 5
                        : upcomingClasses.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 48,
                          child: _buildOnlineClassCard(
                            context,
                            upcomingClasses[index],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    l10n.teacherAttendance,
                    onSeeAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherSelfAttendanceDetailScreen(
                            schoolId: user.schoolId ?? "",
                          ),
                        ),
                      );
                    },
                  ),
                  _buildAttendanceSection(context, data, l10n),
                  const SizedBox(height: 24),
                  if (data?.myClassAttendStudents.isNotEmpty ?? false) ...[
                    _buildSectionHeader(
                      l10n.studentAttendance,
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TeacherAttendanceScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: data!.myClassAttendStudents.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: SizedBox(
                              width: screenSize(context, 0.88),
                              child: _buildClassPerformanceCard(
                                context,
                                data.myClassAttendStudents[index],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (data != null)
                    _buildExamsSection(context, l10n, data.recentExamList),

                  if (data?.mySubmittedHomework.isNotEmpty ?? false) ...[
                    _buildSectionHeader(
                      l10n.recentHomework,
                      onSeeAll: () => _tabController.animateTo(4),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: data!.mySubmittedHomework.length,
                        itemBuilder: (context, index) => _buildHomeworkCard(
                          context,
                          data.mySubmittedHomework[index],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (availableBooks.isNotEmpty) ...[
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.libraryBooks,
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LibraryDashboardScreen(
                              comeFrom: 'teacher',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: availableBooks.length > 5
                            ? 5
                            : availableBooks.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: SizedBox(
                              width: 150,
                              child: BookGridCard(
                                book: availableBooks[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookDetailScreen(
                                        comeFrom: 'teacher',
                                        book: availableBooks[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (data?.recentNotice.isNotEmpty ?? false) ...[
                    _buildSectionHeader(
                      l10n.notices,
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const TeacherNoticeScreen(isFromDrawer: true),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: data!.recentNotice.length > 5
                            ? 5
                            : data.recentNotice.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: SizedBox(
                              width: screenSize(context, 0.75),
                              child: _buildNoticeCard(
                                context,
                                data.recentNotice[index],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 150),
                  ],
                ],
              ),
            ],
          ),
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
              AppLocalizations.of(context)!.seeAll, // Use l10n if available
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
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

              SizedBox(height: 20),

              Text(
                AppLocalizations.of(context)!.aiTutor,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                AppLocalizations.of(context)!.yourSmartLearningCompanion,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),

              SizedBox(height: 20),

              Text(
                AppLocalizations.of(context)!.aiTutorDescription,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.deepPurple,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.homeworkAndAssignmentHelp,
                            ),
                          ),
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
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.examAndQuizPreparation,
                            ),
                          ),
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
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.instantAnswersAndExplanations,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                      child: Text(AppLocalizations.of(context)!.later),
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
                      label: Text(AppLocalizations.of(context)!.start),
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
    TeacherDashboardData? data,
    AppLocalizations l10n,
  ) {
    final status = data?.attendanceStatus;
    final isClockedIn = status?.status == 'clock-in';
    final isClockedOut = status?.status == 'clock-out';
    final record = status?.record;

    return Card(
      margin: const EdgeInsets.all(0.0),

      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isClockedIn
                        ? Colors.orange.shade50
                        : (isClockedOut
                              ? Colors.green.shade50
                              : Colors.blue.shade50),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isClockedIn
                        ? Icons.timer
                        : (isClockedOut
                              ? Icons.task_alt
                              : Icons.location_history),
                    color: isClockedIn
                        ? Colors.orange
                        : (isClockedOut ? Colors.green : Colors.blue),
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
                            ? AppLocalizations.of(context)!.shiftInProgress
                            : (isClockedOut
                                  ? AppLocalizations.of(context)!.shiftCompleted
                                  : AppLocalizations.of(context)!.notStartedYet),
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
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildTimeInfo(
                  status?.clockInTime != null
                      ? DateFormat('hh:mm a').format(
                          DateTime.parse(status?.clockInTime ?? "").toLocal(),
                        )
                      : '--:--',
                  Icons.login_rounded,
                ),
                Container(
                  height: 30,
                  width: 1,
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  color: Colors.grey.shade300,
                ),
                _buildTimeInfo(
                  status?.clockOutTime == null
                      ? '--:--'
                      : DateFormat('hh:mm a').format(
                          DateTime.parse(status?.clockOutTime ?? "").toLocal(),
                        ),

                  Icons.logout_rounded,
                ),
                const Spacer(),
                _buildTimeInfo(
                  '${status?.record?.distanceFromCenter.toInt() ?? "Not Yet "}m',

                  Icons.location_on,
                ),
              ],
            ),
            if (data?.myAttendanceList.isNotEmpty ?? false) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Text(
                  AppLocalizations.of(context)!.recentHistory,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: screenSize(context, .23),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isClockOut
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMM').format(date),
                                style: TextStyle(
                                  color: isClockOut
                                      ? Colors.green.shade800
                                      : Colors.orange.shade800,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isClockOut ? Icons.check_circle : Icons.login,
                                size: 14,
                                color: isClockOut
                                    ? Colors.green.shade600
                                    : Colors.orange.shade600,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildHistoryTime(
                                Icons.login_outlined,
                                DateFormat('hh:mm a').format(
                                  DateTime.parse(
                                    att.startTime ?? att.time,
                                  ).toLocal(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildHistoryTime(
                                Icons.logout_outlined,
                                att.endTime == null
                                    ? '--:--'
                                    : DateFormat('hh:mm a').format(
                                        DateTime.parse(
                                          att.endTime ?? '--:--',
                                        ).toLocal(),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _buildHistoryTime(
                            Icons.location_on,
                            "${att.distanceFromCenter.toInt()}m away",
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

  Widget _buildTimeInfo(String time, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(
          time,

          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTime(IconData icon, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, size: 10),

        SizedBox(width: 5),
        Text(
          time,

          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildClassPerformanceCard(
    BuildContext context,
    MyClassAttendStudent stats,
  ) {
    return _ClassPerformanceCardWithSubjectDropdown(stats: stats);
  }

  Widget _buildStudentAvatarCard(TeacherClassAttendRecord record) {
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

  Widget _buildHomeworkCard(BuildContext context, Homework homework) {
    final bool isOverdue = homework.dueDate.isBefore(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color statusColor = isOverdue ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final Color statusLight = statusColor.withValues(alpha: isDark ? 0.2 : 0.1);

    return Card(
      margin: const EdgeInsets.only(right: 16, bottom: 4, top: 4),
      elevation: 2,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showHomeworkDetailsBottomSheet(context, homework);
        },
        child: Container(
          width: screenSize(context, .8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: statusColor,
                width: 4,
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  size: 110,
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                homework.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (homework.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  homework.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isOverdue ? 'Overdue' : 'Active', // Fallback or static text
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.class_outlined,
                                  size: 13,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  homework.classInfo?.name ?? "--",
                                  style: TextStyle(
                                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              homework.subjectInfo?.name ?? "--",
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM').format(homework.dueDate),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  void _showHomeworkDetailsBottomSheet(BuildContext context, Homework homework) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isOverdue = homework.dueDate.isBefore(DateTime.now());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            homework.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOverdue ? Colors.red.shade600 : Colors.green.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isOverdue ? 'Overdue' : 'Active',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.class_outlined, size: 18, color: AppColors.primaryTeacher),
                        const SizedBox(width: 8),
                        Text(
                          homework.classInfo?.name ?? "--",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.menu_book_outlined, size: 18, color: AppColors.primaryTeacher),
                        const SizedBox(width: 8),
                        Text(
                          homework.subjectInfo?.name ?? "--",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.event_available_rounded, size: 18, color: isOverdue ? Colors.red.shade500 : Colors.green.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${DateFormat('dd MMM, EEEE').format(homework.dueDate)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isOverdue ? Colors.red.shade600 : Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (homework.description.isNotEmpty) ...[
                      Text(
                        homework.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor,
                          foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoticeCard(BuildContext context, Notice notice) {
    bool isNew = false;
    String timeAgo = AppLocalizations.of(context)!.unknown;
    if (notice.createdAt != null) {
      final diff = DateTime.now().difference(notice.createdAt!);
      isNew = diff.inDays <= 3;

      if (diff.inDays == 0) {
        if (DateTime.now().day == notice.createdAt!.day) {
          timeAgo = AppLocalizations.of(context)!.todayText;
        } else {
          timeAgo = AppLocalizations.of(context)!.yesterdayText;
        }
      } else if (diff.inDays == 1) {
        timeAgo = AppLocalizations.of(context)!.yesterdayText;
      } else if (diff.inDays < 7) {
        timeAgo = AppLocalizations.of(context)!.daysAgo(diff.inDays);
      } else {
        timeAgo = DateFormat('MMM dd, yyyy').format(notice.createdAt!);
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = notice.isImportant ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6);
    final Color accentLight = accentColor.withValues(alpha: isDark ? 0.2 : 0.1);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showNoticeDetails(context, notice, timeAgo),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: accentColor,
                width: 4,
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                top: -15,
                child: Icon(
                  notice.isImportant ? Icons.campaign_rounded : Icons.notifications_rounded,
                  size: 90,
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notice.isImportant)
                          Container(
                            margin: const EdgeInsets.only(right: 10, top: 2),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accentLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.priority_high_rounded,
                              color: accentColor,
                              size: 14,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notice.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.newLabel.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notice.content,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          notice.postedBy ?? AppLocalizations.of(context)!.adminText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
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

  void _showNoticeDetails(BuildContext context, Notice notice, String timeAgo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = notice.isImportant ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notice.isImportant)
                          Padding(
                            padding: const EdgeInsets.only(right: 12, top: 4),
                            child: Icon(Icons.priority_high_rounded, color: primaryColor, size: 24),
                          ),
                        Expanded(
                          child: Text(
                            notice.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(
                          'Posted by ${notice.postedBy ?? AppLocalizations.of(context)!.adminText}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      notice.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (notice.fileUrl != null && notice.fileUrl!.isNotEmpty) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(notice.fileUrl!);
                            try {
                              if (!await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              )) {
                                await launchUrl(url, mode: LaunchMode.platformDefault);
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)!.couldNotOpenAttachment,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.attachment_rounded),
                          label: Text(
                            AppLocalizations.of(context)!.viewAttachment,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor,
                          foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.close,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOnlineClassCard(BuildContext context, OnlineClass onlineClass) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF3B82F6); // Professional Blue
    final primaryLight = primaryColor.withValues(alpha: isDark ? 0.2 : 0.1);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showOnlineClassDetailsBottomSheet(context, onlineClass);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: primaryColor,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.videocam_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            onlineClass.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            onlineClass.description,
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                Divider(
                  height: 1, 
                  thickness: 1, 
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                ),
                
                const Spacer(),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 14,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  onlineClass.className ?? AppLocalizations.of(context)!.meetingText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('hh:mm a').format(onlineClass.scheduledTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onlineClass.meetLink.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () {
                          try {
                            launchUrl(
                              Uri.parse(onlineClass.meetLink),
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.video_call_rounded, size: 16),
                        label: Text(
                          AppLocalizations.of(context)!.join,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700, 
                            letterSpacing: 0.5,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: primaryColor.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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

  void _showOnlineClassDetailsBottomSheet(BuildContext context, OnlineClass onlineClass) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF3B82F6);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      onlineClass.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.group_outlined, size: 18, color: primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            onlineClass.className ?? AppLocalizations.of(context)!.meetingText,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 18, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('hh:mm a, dd MMM yyyy').format(onlineClass.scheduledTime),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      onlineClass.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (onlineClass.meetLink.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            try {
                              launchUrl(
                                Uri.parse(onlineClass.meetLink),
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.video_call_rounded),
                          label: Text(
                            AppLocalizations.of(context)!.join,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
        );
      },
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
            SnackBar(content: Text(l10n.locationServicesDisabled)),
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
              SnackBar(content: Text(l10n.locationPermissionsDenied)),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationPermissionsPermanentlyDenied)),
          );
        }
        return;
      }

      // 2. Get current position
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.fetchingCurrentLocation)));
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

      if (distanceInMeters <= user.radius!) {
        // 4. Confirm before submitting (with loading button inside dialog)
        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              bool isSubmitting = false;
              return StatefulBuilder(
                builder: (ctx, setDialogState) {
                  return AlertDialog(
                    title: Text(l10n.confirmAttendanceTitle),
                    content: Text(
                      'Are you sure you want to submit your attendance?\n\n'
                      'Distance from center: ${distanceInMeters.toStringAsFixed(0)}m\n'
                      'Allowed radius: ${user.radius}m',
                    ),
                    actions: [
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                        child: Text(l10n.cancel),
                      ),
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setDialogState(() => isSubmitting = true);
                                try {
                                  await context
                                      .read<TeacherDashboardProvider>()
                                      .submitSelfAttendance(
                                        position.latitude,
                                        position.longitude,
                                      );

                                  // Refresh full dashboard after success
                                  if (mounted) {
                                    context
                                        .read<TeacherDashboardProvider>()
                                        .fetchTeacherDashboard();
                                  }

                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.attendanceMarkedSuccessfully,
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() => isSubmitting = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${l10n.submissionFailed}: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeacher,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(90, 40),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.confirm),
                      ),
                    ],
                  );
                },
              );
            },
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.outOfRangeDetails(l10n.outOfRange, distanceInMeters.toStringAsFixed(0), user.radius.toString()),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.anErrorOccurred(e.toString()))),
        );
      }
    }
  }

  /// Parses a "HH:mm:ss" or "HH:mm" time string and converts it to AM/PM format.
  String _formatTimeAmPm(String timeStr) {
    try {
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return timeStr;
    }
  }

  bool _isCurrentClass(String startTime, String endTime) {
    try {
      final now = TimeOfDay.now();
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final nowMinutes = now.hour * 60 + now.minute;
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } catch (_) {
      return false;
    }
  }

  bool _isUpcomingClass(String startTime) {
    try {
      final now = TimeOfDay.now();
      final startParts = startTime.split(':');
      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final nowMinutes = now.hour * 60 + now.minute;
      return nowMinutes < startMinutes;
    } catch (_) {
      return false;
    }
  }

  bool _isPassedClass(String endTime) {
    try {
      final now = TimeOfDay.now();
      final endParts = endTime.split(':');
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final nowMinutes = now.hour * 60 + now.minute;
      return nowMinutes >= endMinutes;
    } catch (_) {
      return false;
    }
  }

  /// Returns the elapsed fraction [0.0 – 1.0] of the class period at the current time.
  double _classPeriodProgress(String startTime, String endTime) {
    try {
      final now = TimeOfDay.now();
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final nowMinutes = now.hour * 60 + now.minute;
      final total = endMinutes - startMinutes;
      if (total <= 0) return 0.0;
      return ((nowMinutes - startMinutes) / total).clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }

  Widget _buildClassCard(BuildContext context, RoutineEntry classInfo) {
    final classNameText =
        classInfo.classEntity?.name ?? AppLocalizations.of(context)!.classNum(classInfo.classId.toString());
    final sectionNameText = classInfo.sectionEntity?.name != null
        ? ' (${classInfo.sectionEntity!.name})'
        : '';
    final className = '$classNameText$sectionNameText';
    final subjectName =
        classInfo.subjectEntity?.name ?? AppLocalizations.of(context)!.subjectNum(classInfo.subjectId.toString());

    final isActive = _isCurrentClass(classInfo.startTime, classInfo.endTime);
    final isUpcoming = _isUpcomingClass(classInfo.startTime);
    final isPassed = _isPassedClass(classInfo.endTime);
    final progress = isActive
        ? _classPeriodProgress(classInfo.startTime, classInfo.endTime)
        : 0.0;

    final startAmPm = _formatTimeAmPm(classInfo.startTime);
    final endAmPm = _formatTimeAmPm(classInfo.endTime);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Professional Color Palette
    final Color accentColor = isActive
        ? const Color(0xFF10B981) // Emerald Green for active
        : (isPassed ? Colors.grey.shade500 : const Color(0xFF6366F1)); // Gray for passed, Indigo for upcoming
    final Color accentMid = isActive
        ? const Color(0xFF34D399)
        : (isPassed ? Colors.grey.shade400 : const Color(0xFF818CF8));
    final Color accentLight = accentColor.withValues(alpha: isDark ? 0.25 : 0.12);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScheduleClassDetails(
              subjectID: classInfo.subjectId ?? "",
              classRoom: classInfo.classEntity!,
              sectionId: classInfo.sectionId,
              routineId: classInfo.id,
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isActive ? 6 : 2,
        shadowColor: isActive ? accentColor.withValues(alpha: 0.4) : Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isActive ? accentColor.withValues(alpha: 0.5) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            width: 1,
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: screenSize(context, .75), // Slightly wider to fit content better
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top accent strip ───────────────────────────────────────────
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accentColor, accentMid]),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header row: Status badge + Time ────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isActive) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  isActive
                                      ? AppLocalizations.of(context)!.nowText
                                      : (isUpcoming
                                            ? AppLocalizations.of(context)!.upcomingText
                                            : (isPassed ? AppLocalizations.of(context)!.passedText : '')),
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Time
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '$startAmPm - $endAmPm',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Subject name ───────────────────────────────────────
                      Text(
                        subjectName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // ── Class / Section ────────────────────────────────────
                      Text(
                        className,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      // ── Bottom Info Row ────────────────────────────────────
                      Row(
                        children: [
                          if (classInfo.roomNumber != null &&
                              classInfo.roomNumber!.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.meeting_room_outlined,
                                  size: 16,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.roomNum(classInfo.roomNumber.toString()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (classInfo.teacherEntity != null)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 16,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      classInfo.teacherEntity!.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // ── Progress bar (only when class is active) ───────────
                      if (isActive) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: accentLight,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    accentColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildExamsSection(
    BuildContext context,
    AppLocalizations l10n,
    List<Exam> recentExamList,
  ) {
    // Filter exams to show only running or upcoming
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final exams = recentExamList.where((exam) {
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

    if (exams.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _buildSectionHeader(
        l10n.upcomingExams,
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeacherExamScreen()),
            );
          },
        ),

        const SizedBox(height: 12),
        SizedBox(
          height: 165,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final startDateStr = exam.startDate != null
        ? DateFormat('MMM dd, yyyy').format(exam.startDate!)
        : 'N/A';

    final Color accentColor = exam.isPublished ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final Color accentLight = accentColor.withValues(alpha: isDark ? 0.2 : 0.1);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showExamDetailsBottomSheet(context, exam, startDateStr);
        },
        child: Container(
          width: screenSize(context, .88),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: accentColor,
                width: 4,
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -10,
                child: Icon(
                  Icons.text_snippet_rounded,
                  size: 110,
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exam.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (exam.description != null && exam.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  exam.description!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            exam.isPublished ? AppLocalizations.of(context)!.publishedText : AppLocalizations.of(context)!.upcomingText,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.startsOn,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                                  ),
                                ),
                                Text(
                                  startDateStr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                  ),
                                ),
                              ],
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
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.deepPurple.shade300.withValues(alpha: 0.15) : Colors.deepPurple.shade50.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.deepPurple.shade300.withValues(alpha: 0.3) : Colors.deepPurple.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 14,
                                  color: isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)!.routinesCount(assignmentsCount),
                                  style: TextStyle(
                                    color: isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade700,
                                    fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }

  void _showExamDetailsBottomSheet(BuildContext context, Exam exam, String startDateStr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            exam.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: exam.isPublished ? Colors.green.shade600 : Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            exam.isPublished ? AppLocalizations.of(context)!.publishedText : AppLocalizations.of(context)!.upcomingText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 18, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '${AppLocalizations.of(context)!.startsOn}: $startDateStr',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (exam.endDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.event_available_rounded, size: 18, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Ends: ${DateFormat('MMM dd, yyyy').format(exam.endDate!)}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.assignment_outlined, size: 18, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.routinesCount(exam.assignments.length),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (exam.description != null && exam.description!.isNotEmpty) ...[
                      Text(
                        exam.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showExamRoutinesDialog(context, exam);
                        },
                        icon: const Icon(Icons.list_alt_rounded),
                        label: Text(
                          "View Routines",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
        );
      },
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
          l10n.results, // Using results as report
          Icons.bar_chart,
          Colors.purple,
          onTap: () {}, // Future: Add reports screen
        ),
        _buildActionGridItem(
          context,
          AppLocalizations.of(context)!.academicBooks,
          Icons.menu_book_rounded,
          const Color(0xFF2563EB),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AcademicBooksDashboardScreen(comeFrom: "teacher"),
            ),
          ),
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
            AppLocalizations.of(context)!.failedToLoadClasses(error.toString()),
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
            AppLocalizations.of(context)!.noClassesScheduledForToday,
            style: TextStyle(
              color: Colors.blueGrey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(
    BuildContext context,
    String name,
    User user,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color shimBase = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE0E0E0);
    final Color shimHighlight = isDark
        ? const Color(0xFF3D3D3D)
        : const Color(0xFFF5F5F5);
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
                // Just to give the shimmer base a background shape
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
                        const SizedBox(height: 8),
                        sBox(100, 12),
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

                  // My Attendance Section Mock
                  Container(
                    margin: const EdgeInsets.all(0.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
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
                                    sBox(100, 12),
                                    const SizedBox(height: 6),
                                    sBox(130, 18),
                                  ],
                                ),
                              ),
                              sBox(50, 40, r: 14), // Button
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  sBox(16, 16, r: 8),
                                  const SizedBox(width: 4),
                                  sBox(40, 14),
                                ],
                              ),
                              sBox(1, 30),
                              Row(
                                children: [
                                  sBox(16, 16, r: 8),
                                  const SizedBox(width: 4),
                                  sBox(40, 14),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  sBox(16, 16, r: 8),
                                  const SizedBox(width: 4),
                                  sBox(40, 14),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          sBox(100, 14),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: screenSize(context, .23),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 3,
                              itemBuilder: (context, index) => Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: blockColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        sBox(50, 14),
                                        sBox(14, 14, r: 7),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [sBox(40, 10), sBox(40, 10)],
                                    ),
                                    const SizedBox(height: 4),
                                    sBox(60, 10),
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

                  // Attendance (Class Performance) Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [sBox(100, 22), sBox(60, 16)],
                  ),
                  const SizedBox(height: 12),
                  // Attendance Card
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              sBox(65, 65, r: 32), // Circular progress
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    sBox(80, 18),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          children: [
                                            sBox(20, 16),
                                            const SizedBox(height: 4),
                                            sBox(40, 10),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            sBox(20, 16),
                                            const SizedBox(height: 4),
                                            sBox(40, 10),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            sBox(20, 16),
                                            const SizedBox(height: 4),
                                            sBox(40, 10),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            sBox(20, 16),
                                            const SizedBox(height: 4),
                                            sBox(40, 10),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              sBox(16, 16, r: 8), // arrow
                            ],
                          ),
                          const SizedBox(height: 16),
                          sBox(double.infinity, 1),
                          const SizedBox(height: 12),
                          sBox(140, 14),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 85,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 4,
                              itemBuilder: (context, index) => Container(
                                width: 65,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: [
                                    sBox(50, 50, r: 25), // avatar
                                    const SizedBox(height: 6),
                                    sBox(50, 10), // name
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

                  // Schedule Today
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [sBox(140, 22), sBox(60, 16)],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 170,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 2,
                      itemBuilder: (context, index) => Container(
                        width: screenSize(context, .45),
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: blockColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sBox(80, 16),
                            const SizedBox(height: 6),
                            sBox(60, 12),
                            const SizedBox(height: 16),
                            sBox(40, 14),
                            const Spacer(),
                            sBox(80, 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Homework
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [sBox(150, 22), sBox(60, 16)],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 2,
                      itemBuilder: (context, index) => Container(
                        width: screenSize(context, .8),
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: blockColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sBox(120, 14),
                            const SizedBox(height: 6),
                            sBox(double.infinity, 12),
                            const SizedBox(height: 4),
                            sBox(180, 12),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [sBox(80, 10), sBox(14, 14, r: 7)],
                            ),
                          ],
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

class ExamRoutinesDialog extends StatelessWidget {
  final Exam exam;

  const ExamRoutinesDialog({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    if (exam.assignments.isEmpty) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(AppLocalizations.of(context)!.noRoutinesYet),
          ),
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
                                  AppLocalizations.of(context)!.examRoutines,
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
                                      '${AppLocalizations.of(context)!.examiner}: ',
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
                                        AppLocalizations.of(context)!.syllabusLabel,
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
                      child: Text(
                        AppLocalizations.of(context)!.close,
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

class _ClassPerformanceCardWithSubjectDropdown extends StatefulWidget {
  final MyClassAttendStudent stats;
  const _ClassPerformanceCardWithSubjectDropdown({required this.stats});

  @override
  State<_ClassPerformanceCardWithSubjectDropdown> createState() =>
      _ClassPerformanceCardWithSubjectDropdownState();
}

class _ClassPerformanceCardWithSubjectDropdownState
    extends State<_ClassPerformanceCardWithSubjectDropdown> {
  String? _selectedSubjectId;

  // Extract unique subjects from records
  List<Map<String, String>> _getUniqueSubjects() {
    final Map<String, String> subjectsMap = {};
    for (final r in widget.stats.records) {
      if (r.subjectId != null && r.subjectInfo != null) {
        subjectsMap[r.subjectId!] = r.subjectInfo!.name;
      } else if (r.subjectInfo != null) {
        subjectsMap[r.subjectInfo!.name] = r.subjectInfo!.name; // Fallback
      }
    }
    return subjectsMap.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList();
  }

  // Get records filtered by subject and deduplicated by studentId
  List<TeacherClassAttendRecord> _getFilteredRecords() {
    if (_selectedSubjectId == null) return [];

    final filtered = widget.stats.records
        .where(
          (r) =>
              r.subjectId == _selectedSubjectId ||
              r.subjectInfo?.name == _selectedSubjectId,
        )
        .toList();

    final Map<String, TeacherClassAttendRecord> seen = {};
    // Sort descending by date so the latest record is processed first
    final sorted = [...filtered]..sort((a, b) => b.date.compareTo(a.date));

    for (final r in sorted) {
      seen.putIfAbsent(r.studentId, () => r);
    }
    return seen.values.toList();
  }

  @override
  void initState() {
    super.initState();
    final subjects = _getUniqueSubjects();
    if (subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first['id'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = widget.stats;
    final statusColor = stats.attendanceRate > 80
        ? Colors.green
        : (stats.attendanceRate > 50 ? Colors.orange : Colors.red);

    final subjects = _getUniqueSubjects();
    final displayRecords = _getFilteredRecords();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                          Text(
                            stats.classInfo?.name ??
                                AppLocalizations.of(context)!.className,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatItemLocal(
                                l10n.present,
                                stats.present.toString(),
                                Colors.green,
                              ),
                              _buildStatItemLocal(
                                l10n.absent,
                                stats.absent.toString(),
                                Colors.red,
                              ),
                              _buildStatItemLocal(
                                l10n.leave,
                                stats.leave.toString(),
                                Colors.orange,
                              ),
                              _buildStatItemLocal(
                                AppLocalizations.of(context)!.totalText,
                                stats.total.toString(),
                                Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey.shade300,
                      size: 16,
                    ),
                  ],
                ),
                if (stats.records.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Subject Dropdown Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.studentAttendance,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (subjects.isNotEmpty)
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeacher.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryTeacher.withOpacity(0.2),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSubjectId,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: AppColors.primaryTeacher,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryTeacher,
                              ),
                              items: subjects.map((subj) {
                                return DropdownMenuItem<String>(
                                  value: subj['id'],
                                  child: Text(subj['name'] ?? AppLocalizations.of(context)!.unknown),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSubjectId = val);
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Horizontal List of Filtered Students
                  if (displayRecords.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.noRecordsForSelectedSubject,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 85,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: displayRecords.length,
                        itemBuilder: (context, index) {
                          return _buildStudentAvatarCardLocal(
                            displayRecords[index],
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItemLocal(String label, String value, Color color) {
    return Column(
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

  Widget _buildStudentAvatarCardLocal(TeacherClassAttendRecord record) {
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

/// A horizontal list of class cards that auto-scrolls to the currently
/// active class on first render. Manages its own [ScrollController] so it
/// never affects the parent vertical scroll position.
class _ClassCardListView extends StatefulWidget {
  const _ClassCardListView({
    required this.classes,
    required this.buildCard,
    required this.isCurrentClass,
  });

  final List<RoutineEntry> classes;
  final Widget Function(BuildContext, RoutineEntry) buildCard;
  final bool Function(String startTime, String endTime) isCurrentClass;

  @override
  State<_ClassCardListView> createState() => _ClassCardListViewState();
}

class _ClassCardListViewState extends State<_ClassCardListView> {
  late final ScrollController _scrollController;

  static const double _cardGap = 12.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveClass());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveClass() {
    if (!mounted || !_scrollController.hasClients) return;

    final activeIndex = widget.classes.indexWhere(
      (c) => widget.isCurrentClass(c.startTime, c.endTime),
    );

    if (activeIndex <= 0) return; // already at start or none active

    // Calculate the pixel offset: each card occupies its rendered width + gap.
    // We use the actual maxScrollExtent divided by total cards to get
    // a per-card width that accounts for the real rendered size.
    final maxScroll = _scrollController.position.maxScrollExtent;
    final totalCards = widget.classes.length;
    if (totalCards <= 1) return;

    final perCardOffset = maxScroll / (totalCards - 1);
    final targetOffset = (activeIndex * perCardOffset).clamp(0.0, maxScroll);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 185,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.classes.length,
        itemBuilder: (ctx, index) => Padding(
          padding: const EdgeInsets.only(right: _cardGap),
          child: widget.buildCard(ctx, widget.classes[index]),
        ),
      ),
    );
  }
}
