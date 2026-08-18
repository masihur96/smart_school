import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/online_class/providers/online_class_provider.dart';
import 'package:smart_school/models/online_class_model.dart';
import 'package:smart_school/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

import 'add_edit_online_class_screen.dart';

class OnlineClassListScreen extends StatefulWidget {
  final bool isAdminOrTeacher;

  const OnlineClassListScreen({super.key, this.isAdminOrTeacher = true});

  @override
  State<OnlineClassListScreen> createState() => _OnlineClassListScreenState();
}

class _OnlineClassListScreenState extends State<OnlineClassListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      final schoolId = user?.schoolId ?? '';
      context.read<OnlineClassProvider>().fetchOnlineClasses();
      if (schoolId.isNotEmpty) {
        context.read<ClassSetupNotifier>().fetchClasses(schoolId);
      }
      context.read<SectionSetupNotifier>().fetchSections();
    });
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _deleteClass(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text('Are you sure you want to delete this class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await context.read<OnlineClassProvider>().deleteOnlineClass(
      id,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class deleted successfully')),
      );
    } else {
      final error = context.read<OnlineClassProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to delete class')),
      );
    }
  }

  Future<void> _launchURL(String urlString) async {
    String formattedUrl = urlString.trim();
    if (formattedUrl.isEmpty) return;
    if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }
    final Uri url = Uri.parse(formattedUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $formattedUrl')),
        );
      }
    }
  }

  String _getClassSectionLabel(BuildContext context, OnlineClass oClass) {
    if (oClass.className != null && oClass.className!.isNotEmpty) {
      if (oClass.sectionName != null && oClass.sectionName!.isNotEmpty) {
        return '${oClass.className} (${oClass.sectionName})';
      }
      return oClass.className!;
    }

    final classSetup = context.watch<ClassSetupNotifier>();
    final sectionSetup = context.watch<SectionSetupNotifier>();

    if (oClass.classId != null) {
      final clsList = classSetup.classes;
      final cls = clsList.cast<dynamic>().firstWhere(
        (c) => c.id == oClass.classId,
        orElse: () => null,
      );
      if (cls != null) {
        if (oClass.sectionId != null) {
          final secList = sectionSetup.sections;
          final sec = secList.cast<dynamic>().firstWhere(
            (s) => s.id == oClass.sectionId,
            orElse: () => null,
          );
          if (sec != null) {
            return '${cls.name} (${sec.name})';
          }
        }
        return cls.name;
      }
    }

    return 'All Classes & Sections';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    final isTeacher = user?.role == UserRole.teacher;
    final isAdmin =
        user?.role == UserRole.admin || user?.role == UserRole.superadmin;
    final isStudent = user?.role == UserRole.student;

    final bool canManageClass =
        widget.isAdminOrTeacher && (isAdmin || isTeacher);

    Color themeColor = AppColors.primaryAdmin;
    if (isTeacher) {
      themeColor = AppColors.primaryTeacher;
    } else if (isStudent) {
      themeColor = AppColors.primaryStudent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Classes'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<OnlineClassProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildShimmerLoader();
          }

          if (provider.error != null && provider.onlineClasses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 60,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: provider.fetchOnlineClasses,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.onlineClasses.isEmpty) {
            return const Center(
              child: Text(
                'No online classes scheduled.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchOnlineClasses,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.onlineClasses.length,
              itemBuilder: (context, index) {
                return _buildOnlineClassCard(
                  context,
                  provider.onlineClasses[index],
                  canManageClass,
                  themeColor,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: canManageClass
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditOnlineClassScreen(
                      isAdminOrTeacher: canManageClass,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  context.read<OnlineClassProvider>().fetchOnlineClasses();
                }
              },
              backgroundColor: themeColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Class',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  // ── Shimmer ───────────────────────────────────────────────────────────────

  Widget _buildShimmerLoader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 150,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Container(
                      width: 70,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: 120,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────

  Widget _buildOnlineClassCard(
    BuildContext context,
    OnlineClass oClass,
    bool canManageClass,
    Color themeColor,
  ) {
    final formattedDate = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(oClass.scheduledTime);
    final isUpcoming = oClass.scheduledTime.isAfter(DateTime.now());
    final classSectionLabel = _getClassSectionLabel(context, oClass);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    oClass.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isUpcoming
                        ? AppColors.success.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isUpcoming ? 'Upcoming' : 'Past',
                    style: TextStyle(
                      color: isUpcoming ? AppColors.success : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canManageClass)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditOnlineClassScreen(
                              onlineClass: oClass,
                              isAdminOrTeacher: canManageClass,
                            ),
                          ),
                        );
                        if (result == true && mounted) {
                          context
                              .read<OnlineClassProvider>()
                              .fetchOnlineClasses();
                        }
                      } else if (value == 'delete') {
                        _deleteClass(oClass.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Host / Teacher info
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Teacher: ${oClass.teacherName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Target Class & Section
            Row(
              children: [
                const Icon(Icons.school_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Target: $classSectionLabel',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Scheduled Time
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16),
                const SizedBox(width: 6),
                Text(formattedDate, style: const TextStyle(fontSize: 13)),
              ],
            ),

            if (oClass.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                oClass.description,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Join Meeting Button for all roles
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchURL(oClass.meetLink),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.video_call_rounded, color: Colors.white),
                label: const Text(
                  'Join Meeting',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
