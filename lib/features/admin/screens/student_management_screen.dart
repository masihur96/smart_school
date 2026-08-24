import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/screens/add_edit_student_screen.dart';
import 'package:smart_school/features/admin/screens/admin_pricing_plan_screen.dart';
import 'package:smart_school/features/admin/screens/generate_id_card_screen.dart';
import 'package:smart_school/features/admin/screens/generate_transcript_screen.dart';
import 'package:smart_school/features/admin/screens/student_detail_screen.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/student_model.dart';
import 'package:smart_school/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/geocoding_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/student_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StudentManagementScreen extends StatefulWidget {
  final bool hideAppBar;
  const StudentManagementScreen({super.key, this.hideAppBar = false});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  bool? _selectedStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      final schoolId = user?.schoolId ?? '';

      if (schoolId.isNotEmpty &&
          context.read<ClassSetupNotifier>().classes.isEmpty) {
        context.read<ClassSetupNotifier>().fetchClasses(schoolId);
      }
      if (context.read<SectionSetupNotifier>().sections.isEmpty) {
        context.read<SectionSetupNotifier>().fetchSections();
      }
      if (context.read<StudentsNotifier>().students.isEmpty &&
          !context.read<StudentsNotifier>().isLoading) {
        context.read<StudentsNotifier>().fetchStudents();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = context.read<StudentsNotifier>();
      if (!notifier.isLoadingMore && !notifier.isLoading && notifier.hasMore) {
        notifier.fetchStudents(
          classId: _selectedClassId,
          sectionId: _selectedSectionId,
          isActive: _selectedStatus,
          search: _searchQuery.isEmpty ? null : _searchQuery,
          loadMore: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    context.read<StudentsNotifier>().fetchStudents(
      classId: _selectedClassId,
      sectionId: _selectedSectionId,
      isActive: _selectedStatus,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsNotifier = context.watch<StudentsNotifier>();
    final students = studentsNotifier.students;
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: Text(AppLocalizations.of(context)!.studentManagement),
              backgroundColor: AppColors.primaryAdmin,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.receipt_long),
                  onPressed: () {
                    if (students.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No students to generate transcripts.'),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GenerateTranscriptScreen(students: students),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.badge),
                  onPressed: () {
                    if (students.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No students to generate ID cards.'),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GenerateIdCardScreen(students: students),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => context.push('/admin/students/add'),
                ),
              ],
            ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.searchByName,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 500),
                      _applyFilters,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.classLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              AppLocalizations.of(context)!.allClasses,
                            ),
                          ),
                          ...classes.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        value: _selectedClassId,
                        onChanged: (val) {
                          setState(() {
                            _selectedClassId = val;
                            _selectedSectionId = null; // reset section
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.section,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              AppLocalizations.of(context)!.allSections,
                            ),
                          ),
                          ...sections
                              .where((s) => s.classId == _selectedClassId)
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              ),
                        ],
                        value: _selectedSectionId,
                        onChanged: (val) {
                          setState(() => _selectedSectionId = val);
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.status,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<bool?>(
                            value: null,
                            child: Text(
                              AppLocalizations.of(context)!.allStatus,
                            ),
                          ),
                          DropdownMenuItem<bool?>(
                            value: true,
                            child: Text(
                              AppLocalizations.of(context)!.activeOnly,
                            ),
                          ),
                          DropdownMenuItem<bool?>(
                            value: false,
                            child: Text(
                              AppLocalizations.of(context)!.inactiveOnly,
                            ),
                          ),
                        ],
                        value: _selectedStatus,
                        onChanged: (val) {
                          setState(() => _selectedStatus = val);
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.total,
                          style: const TextStyle(
                            fontSize: 12,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${studentsNotifier.totalCount}',
                          style: const TextStyle(
                            fontSize: 16,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final user = context.read<AuthNotifier>().user;
                  final schoolId = user?.schoolId ?? '';
                  if (schoolId.isNotEmpty) {
                    context.read<ClassSetupNotifier>().fetchClasses(schoolId);
                  }
                  context.read<SectionSetupNotifier>().fetchSections();
                  await context.read<StudentsNotifier>().fetchStudents(
                    classId: _selectedClassId,
                    sectionId: _selectedSectionId,
                    isActive: _selectedStatus,
                    search: _searchQuery.isEmpty ? null : _searchQuery,
                  );
                },
                child: studentsNotifier.isLoading && students.isEmpty
                    ? _StudentShimmer(
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      )
                    : students.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)!.noStudentsFound,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: _scrollController,
                        itemCount:
                            students.length +
                            (studentsNotifier.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == students.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryAdmin,
                                ),
                              ),
                            );
                          }
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          final student = students[index];
                          return _buildStudentCard(context, student, isDark);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final studentCount = context.read<StudentsNotifier>().totalCount;

          final authState = context.read<AuthNotifier>();

          final maxStudents =
              authState.adminSubscription?.pricingPlan?.maxStudents;

          if (maxStudents != null && studentCount >= maxStudents) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.limitReached),
                content: Text(
                  AppLocalizations.of(
                    context,
                  )!.studentLimitReached(studentCount, maxStudents),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPricingPlanScreen(),
                        ),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.upgradePlan),
                  ),
                ],
              ),
            );

            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
          ).then((_) {
            _applyFilters();
          });
        },

        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Student student, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final user = student.user;
    final studentName = (user != null && user.name.isNotEmpty)
        ? user.name
        : 'Unknown';
    final studentPhone = user?.phone?.trim() ?? '';
    final guardianPhone = student.guardianContact.trim();
    final email = user?.email.trim() ?? '';
    final hasLatLon = user != null && user.lat != null && user.lon != null;
    final designation = user?.designation?.trim();
    final hasAddressText =
        designation != null &&
        designation.isNotEmpty &&
        designation.toLowerCase() != 'student';

    // Classes string
    final classesStr = student.embeddedClasses.isNotEmpty
        ? student.embeddedClasses.map((c) => c.name).join(', ')
        : '';
    // Sections string
    final sectionsStr = student.embeddedSections.isNotEmpty
        ? student.embeddedSections.map((s) => s.name).join(', ')
        : '';

    return Card(
      key: ValueKey(student.userId),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(student: student),
            ),
          ).then((_) => _applyFilters());
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Avatar, Name, Badges, Action Menu ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'student-avatar-${student.userId}',
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryAdmin.withValues(
                        alpha: 0.12,
                      ),
                      backgroundImage: (user?.avatar?.startsWith('http://') == true ||
                              user?.avatar?.startsWith('https://') == true)
                          ? CachedNetworkImageProvider(user!.avatar!)
                          : null,
                      onBackgroundImageError: (user?.avatar?.startsWith('http://') == true ||
                              user?.avatar?.startsWith('https://') == true)
                          ? (_, __) {}
                          : null,
                      child: (user?.avatar?.startsWith('http://') == true ||
                              user?.avatar?.startsWith('https://') == true)
                          ? null
                          : Text(
                              studentName.isNotEmpty
                                  ? studentName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.primaryAdmin,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Roll Badge
                            if (student.rollId.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.blue.shade900.withValues(
                                          alpha: 0.3,
                                        )
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Roll #${student.rollId}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.blue.shade300
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: student.isActive
                                    ? (isDark
                                          ? Colors.green.shade900.withValues(
                                              alpha: 0.3,
                                            )
                                          : Colors.green.shade50)
                                    : (isDark
                                          ? Colors.red.shade900.withValues(
                                              alpha: 0.3,
                                            )
                                          : Colors.red.shade50),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: student.isActive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    student.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: student.isActive
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StudentDetailScreen(student: student),
                          ),
                        ).then((_) => _applyFilters());
                      } else if (value == 'notify') {
                        _showNotificationDialog(context, student);
                      } else if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditStudentScreen(student: student),
                          ),
                        ).then((_) => _applyFilters());
                      } else if (value == 'status') {
                        context.read<StudentsNotifier>().toggleStudentStatus(
                          student.userId,
                        );
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.deleteStudent),
                            content: const Text(
                              'Are you sure you want to delete this student?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(l10n.cancel),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  context
                                      .read<StudentsNotifier>()
                                      .deleteStudent(student.userId);
                                  Navigator.pop(ctx);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text(
                                  l10n.delete,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'view',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                color: Colors.purple,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.viewDetails),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'notify',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.notifications_active_outlined,
                                color: Colors.purple,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.sendNotification),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_outlined,
                                color: Colors.blue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.edit),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(
                                student.isActive
                                    ? Icons.block
                                    : Icons.check_circle_outline,
                                color: student.isActive
                                    ? Colors.orange
                                    : Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                student.isActive ? 'Deactivate' : 'Activate',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.delete,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),

              // ── Academic Info Row (Class & Section Chips) ──
              if (classesStr.isNotEmpty || sectionsStr.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (classesStr.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAdmin.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 13,
                              color: AppColors.primaryAdmin,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              classesStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryAdmin,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (sectionsStr.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.grid_view_rounded,
                              size: 12,
                              color: Colors.teal.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sec: $sectionsStr',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
              const SizedBox(height: 8),

              // ── Contact & Location Details ──
              // Phone number row
              if (studentPhone.isNotEmpty || guardianPhone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: InkWell(
                    onTap: () {
                      final targetPhone = studentPhone.isNotEmpty
                          ? studentPhone
                          : guardianPhone;
                      _launchUrl('tel:$targetPhone');
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: AppColors.primaryAdmin.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                if (studentPhone.isNotEmpty) ...[
                                  TextSpan(
                                    text: studentPhone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (guardianPhone.isNotEmpty &&
                                      guardianPhone != studentPhone)
                                    TextSpan(
                                      text: '  (Guardian: $guardianPhone)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ] else if (guardianPhone.isNotEmpty) ...[
                                  TextSpan(
                                    text: 'Guardian: $guardianPhone',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.call_outlined,
                          size: 13,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),

              // Address / Location row
              if (hasLatLon || hasAddressText)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.redAccent.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: hasLatLon
                            ? FutureBuilder<String>(
                                future: GeocodingService().getPlaceName(
                                  user.lat.toString(),
                                  user.lon.toString(),
                                ),
                                builder: (context, snapshot) {
                                  final place =
                                      snapshot.connectionState ==
                                          ConnectionState.waiting
                                      ? 'Locating...'
                                      : (snapshot.data ??
                                            '${user.lat?.toStringAsFixed(3)}, ${user.lon?.toStringAsFixed(3)}');
                                  return Text(
                                    place,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              )
                            : Text(
                                user?.designation?.trim() ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                ),

              // Email row
              if (email.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: Colors.blue.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
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
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showNotificationDialog(BuildContext context, Student student) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(
              l10n.notifyStudent(student.user?.name ?? l10n.students),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: l10n.titleLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.messageLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        if (titleController.text.trim().isEmpty ||
                            messageController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.pleaseEnterTitleAndMessage),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          isSending = true;
                        });

                        try {
                          await NotificationService().sendNotification(
                            receiverUuid: student.user?.id ?? student.userId,
                            title: titleController.text.trim(),
                            message: messageController.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.notificationSentSuccessfully,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() {
                            isSending = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.failedToSendNotification),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.send),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Shimmer skeleton ────────────────────────────────────────────────────────

class _StudentShimmer extends StatelessWidget {
  final bool isDark;
  const _StudentShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: 8,
      itemBuilder: (context, _) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar + Name + Badges
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  height: 16,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  height: 16,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Class & section chips placeholder
                  Row(
                    children: [
                      Container(
                        height: 20,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 20,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(height: 1, color: Colors.white),
                  const SizedBox(height: 8),
                  // Phone line placeholder
                  Container(
                    height: 11,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Address line placeholder
                  Container(
                    height: 11,
                    width: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
