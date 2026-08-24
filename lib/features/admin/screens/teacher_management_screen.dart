import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/features/admin/screens/add_edit_teacher_screen.dart';
import 'package:smart_school/features/admin/screens/admin_pricing_plan_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/school_models.dart' hide Teacher;
import 'package:smart_school/models/teacher_model.dart';
import 'package:smart_school/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/geocoding_service.dart';
import '../providers/setup_provider.dart';
import '../providers/teacher_provider.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  State<TeacherManagementScreen> createState() =>
      _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authNotifier = context.read<AuthNotifier>();
      final schoolId = authNotifier.user?.schoolId;

      // Only fetch teachers if not already loaded
      if (context.read<TeachersNotifier>().teachers.isEmpty) {
        _fetchTeachers();
      }

      if (schoolId != null) {
        // Only fetch classes if not already loaded
        if (context.read<ClassSetupNotifier>().classes.isEmpty) {
          context.read<ClassSetupNotifier>().fetchClasses(schoolId);
        }
        // Only fetch sections if not already loaded
        if (context.read<SectionSetupNotifier>().sections.isEmpty) {
          context.read<SectionSetupNotifier>().fetchSections();
        }
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TeachersNotifier>().fetchTeachers(
        loadMore: true,
        classId: _selectedClass,
        sectionId: _selectedSection,
        isActive: _selectedStatus == 'Active'
            ? true
            : (_selectedStatus == 'Inactive' ? false : null),
      );
    }
  }

  void _fetchTeachers() {
    context.read<TeachersNotifier>().fetchTeachers(
      classId: _selectedClass,
      sectionId: _selectedSection,
      isActive: _selectedStatus == 'Active'
          ? true
          : (_selectedStatus == 'Inactive' ? false : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teachers = context.watch<TeachersNotifier>().teachers;
    final isLoading = context.watch<TeachersNotifier>().isLoading;
    final isLoadingMore = context.watch<TeachersNotifier>().isLoadingMore;

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teacherManagementTitle),
        backgroundColor: AppColors.primaryAdmin,
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedStatus,
                  items: ['All', 'Active', 'Inactive']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedStatus = val);
                    _fetchTeachers();
                  },
                ),
              ],
            ),
          ),

          // Teachers List
          Expanded(
            child: isLoading
                ? _TeacherShimmer(
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  )
                : teachers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No teachers found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: teachers.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == teachers.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.purple,
                            ),
                          ),
                        );
                      }

                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final teacher = teachers[index];
                      return _buildTeacherCard(context, teacher, isDark);
                    },
                  ),
          ),
        ],
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
                title: const Text("Limit Reached"),

                content: Text(
                  "You have reached your student limit "
                  "($studentCount / $maxStudents).\n\n"
                  "Upgrade your plan to add more students.",
                ),

                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
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
                    child: const Text("Upgrade Plan"),
                  ),
                ],
              ),
            );

            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditTeacherScreen()),
          ).then((_) => _fetchTeachers());
        },

        backgroundColor: Colors.purple,

        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTeacherCard(BuildContext context, Teacher teacher, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final user = teacher.user;
    final teacherName = user?.name.isNotEmpty == true ? user!.name : 'No Name';
    final teacherPhone = user?.phone?.trim() ?? '';
    final email = user?.email?.trim() ?? '';
    final lat = teacher.lat ?? user?.lat;
    final lon = teacher.lon ?? user?.lon;
    final hasLatLon = lat != null && lon != null;
    final designation = teacher.designation.trim().isNotEmpty
        ? teacher.designation.trim()
        : 'Teacher';

    // Classes string
    final classesStr = teacher.embeddedClasses.isNotEmpty
        ? teacher.embeddedClasses.map((c) => c.name).join(', ')
        : '';
    // Sections string
    final sectionsStr = teacher.embeddedSections.isNotEmpty
        ? teacher.embeddedSections.map((s) => s.name).join(', ')
        : '';
    // Assigned subjects count
    final subjectCount = teacher.assignedSubjects.length;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTeacherDetails(context, teacher),
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
                    tag: 'teacher-avatar-${teacher.userId}',
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryAdmin.withValues(
                        alpha: 0.12,
                      ),
                      backgroundImage:
                          (user?.avatar?.startsWith('http://') == true ||
                              user?.avatar?.startsWith('https://') == true)
                          ? NetworkImage(user!.avatar!)
                          : null,
                      onBackgroundImageError:
                          (user?.avatar?.startsWith('http://') == true ||
                              user?.avatar?.startsWith('https://') == true)
                          ? (_, __) {}
                          : null,
                      child:
                          (user?.avatar?.startsWith('http://') == true ||
                              user?.avatar?.startsWith('https://') == true)
                          ? null
                          : Text(
                              teacherName.isNotEmpty
                                  ? teacherName[0].toUpperCase()
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
                          teacherName,
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
                            // Designation Badge
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 11,
                                    color: isDark
                                        ? Colors.blue.shade300
                                        : Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    designation,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.blue.shade300
                                          : Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: teacher.isActive
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
                                      color: teacher.isActive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    teacher.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: teacher.isActive
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
                    onSelected: (value) async {
                      if (value == 'view') {
                        _showTeacherDetails(context, teacher);
                      } else if (value == 'notify') {
                        _showNotificationDialog(context, teacher);
                      } else if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditTeacherScreen(teacher: teacher),
                          ),
                        ).then((_) => _fetchTeachers());
                      } else if (value == 'status') {
                        await context
                            .read<TeachersNotifier>()
                            .toggleTeacherStatus(teacher.userId);
                      } else if (value == 'delete') {
                        final l10n = AppLocalizations.of(context)!;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.deleteTeacher),
                            content: const Text(
                              'Are you sure you want to delete this teacher?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l10n.cancel),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
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
                        if (confirm == true && context.mounted) {
                          await context.read<TeachersNotifier>().deleteTeacher(
                            teacher.userId,
                          );
                        }
                      }
                    },
                    itemBuilder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                color: Colors.purple,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.viewProfile),
                            ],
                          ),
                        ),
                        PopupMenuItem(
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
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_outlined,
                                color: Colors.blue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.editTeacher),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(
                                teacher.isActive
                                    ? Icons.block
                                    : Icons.check_circle_outline,
                                color: teacher.isActive
                                    ? Colors.orange
                                    : Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                teacher.isActive ? 'Deactivate' : 'Activate',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
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

              // ── Academic & Subject Badges Row ──
              if (classesStr.isNotEmpty ||
                  sectionsStr.isNotEmpty ||
                  subjectCount > 0) ...[
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
                    if (subjectCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 12,
                              color: Colors.indigo.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$subjectCount ${subjectCount == 1 ? "Subject" : "Subjects"}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.indigo.shade700,
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
              if (teacherPhone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: InkWell(
                    onTap: () => _launchUrl('tel:$teacherPhone'),
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
                          child: Text(
                            teacherPhone,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
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
              if (hasLatLon)
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
                        child: FutureBuilder<String>(
                          future: GeocodingService().getPlaceName(
                            lat.toString(),
                            lon.toString(),
                          ),
                          builder: (context, snapshot) {
                            final place =
                                snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? 'Locating...'
                                : (snapshot.data ??
                                      '${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)}');
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
                        ),
                      ),
                    ],
                  ),
                ),

              // Email row
              if (email.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: InkWell(
                    onTap: () => _launchUrl('mailto:$email'),
                    borderRadius: BorderRadius.circular(4),
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTeacherDetails(BuildContext context, Teacher teacher) {
    final user = teacher.user;

    // Use embedded classes/sections from the API response first;
    // fall back to provider lookups if not available.
    final localClasses = context.read<ClassSetupNotifier>().classes;
    final localSections = context.read<SectionSetupNotifier>().sections;

    final classNames = teacher.embeddedClasses.isNotEmpty
        ? teacher.embeddedClasses.map((c) => c.name).join(', ')
        : localClasses
              .firstWhere(
                (c) => c.id == teacher.classId,
                orElse: () => ClassRoom(id: '', name: 'N/A', schoolId: ''),
              )
              .name;

    final sectionNames = teacher.embeddedSections.isNotEmpty
        ? teacher.embeddedSections.map((s) => s.name).join(', ')
        : localSections
              .firstWhere(
                (s) => s.id == teacher.sectionId,
                orElse: () => Section(id: '', name: 'N/A', classId: ''),
              )
              .name;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    backgroundImage:
                        (user?.avatar?.startsWith('http://') == true ||
                            user?.avatar?.startsWith('https://') == true)
                        ? NetworkImage(user!.avatar!)
                        : null,
                    onBackgroundImageError:
                        (user?.avatar?.startsWith('http://') == true ||
                            user?.avatar?.startsWith('https://') == true)
                        ? (_, __) {}
                        : null,
                    child:
                        (user?.avatar?.startsWith('http://') != true &&
                            user?.avatar?.startsWith('https://') != true)
                        ? const Icon(
                            Icons.person,
                            color: Colors.purple,
                            size: 35,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          teacher.designation,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Contact Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildDetailItem(
                Icons.email_outlined,
                'Email',
                user?.email ?? 'N/A',
                actionIcon: Icons.send,
                onTap: user?.email != null
                    ? () => _launchUrl('mailto:${user!.email}')
                    : null,
              ),
              _buildDetailItem(
                Icons.phone_outlined,
                'Phone',
                user?.phone ?? 'N/A',
                actionIcon: Icons.call,
                onTap: user?.phone != null
                    ? () => _launchUrl('tel:${user!.phone}')
                    : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Academic Assignment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildDetailItem(
                Icons.class_outlined,
                'Assigned Class',
                classNames,
              ),
              _buildDetailItem(
                Icons.groups_outlined,
                'Assigned Section',
                sectionNames,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
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

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value, {
    IconData? actionIcon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple.shade300),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (actionIcon != null && onTap != null)
            Material(
              color: Colors.purple.shade50,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    actionIcon,
                    size: 18,
                    color: Colors.purple.shade600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, Teacher teacher) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.notifyTeacher(teacher.user?.name ?? l10n.teacher)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
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
                            receiverUuid: teacher.user?.id ?? teacher.userId,
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

class _TeacherShimmer extends StatelessWidget {
  final bool isDark;
  const _TeacherShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, _) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),

            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar + Name + Badges + menu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              width: 140,
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
                                  width: 70,
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
                  // Class, Section & Subject chips placeholder
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
                      const SizedBox(width: 8),
                      Container(
                        height: 20,
                        width: 75,
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
                    width: 170,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Address line placeholder
                  Container(
                    height: 11,
                    width: 210,
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
