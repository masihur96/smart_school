import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/features/admin/screens/add_edit_student_screen.dart';
import 'package:smart_school/features/admin/screens/generate_id_card_screen.dart';
import 'package:smart_school/features/admin/screens/generate_tc_screen.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StudentDetailScreen extends StatelessWidget {
  final Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;

    final className = student.embeddedClasses.isNotEmpty
        ? student.embeddedClasses.map((c) => c.name).join(', ')
        : classes.firstWhere(
              (c) => c.id == student.classId,
              orElse: () => ClassRoom(id: '', name: 'Unknown'),
            ).name;
    final sectionName = student.embeddedSections.isNotEmpty
        ? student.embeddedSections.map((s) => s.name).join(', ')
        : sections.firstWhere(
              (s) => s.id == student.sectionId,
              orElse: () => Section(id: '', name: 'Unknown', classId: ''),
            ).name;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            title: Text(student.user?.name ?? 'Student Details'),
            floating: false,
            pinned: true,
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              // title: Column(
              //
              //   children: [
              //     Text(
              //       student.user?.name ?? 'Student Details',
              //       style: const TextStyle(
              //         color: Colors.white,
              //         fontWeight: FontWeight.bold,
              //         shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
              //       ),
              //     ),
              //   ],
              // ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.purple.shade700, Colors.purple.shade400],
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Spacer(),
                      SizedBox(height: 30),
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.purple,
                        backgroundImage: (student.user?.avatar?.startsWith('http://') == true ||
                                student.user?.avatar?.startsWith('https://') == true)
                            ? CachedNetworkImageProvider(student.user!.avatar!)
                            : null,
                        onBackgroundImageError: (student.user?.avatar?.startsWith('http://') == true ||
                                student.user?.avatar?.startsWith('https://') == true)
                            ? (_, __) {}
                            : null,
                        child: (student.user?.avatar?.startsWith('http://') == true ||
                                student.user?.avatar?.startsWith('https://') == true)
                            ? null
                            : Text(
                          student.user?.name.isNotEmpty == true
                              ? student.user!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                    ],
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
                    _buildInfoRow(
                      Icons.grid_view,
                      'About',
                      student.user?.designation ?? "N/A",
                    ),
                    _buildStatusRow(student.isActive),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Contact Information'),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.email,
                      'Email',
                      student.user?.email ?? 'N/A',
                      actionIcon: Icons.send,
                      onTap: student.user?.email != null
                          ? () => _launchUrl('mailto:${student.user!.email}')
                          : null,
                    ),
                    _buildInfoRow(
                      Icons.phone,
                      'Phone',
                      student.user?.phone ?? 'N/A',
                      actionIcon: Icons.call,
                      onTap: student.user?.phone != null
                          ? () => _launchUrl('tel:${student.user!.phone}')
                          : null,
                    ),
                    _buildInfoRow(
                      Icons.contact_phone,
                      'Guardian Contact',
                      student.guardianContact,
                      actionIcon: Icons.call,
                      onTap: student.guardianContact.isNotEmpty
                          ? () => _launchUrl('tel:${student.guardianContact}')
                          : null,
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
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GenerateIdCardScreen(
                              students: [student],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.badge, color: Colors.white),
                      label: const Text(
                        'Generate ID Card',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
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
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GenerateTcScreen(
                              student: student,
                              className: className,
                              sectionName: sectionName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.document_scanner, color: Colors.white),
                      label: const Text(
                        'Generate Transfer Certificate (TC)',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    IconData? actionIcon,
    VoidCallback? onTap,
  }) {
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
          if (actionIcon != null && onTap != null)
            Material(
              color: Colors.purple.shade50,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    actionIcon,
                    size: 18,
                    color: Colors.purple.shade600,
                  ),
                ),
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
