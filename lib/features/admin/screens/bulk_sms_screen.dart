import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/student_model.dart';
import 'package:smart_school/services/sms_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_school/l10n/app_localizations.dart';

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
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;
  String? _selectedClassId;
  String? _selectedSectionId;
  String _searchQuery = '';
  String _smsType = 'Normal SMS'; // 'Normal SMS' or 'Mask SMS'
  String _selectedFilterChip = 'all'; // 'all', 'selected', 'with_phone', 'no_phone'
  Timer? _debounce;

  List<Map<String, String>> _getQuickTemplates(AppLocalizations l10n) => [
        {
          'title': l10n.templateSchoolClosedTitle,
          'text': l10n.templateSchoolClosedText,
        },
        {
          'title': l10n.templateExamReminderTitle,
          'text': l10n.templateExamReminderText,
        },
        {
          'title': l10n.templateFeeDueTitle,
          'text': l10n.templateFeeDueText,
        },
        {
          'title': l10n.templatePtmTitle,
          'text': l10n.templatePtmText,
        },
        {
          'title': l10n.templateEmergencyAlertTitle,
          'text': l10n.templateEmergencyAlertText,
        },
      ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _messageController.addListener(() {
      setState(() {});
    });
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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

  // ── Selection Logic ────────────────────────────────────────────────────────

  void _toggleSelection(Student student) {
    final l10n = AppLocalizations.of(context)!;
    if (student.guardianContact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.doesNotHaveContact(student.user?.name ?? l10n.unknownStudent),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
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

  void _selectAllWithContact(List<Student> students) {
    setState(() {
      for (var s in students) {
        if (s.guardianContact.isNotEmpty) {
          _selectedStudentIds.add(s.userId);
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedStudentIds.clear();
    });
  }

  // ── SMS Calculation ────────────────────────────────────────────────────────

  int _calculateSmsParts(String text) {
    if (text.isEmpty) return 0;
    final isUnicode = text.runes.any((rune) => rune > 127);
    if (isUnicode) {
      if (text.length <= 70) return 1;
      return (text.length / 67).ceil();
    } else {
      if (text.length <= 160) return 1;
      return (text.length / 153).ceil();
    }
  }

  int _getMaxCharsSinglePart(String text) {
    final isUnicode = text.runes.any((rune) => rune > 127);
    return isUnicode ? 70 : 160;
  }

  // ── Send Flow & Confirmation ───────────────────────────────────────────────

  void _handleSendPressed() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.selectAtLeastOneStudent),
        ),
      );
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.enterSmsMessageToBroadcast),
        ),
      );
      return;
    }

    final studentsNotifier = context.read<StudentsNotifier>();
    final List<String> validNumbers = [];
    for (var student in studentsNotifier.students) {
      if (_selectedStudentIds.contains(student.userId) &&
          student.guardianContact.isNotEmpty) {
        if (!validNumbers.contains(student.guardianContact)) {
          validNumbers.add(student.guardianContact);
        }
      }
    }

    if (validNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.noSelectedStudentsHavePhone),
        ),
      );
      return;
    }

    _showConfirmationSheet(validNumbers);
  }

  Future<void> _showConfirmationSheet(List<String> validNumbers) async {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = _messageController.text.trim();
    final partsPerMsg = _calculateSmsParts(message);
    final totalCredits = partsPerMsg * validNumbers.length;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAdmin.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: AppColors.primaryAdmin,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.confirmBulkSmsTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.reviewCampaignDetails,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900.withValues(alpha: 0.6)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      icon: Icons.people_alt_rounded,
                      label: l10n.recipientsLabel,
                      value: l10n.parentsGuardiansCount(validNumbers.length),
                      color: Colors.blue,
                    ),
                    const Divider(height: 16),
                    _buildSummaryRow(
                      icon: Icons.verified_user_rounded,
                      label: l10n.smsTypeLabel,
                      value: _smsType == 'Mask SMS'
                          ? l10n.maskedSchoolCare
                          : l10n.normalSmsDirectValue,
                      color: Colors.purple,
                    ),
                    const Divider(height: 16),
                    _buildSummaryRow(
                      icon: Icons.receipt_long_rounded,
                      label: l10n.estimatedSmsCredits,
                      value: l10n.smsCreditsBreakdown(
                        totalCredits,
                        partsPerMsg,
                        validNumbers.length,
                      ),
                      color: Colors.teal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.messagePreviewLabel,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAdmin,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        l10n.sendNowButton,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      _executeSendSms(validNumbers);
    }
  }

  Future<void> _executeSendSms(List<String> numbers) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSending = true;
    });

    final success = await _smsService.sendBulkSms(
      numbers,
      _messageController.text.trim(),
      isMasked: _smsType == 'Mask SMS',
    );

    setState(() {
      _isSending = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.bulkSmsSentSuccess(numbers.length),
                ),
              ),
            ],
          ),
        ),
      );
      _messageController.clear();
      setState(() {
        _selectedStudentIds.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.bulkSmsSentFailed,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ── Class/Section Label Helper ─────────────────────────────────────────────

  String _getClassSectionText(BuildContext context, Student student) {
    if (student.className != null && student.className!.isNotEmpty) {
      if (student.sectionName != null && student.sectionName!.isNotEmpty) {
        return '${student.className} • ${student.sectionName}';
      }
      return student.className!;
    }

    final classSetup = context.watch<ClassSetupNotifier>();
    final sectionSetup = context.watch<SectionSetupNotifier>();

    final cls = classSetup.classes.cast<dynamic>().firstWhere(
      (c) => c.id == student.classId,
      orElse: () => null,
    );

    final sec = sectionSetup.sections.cast<dynamic>().firstWhere(
      (s) => s.id == student.sectionId,
      orElse: () => null,
    );

    if (cls != null && sec != null) {
      return '${cls.name} • ${sec.name}';
    } else if (cls != null) {
      return cls.name;
    }
    final l10n = AppLocalizations.of(context)!;
    return '${l10n.classLabel} ${student.classId}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classes = context.watch<ClassSetupNotifier>().classes;
    final sections = context.watch<SectionSetupNotifier>().sections;
    final studentsNotifier = context.watch<StudentsNotifier>();

    // Calculate stats
    final totalStudents = studentsNotifier.students.length;
    final studentsWithPhone =
        studentsNotifier.students.where((s) => s.guardianContact.isNotEmpty).length;
    final missingPhoneCount = totalStudents - studentsWithPhone;

    // Filter students by active chip
    List<Student> displayedStudents = studentsNotifier.students;
    if (_selectedFilterChip == 'selected') {
      displayedStudents =
          displayedStudents.where((s) => _selectedStudentIds.contains(s.userId)).toList();
    } else if (_selectedFilterChip == 'with_phone') {
      displayedStudents =
          displayedStudents.where((s) => s.guardianContact.isNotEmpty).toList();
    } else if (_selectedFilterChip == 'no_phone') {
      displayedStudents =
          displayedStudents.where((s) => s.guardianContact.isEmpty).toList();
    }

    final messageText = _messageController.text;
    final smsParts = _calculateSmsParts(messageText);
    final maxSinglePart = _getMaxCharsSinglePart(messageText);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bulkSmsBroadcastTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              l10n.bulkSmsBroadcastSubtitle,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: l10n.selectionActions,
            onSelected: (val) {
              if (val == 'select_valid') {
                _selectAllWithContact(studentsNotifier.students);
              } else if (val == 'select_all') {
                setState(() {
                  for (var s in studentsNotifier.students) {
                    _selectedStudentIds.add(s.userId);
                  }
                });
              } else if (val == 'clear') {
                _clearSelection();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'select_valid',
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_read_rounded, size: 18, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(l10n.selectAllWithPhone),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'select_all',
                child: Row(
                  children: [
                    const Icon(Icons.select_all_rounded, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(l10n.selectAllVisible),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.deselect_rounded, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(l10n.clearSelection),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Top Filters & Statistics Section ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stat Cards Row ──
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBadge(
                        label: l10n.statTotal,
                        value: '$totalStudents',
                        icon: Icons.groups_rounded,
                        color: Colors.blue,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBadge(
                        label: l10n.statSelected,
                        value: '${_selectedStudentIds.length}',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.primaryAdmin,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBadge(
                        label: l10n.statSmsReady,
                        value: '$studentsWithPhone',
                        icon: Icons.phone_in_talk_rounded,
                        color: Colors.teal,
                        isDark: isDark,
                      ),
                    ),
                    if (missingPhoneCount > 0) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatBadge(
                          label: l10n.statMissing,
                          value: '$missingPhoneCount',
                          icon: Icons.phonelink_erase_rounded,
                          color: Colors.orange,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // ── Search Bar ──
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchStudentByRollHint,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _applyFilters();
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: isDark
                        ? Colors.grey.shade900.withValues(alpha: 0.5)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
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

                // ── Class & Section Dropdowns ──
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900.withValues(alpha: 0.5)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedClassId,
                            hint: Row(
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  size: 16,
                                  color: AppColors.primaryAdmin,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.allClasses,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  l10n.allClasses,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                              ...classes.map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedClassId = val;
                                _selectedSectionId = null;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900.withValues(alpha: 0.5)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedSectionId,
                            hint: Row(
                              children: [
                                const Icon(
                                  Icons.grid_view_rounded,
                                  size: 16,
                                  color: AppColors.primaryAdmin,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.allSections,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  l10n.allSections,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                              ...sections
                                  .where(
                                    (s) =>
                                        _selectedClassId == null ||
                                        s.classId == _selectedClassId,
                                  )
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(
                                        s.name,
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedSectionId = val;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Filter Chips ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: l10n.filterChipAllCount(totalStudents),
                        chipKey: 'all',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: l10n.filterChipSelectedCount(_selectedStudentIds.length),
                        chipKey: 'selected',
                        isDark: isDark,
                        badgeColor: AppColors.primaryAdmin,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: l10n.filterChipWithPhoneCount(studentsWithPhone),
                        chipKey: 'with_phone',
                        isDark: isDark,
                        badgeColor: Colors.teal,
                      ),
                      if (missingPhoneCount > 0) ...[
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: l10n.filterChipNoPhoneCount(missingPhoneCount),
                          chipKey: 'no_phone',
                          isDark: isDark,
                          badgeColor: Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Student List ──
          Expanded(
            child: Consumer<StudentsNotifier>(
              builder: (context, notifier, child) {
                if (notifier.isLoading && notifier.students.isEmpty) {
                  return _buildShimmerLoader();
                }

                if (displayedStudents.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFilterChip == 'selected'
                                ? l10n.noStudentsSelectedYet
                                : l10n.noStudentsMatchingFilter,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_selectedFilterChip == 'selected')
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _selectAllWithContact(notifier.students),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryAdmin,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.select_all_rounded, size: 16),
                              label: Text(l10n.selectAllWithPhone),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _applyFilters();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                    itemCount:
                        displayedStudents.length + (notifier.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == displayedStudents.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        );
                      }

                      final student = displayedStudents[index];
                      return _buildStudentTile(context, student, isDark);
                    },
                  ),
                );
              },
            ),
          ),

          // ── Bottom SMS Message Composer Panel ──
          _buildComposerPanel(isDark, smsParts, maxSinglePart, studentsWithPhone),
        ],
      ),
    );
  }

  // ── Stat Badge Widget ──────────────────────────────────────────────────────

  Widget _buildStatBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : color,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Chip Widget ─────────────────────────────────────────────────────

  Widget _buildFilterChip({
    required String label,
    required String chipKey,
    required bool isDark,
    Color? badgeColor,
  }) {
    final isSelected = _selectedFilterChip == chipKey;
    final color = badgeColor ?? AppColors.primaryAdmin;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterChip = chipKey;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  // ── Student Tile Card ──────────────────────────────────────────────────────

  Widget _buildStudentTile(
    BuildContext context,
    Student student,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedStudentIds.contains(student.userId);
    final hasContact = student.guardianContact.isNotEmpty;
    final classSection = _getClassSectionText(context, student);
    final name = student.user?.name ?? l10n.unknownStudent;
    final avatarUrl = student.user?.avatar;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? AppColors.primaryAdmin
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      color: isSelected
          ? (isDark
              ? AppColors.primaryAdmin.withValues(alpha: 0.15)
              : AppColors.primaryAdmin.withValues(alpha: 0.05))
          : (isDark ? const Color(0xFF1E293B) : Colors.white),
      child: InkWell(
        onTap: () => _toggleSelection(student),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                activeColor: AppColors.primaryAdmin,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (_) => _toggleSelection(student),
              ),

              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryAdmin.withValues(alpha: 0.1),
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? CachedNetworkImageProvider(
                        avatarUrl,
                        cacheKey: avatarUrl.split('?').first,
                      )
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryAdmin,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Name & Status
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Class, Section & Roll
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            classSection,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        if (student.rollId.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.rollLabel(student.rollId),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Phone Contact Pill
                    Row(
                      children: [
                        Icon(
                          hasContact
                              ? Icons.phone_in_talk_rounded
                              : Icons.phonelink_erase_rounded,
                          size: 13,
                          color: hasContact ? Colors.teal : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hasContact
                                ? student.guardianContact
                                : l10n.noContactNumberRegistered,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: hasContact
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: hasContact
                                  ? (isDark
                                      ? Colors.teal.shade300
                                      : Colors.teal.shade800)
                                  : Colors.orange.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Composer Panel ──────────────────────────────────────────────────

  Widget _buildComposerPanel(
    bool isDark,
    int smsParts,
    int maxSinglePart,
    int studentsWithPhone,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final quickTemplates = _getQuickTemplates(l10n);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Controls: SMS Type & Templates Button ──
            Row(
              children: [
                // SMS Type Dropdown / Toggle
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _smsType,
                      isDense: true,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Normal SMS',
                          child: Text(l10n.normalSmsDirect),
                        ),
                        DropdownMenuItem(
                          value: 'Mask SMS',
                          child: Text(l10n.maskSmsCare),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _smsType = val);
                        }
                      },
                    ),
                  ),
                ),
                const Spacer(),

                // Quick Templates Button
                PopupMenuButton<Map<String, String>>(
                  tooltip: l10n.quickTemplateInsertTooltip,
                  onSelected: (template) {
                    _messageController.text = template['text'] ?? '';
                  },
                  itemBuilder: (context) => quickTemplates.map((t) {
                    return PopupMenuItem(
                      value: t,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['title']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t['text']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAdmin.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryAdmin.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.dashboard_customize_outlined,
                          size: 15,
                          color: AppColors.primaryAdmin,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.quickTemplatesTitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryAdmin,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Message Input ──
            TextField(
              controller: _messageController,
              maxLines: 3,
              minLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: l10n.typeMessageHint,
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.grey.shade900.withValues(alpha: 0.5)
                    : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryAdmin,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 6),

            // ── SMS Counter & Estimated Units ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.selectedRecipientsCount(_selectedStudentIds.length),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _selectedStudentIds.isNotEmpty
                        ? AppColors.primaryAdmin
                        : Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.text_fields_rounded,
                      size: 13,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      l10n.charsAndSmsCount(
                        _messageController.text.length,
                        maxSinglePart,
                        smsParts,
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Send Button ──
            ElevatedButton.icon(
              onPressed: (_isSending || _selectedStudentIds.isEmpty)
                  ? null
                  : _handleSendPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAdmin,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: _isSending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isSending
                    ? l10n.broadcastingSms
                    : l10n.sendBulkSmsButton(_selectedStudentIds.length),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shimmer Loader ─────────────────────────────────────────────────────────

  Widget _buildShimmerLoader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const CircleAvatar(radius: 20, backgroundColor: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 90,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

