import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_homework_provider.dart';
import '../../admin/providers/setup_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/school_models.dart';
import 'package:intl/intl.dart';

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
      if (user?.classId != null) {
        context.read<StudentHomeworkNotifier>().fetchHomework(user!.classId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthNotifier>().user;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    if (currentUser.classId == null) {
      return const Scaffold(
        body: Center(child: Text('Class info not available')),
      );
    }

    final homeworkNotifier = context.watch<StudentHomeworkNotifier>();
    final homeworkList = homeworkNotifier.homeworkList;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text('My Homework'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
      body: homeworkNotifier.isLoading && homeworkList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (currentUser.classId != null) {
                  await context
                      .read<StudentHomeworkNotifier>()
                      .fetchHomework(currentUser.classId!);
                }
              },
              child: homeworkList.isEmpty
                  ? const Center(child: Text('No homework assigned.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: homeworkList.length,
                      itemBuilder: (context, index) {
                        final hw = homeworkList[index];
                        final subName = subjects
                            .firstWhere(
                              (s) => s.id == hw.subjectId,
                              orElse: () => Subject(id: '', name: 'Unknown'),
                            )
                            .name;
                        final isOverdue = hw.dueDate.isBefore(DateTime.now());

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
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
                                    Text(
                                      DateFormat('MMM d').format(hw.dueDate),
                                      style: TextStyle(
                                        color:
                                            isOverdue ? Colors.red : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  hw.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hw.description,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isOverdue ? 'Overdue' : 'Pending',
                                      style: TextStyle(
                                        color: isOverdue
                                            ? Colors.red
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
