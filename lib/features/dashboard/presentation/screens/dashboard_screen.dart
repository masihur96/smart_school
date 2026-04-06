import 'package:flutter/material.dart';
import 'package:teacher_app/core/theme.dart';
import 'package:teacher_app/data/mock_data/mock_data.dart';
import 'package:teacher_app/features/attendance/presentation/screens/mark_attendance_screen.dart';
import 'package:teacher_app/features/attendance/presentation/screens/own_attendance_screen.dart';
import 'package:teacher_app/features/attendance/presentation/screens/student_attendance_screen.dart';
import 'package:teacher_app/features/auth/presentation/screens/login_screen.dart';
import 'package:teacher_app/features/coursework/presentation/screens/coursework_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  final bool isHomeTab;
  const DashboardScreen({super.key, this.isHomeTab = false});

  @override
  Widget build(BuildContext context) {
    final studentStats = MockData.getStudentSummary();
    final teacherStats = MockData.getTeacherSummary();
    final todayCoursework = MockData.coursework
        .where((c) => c['createdAt'] == MockData.today)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          if (!isHomeTab)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildSummaryCards(context, teacherStats, studentStats),
            const SizedBox(height: 32),
            _buildSectionHeader('Today\'s Coursework', () {
              // Navigation to coursework list
            }),
            const SizedBox(height: 16),
            ...todayCoursework
                .map((item) => _buildCourseworkTile(context, item)),
            if (todayCoursework.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No coursework added today.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            const SizedBox(height: 32),
            _buildSectionHeader('Quick Manage', null),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning,',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              Text(
                'Mr. Masihur Rahman',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 28),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.person_2_outlined,
            size: 60,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, Map<String, dynamic> teacher,
      Map<String, dynamic> students) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            'My Attendance',
            teacher['todayStatus'],
            'Monthly: ${teacher['monthlyAttendance']}',
            Icons.calendar_today_rounded,
            AppColors.primary,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const OwnAttendanceScreen())),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Student Attendance',
            '${students['percentage']}%',
            '${students['present']} Present / ${students['absent']} Absent',
            Icons.people_alt_rounded,
            AppColors.success,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const StudentAttendanceScreen(isTab: false))),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String mainStat,
      String subStat, IconData icon, Color color, VoidCallback onTap) {
    bool isTeacherAttendance = title == 'My Attendance';
    bool markedToday = MockData.isTodayMarked();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (isTeacherAttendance && !markedToday)
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MarkAttendanceScreen()),
                      );
                      if (result == true) {
                        (context as Element)
                            .markNeedsBuild(); // Simple refresh for demo
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Submit',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(isTeacherAttendance && !markedToday ? 'Not Marked' : mainStat,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isTeacherAttendance && !markedToday
                        ? AppColors.error
                        : color)),
            const SizedBox(height: 4),
            Text(subStat,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
                maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All', style: TextStyle(fontSize: 14)),
          ),
      ],
    );
  }

  Widget _buildCourseworkTile(BuildContext context, Map<String, dynamic> item) {
    final isHomework = item['type'] == 'Homework';
    final color = isHomework ? Colors.purple : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
                isHomework ? Icons.home_work_outlined : Icons.book_outlined,
                color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${item['type']} • Due: ${item['dueDate']}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionTile(
            context, 'Attendance', Icons.group_add_rounded, AppColors.success,
            () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const StudentAttendanceScreen(isTab: false)));
        }),
        _buildActionTile(
            context, 'New Task', Icons.add_task_rounded, Colors.orange, () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CourseworkListScreen(
                      initialIndex: 0, isTab: false)));
        }),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
