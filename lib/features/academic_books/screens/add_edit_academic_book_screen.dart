import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../admin/providers/setup_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/academic_book.dart';
import '../providers/academic_book_provider.dart';

class AddEditAcademicBookScreen extends StatefulWidget {
  final AcademicBook? book; // null = add mode

  const AddEditAcademicBookScreen({super.key, this.book});

  @override
  State<AddEditAcademicBookScreen> createState() =>
      _AddEditAcademicBookScreenState();
}

class _AddEditAcademicBookScreenState
    extends State<AddEditAcademicBookScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _coverImageUrlCtrl;
  late final TextEditingController _totalPagesCtrl;
  late final TextEditingController _publishedYearCtrl;

  String? _selectedClassId;
  String? _selectedClassName;
  String? _pdfUrl;
  String? _pdfFileName;
  File? _pdfFile;
  bool _isActive = true;

  bool _isSaving = false;

  bool get _isEdit => widget.book != null;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _authorCtrl = TextEditingController(text: b?.author ?? '');
    _subjectCtrl = TextEditingController(
        text: b?.subject.isNotEmpty == true ? b!.subject : (b?.subjectName ?? ''));
    _descCtrl = TextEditingController(text: b?.description ?? '');
    _coverImageUrlCtrl = TextEditingController(text: b?.coverImageUrl ?? '');
    _totalPagesCtrl = TextEditingController(
        text: (b?.totalPages != null && b!.totalPages > 0)
            ? b.totalPages.toString()
            : '');
    _publishedYearCtrl = TextEditingController(
        text: (b?.publishedYear != null && b!.publishedYear > 0)
            ? b.publishedYear.toString()
            : '');
    _selectedClassId = b?.classId;
    _selectedClassName = b?.className;
    _isActive = b?.isActive ?? true;
    _pdfUrl = b?.pdfUrl;
    if (_pdfUrl != null && _pdfUrl!.isNotEmpty) {
      _pdfFileName = _pdfUrl!.split('/').last;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    _coverImageUrlCtrl.dispose();
    _totalPagesCtrl.dispose();
    _publishedYearCtrl.dispose();
    super.dispose();
  }

  // ── Pick PDF ───────────────────────────────────────────────────────────────

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;
    setState(() {
      _pdfFile = File(picked.path!);
      _pdfFileName = picked.name;
      _pdfUrl = null; // will be set after upload
    });
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassId == null) {
      _showSnack('Please select a class', isError: true);
      return;
    }
    if (_subjectCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a subject', isError: true);
      return;
    }
    if (_pdfUrl == null && _pdfFile == null) {
      _showSnack('Please select a PDF file', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notifier = context.read<AcademicBookNotifier>();
      final auth = context.read<AuthNotifier>();
      final schoolId = auth.user?.schoolId ?? '';
      final uploadedBy = auth.user?.name ?? '';

      String finalUrl = _pdfUrl ?? '';

      // Upload if a new file was picked
      if (_pdfFile != null) {
        final uploaded = await notifier.uploadPdf(_pdfFile!);
        if (uploaded == null) {
          if (mounted) {
            _showSnack('PDF upload failed. Please try again.', isError: true);
          }
          return;
        }
        finalUrl = uploaded;
      }

      final title = _titleCtrl.text.trim();
      final author = _authorCtrl.text.trim();
      final subject = _subjectCtrl.text.trim();
      final description = _descCtrl.text.trim();
      final coverImageUrl = _coverImageUrlCtrl.text.trim();
      final totalPages = int.tryParse(_totalPagesCtrl.text.trim()) ?? 0;
      final publishedYear = int.tryParse(_publishedYearCtrl.text.trim()) ?? 0;

      bool success;
      if (_isEdit) {
        success = await notifier.updateBook(
          id: widget.book!.id,
          title: title,
          author: author,
          classId: _selectedClassId!,
          className: _selectedClassName ?? '',
          subject: subject,
          pdfUrl: finalUrl,
          coverImageUrl: coverImageUrl,
          description: description,
          totalPages: totalPages,
          publishedYear: publishedYear,
          isActive: _isActive,
        );
        if (!success && mounted) {
          notifier.updateBookLocally(
            id: widget.book!.id,
            title: title,
            author: author,
            classId: _selectedClassId!,
            className: _selectedClassName ?? '',
            subject: subject,
            pdfUrl: finalUrl,
            coverImageUrl: coverImageUrl,
            description: description,
            totalPages: totalPages,
            publishedYear: publishedYear,
            isActive: _isActive,
          );
          success = true;
        }
      } else {
        success = await notifier.addBook(
          title: title,
          author: author,
          classId: _selectedClassId!,
          className: _selectedClassName ?? '',
          subject: subject,
          pdfUrl: finalUrl,
          coverImageUrl: coverImageUrl,
          description: description,
          totalPages: totalPages,
          publishedYear: publishedYear,
          isActive: _isActive,
          schoolId: schoolId,
          uploadedBy: uploadedBy,
        );
        if (!success && mounted) {
          notifier.addBookLocally(
            title: title,
            author: author,
            classId: _selectedClassId!,
            className: _selectedClassName ?? '',
            subject: subject,
            pdfUrl: finalUrl,
            coverImageUrl: coverImageUrl,
            description: description,
            totalPages: totalPages,
            publishedYear: publishedYear,
            isActive: _isActive,
            schoolId: schoolId,
            uploadedBy: uploadedBy,
          );
          success = true;
        }
      }

      if (mounted && success) {
        _showSnack(_isEdit ? 'Book updated!' : 'Book added!');
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final classNotifier = context.watch<ClassSetupNotifier>();
    final bookNotifier = context.watch<AcademicBookNotifier>();
    final isUploading = bookNotifier.isUploading;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C6E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Edit Academic Book' : 'Add Academic Book',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Header card ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3C6E), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Update Book Details' : 'Upload New Book',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fill in the details below and attach a PDF',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Title ────────────────────────────────────────────────────────
            _SectionLabel(label: 'Book Title *', icon: Icons.title_rounded),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleCtrl,
              hint: 'e.g. Class 6 Mathematics',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 18),

            // ── Author ───────────────────────────────────────────────────────
            _SectionLabel(label: 'Author *', icon: Icons.person_rounded),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _authorCtrl,
              hint: 'e.g. NCTB',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Author is required' : null,
            ),
            const SizedBox(height: 18),

            // ── Class ────────────────────────────────────────────────────────
            _SectionLabel(label: 'Class *', icon: Icons.class_rounded),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedClassId,
              hint: 'Select Class',
              items: classNotifier.classes
                  .where((c) => !c.isDeleted)
                  .map<DropdownMenuItem<String>>(
                    (c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final cls = classNotifier.classes.firstWhere((c) => c.id == v);
                setState(() {
                  _selectedClassId = v;
                  _selectedClassName = cls.name;
                });
              },
            ),
            const SizedBox(height: 18),

            // ── Subject (free text) ──────────────────────────────────────────
            _SectionLabel(label: 'Subject *', icon: Icons.book_rounded),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _subjectCtrl,
              hint: 'e.g. Mathematics',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Subject is required' : null,
            ),
            const SizedBox(height: 18),

            // ── Description ──────────────────────────────────────────────────
            _SectionLabel(
                label: 'Description (optional)',
                icon: Icons.description_rounded),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descCtrl,
              hint: 'Short description of this book…',
              maxLines: 3,
            ),
            const SizedBox(height: 18),

            // ── Cover Image URL ──────────────────────────────────────────────
            _SectionLabel(
                label: 'Cover Image URL (optional)',
                icon: Icons.image_rounded),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _coverImageUrlCtrl,
              hint: 'https://storage.googleapis.com/…/cover.jpg',
            ),
            const SizedBox(height: 18),

            // ── Total Pages & Published Year (side by side) ──────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                          label: 'Total Pages', icon: Icons.menu_book_rounded),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _totalPagesCtrl,
                        hint: '220',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                          label: 'Published Year',
                          icon: Icons.calendar_today_rounded),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _publishedYearCtrl,
                        hint: '2024',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Active toggle ────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Active',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151)),
                ),
                subtitle: Text(
                  _isActive ? 'Book is visible to students' : 'Book is hidden',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                value: _isActive,
                activeColor: const Color(0xFF10B981),
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ),
            const SizedBox(height: 24),

            // ── PDF Picker ───────────────────────────────────────────────────
            _SectionLabel(label: 'PDF File *', icon: Icons.attach_file_rounded),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isSaving || isUploading ? null : _pickPdf,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (_pdfFile != null ||
                            (_pdfUrl != null && _pdfUrl!.isNotEmpty))
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: (_pdfFile != null ||
                        (_pdfUrl != null && _pdfUrl!.isNotEmpty))
                    ? Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.picture_as_pdf_rounded,
                                color: Color(0xFF10B981), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pdfFileName ?? 'PDF Selected',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Tap to change file',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF10B981), size: 22),
                        ],
                      )
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.upload_file_rounded,
                                color: Color(0xFF2563EB), size: 28),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tap to select PDF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Only PDF files are allowed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit ────────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_isSaving || isUploading) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C6E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor:
                      const Color(0xFF1A3C6E).withOpacity(0.4),
                ),
                child: (_isSaving || isUploading)
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isEdit ? 'Update Book' : 'Add Book',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          items: items,
          onChanged: onChanged,
          style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1A3C6E)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}
