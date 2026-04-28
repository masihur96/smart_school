import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/teacher/providers/homework_provider.dart';
import 'package:smart_school/models/school_models.dart';

class HomeworkDetailsScreen extends StatefulWidget {
  final String homeworkId;
  const HomeworkDetailsScreen({super.key, required this.homeworkId});

  @override
  State<HomeworkDetailsScreen> createState() => _HomeworkDetailsScreenState();
}

class _HomeworkDetailsScreenState extends State<HomeworkDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeworkNotifier>().getHomeworkDetails(widget.homeworkId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Details'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              final homework = context
                  .read<HomeworkNotifier>()
                  .selectedHomework;
              if (homework != null) {
                _showUpdateStatusDialog(homeworkId: homework.id);
              }
            },
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Bulk Update Status',
          ),
        ],
      ),
      body: Consumer<HomeworkNotifier>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.selectedHomework == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final homework = provider.selectedHomework;
          if (homework == null) {
            return const Center(child: Text('Homework not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailsCard(homework),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Students (${homework.studentHomeworks.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _showUpdateStatusDialog(homeworkId: homework.id),
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('Bulk Update'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (homework.studentHomeworks.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No students assigned to this homework'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: homework.studentHomeworks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final studentHomework = homework.studentHomeworks[index];
                      return _buildStudentItem(homework.id, studentHomework);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsCard(Homework homework) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    homework.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                _buildDueDateChip(homework.dueDate),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow(
              Icons.description_outlined,
              'Description',
              homework.description,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Assigned On',
              DateFormat('MMM dd, yyyy').format(homework.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateChip(DateTime dueDate) {
    final isOverdue = dueDate.isBefore(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: isOverdue ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(
            'Due: ${DateFormat('MMM dd').format(dueDate)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isOverdue ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentItem(String homeworkId, StudentHomework studentHomework) {
    final student = studentHomework.student;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                  child: Text(
                    student?.name.substring(0, 1).toUpperCase() ?? 'S',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student?.name ?? 'Unknown Student',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (student?.rollNumber != null)
                        Text(
                          'Roll: ${student!.rollNumber}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(studentHomework.status),
              ],
            ),
            if (studentHomework.comment != null &&
                studentHomework.comment!.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      studentHomework.comment!,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  print(studentHomework.studentId);
                  print(studentHomework.id);

                  _showUpdateStatusDialog(
                    homeworkId: studentHomework.studentId,
                    studentId: studentHomework.id,
                    currentStatus: studentHomework.status,
                    currentComment: studentHomework.comment,
                  );
                },
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Update Status & Comment'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'done':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showUpdateStatusDialog({
    required String homeworkId,
    String? studentId,
    String currentStatus = 'pending',
    String? currentComment,
  }) {
    String selectedStatus = currentStatus;
    final commentController = TextEditingController(text: currentComment);
    final isBulk = studentId == null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isBulk ? 'Bulk Update Status' : 'Update Student Status',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBulk)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'This will update the status for ALL students in this homework.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    value:
                        [
                          'pending',
                          'done',
                        ].contains(selectedStatus.toLowerCase())
                        ? selectedStatus.toLowerCase()
                        : 'pending',
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(value: 'done', child: Text('Done')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      border: OutlineInputBorder(),
                      hintText: 'Add feedback...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    final success = isBulk
                        ? await context
                              .read<HomeworkNotifier>()
                              .bulkUpdateStudentHomeworkStatus(
                                homeworkId: homeworkId,
                                status: selectedStatus,
                                comment: commentController.text,
                              )
                        : await context
                              .read<HomeworkNotifier>()
                              .updateStudentHomeworkStatus(
                                homeworkId: homeworkId,
                                studentId: studentId!,
                                status: selectedStatus,
                                comment: commentController.text,
                              );

                    if (success) {
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isBulk
                                ? 'Bulk status updated successfully'
                                : 'Student status updated successfully',
                          ),
                        ),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update status'),
                        ),
                      );
                    }
                  },
                  child: Text(isBulk ? 'Bulk Update' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
