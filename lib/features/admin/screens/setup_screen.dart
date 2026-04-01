import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/school_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/setup_provider.dart';
import 'class_detail_screen.dart';

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
        context.read<ClassSetupNotifier>().fetchClasses(user.schoolId ?? '');
        context.read<SectionSetupNotifier>().fetchSections();
        context.read<SubjectSetupNotifier>().fetchSubjects(user.schoolId ?? '');
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
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tab,
        children: const [_ClassTab(), _SectionTab(), _SubjectTab()],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(110),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: _kClassGrad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
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
                    fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400, fontSize: 14),
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

    return Scaffold(
      backgroundColor: _kBg,
      body: notifier.isLoading
          ? const _LoadingView()
          : classes.isEmpty
              ? const _EmptyView(label: 'No classes yet')
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: classes.length,
                  itemBuilder: (ctx, i) => _ClassCard(classRoom: classes[i]),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // ── Header strip ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: _kClassGrad),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.class_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    classRoom.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Body ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (classRoom.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      classRoom.description,
                      style: const TextStyle(
                          color: _kTextMid, fontSize: 13, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Divider(color: _kDivider),
                const SizedBox(height: 4),
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
                              ClassDetailScreen(classRoom: classRoom),
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
class _SectionTab extends StatelessWidget {
  const _SectionTab();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SectionSetupNotifier>();
    final sections = notifier.sections;

    return Scaffold(
      backgroundColor: _kBg,
      body: notifier.isLoading
          ? const _LoadingView()
          : sections.isEmpty
              ? const _EmptyView(label: 'No sections yet')
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: sections.length,
                  itemBuilder: (ctx, i) => _SectionCard(section: sections[i]),
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
    final className = classes
        .firstWhere(
          (c) => c.id == section.classId,
          orElse: () => ClassRoom(id: '', name: 'Unknown'),
        )
        .name;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // ── Header strip ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: _kSectionGrad),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tab_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Section ${section.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        className,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Actions ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.class_outlined,
                  label: 'Class',
                  value: className,
                ),
                const Divider(color: _kDivider, height: 20),
                Row(
                  children: [
                    _ActionChip(
                      icon: Icons.visibility_outlined,
                      label: 'View',
                      color: const Color(0xFF0EA5E9),
                      onTap: () => _showViewSectionDialog(
                          context, section, className),
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => _showAddEditSectionDialog(
                        context,
                        existing: section,
                      ),
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
class _SubjectTab extends StatelessWidget {
  const _SubjectTab();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SubjectSetupNotifier>();
    final subjects = notifier.subjects;

    return Scaffold(
      backgroundColor: _kBg,
      body: notifier.isLoading
          ? const _LoadingView()
          : subjects.isEmpty
              ? const _EmptyView(label: 'No subjects yet')
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: subjects.length,
                  itemBuilder: (ctx, i) =>
                      _SubjectCard(subject: subjects[i]),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // ── Header strip ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: _kSubjectGrad),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.book_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subject.code.isNotEmpty)
                        Text(
                          subject.code,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                // Code badge
                if (subject.code.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subject.code,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          // ── Actions ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.class_outlined,
                  label: 'Class',
                  value: className,
                ),
                const Divider(color: _kDivider, height: 20),
                Row(
                  children: [
                    _ActionChip(
                      icon: Icons.visibility_outlined,
                      label: 'View',
                      color: const Color(0xFF10B981),
                      onTap: () => _showViewSubjectDialog(
                          context, subject, className),
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: const Color(0xFF0EA5E9),
                      onTap: () => _showAddEditSubjectDialog(
                        context,
                        existing: subject,
                      ),
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
                    fontWeight: FontWeight.w600),
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

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kTextMid),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                color: _kTextMid, fontSize: 13, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: _kTextDark,
                fontSize: 13,
                fontWeight: FontWeight.w600),
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
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: gradientColors.last.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
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
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(_kPrimary),
      ),
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
          Icon(Icons.inbox_outlined, size: 64, color: _kPrimary.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                  color: _kTextMid,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Tap + to add one',
              style: TextStyle(
                  color: _kTextMid.withOpacity(0.6), fontSize: 13)),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: body,
          ),
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
                          borderRadius: BorderRadius.circular(12)),
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
                              offset: const Offset(0, 3))
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
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(confirmLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
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

InputDecoration _inputDec(String label, {IconData? icon}) => InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: _kPrimary, size: 20) : null,
      filled: true,
      fillColor: _kBg,
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
          decoration:
              _inputDec('Description (optional)', icon: Icons.notes_outlined),
        ),
      ],
    ),
    onConfirm: () {
      if (nameCtrl.text.isNotEmpty) {
        if (isEdit) {
          context.read<ClassSetupNotifier>().updateClass(
                existing.id,
                nameCtrl.text.trim(),
                descCtrl.text.trim(),
                schoolId,
              );
        } else {
          context.read<ClassSetupNotifier>().addClass(
                nameCtrl.text.trim(),
                descCtrl.text.trim(),
                schoolId,
              );
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
                .map((c) =>
                    DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => selectedClassId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: _inputDec('Section Name (e.g. A)',
                icon: Icons.tab_outlined),
          ),
        ],
      ),
    ),
    onConfirm: () {
      if (selectedClassId != null && nameCtrl.text.isNotEmpty) {
        if (isEdit) {
          context.read<SectionSetupNotifier>().updateSection(
                existing.id,
                selectedClassId!,
                nameCtrl.text.trim(),
              );
        } else {
          context.read<SectionSetupNotifier>().addSection(
                selectedClassId!,
                nameCtrl.text.trim(),
              );
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
                .map((c) =>
                    DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => selectedClassId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: _inputDec('Subject Name (e.g. Mathematics)',
                icon: Icons.book_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: codeCtrl,
            decoration: _inputDec('Subject Code (e.g. MATH101)',
                icon: Icons.qr_code_outlined),
          ),
        ],
      ),
    ),
    onConfirm: () {
      if (selectedClassId != null &&
          nameCtrl.text.isNotEmpty &&
          user?.schoolId != null) {
        if (isEdit) {
          context.read<SubjectSetupNotifier>().updateSubject(
                existing.id,
                nameCtrl.text.trim(),
                codeCtrl.text.trim(),
                selectedClassId!,
                user!.schoolId!,
              );
        } else {
          context.read<SubjectSetupNotifier>().addSubject(
                nameCtrl.text.trim(),
                codeCtrl.text.trim(),
                selectedClassId!,
                user!.schoolId!,
              );
        }
      }
    },
  );
}

// ═══════════════════════════════════════════════════════════
//  Dialog: View Section Details
// ═══════════════════════════════════════════════════════════
void _showViewSectionDialog(
    BuildContext context, Section section, String className) {
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
            value: className),
        const SizedBox(height: 8),
        _DetailRow(icon: Icons.key, label: 'ID', value: section.id),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  Dialog: View Subject Details
// ═══════════════════════════════════════════════════════════
void _showViewSubjectDialog(
    BuildContext context, Subject subject, String className) {
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
            icon: Icons.book_outlined, label: 'Subject', value: subject.name),
        const SizedBox(height: 8),
        _DetailRow(
            icon: Icons.qr_code_outlined,
            label: 'Code',
            value: subject.code.isEmpty ? '-' : subject.code),
        const SizedBox(height: 8),
        _DetailRow(
            icon: Icons.class_outlined, label: 'Class', value: className),
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

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _kPrimary),
          const SizedBox(width: 10),
          Text('$label:',
              style: const TextStyle(
                  color: _kTextMid,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
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
  required VoidCallback onConfirm,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
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
          child: const Text('Cancel',
              style: TextStyle(color: _kTextMid)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
