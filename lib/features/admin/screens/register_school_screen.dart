import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/admin/providers/school_provider.dart';
import 'package:smart_school/features/admin/screens/onboarding_progress_screen.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';

class AdminRegisterSchoolScreen extends StatefulWidget {
  const AdminRegisterSchoolScreen({Key? key}) : super(key: key);

  @override
  State<AdminRegisterSchoolScreen> createState() =>
      _AdminRegisterSchoolScreenState();
}

class _AdminRegisterSchoolScreenState extends State<AdminRegisterSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  File? _logoFile;

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
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
      final XFile? file = await picker.pickImage(source: source);
      if (file != null) {
        setState(() {
          _logoFile = File(file.path);
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = context.read<AuthNotifier>();
    final schoolId = authNotifier.user?.schoolId;

    if (schoolId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorNoSchoolIdAssigned)),
        );
      }
      return;
    }

    final success = await context.read<AdminSchoolNotifier>().registerSchool(
          schoolId: schoolId,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          logoFile: _logoFile,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.schoolRegisteredSuccessfully)),
      );
      // Navigate to onboarding progress screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingProgressScreen()),
      );
    } else if (mounted) {
      final error = context.read<AdminSchoolNotifier>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? AppLocalizations.of(context)!.failedToRegisterSchool)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AdminSchoolNotifier>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.registerSchool),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context)!.completeYourSchoolProfile,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickLogo,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        backgroundImage:
                            _logoFile != null ? FileImage(_logoFile!) : null,
                        child: _logoFile == null
                            ? const Icon(
                                Icons.add_a_photo,
                                size: 30,
                                color: Colors.purple,
                              )
                            : null,
                      ),
                    ),
                    if (_logoFile != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.schoolName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.school),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.address,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.phone,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return AppLocalizations.of(context)!.requiredField;
                  if (!v.contains('@')) return AppLocalizations.of(context)!.enterValidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        AppLocalizations.of(context)!.registerSchoolAction,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
