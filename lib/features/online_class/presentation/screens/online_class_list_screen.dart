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

          if (provider.onlineClasses.isEmpty) {
            return _buildEmptyState(canManageClass, themeColor);
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
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _getTimeAgoOrUpcoming(BuildContext context, DateTime scheduledTime) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.isNegative) {
      final pastDiff = now.difference(scheduledTime);
      if (pastDiff.inMinutes < 60) {
        return l10n.minutesAgo(pastDiff.inMinutes);
      } else if (pastDiff.inHours < 24) {
        return l10n.hoursAgo(pastDiff.inHours);
      } else if (pastDiff.inDays == 1) {
        return l10n.yesterday;
      } else if (pastDiff.inDays < 7) {
        return l10n.daysAgo(pastDiff.inDays);
      } else {
        return DateFormat('MMM dd').format(scheduledTime);
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
        return DateFormat('MMM dd').format(scheduledTime);
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
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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

    // Meeting status computation
    // Upcoming: Scheduled in the future
    final isUpcoming = oClass.scheduledTime.isAfter(now);
    // Live: Started within the last 60 minutes
    final isLive =
        !isUpcoming &&
        now.isBefore(oClass.scheduledTime.add(const Duration(minutes: 60)));
    // Past: Started more than 60 minutes ago
    final isPast = !isUpcoming && !isLive;

    final classSectionLabel = _getClassSectionLabel(context, oClass);
    final relativeTime = _getTimeAgoOrUpcoming(context, oClass.scheduledTime);
    final platformLabel = _getPlatformLabel(context, oClass.meetLink);
    final platformIcon = _getPlatformIcon(oClass.meetLink);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: Title, Status Badge, 3-dot Menu ──
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
                      // Badges: Subject & Platform
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (oClass.subjectName != null &&
                              oClass.subjectName!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
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
                                    size: 11,
                                    color: Colors.indigo.shade700,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    oClass.subjectName!,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  platformIcon,
                                  size: 11,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  platformLabel,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
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
                const SizedBox(width: 8),
                // Status badge (Live / Upcoming / Ended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.red.shade50
                        : (isUpcoming
                              ? Colors.green.shade50
                              : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLive
                          ? Colors.red.shade300
                          : (isUpcoming
                                ? Colors.green.shade300
                                : (isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300)),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLive
                              ? Colors.red
                              : (isUpcoming ? Colors.green : Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isLive
                            ? l10n.statusLiveNow
                            : (isUpcoming
                                  ? l10n.statusUpcoming
                                  : l10n.statusEnded),
                        style: TextStyle(
                          color: isLive
                              ? Colors.red.shade700
                              : (isUpcoming
                                    ? Colors.green.shade700
                                    : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600)),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
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

            // ── Professional Time Box ──
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
                  Text(
                    DateFormat('hh:mm a').format(oClass.scheduledTime),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.grey.shade200
                          : Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
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

            // ── Details Row: Teacher & Target Class ──
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: Colors.teal.shade600,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          oClass.teacherName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 14,
                        color: AppColors.primaryAdmin,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          classSectionLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
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

            if (oClass.description.isNotEmpty) ...[
              const SizedBox(height: 8),
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
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Action Button: Join Meeting (Disabled if already passed) ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isPast ? null : () => _launchURL(oClass.meetLink),
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
}
