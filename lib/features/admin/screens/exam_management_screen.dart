import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_school/models/teacher_model.dart';
import '../../../models/school_models.dart';
import '../providers/exam_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/teacher_provider.dart';
import 'add_edit_exam_screen.dart';

class ExamManagementScreen extends StatefulWidget {
  final bool hideAppBar;
  const ExamManagementScreen({super.key, this.hideAppBar = false});

  @override
  State<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends State<ExamManagementScreen> {
  String? _selectedClass;
  String? _selectedSubject;
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final examsNotifier = context.watch<ExamsNotifier>();
    final allExams = examsNotifier.state;
    final classes = context.watch<ClassSetupNotifier>().classes;
    final subjects = context.watch<SubjectSetupNotifier>().subjects;

    // Apply filters
    final exams = allExams.where((exam) {
      final matchesClass = _selectedClass == null || exam.classId == _selectedClass;
      final matchesSubject = _selectedSubject == null || exam.subjectId == _selectedSubject;
      final matchesStatus = _selectedStatus == 'All' ||
          (_selectedStatus == 'Published' && exam.isPublished) ||
          (_selectedStatus == 'Unpublished' && !exam.isPublished);
      return matchesClass && matchesSubject && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text('Exam Management'),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Class',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        value: _selectedClass,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Classes')),
                          ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedClass = val;
                            _selectedSubject = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        value: _selectedSubject,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Subjects')),
                          ...subjects
                              .where((s) => _selectedClass == null || s.classId == _selectedClass)
                              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                        ],
                        onChanged: (val) => setState(() => _selectedSubject = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Publish Status',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  value: _selectedStatus,
                  items: ['All', 'Published', 'Unpublished']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedStatus = val!),
                ),
              ],
            ),
          ),

          // Exam List
          Expanded(
            child: examsNotifier.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                : exams.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No exams found',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: exams.length,
                        itemBuilder: (context, index) {
                          final exam = exams[index];
                          final className = classes
                              .firstWhere((c) => c.id == exam.classId,
                                  orElse: () => ClassRoom(id: '', name: 'N/A'))
                              .name;
                          final subject = subjects.firstWhere((s) => s.id == exam.subjectId,
                              orElse: () => Subject(id: '', name: 'N/A'));

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.purple.shade300, Colors.purple.shade600],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.assignment, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exam.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$className | ${subject.name}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_outlined,
                                                size: 14, color: Colors.grey.shade400),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(exam.dateTime),
                                              style: TextStyle(
                                                  color: Colors.grey.shade500, fontSize: 12),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: exam.isPublished
                                                    ? Colors.green.shade50
                                                    : Colors.orange.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                exam.isPublished ? 'Published' : 'Draft',
                                                style: TextStyle(
                                                  color: exam.isPublished
                                                      ? Colors.green
                                                      : Colors.orange,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) async {
                                      if (value == 'view') {
                                        _showExamDetails(context, exam);
                                      } else if (value == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddEditExamScreen(exam: exam),
                                          ),
                                        );
                                      } else if (value == 'publish') {
                                        _confirmPublish(context, exam);
                                      } else if (value == 'delete') {
                                        _confirmDelete(context, exam);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility_outlined, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('View Details'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, color: Colors.orange),
                                            SizedBox(width: 8),
                                            Text('Edit Exam'),
                                          ],
                                        ),
                                      ),
                                      if (!exam.isPublished)
                                        const PopupMenuItem(
                                          value: 'publish',
                                          child: Row(
                                            children: [
                                              Icon(Icons.publish, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Publish Result'),
                                            ],
                                          ),
                                        ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete Exam'),
                                          ],
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditExamScreen()),
          );
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showExamDetails(BuildContext context, Exam exam) {
    final classes = context.read<ClassSetupNotifier>().classes;
    final subjects = context.read<SubjectSetupNotifier>().subjects;
    final teachers = context.read<TeachersNotifier>().teachers;

    final className = classes.firstWhere((c) => c.id == exam.classId, orElse: () => ClassRoom(id: '', name: 'N/A')).name;
    final subjectName = subjects.firstWhere((s) => s.id == exam.subjectId, orElse: () => Subject(id: '', name: 'N/A')).name;
    final examinerName = teachers.firstWhere((t) => t.userId == exam.teacherId, orElse: () => Teacher(userId: '', designation: 'N/A')).user?.name ?? 'N/A';

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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                    child: const Icon(Icons.assignment, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exam.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(exam.isPublished ? 'Published' : 'Drafting',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Academic Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildDetailItem(Icons.class_outlined, 'Class', className),
              _buildDetailItem(Icons.book_outlined, 'Subject', subjectName),
              _buildDetailItem(Icons.person_outline, 'Examiner', examinerName),
              const SizedBox(height: 20),
              const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildDetailItem(Icons.calendar_today_outlined, 'Date',
                  DateFormat('EEEE, MMM dd, yyyy').format(exam.dateTime)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple.shade300),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmPublish(BuildContext context, Exam exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Result'),
        content: Text('Are you sure you want to publish the results for ${exam.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<ExamsNotifier>().publishResult(exam.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Results published successfully!'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Exam exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete ${exam.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await context.read<ExamsNotifier>().deleteExam(exam.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exam deleted successfully!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
