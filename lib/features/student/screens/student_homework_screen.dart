import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/configs/custom_size.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/l10n/app_localizations.dart';

import '../../../models/school_models.dart';
import '../../admin/providers/setup_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/student_homework_provider.dart';

class StudentHomeworkScreen extends StatefulWidget {
  final bool hideAppBar;
  const StudentHomeworkScreen({super.key, this.hideAppBar = false});

  @override
  State<StudentHomeworkScreen> createState() => _StudentHomeworkScreenState();
}

class _StudentHomeworkScreenState extends State<StudentHomeworkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      if (user?.classIds != null) {
        context.read<StudentHomeworkNotifier>().fetchHomework(
          user!.classIds.first,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.watch<AuthNotifier>().user;
    if (currentUser == null) {
      return Scaffold(body: Center(child: Text(l10n.notLoggedIn)));
    }

    if (currentUser.classIds.isEmpty) {
      return Scaffold(body: Center(child: Text(l10n.classInfoNotAvailable)));
    }

    final homeworkNotifier = context.watch<StudentHomeworkNotifier>();
    final homeworkList = homeworkNotifier.homeworkList;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: Text(
                l10n.homework,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primaryStudent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
      body: homeworkNotifier.isLoading && homeworkList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (currentUser.classIds.isNotEmpty) {
                  await context.read<StudentHomeworkNotifier>().fetchHomework(
                    currentUser.classIds.first,
                  );
                }
              },
              child: homeworkList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: homeworkList.length,
                      itemBuilder: (context, index) {
                        final studentHw = homeworkList[index];
                        final hw = studentHw.homework;

                        if (hw == null) return const SizedBox();

                        final subName = subjects
                            .firstWhere(
                              (s) => s.id == hw.subjectId,
                              orElse: () => Subject(id: '', name: 'Subject'),
                            )
                            .name;

                        return _HomeworkCard(
                          studentHomework: studentHw,
                          subjectName: subName,
                          onTap: () =>
                              _showDetailSheet(context, studentHw, subName),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_turned_in_outlined,
              size: 64,
              color: Colors.green.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'All caught up!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(l10n.noHomeworkAssigned),
        ],
      ),
    );
  }

  void _showDetailSheet(
    BuildContext context,
    StudentHomework sh,
    String subName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HomeworkDetailSheet(sh: sh, subName: subName),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final StudentHomework studentHomework;
  final String subjectName;
  final VoidCallback onTap;

  const _HomeworkCard({
    required this.studentHomework,
    required this.subjectName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hw = studentHomework.homework!;
    final isDone = studentHomework.status == 'done';
    final isSubmitted = studentHomework.status == 'submitted';
    final dueDate = hw.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now()) && !isDone;

    Color statusColor;
    String statusText;

    if (isDone) {
      statusColor = const Color(0xFF10B981); // Emerald
      statusText = 'Completed';
    } else if (isSubmitted) {
      statusColor = const Color(0xFF3B82F6); // blue
      statusText = 'Submitted';
    } else if (isOverdue) {
      statusColor = const Color(0xFFEF4444); // red
      statusText = 'Overdue';
    } else {
      statusColor = const Color(0xFFF59E0B); // Amber/Orange
      statusText = 'Pending';
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),

        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          subjectName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _StatusChip(color: statusColor, text: statusText),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hw.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hw.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Text(
                    'Due: ${DateFormat('MMM d, yyyy').format(dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOverdue ? Colors.red[400] : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppLocalizations.of(context)!.viewDetailsOption,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.primaryStudent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String text;

  const _StatusChip({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeworkDetailSheet extends StatelessWidget {
  final StudentHomework sh;
  final String subName;

  const _HomeworkDetailSheet({required this.sh, required this.subName});

  @override
  Widget build(BuildContext context) {
    final hw = sh.homework!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final cardColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF3F4F6);

    final primaryText = isDark ? Colors.white : const Color(0xFF111827);

    final secondaryText = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      width: screenSize(context, 2),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subName,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy').format(hw.dueDate),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              hw.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: primaryText,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              hw.description,
              style: TextStyle(fontSize: 15, height: 1.6, color: secondaryText),
            ),

            if (sh.comment != null && sh.comment!.isNotEmpty) ...[
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.comment_outlined,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Teacher\'s Comment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      sh.comment!,
                      style: TextStyle(
                        color: secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
