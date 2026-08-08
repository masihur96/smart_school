import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/student_model.dart';
import 'package:smart_school/services/sms_service.dart';

class BulkSmsScreen extends StatefulWidget {
  const BulkSmsScreen({super.key});

  @override
  State<BulkSmsScreen> createState() => _BulkSmsScreenState();
}

class _BulkSmsScreenState extends State<BulkSmsScreen> {
  final Set<String> _selectedStudentIds = {};
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final SmsService _smsService = SmsService();
  bool _isSending = false;

  String? _selectedClassId;
  String? _selectedSectionId;
  String _searchQuery = '';
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      final schoolId = user?.schoolId ?? '';
      if (schoolId.isNotEmpty) {
        context.read<ClassSetupNotifier>().fetchClasses(schoolId);
      }
      context.read<SectionSetupNotifier>().fetchSections();
      context.read<StudentsNotifier>().fetchStudents();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final notifier = context.read<StudentsNotifier>();
      if (!notifier.isLoadingMore && notifier.hasMore) {
        notifier.fetchStudents(
          classId: _selectedClassId,
          sectionId: _selectedSectionId,
          search: _searchQuery.isEmpty ? null : _searchQuery,
          loadMore: true,
        );
      }
    }
  }

  void _applyFilters() {
    context.read<StudentsNotifier>().fetchStudents(
      classId: _selectedClassId,
      sectionId: _selectedSectionId,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
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
      if (_selectedStudentIds.contains(student.userId)) {
        _selectedStudentIds.remove(student.userId);
      } else {
        _selectedStudentIds.add(student.userId);
      }
    });
  }

  Future<void> _sendBulkSms() async {
    if (_selectedStudentIds.isEmpty) {
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

    final studentsNotifier = context.read<StudentsNotifier>();
    final List<String> numbers = [];
    // Collect unique phone numbers for the selected student IDs
    for (var student in studentsNotifier.students) {
      if (_selectedStudentIds.contains(student.userId) && student.guardianContact.isNotEmpty) {
        if (!numbers.contains(student.guardianContact)) {
          numbers.add(student.guardianContact);
        }
      }
    }

    final success = await _smsService.sendBulkSms(
      numbers,
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
        _selectedStudentIds.clear();
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
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        title: const Text('Bulk SMS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () {
              final notifier = context.read<StudentsNotifier>();
              setState(() {
                for (var s in notifier.students) {
                  if (s.guardianContact.isNotEmpty) {
                    _selectedStudentIds.add(s.userId);
                  }
                }
              });
            },
            tooltip: 'Select All on Page',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _selectedStudentIds.clear();
              });
            },
            tooltip: 'Clear Selection',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by name',
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
                      borderRadius: BorderRadius.circular(8),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Classes'),
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
                            _selectedSectionId = null;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Sections'),
                          ),
                          ...sections
                            .where((s) => _selectedClassId == null || s.classId == _selectedClassId)
                            .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          ),
                        ],
                        value: _selectedSectionId,
                        onChanged: (val) {
                          setState(() {
                            _selectedSectionId = val;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                  controller: _scrollController,
                  itemCount: notifier.students.length + (notifier.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == notifier.students.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final student = notifier.students[index];
                    final hasContact = student.guardianContact.isNotEmpty;
                    final isSelected = _selectedStudentIds.contains(student.userId);

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
                          student.user?.name?.substring(0, 1).toUpperCase() ?? '?',
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
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Selected: ${_selectedStudentIds.length} students',
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
