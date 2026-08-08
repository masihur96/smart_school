import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/models/student_model.dart';
import 'package:smart_school/services/sms_service.dart';

class BulkSmsScreen extends StatefulWidget {
  const BulkSmsScreen({super.key});

  @override
  State<BulkSmsScreen> createState() => _BulkSmsScreenState();
}

class _BulkSmsScreenState extends State<BulkSmsScreen> {
  final Set<String> _selectedStudentNumbers = {};
  final TextEditingController _messageController = TextEditingController();
  final SmsService _smsService = SmsService();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentsNotifier>().fetchStudents();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _toggleSelection(Student student) {
    if (student.guardianContact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${student.user?.name ?? 'Student'} does not have a contact number.',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (_selectedStudentNumbers.contains(student.guardianContact)) {
        _selectedStudentNumbers.remove(student.guardianContact);
      } else {
        _selectedStudentNumbers.add(student.guardianContact);
      }
    });
  }

  Future<void> _sendBulkSms() async {
    if (_selectedStudentNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one student.')),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message.')));
      return;
    }

    setState(() {
      _isSending = true;
    });

    final success = await _smsService.sendBulkSms(
      _selectedStudentNumbers.toList(),
      _messageController.text.trim(),
    );

    setState(() {
      _isSending = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bulk SMS sent successfully!')),
      );
      _messageController.clear();
      setState(() {
        _selectedStudentNumbers.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to send SMS. Please check your credentials and try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryAdmin,
        title: const Text('Bulk SMS (Selected Students)'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<StudentsNotifier>(
              builder: (context, notifier, child) {
                if (notifier.isLoading && notifier.students.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (notifier.students.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }

                return ListView.builder(
                  itemCount: notifier.students.length,
                  itemBuilder: (context, index) {
                    final student = notifier.students[index];
                    final hasContact = student.guardianContact.isNotEmpty;
                    final isSelected = _selectedStudentNumbers.contains(
                      student.guardianContact,
                    );

                    return CheckboxListTile(
                      title: Text(student.user?.name ?? 'Unknown Student'),
                      subtitle: Text(
                        hasContact
                            ? 'Contact: ${student.guardianContact}'
                            : 'No contact number',
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleSelection(student);
                      },
                      secondary: CircleAvatar(
                        child: Text(
                          student.user?.name?.substring(0, 1).toUpperCase() ??
                              '?',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Selected: ${_selectedStudentNumbers.length} students',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter your SMS message here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSending ? null : _sendBulkSms,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send SMS'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
