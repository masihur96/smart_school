import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/utils/storage_service.dart';

import '../../../configs/network/data_provider.dart';
import '../../../models/school_models.dart';
import '../../../models/student_model.dart';
import '../providers/setup_provider.dart';
import '../providers/student_provider.dart';

// ─── Colour palette ───────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF6C3CE1);
const _kBg = Color(0xFFF4F2FB);
const _kDivider = Color(0xFFEDE9F8);
const _kTextMid = Color(0xFF6B7280);
const _kGrad = [Color(0xFF6C3CE1), Color(0xFF9B6DFF)];

// ─────────────────────────────────────────────────────────────────────────────
// ClassStudentsScreen
// ─────────────────────────────────────────────────────────────────────────────

class SectionStudentsScreen extends StatefulWidget {
  final ClassRoom classRoom;
  final Section section;

  const SectionStudentsScreen({
    super.key,
    required this.classRoom,
    required this.section,
  });

  @override
  State<SectionStudentsScreen> createState() => _SectionStudentsScreenState();
}

class _SectionStudentsScreenState extends State<SectionStudentsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabAnim;
  String _searchQuery = '';

  bool _multiSelectMode = false;
  final Set<String> _selectedIds = {};
  bool _isUnassigning = false;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentsNotifier>().fetchStudentsBySection(
        classId: widget.classRoom.id,
        sectionId: widget.section.id,
      );
    });
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  // ── Unassign logic ───────────────────────────────────────────────────────────

  Future<void> _showUnassignConfirm(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unassign Student'),
        content: Text(
          'Remove ${student.user?.name ?? 'this student'} from Section ${widget.section.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _unassignSingle(student);
    }
  }

  Future<void> _unassignSingle(Student student) async {
    await _doUnassign([student.userId]);
  }

  Future<void> _unassignSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unassign Students'),
        content: Text(
          'Remove ${_selectedIds.length} selected students from Section ${widget.section.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _doUnassign(_selectedIds.toList());
    }
  }

  Future<void> _doUnassign(List<String> userIds) async {
    setState(() => _isUnassigning = true);
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token');

      final allStudents = context.read<StudentsNotifier>().students;

      int successCount = 0;
      for (final uid in userIds) {
        final student = allStudents.firstWhere((s) => s.userId == uid);
        final currentClassIds = student.user?.classIds.toList() ?? [];
        final currentSectionIds = student.user?.sectionIds.toList() ?? [];

        currentSectionIds.remove(widget.section.id);

        final resp = await DataProvider().performRequest(
          'PUT',
          '${APIPath.fetchUsers}/$uid',
          data: {
            'classIds': currentClassIds,
            'sectionIds': currentSectionIds,
          },
          header: {'Authorization': 'Bearer $token'},
        );
        if (resp != null && resp.statusCode == 200) successCount++;
      }

      if (mounted) {
        final msg = successCount == userIds.length
            ? '$successCount student${successCount > 1 ? 's' : ''} unassigned'
            : '$successCount of ${userIds.length} students unassigned';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        _selectedIds.clear();
        _multiSelectMode = false;
        context.read<StudentsNotifier>().fetchStudentsBySection(
          classId: widget.classRoom.id,
          sectionId: widget.section.id,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUnassigning = false);
    }
  }

  // ── Assign dialog ────────────────────────────────────────────────────────────

  Future<void> _openAssignDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignSectionStudentsSheet(
        classRoom: widget.classRoom,
        section: widget.section,
      ),
    );
    // Refresh after assignment
    if (mounted) {
      context.read<StudentsNotifier>().fetchStudentsBySection(
        classId: widget.classRoom.id,
        sectionId: widget.section.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<StudentsNotifier>();
    final all = notifier.students;

    // Filter by search
    final filtered = _searchQuery.isEmpty
        ? all
        : all
              .where(
                (s) =>
                    (s.user?.name ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    s.rollId.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryAdmin,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(color: AppColors.primaryAdmin),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(72, 16, 16, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Section ${widget.section.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.classRoom.name,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or roll…',
                    hintStyle: TextStyle(color: _kTextMid, fontSize: 13),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: _kPrimary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: notifier.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(_kPrimary),
                ),
              )
            : filtered.isEmpty
            ? _EmptyState(
                hasSearch: _searchQuery.isNotEmpty,
                className: 'Section ${widget.section.name}',
              )
            : Column(
                children: [
                  // Stats bar
                  _StatsBar(
                    total: all.length,
                    shown: filtered.length,
                    multiSelectMode: _multiSelectMode,
                    selectedCount: _selectedIds.length,
                    onToggleMultiSelect: () {
                      setState(() {
                        _multiSelectMode = !_multiSelectMode;
                        if (!_multiSelectMode) _selectedIds.clear();
                      });
                    },
                  ),
                  if (_multiSelectMode)
                    _UnassignActionBar(
                      selectedCount: _selectedIds.length,
                      totalCount: filtered.length,
                      isUnassigning: _isUnassigning,
                      onSelectAll: () {
                        setState(() {
                          if (_selectedIds.length == filtered.length) {
                            _selectedIds.clear();
                          } else {
                            _selectedIds.addAll(filtered.map((s) => s.userId));
                          }
                        });
                      },
                      onUnassign: _selectedIds.isEmpty
                          ? null
                          : _unassignSelected,
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final student = filtered[i];
                        final isSelected = _selectedIds.contains(
                          student.userId,
                        );
                        return _StudentTile(
                          student: student,
                          index: i,
                          isMultiSelectMode: _multiSelectMode,
                          isSelected: isSelected,
                          isUnassigning: _isUnassigning,
                          onTap: () {
                            if (_multiSelectMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(student.userId);
                                } else {
                                  _selectedIds.add(student.userId);
                                }
                              });
                            }
                          },
                          onLongPress: () {
                            if (!_multiSelectMode) {
                              setState(() {
                                _multiSelectMode = true;
                                _selectedIds.add(student.userId);
                              });
                            }
                          },
                          onUnassign: () => _showUnassignConfirm(student),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnim,
        child: _AssignFab(onTap: _openAssignDialog),
      ),
    );
  }
}

// ─── Stats bar ────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final int total;
  final int shown;
  final bool multiSelectMode;
  final int selectedCount;
  final VoidCallback onToggleMultiSelect;

  const _StatsBar({
    required this.total,
    required this.shown,
    required this.multiSelectMode,
    required this.selectedCount,
    required this.onToggleMultiSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kDivider),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.people_outlined,
            label: 'Total',
            value: '$total',
            color: _kPrimary,
          ),
          const SizedBox(width: 16),
          if (shown != total)
            _StatChip(
              icon: Icons.filter_list,
              label: 'Filtered',
              value: '$shown',
              color: const Color(0xFF0EA5E9),
            ),
          const Spacer(),
          _MultiSelectToggleBtn(
            active: multiSelectMode,
            selectedCount: selectedCount,
            onToggle: onToggleMultiSelect,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text('$label: ', style: TextStyle(fontSize: 12, color: _kTextMid)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Student tile ─────────────────────────────────────────────────────────────

class _StudentTile extends StatelessWidget {
  final Student student;
  final int index;
  final bool isMultiSelectMode;
  final bool isSelected;
  final bool isUnassigning;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onUnassign;

  const _StudentTile({
    required this.student,
    required this.index,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.isUnassigning,
    required this.onTap,
    required this.onLongPress,
    required this.onUnassign,
  });

  Color get _avatarColor {
    final colors = [
      const Color(0xFF6C3CE1),
      const Color(0xFF0EA5E9),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final name = student.user?.name ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final email = student.user?.email ?? '';
    final sectionName = student.sectionName ?? '';

    return GestureDetector(
      onTap: isUnassigning ? null : onTap,
      onLongPress: isUnassigning ? null : onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.red.withOpacity(0.4) : _kDivider,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Checkbox or Avatar
              if (isMultiSelectMode)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isSelected ? Colors.red : Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                )
              else
                Container(
                  width: 46,
                  height: 46,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: _avatarColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _avatarColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: _avatarColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _MiniChip(
                          icon: Icons.tag,
                          label: 'Roll: ${student.rollId}',
                          color: _kPrimary,
                        ),
                        if (sectionName.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _MiniChip(
                            icon: Icons.tab_outlined,
                            label: 'Sec: $sectionName',
                            color: const Color(0xFF0EA5E9),
                          ),
                        ],
                      ],
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: TextStyle(fontSize: 11, color: _kTextMid),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Status badge & Actions
              if (isMultiSelectMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: student.isActive
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    student.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: student.isActive
                          ? const Color(0xFF10B981)
                          : Colors.red,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: student.isActive
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        student.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: student.isActive
                              ? const Color(0xFF10B981)
                              : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.person_remove_outlined,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: isUnassigning ? null : onUnassign,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _AssignFab extends StatelessWidget {
  final VoidCallback onTap;

  const _AssignFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: _kGrad),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.person_add_alt_1, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Assign Students',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final String className;

  const _EmptyState({required this.hasSearch, required this.className});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                hasSearch
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                size: 64,
                color: _kPrimary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch
                  ? 'No students match your search'
                  : 'No students assigned to $className',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try a different search term'
                  : 'Tap "Assign Students" to add students to this class',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kTextMid, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assign Students Sheet (Bottom Sheet)
// Supports single-tap assign AND multi-select bulk assign
// ─────────────────────────────────────────────────────────────────────────────

class _AssignSectionStudentsSheet extends StatefulWidget {
  final ClassRoom classRoom;
  final Section section;

  const _AssignSectionStudentsSheet({
    required this.classRoom,
    required this.section,
  });

  @override
  State<_AssignSectionStudentsSheet> createState() =>
      _AssignSectionStudentsSheetState();
}

class _AssignSectionStudentsSheetState
    extends State<_AssignSectionStudentsSheet> {
  List<Student> _unassigned = [];
  bool _isLoading = true;
  bool _isAssigning = false;
  String _searchQuery = '';
  String? _selectedFilterSectionId;

  // Multi-select
  bool _multiSelectMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadUnassignedStudents();
  }

  Future<void> _loadUnassignedStudents() async {
    setState(() => _isLoading = true);
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token');

      // Fetch ALL students (no class filter)
      final response = await DataProvider().performRequest(
        'GET',
        APIPath.fetchUsers,
        query: {'role': 'student', 'limit': '200'},
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final inner = response.data is Map
            ? response.data['data']
            : response.data;
        final List<dynamic> data = inner is List
            ? inner
            : (inner is Map ? (inner['data'] as List<dynamic>? ?? []) : []);

        final all = data
            .map((e) {
              try {
                return Student.fromJson(e as Map<String, dynamic>);
              } catch (_) {
                return null;
              }
            })
            .whereType<Student>()
            .where((s) => !s.isDeleted)
            .toList();

        final unassigned = all
            .where(
              (s) =>
                  s.classId == widget.classRoom.id &&
                  s.sectionId != widget.section.id,
            )
            .toList();

        setState(() {
          _unassigned = unassigned;
        });
      }
    } catch (e) {
      log('_loadUnassignedStudents error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Student> get _filtered {
    List<Student> list = _unassigned;

    if (_selectedFilterSectionId != null) {
      if (_selectedFilterSectionId!.isEmpty) {
        list = list
            .where((s) => s.sectionId == null || s.sectionId!.isEmpty)
            .toList();
      } else {
        list = list
            .where((s) => s.sectionId == _selectedFilterSectionId)
            .toList();
      }
    }

    if (_searchQuery.isEmpty) return list;
    return list.where((s) {
      final name = (s.user?.name ?? '').toLowerCase();
      final roll = s.rollId.toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || roll.contains(q);
    }).toList();
  }

  // ── Assign single student ────────────────────────────────────────────────────

  Future<void> _assignSingle(Student student) async {
    await _doAssign([student.userId]);
  }

  // ── Assign multiple students ─────────────────────────────────────────────────

  Future<void> _assignSelected() async {
    if (_selectedIds.isEmpty) return;
    await _doAssign(_selectedIds.toList());
  }

  Future<void> _doAssign(List<String> userIds) async {
    setState(() => _isAssigning = true);
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token');

      int successCount = 0;
      for (final uid in userIds) {
        final student = _unassigned.firstWhere((s) => s.userId == uid);
        final currentClassIds = student.user?.classIds.toList() ?? [];
        final currentSectionIds = student.user?.sectionIds.toList() ?? [];

        if (!currentClassIds.contains(widget.classRoom.id)) {
          currentClassIds.add(widget.classRoom.id);
        }
        if (!currentSectionIds.contains(widget.section.id)) {
          currentSectionIds.add(widget.section.id);
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
        if (resp != null && resp.statusCode == 200) successCount++;
      }

      if (mounted) {
        final msg = successCount == userIds.length
            ? '$successCount student${successCount > 1 ? 's' : ''} assigned to Section ${widget.section.name}'
            : '$successCount of ${userIds.length} students assigned';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Reload unassigned list
        _selectedIds.clear();
        _multiSelectMode = false;
        await _loadUnassignedStudents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _kGrad),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign Students',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'to Section ${widget.section.name}',
                        style: TextStyle(fontSize: 12, color: _kTextMid),
                      ),
                    ],
                  ),
                ),
                // Multi-select toggle
                _MultiSelectToggleBtn(
                  active: _multiSelectMode,
                  selectedCount: _selectedIds.length,
                  onToggle: () {
                    setState(() {
                      _multiSelectMode = !_multiSelectMode;
                      if (!_multiSelectMode) _selectedIds.clear();
                    });
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEDE9F8)),

          // ── Search & Filter ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F2FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEDE9F8)),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search name/roll…',
                        hintStyle: TextStyle(color: _kTextMid, fontSize: 13),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: _kPrimary,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEDE9F8)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        isExpanded: true,
                        value: _selectedFilterSectionId,
                        icon: const Icon(
                          Icons.filter_list,
                          color: _kPrimary,
                          size: 20,
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _selectedFilterSectionId = val;
                            _selectedIds.clear();
                          });
                        },
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Sections'),
                          ),
                          const DropdownMenuItem(
                            value: '',
                            child: Text('No Section'),
                          ),
                          ...context
                              .watch<ClassSetupNotifier>()
                              .classes
                              .where((c) => c.id != widget.classRoom.id)
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Multi-select action bar ────────────────────────────────────────
          if (_multiSelectMode)
            _MultiSelectActionBar(
              selectedCount: _selectedIds.length,
              totalCount: filtered.length,
              isAssigning: _isAssigning,
              onSelectAll: () {
                setState(() {
                  if (_selectedIds.length == filtered.length) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds.addAll(filtered.map((s) => s.userId));
                  }
                });
              },
              onAssign: _selectedIds.isEmpty ? null : _assignSelected,
            ),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(_kPrimary),
                    ),
                  )
                : filtered.isEmpty
                ? _SheetEmptyState(hasSearch: _searchQuery.isNotEmpty)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (ctx, i) {
                      final student = filtered[i];
                      final isSelected = _selectedIds.contains(student.userId);
                      return _AssignStudentTile(
                        student: student,
                        index: i,
                        isMultiSelectMode: _multiSelectMode,
                        isSelected: isSelected,
                        isAssigning: _isAssigning,
                        onTap: () {
                          if (_multiSelectMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(student.userId);
                              } else {
                                _selectedIds.add(student.userId);
                              }
                            });
                          } else {
                            _assignSingle(student);
                          }
                        },
                        onLongPress: () {
                          if (!_multiSelectMode) {
                            setState(() {
                              _multiSelectMode = true;
                              _selectedIds.add(student.userId);
                            });
                          }
                        },
                      );
                    },
                  ),
          ),

          // ── Bottom hint ───────────────────────────────────────────────────
          if (!_isLoading && !_multiSelectMode && filtered.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 14,
                      color: _kTextMid.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to assign one · Long-press for multi-select',
                      style: TextStyle(
                        color: _kTextMid.withOpacity(0.7),
                        fontSize: 11,
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
}

// ─── Multi-select toggle button ───────────────────────────────────────────────

class _MultiSelectToggleBtn extends StatelessWidget {
  final bool active;
  final int selectedCount;
  final VoidCallback onToggle;
  final Color color;

  const _MultiSelectToggleBtn({
    required this.active,
    required this.selectedCount,
    required this.onToggle,
    this.color = _kPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: active ? Colors.white : color,
            ),
            const SizedBox(width: 4),
            Text(
              active
                  ? (selectedCount > 0 ? '$selectedCount' : 'Multi')
                  : 'Multi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Unassign action bar ──────────────────────────────────────────────────────

class _UnassignActionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final bool isUnassigning;
  final VoidCallback onSelectAll;
  final VoidCallback? onUnassign;

  const _UnassignActionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.isUnassigning,
    required this.onSelectAll,
    required this.onUnassign,
  });

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedCount == totalCount && totalCount > 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onSelectAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  allSelected ? Icons.select_all : Icons.deselect,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  allSelected ? 'Deselect All' : 'Select All',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '$selectedCount selected',
            style: TextStyle(
              fontSize: 12,
              color: _kTextMid,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onUnassign,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: onUnassign != null ? Colors.red : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
                boxShadow: onUnassign != null
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: isUnassigning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Remove ${selectedCount > 0 ? '($selectedCount)' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: onUnassign != null ? Colors.white : Colors.grey,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Multi-select action bar ──────────────────────────────────────────────────

class _MultiSelectActionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final bool isAssigning;
  final VoidCallback onSelectAll;
  final VoidCallback? onAssign;

  const _MultiSelectActionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.isAssigning,
    required this.onSelectAll,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedCount == totalCount && totalCount > 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Select all
          GestureDetector(
            onTap: onSelectAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  allSelected ? Icons.select_all : Icons.deselect,
                  size: 16,
                  color: _kPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  allSelected ? 'Deselect All' : 'Select All',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '$selectedCount selected',
            style: TextStyle(
              fontSize: 12,
              color: _kTextMid,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          // Assign button
          GestureDetector(
            onTap: onAssign,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: onAssign != null
                    ? const LinearGradient(colors: _kGrad)
                    : null,
                color: onAssign == null ? Colors.grey.shade300 : null,
                borderRadius: BorderRadius.circular(10),
                boxShadow: onAssign != null
                    ? [
                        BoxShadow(
                          color: _kPrimary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: isAssigning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Assign ${selectedCount > 0 ? '($selectedCount)' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: onAssign != null ? Colors.white : Colors.grey,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Assign student tile ──────────────────────────────────────────────────────

class _AssignStudentTile extends StatelessWidget {
  final Student student;
  final int index;
  final bool isMultiSelectMode;
  final bool isSelected;
  final bool isAssigning;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AssignStudentTile({
    required this.student,
    required this.index,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.isAssigning,
    required this.onTap,
    required this.onLongPress,
  });

  Color get _color {
    const colors = [
      Color(0xFF6C3CE1),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final name = student.user?.name ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final currentClass = student.className;
    final currentSection = student.sectionName;

    return GestureDetector(
      onTap: isAssigning ? null : onTap,
      onLongPress: isAssigning ? null : onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? _kPrimary.withOpacity(0.4)
                : const Color(0xFFEDE9F8),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox or Avatar
            if (isMultiSelectMode)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isSelected ? _kPrimary : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              )
            else
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _MiniChip(
                        icon: Icons.tag,
                        label: 'Roll: ${student.rollId}',
                        color: _kPrimary,
                      ),
                      if (currentClass != null) ...[
                        const SizedBox(width: 5),
                        _MiniChip(
                          icon: Icons.class_outlined,
                          label: currentClass,
                          color: const Color(0xFF0EA5E9),
                        ),
                      ],
                      if (currentSection != null) ...[
                        const SizedBox(width: 5),
                        _MiniChip(
                          icon: Icons.tab_outlined,
                          label: 'Sec: $currentSection',
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Action
            if (!isMultiSelectMode)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _kGrad),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Sheet empty state ────────────────────────────────────────────────────────

class _SheetEmptyState extends StatelessWidget {
  final bool hasSearch;

  const _SheetEmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.people_outline,
            size: 56,
            color: _kPrimary.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch
                ? 'No students match your search'
                : 'All students are already assigned\nto this class',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kTextMid, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
