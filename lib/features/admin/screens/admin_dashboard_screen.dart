import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_school/features/admin/screens/setup_screen.dart';
import 'package:smart_school/features/admin/screens/teacher_management_screen.dart';
import 'package:smart_school/features/profile/presentation/views/profile_screen.dart';
import 'package:smart_school/models/school_models.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../teacher/providers/attendance_provider.dart';
import '../../teacher/domain/entities/attendance.dart';
import 'student_management_screen.dart';
import 'exam_management_screen.dart';
import 'notice_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load all attendance data for the chart
    Future.microtask(() {
      if (mounted) {
        context.read<AttendanceNotifier>().loadAll();
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
        return 'Admin Dashboard';
      case 1:
        return 'Student Management';
      case 2:
        return 'Exam Management';
      case 3:
        return 'School Notices';
      default:
        return 'Admin Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceRecords = context.watch<AttendanceNotifier>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_)=>ProfileScreen(),),);

            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardOverview(attendanceRecords),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in), label: 'Exams'),
          BottomNavigationBarItem(icon: Icon(Icons.announcement), label: 'Notices'),
        ],
      ),
    );
  }

  Widget _buildDashboardOverview(List<AttendanceEntity> attendanceRecords) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'School Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              _buildStatCard(context, 'Total Students', '450', Icons.people, Colors.blue, onTap: () => setState(() => _selectedIndex = 1)),
              _buildStatCard(context, 'Total Teachers', '25', Icons.person, Colors.orange, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_)=>TeacherManagementScreen()));
              }),
              _buildStatCard(context, 'Total Classes', '12', Icons.class_, Colors.green, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_)=>SetupScreen()));
              }),
              _buildStatCard(context, 'Active Notices', '5', Icons.announcement, Colors.red, onTap: () => setState(() => _selectedIndex = 3)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Attendance Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAttendanceChart(attendanceRecords),
          const SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActionTile(context, 'Add Student', Icons.person_add, Colors.blue, onTap: () => context.push('/admin/students/add')),
          _buildActionTile(context, 'Add Teacher', Icons.group_add, Colors.orange, onTap: () => context.push('/admin/teachers/add')),
          _buildActionTile(context, 'Post Notice', Icons.post_add, Colors.red, onTap: () => setState(() => _selectedIndex = 3)),
          _buildActionTile(context, 'Manage Routine', Icons.calendar_month, Colors.purple, onTap: () => context.push('/admin/routine')),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildAttendanceChart(List<AttendanceEntity> records) {
    // Process data: Group by day for the current month
    final Map<int, List<AttendanceEntity>> dailyData = {};
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // Initialize all days of the current month
    for (int i = 1; i <= daysInMonth; i++) {
      dailyData[i] = [];
    }

    // Fill with data
    for (var record in records) {
      if (record.date.year == now.year && record.date.month == now.month) {
        dailyData[record.date.day]!.add(record);
      }
    }

    final sortedDays = dailyData.keys.toList()..sort();
    
    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 12, right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.purple.withValues(alpha: 0.8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'Day ${sortedDays[group.x.toInt()]}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= sortedDays.length) return const SizedBox.shrink();
                  final day = sortedDays[value.toInt()];
                  // Show only every 5th day to avoid crowding
                  if (day % 5 != 0 && day != 1 && day != daysInMonth) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      day.toString(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value % 20 != 0) return const SizedBox.shrink();
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: sortedDays.asMap().entries.map((entry) {
            final dayRecords = dailyData[entry.value]!;
            final total = dayRecords.length;
            final present = dayRecords.where((r) => r.status == AttendanceStatus.present).length;
            final percentage = total == 0 ? 0.0 : (present / total) * 100;

            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: percentage,
                  color: Colors.purple,
                  width: 6,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: Colors.purple.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
