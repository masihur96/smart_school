import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/features/admin/screens/add_edit_student_screen.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';

class StudentDetailScreen extends StatelessWidget {
  final Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;

    final className = classes
        .firstWhere(
          (c) => c.id == student.classId,
          orElse: () => ClassRoom(id: '', name: 'Unknown'),
        )
        .name;
    final sectionName = sections
        .firstWhere(
          (s) => s.id == student.sectionId,
          orElse: () => Section(id: '', name: 'Unknown', classId: ''),
        )
        .name;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.purple,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                children: [
                  Text(
                    student.user?.name ?? 'Student Details',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
              centerTitle: T,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.purple.shade700, Colors.purple.shade400],
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'student-avatar-${student.userId}',
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          student.user?.name[0] ?? '?',
                          style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditStudentScreen(student: student),
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Academic Information'),
                  _buildInfoCard([
                    _buildInfoRow(Icons.numbers, 'Roll Number', student.rollId),
                    _buildInfoRow(Icons.class_, 'Class', className),
                    _buildInfoRow(Icons.grid_view, 'Section', sectionName),
                    _buildStatusRow(student.isActive),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Contact Information'),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.email,
                      'Email',
                      student.user?.email ?? 'N/A',
                    ),
                    _buildInfoRow(
                      Icons.phone,
                      'Phone',
                      student.user?.phone ?? 'N/A',
                    ),
                    _buildInfoRow(
                      Icons.contact_phone,
                      'Guardian Contact',
                      student.guardianContact,
                    ),
                  ]),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<StudentsNotifier>().toggleStudentStatus(
                          student.userId,
                        );
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        student.isActive ? Icons.block : Icons.check_circle,
                        color: Colors.white,
                      ),
                      label: Text(
                        student.isActive
                            ? 'Deactivate Student'
                            : 'Activate Student',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: student.isActive
                            ? Colors.orange
                            : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteDialog(context),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete Student',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children
              .expand(
                (widget) => [
                  widget,
                  if (widget != children.last) const Divider(),
                ],
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.error,
            color: isActive ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<StudentsNotifier>().deleteStudent(student.userId);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close details screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
