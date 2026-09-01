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
import 'package:smart_school/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
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
        context.read<SubjectSetupNotifier>().fetchSubjects(schoolId);
      }
      context.read<SectionSetupNotifier>().fetchSections();
    });
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _deleteClass(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteClassTitle),
        content: Text(l10n.deleteClassConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.classDeletedSuccess)));
      context.read<OnlineClassProvider>().fetchOnlineClasses();
    } else {
      final error = context.read<OnlineClassProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? l10n.failedToDeleteClass)),
      );
    }
  }

  Future<void> _launchURL(String urlString) async {
    final l10n = AppLocalizations.of(context)!;
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
          SnackBar(content: Text(l10n.couldNotLaunchUrl(formattedUrl))),
        );
      }
    }
  }

  String _getClassSectionLabel(BuildContext context, OnlineClass oClass) {
    final l10n = AppLocalizations.of(context)!;
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

    return l10n.allClassesAndSections;
  }

  void _showMeetingDetails(
    BuildContext context,
    OnlineClass oClass,
    bool canManageClass,
    Color themeColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    Text(
                      oClass.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.person, color: themeColor),
                      title: const Text(
                        'Host / Teacher',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      subtitle: Text(
                        oClass.teacherName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    if (oClass.description.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.description, color: themeColor),
                        title: const Text(
                          'Description',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        subtitle: Text(
                          oClass.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_today, color: themeColor),
                      title: const Text(
                        'Date & Time',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      subtitle: Text(
                        '${DateFormat('MMM dd, yyyy').format(oClass.scheduledTime)}\n'
                        '${oClass.startTime != null ? (oClass.endTime != null ? '${oClass.startTime} – ${oClass.endTime}' : oClass.startTime!) : DateFormat('hh:mm a').format(oClass.scheduledTime)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (oClass.meetLink.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.link, color: themeColor),
                        title: const Text(
                          'Meeting Link',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        subtitle: Text(
                          oClass.meetLink,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    const Divider(height: 30),
                    Text(
                      'Participants (${oClass.participants.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...oClass.participants.map(
                      (p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _buildAvatarCircle(p, isDark),
                        title: Text(
                          p.name.isNotEmpty && p.name != 'Unknown'
                              ? p.name
                              : 'Participant',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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

    if (isStudent) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.onlineClassesTitle),
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
        ),
        body: Consumer<OnlineClassProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return _buildShimmerLoader();
            }

            if (provider.error != null && provider.onlineClasses.isEmpty) {
              return _buildErrorState(provider, themeColor);
            }

            return _buildListForTab(
              provider,
              themeColor,
              canManageClass,
              1, // Class meeting filter
            );
          },
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.onlineClassesTitle),
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Class Meeting'),
              Tab(text: 'Teacher Meeting'),
            ],
          ),
        ),
        body: Consumer<OnlineClassProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return _buildShimmerLoader();
            }

            if (provider.error != null && provider.onlineClasses.isEmpty) {
              return _buildErrorState(provider, themeColor);
            }

            return TabBarView(
              children: [
                _buildListForTab(
                  provider,
                  themeColor,
                  canManageClass,
                  0,
                ), // All
                _buildListForTab(
                  provider,
                  themeColor,
                  canManageClass,
                  1,
                ), // Class
                _buildListForTab(
                  provider,
                  themeColor,
                  canManageClass,
                  2,
                ), // Teacher
              ],
            );
          },
        ),
        floatingActionButton: user?.role.name.toLowerCase() != "student"
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditOnlineClassScreen(
                        isAdminOrTeacher: widget.isAdminOrTeacher,
                      ),
                    ),
                  );
                  if (result == true && context.mounted) {
                    context.read<OnlineClassProvider>().fetchOnlineClasses();
                  }
                },
                backgroundColor: themeColor,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  l10n.newClass,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildListForTab(
    OnlineClassProvider provider,
    Color themeColor,
    bool canManageClass,
    int tabIndex,
  ) {
    List<OnlineClass> filteredList = provider.onlineClasses;

    if (tabIndex == 1) {
      // Class Meetings
      filteredList = provider.onlineClasses
          .where(
            (o) =>
                o.className != null ||
                o.sectionName != null ||
                o.subjectName != null,
          )
          .toList();
    } else if (tabIndex == 2) {
      // Teacher Meetings
      filteredList = provider.onlineClasses
          .where(
            (o) =>
                o.className == null &&
                o.sectionName == null &&
                o.subjectName == null,
          )
          .toList();
    }

    final now = DateTime.now();
    filteredList.sort((a, b) {
      final startA = _getExactStartDateTime(a);
      final endA = _getExactEndDateTime(a);
      final startB = _getExactStartDateTime(b);
      final endB = _getExactEndDateTime(b);

      final isLiveA = startA.isBefore(now) && endA.isAfter(now);
      final isLiveB = startB.isBefore(now) && endB.isAfter(now);

      if (isLiveA && !isLiveB) return -1;
      if (!isLiveA && isLiveB) return 1;

      final isUpcomingA = startA.isAfter(now);
      final isUpcomingB = startB.isAfter(now);

      if (isUpcomingA && !isUpcomingB) return -1;
      if (!isUpcomingA && isUpcomingB) return 1;

      if (isUpcomingA && isUpcomingB) {
        return startA.compareTo(startB); // Nearest future first
      }

      // Both are past
      return startB.compareTo(startA); // Nearest past first (descending)
    });

    if (filteredList.isEmpty) {
      return _buildEmptyState(canManageClass, themeColor);
    }

    return RefreshIndicator(
      onRefresh: provider.fetchOnlineClasses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        // reverse: true,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showMeetingDetails(
              context,
              filteredList[index],
              canManageClass,
              themeColor,
            ),
            child: _buildOnlineClassCard(
              context,
              filteredList[index],
              canManageClass,
              themeColor,
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  DateTime _parseTimeStr(DateTime baseDate, String? timeStr, {bool isEnd = false}) {
    if (timeStr == null || timeStr.trim().isEmpty) {
      return isEnd ? baseDate.add(const Duration(hours: 1)) : baseDate;
    }
    
    try {
      final cleanTimeStr = timeStr.trim().replaceAll('\u202F', ' '); // Handle narrow no-break space
      // Try parsing with AM/PM
      final format = DateFormat('h:mm a');
      final parsed = format.parse(cleanTimeStr);
      return DateTime(baseDate.year, baseDate.month, baseDate.day, parsed.hour, parsed.minute);
    } catch (_) {}
    
    try {
      final cleanTimeStr = timeStr.trim().replaceAll('\u202F', ' '); // Handle narrow no-break space
      final format = DateFormat('hh:mm a');
      final parsed = format.parse(cleanTimeStr);
      return DateTime(baseDate.year, baseDate.month, baseDate.day, parsed.hour, parsed.minute);
    } catch (_) {}

    try {
      // Try 24 hour format
      final format = DateFormat('HH:mm');
      final parsed = format.parse(timeStr.trim());
      return DateTime(baseDate.year, baseDate.month, baseDate.day, parsed.hour, parsed.minute);
    } catch (_) {}

    try {
      // Manual fallback parsing
      final parts = timeStr.trim().split(RegExp(r'[:\s]'));
      if (parts.length >= 2) {
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;
        final lower = timeStr.toLowerCase();
        if (lower.contains('pm') && hour < 12) {
          hour += 12;
        } else if (lower.contains('am') && hour == 12) {
          hour = 0;
        }
        return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
      }
    } catch (_) {}
    
    return isEnd ? baseDate.add(const Duration(hours: 1)) : baseDate;
  }

  DateTime _getExactStartDateTime(OnlineClass oClass) {
    return _parseTimeStr(oClass.scheduledTime, oClass.startTime);
  }

  DateTime _getExactEndDateTime(OnlineClass oClass) {
    // If end time is missing, default to start time + 1 hour
    final start = _getExactStartDateTime(oClass);
    if (oClass.endTime == null || oClass.endTime!.isEmpty) {
      return start.add(const Duration(hours: 1));
    }
    DateTime end = _parseTimeStr(oClass.scheduledTime, oClass.endTime, isEnd: true);
    // If end time ends up being before start time (e.g. cross midnight), add a day
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }
    return end;
  }

  String _getTimeAgoOrUpcoming(BuildContext context, DateTime exactStartTime) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = exactStartTime.difference(now);

    if (difference.isNegative) {
      final pastDiff = now.difference(exactStartTime);
      if (pastDiff.inMinutes < 60) {
        return l10n.minutesAgo(pastDiff.inMinutes);
      } else if (pastDiff.inHours < 24) {
        return l10n.hoursAgo(pastDiff.inHours);
      } else if (pastDiff.inDays == 1) {
        return l10n.yesterday;
      } else if (pastDiff.inDays < 7) {
        return l10n.daysAgo(pastDiff.inDays);
      } else {
        return DateFormat('MMM dd').format(exactStartTime);
      }
    } else {
      if (difference.inMinutes < 60) {
        return l10n.inMinutes(difference.inMinutes);
      } else if (difference.inHours < 24) {
        return l10n.inHours(difference.inHours);
      } else if (difference.inDays == 1) {
        return l10n.tomorrow;
      } else if (difference.inDays < 7) {
        return l10n.inDays(difference.inDays);
      } else {
        return DateFormat('MMM dd').format(exactStartTime);
      }
    }
  }

  String _getPlatformLabel(BuildContext context, String meetLink) {
    final l10n = AppLocalizations.of(context)!;
    final lower = meetLink.toLowerCase();
    if (lower.contains('meet.google.com')) return l10n.googleMeet;
    if (lower.contains('zoom.us')) return l10n.zoom;
    if (lower.contains('teams.microsoft.com') ||
        lower.contains('teams.live.com')) {
      return l10n.msTeams;
    }
    if (lower.contains('webex.com')) return l10n.webex;
    return l10n.onlineMeeting;
  }

  IconData _getPlatformIcon(String meetLink) {
    final lower = meetLink.toLowerCase();
    if (lower.contains('meet.google.com')) {
      return Icons.video_camera_front_rounded;
    }
    if (lower.contains('zoom.us')) return Icons.videocam_rounded;
    if (lower.contains('teams.microsoft.com') ||
        lower.contains('teams.live.com')) {
      return Icons.groups_rounded;
    }
    return Icons.link_rounded;
  }

  // ── Error & Empty States ──────────────────────────────────────────────────

  Widget _buildErrorState(OnlineClassProvider provider, Color themeColor) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: provider.fetchOnlineClasses,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.unableToLoadClasses,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error ?? l10n.unableToLoadClassesMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: provider.fetchOnlineClasses,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      l10n.retry,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool canManageClass, Color themeColor) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: () => context.read<OnlineClassProvider>().fetchOnlineClasses(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.video_camera_front_outlined,
                      size: 52,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.noOnlineClassesScheduled,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canManageClass
                        ? l10n.noOnlineClassesAdminMessage
                        : l10n.noOnlineClassesStudentMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  if (canManageClass) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditOnlineClassScreen(
                              isAdminOrTeacher: canManageClass,
                            ),
                          ),
                        );
                        if (result == true) {
                          if (!mounted) return;
                          context
                              .read<OnlineClassProvider>()
                              .fetchOnlineClasses();
                        }
                      },
                      icon: Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: themeColor,
                      ),
                      label: Text(
                        l10n.scheduleClass,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: themeColor.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
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

            margin: const EdgeInsets.only(bottom: 14),

            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 150,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 90,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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

  // ── Card ──────────────────────────────────────────────────────────────────

  Widget _buildOnlineClassCard(
    BuildContext context,
    OnlineClass oClass,
    bool canManageClass,
    Color themeColor,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final exactStart = _getExactStartDateTime(oClass);
    final exactEnd = _getExactEndDateTime(oClass);

    // Meeting status computation
    final isUpcoming = exactStart.isAfter(now);
    final isLive = exactStart.isBefore(now) && exactEnd.isAfter(now);
    final isPast = exactEnd.isBefore(now);

    final relativeTime = _getTimeAgoOrUpcoming(context, exactStart);
    final platformLabel = _getPlatformLabel(context, oClass.meetLink);
    final platformIcon = _getPlatformIcon(oClass.meetLink);

    // Teacher Meeting = no class/section assigned
    final bool isTeacherMeeting =
        oClass.className == null && oClass.sectionName == null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLive
              ? Colors.red.shade300
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: isLive ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: Title + Status Badge + 3-dot Menu ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        oClass.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Badges: Subject, Platform, Meeting Type
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (oClass.subjectName != null &&
                              oClass.subjectName!.isNotEmpty)
                            _buildBadge(
                              icon: Icons.menu_book_outlined,
                              label: oClass.subjectName!,
                              bgColor: Colors.indigo.withValues(alpha: 0.08),
                              textColor: Colors.indigo.shade700,
                              iconColor: Colors.indigo.shade700,
                            ),
                          _buildBadge(
                            icon: platformIcon,
                            label: platformLabel,
                            bgColor: Colors.blue.withValues(alpha: 0.08),
                            textColor: Colors.blue.shade700,
                            iconColor: Colors.blue.shade700,
                          ),
                          _buildBadge(
                            icon: isTeacherMeeting
                                ? Icons.supervisor_account_rounded
                                : Icons.school_rounded,
                            label: isTeacherMeeting
                                ? 'Teacher Meeting'
                                : 'Class Meeting',
                            bgColor: isTeacherMeeting
                                ? Colors.orange.withValues(alpha: 0.10)
                                : Colors.teal.withValues(alpha: 0.09),
                            textColor: isTeacherMeeting
                                ? Colors.orange.shade800
                                : Colors.teal.shade700,
                            iconColor: isTeacherMeeting
                                ? Colors.orange.shade700
                                : Colors.teal.shade600,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status badge (Live Now / Upcoming / Ended)
                if (canManageClass)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 20),
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
                        if (result == true && context.mounted) {
                          context
                              .read<OnlineClassProvider>()
                              .fetchOnlineClasses();
                        }
                      } else if (value == 'delete') {
                        _deleteClass(oClass.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.editClass),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.deleteClassTitle,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Date & Time Range Box ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade900.withValues(alpha: 0.6)
                    : (isLive
                          ? Colors.red.shade50.withValues(alpha: 0.5)
                          : (isUpcoming
                                ? themeColor.withValues(alpha: 0.05)
                                : Colors.grey.shade100)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLive
                      ? Colors.red.shade200
                      : (isUpcoming
                            ? themeColor.withValues(alpha: 0.15)
                            : (isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: isLive
                        ? Colors.red
                        : (isUpcoming ? themeColor : Colors.grey.shade600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy').format(oClass.scheduledTime),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.grey.shade200
                          : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.access_time_filled_rounded,
                    size: 14,
                    color: isLive
                        ? Colors.red
                        : (isUpcoming ? themeColor : Colors.grey.shade600),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      oClass.startTime != null
                          ? (oClass.endTime != null
                                ? '${oClass.startTime} – ${oClass.endTime}'
                                : oClass.startTime!)
                          : DateFormat('hh:mm a').format(oClass.scheduledTime),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isLive
                          ? Colors.red
                          : (isUpcoming
                                ? themeColor.withValues(alpha: 0.12)
                                : (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isLive ? l10n.statusLive : relativeTime,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLive
                            ? Colors.white
                            : (isUpcoming
                                  ? themeColor
                                  : (isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Class / Section / Subject Info Row ──
            if (oClass.className != null ||
                oClass.sectionName != null ||
                oClass.subjectName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    if (oClass.className != null) ...[
                      Icon(
                        Icons.class_outlined,
                        size: 13,
                        color: Colors.purple.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        oClass.className!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if (oClass.sectionName != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '·',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.group_outlined,
                        size: 13,
                        color: Colors.teal.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        oClass.sectionName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if (oClass.subjectName != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '·',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.menu_book_outlined,
                        size: 13,
                        color: Colors.indigo.shade400,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          oClass.subjectName!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // ── Description ──
            if (oClass.description.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900.withValues(alpha: 0.4)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  oClass.description,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Host Info ──
            _buildHostRow(oClass, isDark, themeColor),
            const SizedBox(height: 8),

            // ── Participants ──
            if (oClass.participants.isNotEmpty) ...[
              _buildParticipantsRow(oClass.participants, isDark),
              const SizedBox(height: 10),
            ],

            // ── Divider ──
            Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            const SizedBox(height: 10),

            // ── Action Button: Join Meeting ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isPast ? null : () {
                  final user = context.read<AuthNotifier>().user;
                  if (user != null && 
                      (user.id == oClass.teacherId || user.role == UserRole.teacher || user.role == UserRole.admin || user.role == UserRole.superadmin) && 
                      oClass.participants.isNotEmpty) {
                    NotificationService().sendBulkNotification(
                      receiverUuids: oClass.participants.map((p) => p.uuid).toList(),
                      title: 'Class is Starting',
                      message: 'The host has joined ${oClass.title}. Please join the meeting now.',
                    );
                  }
                  _launchURL(oClass.meetLink);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLive
                      ? const Color(0xFFEF4444)
                      : themeColor,
                  disabledBackgroundColor: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  disabledForegroundColor: isDark
                      ? Colors.grey.shade500
                      : Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  isPast
                      ? Icons.videocam_off_outlined
                      : (isLive
                            ? Icons.videocam_rounded
                            : Icons.video_call_rounded),
                  color: isPast
                      ? (isDark ? Colors.grey.shade500 : Colors.grey.shade500)
                      : Colors.white,
                  size: 18,
                ),
                label: Text(
                  isPast
                      ? l10n.classEnded
                      : (isLive ? l10n.joinLiveClass : l10n.joinMeeting),
                  style: TextStyle(
                    color: isPast
                        ? (isDark ? Colors.grey.shade500 : Colors.grey.shade500)
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Host Row ──────────────────────────────────────────────────────────────

  Widget _buildHostRow(OnlineClass oClass, bool isDark, Color themeColor) {
    final avatarUrl = oClass.teacherAvatar;
    final initial = oClass.teacherName.isNotEmpty
        ? oClass.teacherName[0].toUpperCase()
        : 'H';

    return Row(
      children: [
        // Avatar
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: themeColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: isDark
                          ? themeColor.withValues(alpha: 0.25)
                          : themeColor.withValues(alpha: 0.12),
                      child: Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: isDark
                        ? themeColor.withValues(alpha: 0.25)
                        : themeColor.withValues(alpha: 0.12),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.person_rounded,
          size: 12,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            'Host: ${oClass.teacherName}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Participants Row ───────────────────────────────────────────────────────

  Widget _buildParticipantsRow(
    List<OnlineClassParticipant> participants,
    bool isDark,
  ) {
    const int maxVisible = 4;
    final visibleList = participants.take(maxVisible).toList();
    final extraCount = participants.length - maxVisible;
    final stackCount = visibleList.length + (extraCount > 0 ? 1 : 0);
    final stackWidth = stackCount * 20.0 + 6.0;

    return Row(
      children: [
        Icon(
          Icons.people_outline_rounded,
          size: 14,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 26,
          width: stackWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < visibleList.length; i++)
                Positioned(
                  left: i * 20.0,
                  child: _buildAvatarCircle(visibleList[i], isDark),
                ),
              if (extraCount > 0)
                Positioned(
                  left: visibleList.length * 20.0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      border: Border.all(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '+$extraCount',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _participantsLabel(participants),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarCircle(OnlineClassParticipant p, bool isDark) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: p.avatar != null && p.avatar!.isNotEmpty
            ? Image.network(
                p.avatar!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatar(p.name, isDark),
              )
            : _defaultAvatar(p.name, isDark),
      ),
    );
  }

  Widget _defaultAvatar(String name, bool isDark) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: isDark ? Colors.indigo.shade900 : Colors.indigo.shade100,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.indigo.shade200 : Colors.indigo.shade700,
          ),
        ),
      ),
    );
  }

  String _participantsLabel(List<OnlineClassParticipant> participants) {
    if (participants.isEmpty) return '';
    final named = participants
        .where((p) => p.name.isNotEmpty && p.name != 'Unknown')
        .toList();
    if (named.isEmpty) return '${participants.length} participant(s)';
    if (named.length == 1) return named[0].name;
    if (named.length == 2) return '${named[0].name} & ${named[1].name}';
    return '${named[0].name}, ${named[1].name} & ${named.length - 2} more';
  }

  // ── Badge Helper ──────────────────────────────────────────────────────────

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: iconColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
