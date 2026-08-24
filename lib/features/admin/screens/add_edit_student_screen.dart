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

  String? _selectedClassId;
  String? _selectedSectionId;

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

      if (s.classId.isNotEmpty) {
        _selectedClassId = s.classId;
      } else if (s.user?.classIds.isNotEmpty == true) {
        _selectedClassId = s.user!.classIds.first;
      }

      if (s.sectionId.isNotEmpty) {
        _selectedSectionId = s.sectionId;
      } else if (s.user?.sectionIds.isNotEmpty == true) {
        _selectedSectionId = s.user!.sectionIds.first;
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

      final selectedClassIds = _selectedClassId != null && _selectedClassId!.isNotEmpty
          ? [_selectedClassId!]
          : <String>[];
      final selectedSectionIds = _selectedSectionId != null && _selectedSectionId!.isNotEmpty
          ? [_selectedSectionId!]
          : <String>[];

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

    // Sections filtered to only those belonging to the selected class
    final filteredSections = _selectedClassId == null || _selectedClassId!.isEmpty
        ? <Section>[]
        : allSections
            .where((s) => s.classId == _selectedClassId)
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

            // ── Class Dropdown ───────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: classes.any((c) => c.id == _selectedClassId)
                  ? _selectedClassId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Class',
                prefixIcon: const Icon(Icons.class_),
                hintText: isClassesLoading
                    ? 'Loading classes...'
                    : (classes.isEmpty ? 'No classes available' : 'Select Class'),
                suffixIcon: isClassesLoading
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
                    : null,
              ),
              items: classes.map((c) {
                return DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: isClassesLoading
                  ? null
                  : (val) {
                      setState(() {
                        _selectedClassId = val;
                        // Reset section if it does not belong to the selected class
                        if (_selectedSectionId != null) {
                          final currentSection = allSections.firstWhere(
                            (s) => s.id == _selectedSectionId,
                            orElse: () => Section(id: '', classId: '', name: ''),
                          );
                          if (currentSection.classId != val) {
                            _selectedSectionId = null;
                          }
                        }
                      });
                    },
              validator: (val) =>
                  (val == null || val.isEmpty) ? 'Please select a class' : null,
            ),
            const SizedBox(height: 16),

            // ── Section Dropdown ─────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: filteredSections.any((s) => s.id == _selectedSectionId)
                  ? _selectedSectionId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Section',
                prefixIcon: const Icon(Icons.meeting_room),
                hintText: _selectedClassId == null
                    ? 'Select a class first'
                    : (isSectionsLoading
                        ? 'Loading sections...'
                        : (filteredSections.isEmpty
                            ? 'No sections in this class'
                            : 'Select Section')),
                suffixIcon: isSectionsLoading
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
                    : null,
              ),
              items: filteredSections.map((s) {
                return DropdownMenuItem<String>(
                  value: s.id,
                  child: Text(s.name),
                );
              }).toList(),
              onChanged: (_selectedClassId == null ||
                      isSectionsLoading ||
                      filteredSections.isEmpty)
                  ? null
                  : (val) {
                      setState(() {
                        _selectedSectionId = val;
                      });
                    },
              validator: (val) {
                if (_selectedClassId == null) {
                  return 'Please select class first';
                }
                if (filteredSections.isNotEmpty && (val == null || val.isEmpty)) {
                  return 'Please select a section';
                }
                return null;
              },
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

