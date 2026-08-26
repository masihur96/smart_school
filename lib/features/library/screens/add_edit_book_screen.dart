import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_school/core/utils/image_compress_utils.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/features/library/data/models/book.dart';
import 'package:smart_school/features/library/providers/library_book_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class AddEditBookScreen extends StatefulWidget {
  final Book? book;
  final bool isAdminOrTeacher;

  const AddEditBookScreen({super.key, this.book, this.isAdminOrTeacher = true});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _coverImageController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Mathematics',
    'Science',
    'History',
    'Literature',
    'Computer Science',
    'Arts',
    'Geography',
    'Languages',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.author;
      _isbnController.text = widget.book!.isbn;
      _coverImageController.text = widget.book!.coverImageUrl;
      _descriptionController.text = widget.book!.description;
      _selectedCategory = widget.book!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _coverImageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveBook() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.selectCategoryError)),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final bookData = {
          "title": _titleController.text.trim(),
          "author": _authorController.text.trim(),
          "isbn": _isbnController.text.trim(),
          "category": _selectedCategory,
          "coverImageUrl": _coverImageController.text.trim(),
          "isAvailable": widget.book?.isAvailable ?? true,
          "description": _descriptionController.text.trim(),
        };

        Book savedBook;
        final notifier = context.read<LibraryBookNotifier>();

        if (widget.book == null) {
          savedBook = await notifier.addBook(bookData);
        } else {
          savedBook = await notifier.updateBook(widget.book!.id, bookData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text(
                widget.book == null
                    ? l10n.bookAddedSuccess
                    : l10n.bookUpdatedSuccess,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
          Navigator.pop(context, savedBook);
        }
      } catch (e) {
        debugPrint('Error saving book: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text(
                e.toString().replaceFirst('Exception: ', ''),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        // Compress to under 50 KB before upload
        final File compressed = await ImageCompressUtils.compressToUnder50KB(
          File(pickedFile.path),
        );
        final token = await StorageService.getToken();
        final uploadFormData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            compressed.path,
            filename: compressed.path.split('/').last,
          ),
        });

        final uploadResponse = await DataProvider().performRequest(
          'POST',
          'https://smart-school-backend-production.up.railway.app/general/upload',
          header: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
          data: uploadFormData,
        );

        if (uploadResponse != null &&
            (uploadResponse.statusCode == 200 ||
                uploadResponse.statusCode == 201)) {
          final url = uploadResponse.data['data']['url'];
          if (url != null) {
            setState(() {
              _coverImageController.text = url;
            });
          }
        } else {
          throw Exception(uploadResponse?.data ?? 'Failed to upload image');
        }
      } catch (e) {
        debugPrint('Image upload error: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.failedToUploadImage(e.toString()))));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showImageOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                ),
                title: Text(l10n.generateRandomCover),
                onTap: () {
                  Navigator.pop(context);
                  final randomId = const Uuid().v4().substring(0, 8);
                  final url = 'https://picsum.photos/seed/$randomId/400/600';
                  _coverImageController.text = url;
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: Text(l10n.pickFromGallery),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text(l10n.takeAPhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book == null ? l10n.addBookTitle : l10n.editBookTitle),
        backgroundColor: widget.isAdminOrTeacher
            ? AppColors.primaryAdmin
            : AppColors.primaryTeacher,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(l10n.basicDetails),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _titleController,
                label: l10n.bookTitleLabel,
                hint: l10n.bookTitleHint,
                icon: Icons.menu_book,
                validator: (val) =>
                    val == null || val.isEmpty ? l10n.titleRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _authorController,
                label: l10n.authorNameLabel,
                hint: l10n.authorNameHint,
                icon: Icons.person_outline,
                validator: (val) =>
                    val == null || val.isEmpty ? l10n.authorRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _isbnController,
                label: l10n.isbnNumberLabel,
                hint: l10n.isbnNumberHint,
                icon: Icons.qr_code,
                validator: (val) =>
                    val == null || val.isEmpty ? l10n.isbnRequired : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(l10n.additionalInfo),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _buildInputDecoration(l10n.categoryLabel, Icons.category),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) =>
                    val == null ? l10n.selectCategoryError : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _coverImageController,
                label: l10n.coverImageLabel,
                hint: l10n.coverImageHint,
                icon: Icons.image_outlined,
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.add_photo_alternate,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Image Options',
                  onPressed: _showImageOptions,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return l10n.coverImageRequired;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: l10n.descriptionLabel,
                hint: l10n.descriptionHint,
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isAdminOrTeacher
                        ? AppColors.primaryAdmin
                        : AppColors.primaryTeacher,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.saveBookButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: _buildInputDecoration(
        label,
        icon,
        suffixIcon: suffixIcon,
      ).copyWith(hintText: hint),
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      filled: true,
    );
  }
}
