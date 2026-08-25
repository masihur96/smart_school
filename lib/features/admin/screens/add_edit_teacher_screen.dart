import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_school/core/utils/image_compress_utils.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/student_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';

import '../../../models/teacher_model.dart';
import '../providers/setup_provider.dart';
import '../providers/teacher_provider.dart';
import 'admin_pricing_plan_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddEditTeacherScreen extends StatefulWidget {
  final Teacher? teacher;
  const AddEditTeacherScreen({super.key, this.teacher});

  @override
  State<AddEditTeacherScreen> createState() => _AddEditTeacherScreenState();
}

class _AddEditTeacherScreenState extends State<AddEditTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isFetchingLocation = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _radiusController = TextEditingController();

  final List<AssignedSubject> _assignedSubjects = [];
  bool _obscurePassword = true;
  bool _isLoading = false;
  File? _imageFile;
  String? _existingImageUrl;
  String _selectedRole = 'teacher';

  bool get isEditing => widget.teacher != null;

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
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
    if (!isEditing) {
      // Required when adding a new user
      if (value == null || value.isEmpty) {
        return 'Please enter password';
      }
      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
    } else {
      // Optional when editing — only validate if the user typed something
      if (value != null && value.isNotEmpty && value.length < 6) {
        return 'Password must be at least 6 characters';
      }
    }
    return null;
  }

  String? _validateDesignation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter designation';
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
    if (isEditing) {
      final teacher = widget.teacher!;
      _nameController.text = teacher.user?.name ?? '';
      _emailController.text = teacher.user?.email ?? '';
      _phoneController.text = teacher.user?.phone ?? '';
      _designationController.text = teacher.designation;

      _latController.text = teacher.lat?.toString() ?? '';
      _lonController.text = teacher.lon?.toString() ?? '';
      _radiusController.text = teacher.radius?.toString() ?? '';
      final avatar = teacher.user?.avatar?.trim();
      _existingImageUrl = _isValidImageUrl(avatar) ? avatar : null;
      // Pre-select the role from the existing teacher data
      _selectedRole = teacher.user?.role.name ?? 'teacher';
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
    _designationController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          _latController.text = position.latitude.toString();
          _lonController.text = position.longitude.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.locationFetchedSuccessfully,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorGettingLocation}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
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

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (!isEditing) {
        final authNotifier = context.read<AuthNotifier>();
        final adminSubscription = authNotifier.adminSubscription;
        final teacherNotifier = context.read<TeachersNotifier>();
        final studentNotifier = context.read<StudentsNotifier>();

        if (adminSubscription != null &&
            adminSubscription.pricingPlan != null) {
          final maxStudents = adminSubscription.pricingPlan!.maxStudents;
          print(maxStudents);
          print(teacherNotifier.totalCount);
          print(studentNotifier.totalCount);

          int totalUser =
              teacherNotifier.totalCount + studentNotifier.totalCount;
          print(totalUser);

          if (totalUser >= maxStudents) {
            _showLimitReachedDialog();
            return;
          }
        }
      }

      setState(() {
        _isLoading = true;
      });

      final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
      final teacherNotifier = context.read<TeachersNotifier>();

      try {
        if (isEditing) {
          await teacherNotifier.updateTeacherOnAPI(
            userId: widget.teacher!.userId,
            name: _nameController.text.trim(),
            email: _emailController.text.trim().toLowerCase(),
            phone: _phoneController.text.trim(),
            designation: _designationController.text.trim(),
            role: _selectedRole,
            password: _passwordController.text.trim().isNotEmpty
                ? _passwordController.text.trim()
                : null,
            lat: double.tryParse(_latController.text),
            lon: double.tryParse(_lonController.text),
            radius: double.tryParse(_radiusController.text),
            imageFile: _imageFile,
          );
        } else {
          await teacherNotifier.addTeacherToAPI(
            name: _nameController.text.trim(),
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text,
            role: _selectedRole,
            schoolId: schoolId,
            phone: _phoneController.text.trim(),
            designation: _designationController.text.trim(),
            lat: double.tryParse(_latController.text),
            lon: double.tryParse(_lonController.text),
            radius: double.tryParse(_radiusController.text),
            imageFile: _imageFile,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? AppLocalizations.of(context)!.teacherUpdatedSuccessfully
                    : AppLocalizations.of(
                        context,
                      )!.teacherRegisteredSuccessfully,
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${isEditing ? AppLocalizations.of(context)!.updateFailed : AppLocalizations.of(context)!.registrationFailed}: $e',
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
    final sections = context.watch<SectionSetupNotifier>().sections;
    final teacherNotifier = context.watch<TeachersNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? AppLocalizations.of(context)!.editTeacher
              : AppLocalizations.of(context)!.registerTeacher,
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 24),
            // Personal Details Section
            _buildSectionHeader(
              context,
              'Personal Details',
              Icons.person_outline,
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        hintText: 'e.g. Dr. John Doe',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email),
                        hintText: 'e.g. teacher@school.edu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        hintText: 'e.g. +8801712345678',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),
                    // Role Selector
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'teacher',
                          child: Row(
                            children: [
                              Icon(Icons.school_outlined, size: 20, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('Teacher'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Row(
                            children: [
                              Icon(Icons.manage_accounts_outlined, size: 20, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('Admin'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRole = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a role';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Account Security Section
            _buildSectionHeader(
              context,
              isEditing ? 'Change Password' : 'Account Security',
              Icons.lock_outline,
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: isEditing ? 'New Password (optional)' : 'Password',
                    prefixIcon: const Icon(Icons.security),
                    hintText: isEditing
                        ? 'Leave blank to keep current password'
                        : 'At least 6 characters',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.next,
                  validator: _validatePassword,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Professional Details Section
            _buildSectionHeader(
              context,
              'Professional Details',
              Icons.work_outline,
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _designationController,
                      decoration: InputDecoration(
                        labelText: 'Designation',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        hintText: 'e.g. Senior Lecturer, Mathematics',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validateDesignation,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(
                  context,
                  'Arrival Settings',
                  Icons.location_on_outlined,
                ),
                _isFetchingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.purple,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.location_on_outlined),
                      ),
              ],
            ),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Latitude',
                              prefixIcon: const Icon(Icons.map_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lonController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Longitude',
                              prefixIcon: const Icon(Icons.explore_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Allowed Radius (meters)',
                        prefixIcon: const Icon(Icons.radar_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Radius in meters for arrival check',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditing
                            ? AppLocalizations.of(context)!.updateTeacher
                            : AppLocalizations.of(context)!.registerTeacher,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
