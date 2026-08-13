import 'package:flutter/material.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/library/models/book.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
class AddEditBookScreen extends StatefulWidget {
  final Book? book;
  final bool isAdminOrTeacher;

  const AddEditBookScreen({
    super.key,
    this.book,
    this.isAdminOrTeacher = true,
  });

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
    'Others'
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
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        if (widget.book == null) {
          // Create book using the API
          await Dio().post(
            'https://smart-school-backend-production.up.railway.app/library/books',
            data: {
              "title": _titleController.text.trim(),
              "author": _authorController.text.trim(),
              "isbn": _isbnController.text.trim(),
              "category": _selectedCategory,
              "coverImageUrl": _coverImageController.text.trim(),
              "isAvailable": true,
              "description": _descriptionController.text.trim(),
            },
            options: Options(
              headers: {
                'accept': '*/*',
                'Content-Type': 'application/json',
              },
            ),
          );
        } else {
          // Simulate a network request for editing
          await Future.delayed(const Duration(seconds: 1));
        }

        final newBook = Book(
          id: widget.book?.id ?? const Uuid().v4(),
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          isbn: _isbnController.text.trim(),
          category: _selectedCategory!,
          coverImageUrl: _coverImageController.text.trim(),
          description: _descriptionController.text.trim(),
          isAvailable: widget.book?.isAvailable ?? true,
        );

        if (mounted) {
          Navigator.pop(context, newBook);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving book: $e')),
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
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _coverImageController.text = pickedFile.path;
      });
    }
  }

  void _showImageOptions() {
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
                leading: const Icon(Icons.auto_awesome, color: AppColors.primary),
                title: const Text('Generate Random Cover'),
                onTap: () {
                  Navigator.pop(context);
                  final randomId = const Uuid().v4().substring(0, 8);
                  final url = 'https://picsum.photos/seed/$randomId/400/600';
                  _coverImageController.text = url;
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take a Photo'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book == null ? 'Add Book' : 'Edit Book'),
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
              _buildSectionTitle('Basic Details'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _titleController,
                label: 'Book Title',
                hint: 'e.g., Fundamentals of Physics',
                icon: Icons.menu_book,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _authorController,
                label: 'Author Name',
                hint: 'e.g., David Halliday',
                icon: Icons.person_outline,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Author is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _isbnController,
                label: 'ISBN Number',
                hint: 'e.g., 978-0471320005',
                icon: Icons.qr_code,
                validator: (val) =>
                    val == null || val.isEmpty ? 'ISBN is required' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Additional Info'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _buildInputDecoration('Category', Icons.category),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) =>
                    val == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _coverImageController,
                label: 'Cover Image URL or Path',
                hint: 'https://example.com/image.jpg',
                icon: Icons.image_outlined,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_photo_alternate, color: AppColors.primary),
                  tooltip: 'Image Options',
                  onPressed: _showImageOptions,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Cover image is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Optional book description',
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
                      : const Text(
                          'Save Book',
                          style: TextStyle(
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
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
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
      decoration: _buildInputDecoration(label, icon, suffixIcon: suffixIcon).copyWith(
        hintText: hint,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
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
      fillColor: Colors.white,
    );
  }
}
