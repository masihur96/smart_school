import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_school/core/utils/image_compress_utils.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/features/admin/providers/teacher_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';

import '../../../models/school_models.dart';
import '../../../models/student_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/setup_provider.dart';
import 'admin_pricing_plan_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  final List<String> _selectedClassIds = [];
  final List<String> _selectedSectionIds = [];

  bool _obscurePassword = true;
  bool _isLoading = false;
  File? _imageFile;
  String? _existingImageUrl;

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter student name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateRollId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter roll number';
    }
    return null;
  }

  String? _validateAbout(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter about / description for student';
    }
    if (value.trim().length < 3) {
      return 'About must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter email address';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter phone number';
    }
    final cleanPhone = value.trim().replaceAll(RegExp(r'[\s-]'), '');
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (widget.student == null) {
      if (value == null || value.isEmpty) {
        return 'Please enter password';
      }
      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
    } else if (value != null && value.isNotEmpty && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  bool _isValidImageUrl(String? url) {
    if (url == null) return false;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      final s = widget.student!;
      _nameController.text = s.user?.name ?? '';
      _emailController.text = s.user?.email ?? '';
      _phoneController.text = s.user?.phone ?? s.guardianContact;
      _aboutController.text = s.user?.designation ?? '';
      _rollIdController.text = s.rollId;
      final avatar = s.user?.avatar?.trim();
      _existingImageUrl = _isValidImageUrl(avatar) ? avatar : null;

      // Load existing class IDs
      if (s.user?.classIds.isNotEmpty == true) {
        _selectedClassIds.addAll(s.user!.classIds);
      } else if (s.classId.isNotEmpty) {
        _selectedClassIds.add(s.classId);
      }

      // Load existing section IDs
      if (s.user?.sectionIds.isNotEmpty == true) {
        _selectedSectionIds.addAll(s.user!.sectionIds);
      } else if (s.sectionId.isNotEmpty) {
        _selectedSectionIds.add(s.sectionId);
      }
    }

    // Auto-fetch classes and sections if not already in memory
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      final schoolId = user?.schoolId ?? '';
      final classNotifier = context.read<ClassSetupNotifier>();
      final sectionNotifier = context.read<SectionSetupNotifier>();

      if (classNotifier.classes.isEmpty && !classNotifier.isLoading) {
        if (schoolId.isNotEmpty) {
          classNotifier.fetchClasses(schoolId);
        } else {
          classNotifier.fetchSchoolData();
        }
      }
      if (sectionNotifier.sections.isEmpty && !sectionNotifier.isLoading) {
        sectionNotifier.fetchSections();
      }
    });
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
        imageQuality: 85,
      );
      if (pickedFile != null) {
        // Compress to under 50 KB before upload
        final File compressed = await ImageCompressUtils.compressToUnder50KB(
          File(pickedFile.path),
        );
        setState(() {
          _imageFile = compressed;
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

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (widget.student == null) {
        final authNotifier = context.read<AuthNotifier>();
        final adminSubscription = authNotifier.adminSubscription;
        final studentNotifier = context.read<StudentsNotifier>();
        final teacherNotifier = context.read<TeachersNotifier>();

        int totalUser = teacherNotifier.totalCount + studentNotifier.totalCount;

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

      final selectedClassIds = List<String>.from(_selectedClassIds);
      final selectedSectionIds = List<String>.from(_selectedSectionIds);

      try {
        if (widget.student != null) {
          await context.read<StudentsNotifier>().updateStudentToAPI(
            userId: widget.student!.userId,
            name: _nameController.text.trim(),
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text,
            phone: _phoneController.text.trim(),
            classIds: selectedClassIds,
            sectionIds: selectedSectionIds,
            rollId: _rollIdController.text.trim(),
            designation: _aboutController.text.trim(),
            imageFile: _imageFile,
          );
        } else {
          await context.read<StudentsNotifier>().addStudentToAPI(
            name: _nameController.text.trim(),
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text,
            role: 'student',
            schoolId: schoolId,
            phone: _phoneController.text.trim(),
            classIds: selectedClassIds,
            sectionIds: selectedSectionIds,
            rollId: _rollIdController.text.trim(),
            designation: _aboutController.text.trim(),
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
    final classNotifier = context.watch<ClassSetupNotifier>();
    final sectionNotifier = context.watch<SectionSetupNotifier>();
    final classes = classNotifier.classes;
    final allSections = sectionNotifier.sections;

    final isClassesLoading = classNotifier.isLoading;
    final isSectionsLoading = sectionNotifier.isLoading;

    // Sections filtered to those belonging to ANY selected class
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
                    child: Builder(
                      builder: (context) {
                        final hasValidNetworkImage = _isValidImageUrl(_existingImageUrl);
                        final ImageProvider? avatarImage = _imageFile != null
                            ? FileImage(_imageFile!)
                            : (hasValidNetworkImage
                                ? CachedNetworkImageProvider(
                                    _existingImageUrl!,
                                    cacheKey: _existingImageUrl!.split('?').first,
                                  )
                                : null);

                        return CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          backgroundImage: avatarImage,
                          onBackgroundImageError: avatarImage != null
                              ? (_, __) {
                                  // Gracefully handle broken or unreachable URLs
                                }
                              : null,
                          child: (_imageFile == null && !hasValidNetworkImage)
                              ? const Icon(
                                  Icons.person_add_alt_1,
                                  size: 40,
                                  color: Colors.purple,
                                )
                              : null,
                        );
                      },
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
                hintText: 'e.g. John Doe',
              ),
              textInputAction: TextInputAction.next,
              validator: _validateName,
            ),
            const SizedBox(height: 16),

            // ── Multi-Select Class Picker ────────────────────────────────────
            _MultiSelectField(
              label: 'Class',
              icon: Icons.class_,
              isLoading: isClassesLoading,
              emptyHint: classes.isEmpty ? 'No classes available' : 'Select Classes',
              allItems: classes.map((c) => _SelectItem(id: c.id, name: c.name)).toList(),
              selectedIds: _selectedClassIds,
              onChanged: (ids) {
                setState(() {
                  _selectedClassIds
                    ..clear()
                    ..addAll(ids);
                  // Remove sections that no longer belong to any selected class
                  _selectedSectionIds.removeWhere(
                    (sid) => !allSections
                        .any((s) => s.id == sid && ids.contains(s.classId)),
                  );
                });
              },
              validator: (_) => _selectedClassIds.isEmpty
                  ? 'Please select at least one class'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Multi-Select Section Picker ──────────────────────────────────
            _MultiSelectField(
              label: 'Section',
              icon: Icons.meeting_room,
              isLoading: isSectionsLoading,
              emptyHint: _selectedClassIds.isEmpty
                  ? 'Select a class first'
                  : (filteredSections.isEmpty
                      ? 'No sections in selected class(es)'
                      : 'Select Sections'),
              allItems: filteredSections
                  .map((s) => _SelectItem(id: s.id, name: s.name))
                  .toList(),
              selectedIds: _selectedSectionIds,
              onChanged: (ids) {
                setState(() {
                  _selectedSectionIds
                    ..clear()
                    ..addAll(ids);
                });
              },
              validator: (_) {
                if (_selectedClassIds.isEmpty) {
                  return 'Please select class first';
                }
                if (filteredSections.isNotEmpty && _selectedSectionIds.isEmpty) {
                  return 'Please select at least one section';
                }
                return null;
              },
              enabled: _selectedClassIds.isNotEmpty,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _rollIdController,
              decoration: const InputDecoration(
                labelText: 'Roll Number',
                prefixIcon: Icon(Icons.numbers),
                hintText: 'e.g. 101',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: _validateRollId,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aboutController,
              decoration: const InputDecoration(
                labelText: 'About (e.g. About Student)',
                prefixIcon: Icon(Icons.badge),
                hintText: 'e.g. Student Bio or Notes',
              ),
              textInputAction: TextInputAction.next,
              validator: _validateAbout,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email),
                hintText: 'e.g. student@school.edu',
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone),
                hintText: 'e.g. +8801712345678',
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: _validatePhone,
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
                hintText: 'At least 6 characters',
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
              textInputAction: TextInputAction.done,
              validator: _validatePassword,
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

// ── Helper data class ────────────────────────────────────────────────────────
class _SelectItem {
  final String id;
  final String name;
  const _SelectItem({required this.id, required this.name});
}

// ── Reusable multi-select field widget ───────────────────────────────────────
class _MultiSelectField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final String emptyHint;
  final List<_SelectItem> allItems;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final FormFieldValidator<List<String>>? validator;
  final bool enabled;

  const _MultiSelectField({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.emptyHint,
    required this.allItems,
    required this.selectedIds,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  void _openBottomSheet(BuildContext context) {
    final tempSelected = List<String>.from(selectedIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.55,
              minChildSize: 0.35,
              maxChildSize: 0.85,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Handle bar
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Title row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Row(
                        children: [
                          Icon(icon, color: Colors.purple),
                          const SizedBox(width: 10),
                          Text(
                            'Select $label',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setModalState(() => tempSelected.clear());
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(color: Colors.purple),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // List
                    Expanded(
                      child: allItems.isEmpty
                          ? Center(
                              child: Text(
                                emptyHint,
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: allItems.length,
                              itemBuilder: (_, i) {
                                final item = allItems[i];
                                final isChecked =
                                    tempSelected.contains(item.id);
                                return CheckboxListTile(
                                  value: isChecked,
                                  title: Text(item.name),
                                  activeColor: Colors.purple,
                                  onChanged: (checked) {
                                    setModalState(() {
                                      if (checked == true) {
                                        tempSelected.add(item.id);
                                      } else {
                                        tempSelected.remove(item.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    // Confirm button
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              onChanged(List<String>.from(tempSelected));
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              'Confirm (${tempSelected.length} selected)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedNames = allItems
        .where((item) => selectedIds.contains(item.id))
        .map((item) => item.name)
        .toList();

    return FormField<List<String>>(
      initialValue: selectedIds,
      validator: validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: (enabled && !isLoading && allItems.isNotEmpty)
                  ? () => _openBottomSheet(context)
                  : null,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon),
                  hintText: emptyHint,
                  suffixIcon: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.purple,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.arrow_drop_down,
                          color: enabled ? Colors.purple : Colors.grey,
                        ),
                  errorText: field.errorText,
                  enabled: enabled && !isLoading,
                ),
                isEmpty: selectedNames.isEmpty,
                child: selectedNames.isEmpty
                    ? Text(
                        emptyHint,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: selectedNames.map((name) {
                          return Chip(
                            label: Text(
                              name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor:
                                Colors.purple.withOpacity(0.12),
                            side: BorderSide(
                              color: Colors.purple.withOpacity(0.4),
                            ),
                            deleteIconColor: Colors.purple,
                            onDeleted: () {
                              final item = allItems.firstWhere(
                                  (i) => i.name == name);
                              final newIds = List<String>.from(selectedIds)
                                ..remove(item.id);
                              onChanged(newIds);
                            },
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
