import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/utils/storage_service.dart';

import '../../../configs/network/data_provider.dart';
import '../../../models/school_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/teacher_provider.dart';
import 'class_students_screen.dart';
import 'section_students_screen.dart';

// ─── Colour palette (shared) ─────────────────────────────────────────────────
const _kPrimary = Color(0xFF6C3CE1);
const _kPrimaryLight = Color(0xFF9B6DFF);
const _kBg = Color(0xFFF4F2FB);
const _kCardBg = Colors.white;
const _kTextDark = Color(0xFF1A1035);
const _kTextMid = Color(0xFF6B7280);
const _kDivider = Color(0xFFEDE9F8);

// ─── Per-tab accent colours ───────────────────────────────────────────────────
const _kClassGrad = [Color(0xFF6C3CE1), Color(0xFF9B6DFF)];
const _kSectionGrad = [Color(0xFF0EA5E9), Color(0xFF38BDF8)];
const _kSubjectGrad = [Color(0xFF10B981), Color(0xFF34D399)];

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      if (user != null) {
        final schoolId = user.schoolId ?? '';
        if (context.read<ClassSetupNotifier>().classes.isEmpty) {
          context.read<ClassSetupNotifier>().fetchClasses(schoolId);
        }
        if (context.read<SectionSetupNotifier>().sections.isEmpty) {
          context.read<SectionSetupNotifier>().fetchSections();
        }
        if (context.read<SubjectSetupNotifier>().subjects.isEmpty) {
          context.read<SubjectSetupNotifier>().fetchSubjects(schoolId);
        }
        if (context.read<TeachersNotifier>().teachers.isEmpty) {
          context.read<TeachersNotifier>().fetchTeachers();
        }
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tab,
        children: const [_ClassTab(), _SectionTab(), _SubjectTab()],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final user = context.read<AuthNotifier>().user;
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        decoration: BoxDecoration(
          color: user?.role.name.toLowerCase() == "admin"
              ? AppColors.primaryAdmin
              : AppColors.primary,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x446C3CE1),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Class & Subject Setup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tab,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Classes'),
                  Tab(text: 'Sections'),
                  Tab(text: 'Subjects'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Classes Tab
// ═══════════════════════════════════════════════════════════
class _ClassTab extends StatelessWidget {
  const _ClassTab();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClassSetupNotifier>();
    final classes = notifier.classes;
    final user = context.read<AuthNotifier>().user;
    return Scaffold(
      body: notifier.isLoading
          ? const _LoadingView()
          : classes.isEmpty
          ? const _EmptyView(label: 'No classes yet')
          : ListView.builder(
              // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: classes.length,
              itemBuilder: (ctx, i) {
                if (user?.schoolId == classes[i].schoolId) {
                  return _ClassCard(classRoom: classes[i]);
                } else {
                  return SizedBox();
                }
              },
            ),
      floatingActionButton: _AddFab(
        gradientColors: _kClassGrad,
        onTap: () {
          final user = context.read<AuthNotifier>().user;
          _showAddEditClassDialog(context, schoolId: user?.schoolId ?? '');
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassRoom classRoom;
  const _ClassCard({required this.classRoom});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // ── Header strip ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              // gradient: LinearGradient(
              //   colors: _kClassGrad,
              //   begin: Alignment.centerLeft,
              //   end: Alignment.centerRight,
              // ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.class_outlined, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    classRoom.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Body ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (classRoom.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      classRoom.description,
                      style: TextStyle(fontSize: 13, height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Divider(color: _kDivider, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // View
                    _ActionChip(
                      icon: Icons.visibility_outlined,
                      label: 'View',
                      color: _kPrimary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ClassStudentsScreen(classRoom: classRoom),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Edit
                    _ActionChip(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: const Color(0xFF0EA5E9),
                      onTap: () {
                        final user = context.read<AuthNotifier>().user;


                        _showAddEditClassDialog(
                          context,
                          schoolId: user?.schoolId ?? '',
                          existing: classRoom,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Delete
                    _ActionChip(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: const Color(0xFFEF4444),
                      onTap: () => _confirmDelete(
                        context,
                        label: classRoom.name,
                        onConfirm: () => context
                            .read<ClassSetupNotifier>()
                            .deleteClass(classRoom.id),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Sections Tab
// ═══════════════════════════════════════════════════════════
class _SectionTab extends StatefulWidget {
  const _SectionTab();

  @override
  State<_SectionTab> createState() => _SectionTabState();
}

class _SectionTabState extends State<_SectionTab> {
  String? _selectedClassId; // null = All

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SectionSetupNotifier>();
    final classes = context.watch<ClassSetupNotifier>().classes;
    final user = context.read<AuthNotifier>().user;

    // Filter sections by school first, then by selected class
    final sections = notifier.sections.where((s) {
      final classObj = classes.firstWhere(
        (c) => c.id == s.classId,
        orElse: () => ClassRoom(id: '', name: ''),
      );
      final belongsToSchool =
          user == null || classObj.schoolId == user.schoolId;
      final matchesClass =
          _selectedClassId == null || s.classId == _selectedClassId;
      return belongsToSchool && matchesClass;
    }).toList();

    // Only show classes that belong to this school
    final schoolClasses = classes
        .where((c) => user == null || c.schoolId == user.schoolId)
        .toList();

    return Scaffold(
      body: notifier.isLoading
          ? const _LoadingView()
          : Column(
              children: [
                // ── Class filter chips ──
                _ClassFilterBar(
                  classes: schoolClasses,
                  selectedClassId: _selectedClassId,
                  accentColor: _kSectionGrad.first,
                  onSelected: (id) => setState(() => _selectedClassId = id),
                ),
                Expanded(
                  child: sections.isEmpty
                      ? const _EmptyView(label: 'No sections yet')
                      : ListView.builder(
                          itemCount: sections.length,
                          itemBuilder: (ctx, i) =>
                              _SectionCard(section: sections[i]),
                        ),
                ),
              ],
            ),
      floatingActionButton: _AddFab(
        gradientColors: _kSectionGrad,
        onTap: () => _showAddEditSectionDialog(context),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Section section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final classObj = classes.firstWhere(
      (c) => c.id == section.classId,
      orElse: () => ClassRoom(id: '', name: 'Unknown'),
    );
    final className = classObj.name;
    final teachers = context.watch<TeachersNotifier>().teachers;
    final assignedTeachers = teachers
        .where((t) => t.user?.sectionIds.contains(section.id) == true)
        .toList();

    return Card(
      child: Column(
        children: [
          // ── Header strip ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              // gradient: LinearGradient(
              //   colors: _kSectionGrad,
              //   begin: Alignment.centerLeft,
              //   end: Alignment.centerRight,
              // ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tab_outlined,
                    // color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Section ${section.name}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(className, style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Actions ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.class_outlined,
                  label: 'Class',
                  value: className,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: _kTextMid,
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: assignedTeachers.isEmpty
                          ? const Text(
                              'None assigned',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: _kTextMid,
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: assignedTeachers.map((t) {
                                  final name = t.user?.name ?? '?';

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              _AssignSectionTeachersSheet(section: section),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.manage_accounts,
                              size: 14,
                              color: _kPrimary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Manage',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: _kDivider, height: 24),
                Row(
                  children: [
                    _ActionChip(
                      icon: Icons.visibility_outlined,
                      label: 'View',
                      color: const Color(0xFF0EA5E9),
                      onTap: () {
                        if (classObj.id.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SectionStudentsScreen(
                                classRoom: classObj,
                                section: section,
                              ),
                            ),
                          );
                        } else {
                          _showViewSectionDialog(context, section, className);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: const Color(0xFF8B5CF6),
                      onTap: () =>
                          _showAddEditSectionDialog(context, existing: section),
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: const Color(0xFFEF4444),
                      onTap: () => _confirmDelete(
                        context,
                        label: 'Section ${section.name}',
                        onConfirm: () => context
                            .read<SectionSetupNotifier>()
                            .deleteSection(section.id),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Subjects Tab
// ═══════════════════════════════════════════════════════════
class _SubjectTab extends StatefulWidget {
  const _SubjectTab();

  @override
  State<_SubjectTab> createState() => _SubjectTabState();
}

class _SubjectTabState extends State<_SubjectTab> {
  String? _selectedClassId; // null = All

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SubjectSetupNotifier>();
    final classes = context.watch<ClassSetupNotifier>().classes;
    final user = context.read<AuthNotifier>().user;

    // Filter by school then by selected class
    final subjects = notifier.subjects.where((s) {
      final belongsToSchool = user == null || s.schoolId == user.schoolId;
      final matchesClass =
          _selectedClassId == null || s.classId == _selectedClassId;
      return belongsToSchool && matchesClass;
    }).toList();

    // Only show classes that belong to this school
    final schoolClasses = classes
        .where((c) => user == null || c.schoolId == user.schoolId)
        .toList();

    return Scaffold(
      body: notifier.isLoading
          ? const _LoadingView()
          : Column(
              children: [
                // ── Class filter chips ──
                _ClassFilterBar(
                  classes: schoolClasses,
                  selectedClassId: _selectedClassId,
                  accentColor: _kSubjectGrad.first,
                  onSelected: (id) => setState(() => _selectedClassId = id),
                ),
                Expanded(
                  child: subjects.isEmpty
                      ? const _EmptyView(label: 'No subjects yet')
                      : ListView.builder(
                          itemCount: subjects.length,
                          itemBuilder: (ctx, i) =>
                              _SubjectCard(subject: subjects[i]),
                        ),
                ),
              ],
            ),
      floatingActionButton: _AddFab(
        gradientColors: _kSubjectGrad,
        onTap: () => _showAddEditSubjectDialog(context),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final className = classes
        .firstWhere(
          (c) => c.id == subject.classId,
          orElse: () => ClassRoom(id: '', name: 'Unknown'),
        )
        .name;

    return Card(
      child: Column(
        children: [
          // ── Header strip ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.book_outlined, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (subject.code.isNotEmpty)
                        Text(subject.code, style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                // Code badge
                if (subject.code.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subject.code,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── Actions ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.class_outlined,
                  label: 'Class',
                  value: className,
                ),
                const Divider(color: _kDivider, height: 24),
                Row(
                  children: [
                    _ActionChip(
                      icon: Icons.visibility_outlined,
                      label: 'View',
                      color: const Color(0xFF10B981),
                      onTap: () =>
                          _showViewSubjectDialog(context, subject, className),
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: const Color(0xFF0EA5E9),
                      onTap: () =>
                          _showAddEditSubjectDialog(context, existing: subject),
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: const Color(0xFFEF4444),
                      onTap: () => _confirmDelete(
                        context,
                        label: subject.name,
                        onConfirm: () => context
                            .read<SubjectSetupNotifier>()
                            .deleteSubject(subject.id),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Class Filter Bar
// ═══════════════════════════════════════════════════════════
class _ClassFilterBar extends StatelessWidget {
  final List<ClassRoom> classes;
  final String? selectedClassId;
  final Color accentColor;
  final ValueChanged<String?> onSelected;

  const _ClassFilterBar({
    required this.classes,
    required this.selectedClassId,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: selectedClassId == null,
              accentColor: accentColor,
              onTap: () => onSelected(null),
            ),
            ...classes.map(
              (c) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _FilterChip(
                  label: c.name,
                  isSelected: selectedClassId == c.id,
                  accentColor: accentColor,
                  onTap: () =>
                      onSelected(selectedClassId == c.id ? null : c.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : _kDivider,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : _kTextMid,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Shared UI Helpers
// ═══════════════════════════════════════════════════════════

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AddFab extends StatelessWidget {
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _AddFab({required this.gradientColors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primaryAdmin,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, _) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Card(
            child: Column(
              children: [
                // Header strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(width: 60, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                          const SizedBox(width: 8),
                          Container(width: 60, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                          const SizedBox(width: 8),
                          Container(width: 60, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String label;
  const _EmptyView({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: _kPrimary.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: _kTextMid,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to add one',
            style: TextStyle(color: _kTextMid.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Styled dialog helper ─────────────────────────────────────────────────────
Future<void> _showStyledDialog({
  required BuildContext context,
  required String title,
  required List<Color> gradientColors,
  required Widget body,
  required String confirmLabel,
  required VoidCallback? onConfirm,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryAdmin,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Body
          Padding(padding: const EdgeInsets.all(20), child: body),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: gradientColors.first),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                if (onConfirm != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.last.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

void _showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

InputDecoration _inputDec(String label, {IconData? icon}) => InputDecoration(
  labelText: label,
  prefixIcon: icon != null ? Icon(icon, color: _kPrimary, size: 20) : null,
  filled: true,

  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _kDivider),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _kPrimary, width: 1.5),
  ),
  labelStyle: const TextStyle(color: _kTextMid, fontSize: 13),
);

// ═══════════════════════════════════════════════════════════
//  Dialog: Add / Edit Class
// ═══════════════════════════════════════════════════════════
void _showAddEditClassDialog(
  BuildContext context, {
  required String schoolId,
  ClassRoom? existing,
}) {
  final isEdit = existing != null;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');

  _showStyledDialog(
    context: context,
    title: isEdit ? 'Edit Class' : 'Add Class',
    gradientColors: _kClassGrad,
    confirmLabel: isEdit ? 'Update' : 'Add',
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: nameCtrl,
          decoration: _inputDec('Class Name', icon: Icons.class_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descCtrl,
          maxLines: 2,
          decoration: _inputDec(
            'Description (optional)',
            icon: Icons.notes_outlined,
          ),
        ),
      ],
    ),
    onConfirm: () async {
      if (nameCtrl.text.isNotEmpty) {
        bool success;
        if (isEdit) {

          success = await context.read<ClassSetupNotifier>().updateClass(
            existing.id,
            nameCtrl.text.trim(),
            descCtrl.text.trim(),
            schoolId,
          );
        } else {
          success = await context.read<ClassSetupNotifier>().addClass(
            nameCtrl.text.trim(),
            descCtrl.text.trim(),
            schoolId,
          );
        }

        if (context.mounted) {
          if (success) {
            _showSuccessSnackBar(
              context,
              'Class ${isEdit ? 'updated' : 'added'} successfully',
            );
          } else {
            _showErrorSnackBar(
              context,
              'Failed to ${isEdit ? 'update' : 'add'} class',
            );
          }
        }
      }
    },
  );
}

// ═══════════════════════════════════════════════════════════
//  Dialog: Add / Edit Section
// ═══════════════════════════════════════════════════════════
void _showAddEditSectionDialog(BuildContext context, {Section? existing}) {
  final isEdit = existing != null;
  final classes = context.read<ClassSetupNotifier>().classes;
  String? selectedClassId = existing?.classId;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');

  _showStyledDialog(
    context: context,
    title: isEdit ? 'Edit Section' : 'Add Section',
    gradientColors: _kSectionGrad,
    confirmLabel: isEdit ? 'Update' : 'Add',
    body: StatefulBuilder(
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selectedClassId,
            decoration: _inputDec('Select Class', icon: Icons.class_outlined),
            items: classes
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => selectedClassId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: _inputDec(
              'Section Name (e.g. A)',
              icon: Icons.tab_outlined,
            ),
          ),
        ],
      ),
    ),
    onConfirm: () async {
      if (selectedClassId != null && nameCtrl.text.isNotEmpty) {
        bool success;
        if (isEdit) {
          success = await context.read<SectionSetupNotifier>().updateSection(
            existing!.id,
            selectedClassId!,
            nameCtrl.text.trim(),
          );
        } else {
          success = await context.read<SectionSetupNotifier>().addSection(
            selectedClassId!,
            nameCtrl.text.trim(),
          );
        }

        if (context.mounted) {
          if (success) {
            _showSuccessSnackBar(
              context,
              'Section ${isEdit ? 'updated' : 'added'} successfully',
            );
          } else {
            _showErrorSnackBar(
              context,
              'Failed to ${isEdit ? 'update' : 'add'} section',
            );
          }
        }
      }
    },
  );
}

// ═══════════════════════════════════════════════════════════
//  Dialog: Add / Edit Subject
// ═══════════════════════════════════════════════════════════
void _showAddEditSubjectDialog(BuildContext context, {Subject? existing}) {
  final isEdit = existing != null;
  final classes = context.read<ClassSetupNotifier>().classes;
  final user = context.read<AuthNotifier>().user;
  String? selectedClassId = existing?.classId;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final codeCtrl = TextEditingController(text: existing?.code ?? '');

  _showStyledDialog(
    context: context,
    title: isEdit ? 'Edit Subject' : 'Add Subject',
    gradientColors: _kSubjectGrad,
    confirmLabel: isEdit ? 'Update' : 'Add',
    body: StatefulBuilder(
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selectedClassId,
            decoration: _inputDec('Select Class', icon: Icons.class_outlined),
            items: classes
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => selectedClassId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: _inputDec(
              'Subject Name (e.g. Mathematics)',
              icon: Icons.book_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: codeCtrl,
            decoration: _inputDec(
              'Subject Code (e.g. MATH101)',
              icon: Icons.qr_code_outlined,
            ),
          ),
        ],
      ),
    ),
    onConfirm: () async {
      if (selectedClassId != null &&
          nameCtrl.text.isNotEmpty &&
          user?.schoolId != null) {
        bool success;
        if (isEdit) {
          success = await context.read<SubjectSetupNotifier>().updateSubject(
            existing!.id,
            nameCtrl.text.trim(),
            codeCtrl.text.trim(),
            selectedClassId!,
            user!.schoolId!,
          );
        } else {
          success = await context.read<SubjectSetupNotifier>().addSubject(
            nameCtrl.text.trim(),
            codeCtrl.text.trim(),
            selectedClassId!,
            user!.schoolId!,
          );
        }

        if (context.mounted) {
          if (success) {
            _showSuccessSnackBar(
              context,
              'Subject ${isEdit ? 'updated' : 'added'} successfully',
            );
          } else {
            _showErrorSnackBar(
              context,
              'Failed to ${isEdit ? 'update' : 'add'} subject',
            );
          }
        }
      }
    },
  );
}

// ═══════════════════════════════════════════════════════════
//  Dialog: View Class Details
// ═══════════════════════════════════════════════════════════
void _showViewClassDialog(BuildContext context, ClassRoom classRoom) {
  _showStyledDialog(
    context: context,
    title: 'Class Details',
    gradientColors: _kClassGrad,
    confirmLabel: '',
    onConfirm: null,
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DetailRow(
          icon: Icons.class_outlined,
          label: 'Class Name',
          value: classRoom.name,
        ),
        if (classRoom.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.notes_outlined,
            label: 'Description',
            value: classRoom.description,
          ),
        ],
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  Dialog: View Section Details
// ═══════════════════════════════════════════════════════════
void _showViewSectionDialog(
  BuildContext context,
  Section section,
  String className,
) {
  _showStyledDialog(
    context: context,
    title: 'Section Details',
    gradientColors: _kSectionGrad,
    confirmLabel: '',
    onConfirm: null,
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DetailRow(icon: Icons.tag, label: 'Section', value: section.name),
        const SizedBox(height: 8),
        _DetailRow(
          icon: Icons.class_outlined,
          label: 'Class',
          value: className,
        ),
        // const SizedBox(height: 8),
        // _DetailRow(icon: Icons.key, label: 'ID', value: section.id),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  Dialog: View Subject Details
// ═══════════════════════════════════════════════════════════
void _showViewSubjectDialog(
  BuildContext context,
  Subject subject,
  String className,
) {
  _showStyledDialog(
    context: context,
    title: 'Subject Details',
    gradientColors: _kSubjectGrad,
    confirmLabel: '',
    onConfirm: null,
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DetailRow(
          icon: Icons.book_outlined,
          label: 'Subject',
          value: subject.name,
        ),
        const SizedBox(height: 8),
        _DetailRow(
          icon: Icons.qr_code_outlined,
          label: 'Code',
          value: subject.code.isEmpty ? '-' : subject.code,
        ),
        const SizedBox(height: 8),
        _DetailRow(
          icon: Icons.class_outlined,
          label: 'Class',
          value: className,
        ),
        const SizedBox(height: 8),
        _DetailRow(icon: Icons.key, label: 'ID', value: subject.id),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: _kDivider.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Common delete confirmation
// ═══════════════════════════════════════════════════════════
void _confirmDelete(
  BuildContext context, {
  required String label,
  required Future<bool> Function() onConfirm,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Are you sure you want to delete "$label"?\nThis action cannot be undone.',
          style: const TextStyle(color: _kTextMid, fontSize: 14, height: 1.5),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: _kTextMid)),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final success = await onConfirm();
            if (context.mounted) {
              if (success) {
                _showSuccessSnackBar(context, '$label deleted successfully');
              } else {
                _showErrorSnackBar(context, 'Failed to delete $label');
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  Bottom Sheet: Assign Teachers to Section
// ═══════════════════════════════════════════════════════════

class _AssignSectionTeachersSheet extends StatefulWidget {
  final Section section;

  const _AssignSectionTeachersSheet({required this.section});

  @override
  State<_AssignSectionTeachersSheet> createState() =>
      _AssignSectionTeachersSheetState();
}

class _AssignSectionTeachersSheetState
    extends State<_AssignSectionTeachersSheet> {
  final Set<String> _selectedIds = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final teachers = context.read<TeachersNotifier>().teachers;
    for (final t in teachers) {
      if (t.user?.sectionIds.contains(widget.section.id) == true) {
        _selectedIds.add(t.userId);
      }
    }
  }

  Future<void> _save() async {
    final teachersNotifier = context.read<TeachersNotifier>();
    setState(() => _isSaving = true);
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token');

      final teachers = teachersNotifier.teachers;

      for (final teacher in teachers) {
        final uid = teacher.userId;
        final wasAssigned =
            teacher.user?.sectionIds.contains(widget.section.id) == true;
        final isAssignedNow = _selectedIds.contains(uid);

        if (wasAssigned != isAssignedNow) {
          final currentClassIds = teacher.user?.classIds.toList() ?? [];
          final currentSectionIds = teacher.user?.sectionIds.toList() ?? [];

          if (isAssignedNow) {
            currentSectionIds.add(widget.section.id);
            if (!currentClassIds.contains(widget.section.classId)) {
              currentClassIds.add(widget.section.classId);
            }
          } else {
            currentSectionIds.remove(widget.section.id);
            // Leaving classId intact as it might be used for other sections of the same class
          }

          final resp = await DataProvider().performRequest(
            'PUT',
            '${APIPath.fetchUsers}/$uid',
            data: {
              'classIds': currentClassIds,
              'sectionIds': currentSectionIds,
            },
            header: {'Authorization': 'Bearer $token'},
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar(
          context,
          'Updated teachers for Section ${widget.section.name}',
        );
        teachersNotifier.fetchTeachers();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Error saving assignments: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachers = context.watch<TeachersNotifier>().teachers;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Card(
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assign Teachers to ${widget.section.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: _kTextMid),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: teachers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final teacher = teachers[i];
                  final name = teacher.user?.name ?? 'Unknown';
                  final isSelected = _selectedIds.contains(teacher.userId);
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                  return InkWell(
                    onTap: _isSaving
                        ? null
                        : () {
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(teacher.userId);
                              } else {
                                _selectedIds.add(teacher.userId);
                              }
                            });
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kPrimary.withOpacity(0.05)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? _kPrimary.withOpacity(0.3)
                              : _kDivider,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _kPrimary.withOpacity(0.1),
                            foregroundColor: _kPrimary,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (teacher.designation.isNotEmpty)
                                  Text(
                                    teacher.designation,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _kTextMid,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: _kPrimary)
                          else
                            const Icon(
                              Icons.radio_button_unchecked,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,

                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: const Text(
                          'Save Assignments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
