import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/features/admin/providers/teacher_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';

import '../../../models/school_models.dart';
import '../../../models/student_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/setup_provider.dart';
import 'admin_pricing_plan_screen.dart';

class AddEditStudentScreen extends StatefulWidget {
  final Student? student;
  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _phoneController = TextEditingController();
  final _aboutController = TextEditingController();
  final _rollIdController = TextEditingController();

  /// Multi-select state
  List<String> _selectedClassIds = [];
  List<String> _selectedSectionIds = [];

  bool _obscurePassword = true;
  bool _isLoading = false;
  File? _imageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      final s = widget.student!;
      _nameController.text = s.user?.name ?? '';
      _emailController.text = s.user?.email ?? '';
      _phoneController.text = s.user?.phone ?? s.guardianContact;
      _rollIdController.text = s.rollId;
      _existingImageUrl = s.user?.avatar;

      if (s.classId.isNotEmpty) _selectedClassIds = [s.classId];
      if (s.sectionId.isNotEmpty) _selectedSectionIds = [s.sectionId];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.galleryOption),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.cameraOption),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 50,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    _phoneController.dispose();
    _aboutController.dispose();
    _rollIdController.dispose();
    super.dispose();
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Reached'),
        content: const Text(
          'You have reached the maximum limit of your current pricing plan. Please upgrade to add more.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminPricingPlanScreen(),
                ),
              );
            },
            child: const Text('Upgrade', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Multi-select bottom sheet for classes ──────────────────────────────────

  Future<void> _showClassPicker(List<ClassRoom> classes) async {
    final tempSelected = List<String>.from(_selectedClassIds);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              maxChildSize: 0.85,
              builder: (_, scrollCtrl) => Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.class_, color: Colors.purple),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Select Classes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Done',
                            style: TextStyle(color: Colors.purple),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: classes.length,
                      itemBuilder: (_, i) {
                        final cls = classes[i];
                        final isSelected = tempSelected.contains(cls.id);
                        return CheckboxListTile(
                          activeColor: Colors.purple,
                          value: isSelected,
                          title: Text(cls.name),
                          secondary: CircleAvatar(
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            child: Text(
                              cls.name.isNotEmpty
                                  ? cls.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onChanged: (checked) {
                            setModal(() {
                              if (checked == true) {
                                tempSelected.add(cls.id);
                              } else {
                                tempSelected.remove(cls.id);
                                // Also remove sections that belong to this class
                                final allSections =
                                    context
                                        .read<SectionSetupNotifier>()
                                        .sections;
                                final sectionIdsForClass = allSections
                                    .where((s) => s.classId == cls.id)
                                    .map((s) => s.id)
                                    .toSet();
                                _selectedSectionIds.removeWhere(
                                  (id) => sectionIdsForClass.contains(id),
                                );
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    setState(() {
      _selectedClassIds = tempSelected;
      // clean up orphan sections
      final allSections = context.read<SectionSetupNotifier>().sections;
      _selectedSectionIds = _selectedSectionIds.where((sid) {
        final section = allSections.firstWhere(
          (s) => s.id == sid,
          orElse: () => Section(id: '', classId: '', name: ''),
        );
        return _selectedClassIds.contains(section.classId);
      }).toList();
    });
  }

  // ─── Multi-select bottom sheet for sections ─────────────────────────────────

  Future<void> _showSectionPicker(List<Section> filteredSections) async {
    if (_selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one class first')),
      );
      return;
    }

    final tempSelected = List<String>.from(_selectedSectionIds);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              maxChildSize: 0.85,
              builder: (_, scrollCtrl) => Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.meeting_room, color: Colors.purple),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Select Sections',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Done',
                            style: TextStyle(color: Colors.purple),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  filteredSections.isEmpty
                      ? const Expanded(
                          child: Center(
                            child: Text(
                              'No sections available for selected classes',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            controller: scrollCtrl,
                            itemCount: filteredSections.length,
                            itemBuilder: (_, i) {
                              final sec = filteredSections[i];
                              final isSelected = tempSelected.contains(sec.id);
                              return CheckboxListTile(
                                activeColor: Colors.purple,
                                value: isSelected,
                                title: Text(sec.name),
                                subtitle: Text(
                                  'Class: ${_classNameForId(context.read<ClassSetupNotifier>().classes, sec.classId)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                secondary: CircleAvatar(
                                  backgroundColor:
                                      Colors.purple.withOpacity(0.1),
                                  child: Text(
                                    sec.name.isNotEmpty
                                        ? sec.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                onChanged: (checked) {
                                  setModal(() {
                                    if (checked == true) {
                                      tempSelected.add(sec.id);
                                    } else {
                                      tempSelected.remove(sec.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );

    setState(() => _selectedSectionIds = tempSelected);
  }

  String _classNameForId(List<ClassRoom> classes, String classId) {
    try {
      return classes.firstWhere((c) => c.id == classId).name;
    } catch (_) {
      return classId;
    }
  }

  // ─── Build chip display for selected items ──────────────────────────────────

  Widget _buildMultiSelectField({
    required String label,
    required IconData icon,
    required List<String> selectedIds,
    required List<String> Function(String id) getLabel,
    required VoidCallback onTap,
    required String? Function(List<String> val) validator,
  }) {
    return FormField<List<String>>(
      initialValue: selectedIds,
      validator: (_) => validator(selectedIds),
      builder: (state) {
        return GestureDetector(
          onTap: () async {
            await Future.microtask(onTap);
            state.didChange(selectedIds);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              errorText: state.errorText,
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: selectedIds.isEmpty
                ? Text(
                    'Tap to select $label',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: selectedIds.map((id) {
                      final labels = getLabel(id);
                      final displayLabel =
                          labels.isNotEmpty ? labels.first : id;
                      return Chip(
                        label: Text(
                          displayLabel,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.purple.withOpacity(0.12),
                        labelStyle: const TextStyle(color: Colors.purple),
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.purple,
                        ),
                        onDeleted: () {
                          setState(() {
                            selectedIds.remove(id);
                          });
                          state.didChange(selectedIds);
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
          ),
        );
      },
    );
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (widget.student == null) {
        final authNotifier = context.read<AuthNotifier>();
        final adminSubscription = authNotifier.adminSubscription;
        final studentNotifier = context.read<StudentsNotifier>();
        final teacherNotifier = context.read<TeachersNotifier>();

        int totalUser =
            teacherNotifier.totalCount + studentNotifier.totalCount;

        if (adminSubscription != null &&
            adminSubscription.pricingPlan != null) {
          final maxStudents = adminSubscription.pricingPlan!.maxStudents;
          if (totalUser >= maxStudents) {
            _showLimitReachedDialog();
            return;
          }
        }
      }

      setState(() {
        _isLoading = true;
      });
      final user = context.read<AuthNotifier>().user;
      final schoolId = user?.schoolId ?? '';

      try {
        if (widget.student != null) {
          await context.read<StudentsNotifier>().updateStudentToAPI(
            userId: widget.student!.userId,
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            phone: _phoneController.text,
            classIds: _selectedClassIds,
            sectionIds: _selectedSectionIds,
            rollId: _rollIdController.text,
            designation: _aboutController.text,
            imageFile: _imageFile,
          );
        } else {
          await context.read<StudentsNotifier>().addStudentToAPI(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            role: 'student',
            schoolId: schoolId,
            phone: _phoneController.text,
            classIds: _selectedClassIds,
            sectionIds: _selectedSectionIds,
            rollId: _rollIdController.text,
            designation: _aboutController.text,
            imageFile: _imageFile,
          );
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.errorLabel(e.toString()),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassSetupNotifier>().classes;
    final allSections = context.watch<SectionSetupNotifier>().sections;

    // Sections filtered to only those belonging to the selected classes
    final filteredSections = _selectedClassIds.isEmpty
        ? <Section>[]
        : allSections
            .where((s) => _selectedClassIds.contains(s.classId))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.student != null
              ? AppLocalizations.of(context)!.editStudent
              : AppLocalizations.of(context)!.addStudent,
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.purple.withOpacity(0.1),
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_existingImageUrl != null
                                    ? NetworkImage(_existingImageUrl!)
                                    : null)
                                as ImageProvider?,
                      child: (_imageFile == null && _existingImageUrl == null)
                          ? const Icon(
                              Icons.person_add_alt_1,
                              size: 40,
                              color: Colors.purple,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (val) => val!.isEmpty ? 'Please enter name' : null,
            ),
            const SizedBox(height: 16),

            // ── Multi-select: Class ───────────────────────────────────────────
            _buildMultiSelectField(
              label: 'Class',
              icon: Icons.class_,
              selectedIds: _selectedClassIds,
              getLabel: (id) {
                try {
                  return [classes.firstWhere((c) => c.id == id).name];
                } catch (_) {
                  return [id];
                }
              },
              onTap: () => _showClassPicker(classes),
              validator: (val) =>
                  val.isEmpty ? 'Please select at least one class' : null,
            ),
            const SizedBox(height: 16),

            // ── Multi-select: Section ─────────────────────────────────────────
            _buildMultiSelectField(
              label: 'Section',
              icon: Icons.meeting_room,
              selectedIds: _selectedSectionIds,
              getLabel: (id) {
                try {
                  return [
                    filteredSections.firstWhere((s) => s.id == id).name,
                  ];
                } catch (_) {
                  return [id];
                }
              },
              onTap: () => _showSectionPicker(filteredSections),
              validator: (val) =>
                  val.isEmpty ? 'Please select at least one section' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _rollIdController,
              decoration: const InputDecoration(
                labelText: 'Roll Number',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (val) =>
                  val!.isEmpty ? 'Please enter roll number' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aboutController,
              decoration: const InputDecoration(
                labelText: 'About (e.g. About Student)',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (val) => val!.isEmpty ? 'Please enter email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (val) => val!.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: widget.student != null
                    ? 'Password (leave blank to keep current)'
                    : 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              keyboardType: TextInputType.visiblePassword,
              validator: (val) {
                if (widget.student == null && (val == null || val.isEmpty)) {
                  return 'Please enter password';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.student != null
                          ? AppLocalizations.of(context)!.updateStudent
                          : AppLocalizations.of(context)!.saveStudent,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
