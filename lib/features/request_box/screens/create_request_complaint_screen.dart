import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';

import '../models/request_complaint_model.dart';
import '../providers/request_complaint_provider.dart';

class CreateRequestComplaintScreen extends StatefulWidget {
  final String? initialType;
  final Color scaffoldColor; // 'REQUEST' or 'COMPLAINT'
  final String? classId;

  const CreateRequestComplaintScreen({
    super.key,
    this.initialType,
    required this.scaffoldColor,
    this.classId,
  });

  @override
  State<CreateRequestComplaintScreen> createState() =>
      _CreateRequestComplaintScreenState();
}

class _CreateRequestComplaintScreenState
    extends State<CreateRequestComplaintScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _type; // REQUEST or COMPLAINT
  String _category = 'LEAVE';
  String _priority = 'MEDIUM';
  String? _recipientId;
  String? _recipientName;
  String? _selectedClassId;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlAttachmentController =
      TextEditingController();

  final List<String> _attachments = [];
  bool _isUploading = false;

  final List<String> _categories = [
    'LEAVE',
    'ACADEMIC',
    'ATTENDANCE',
    'FACILITY',
    'FEE',
    'DISCIPLINE',
    'BEHAVIOR',
    'EXAM',
    'OTHER',
  ];

  final List<String> _priorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType?.toUpperCase() == 'COMPLAINT'
        ? 'COMPLAINT'
        : 'REQUEST';
    _selectedClassId = widget.classId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthNotifier>().user;
      final schoolId = user?.schoolId ?? '';
      final classSetup = context.read<ClassSetupNotifier>();
      if (schoolId.isNotEmpty && classSetup.classes.isEmpty) {
        classSetup.fetchClasses(schoolId);
      }

      if (_selectedClassId == null && user?.classIds.isNotEmpty == true) {
        _selectedClassId = user!.classIds.first;
      }

      context.read<RequestComplaintProvider>().fetchPotentialRecipients(
        classId: _selectedClassId,
        force: true,
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlAttachmentController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        if (!mounted) return;
        final file = File(result.files.first.path!);
        final provider = context.read<RequestComplaintProvider>();
        setState(() => _isUploading = true);

        final url = await provider.uploadAttachment(file);

        if (url != null && mounted) {
          setState(() {
            _attachments.add(url);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attachment uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload file. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (!mounted) return;
        final file = File(picked.path);
        final provider = context.read<RequestComplaintProvider>();
        setState(() => _isUploading = true);

        final url = await provider.uploadAttachment(file);

        if (url != null && mounted) {
          setState(() {
            _attachments.add(url);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showAddUrlDialog() {
    _urlAttachmentController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Attachment URL'),
        content: TextField(
          controller: _urlAttachmentController,
          decoration: const InputDecoration(
            labelText: 'URL Link',
            hintText: 'https://example.com/document.pdf',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _urlAttachmentController.text.trim();
              if (text.isNotEmpty &&
                  (text.startsWith('http://') || text.startsWith('https://'))) {
                setState(() {
                  _attachments.add(text);
                });
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid HTTP/HTTPS URL'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRecipientPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String filter = '';
        String roleFilter = 'ALL'; // ALL, TEACHER, STUDENT
        String? modalClassId = _selectedClassId;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final provider = context.watch<RequestComplaintProvider>();
            final classNotifier = context.watch<ClassSetupNotifier>();
            final classes = classNotifier.classes;

            List<RequestComplaintUser> list = provider.potentialRecipients;
            if (roleFilter == 'TEACHER') {
              list = provider.recipientTeachers;
            } else if (roleFilter == 'STUDENT') {
              list = provider.recipientStudents;
            }

            final query = filter.trim().toLowerCase();
            final filtered = list.where((u) {
              if (query.isEmpty) return true;
              final nameMatch = u.name.toLowerCase().contains(query);
              final roleMatch = u.role?.toLowerCase().contains(query) ?? false;
              final desigMatch =
                  u.designation?.toLowerCase().contains(query) ?? false;
              final rollMatch =
                  u.rollNumber?.toLowerCase().contains(query) ?? false;
              final phoneMatch =
                  u.phone?.toLowerCase().contains(query) ?? false;
              return nameMatch ||
                  roleMatch ||
                  desigMatch ||
                  rollMatch ||
                  phoneMatch;
            }).toList();

            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.people_alt_outlined,
                              color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Select Participant / Recipient',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_recipientId != null)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _recipientId = null;
                                  _recipientName = null;
                                });
                                Navigator.pop(ctx);
                              },
                              child: const Text('Clear',
                                  style: TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name, role, roll no...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1E232E)
                              : Colors.grey.shade100,
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            filter = val;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: Text(
                                        'All (${provider.potentialRecipients.length})'),
                                    selected: roleFilter == 'ALL',
                                    onSelected: (_) {
                                      setModalState(() => roleFilter = 'ALL');
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  ChoiceChip(
                                    label: Text(
                                        'Teachers (${provider.recipientTeachers.length})'),
                                    selected: roleFilter == 'TEACHER',
                                    onSelected: (_) {
                                      setModalState(
                                          () => roleFilter = 'TEACHER');
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  ChoiceChip(
                                    label: Text(
                                        'Students (${provider.recipientStudents.length})'),
                                    selected: roleFilter == 'STUDENT',
                                    onSelected: (_) {
                                      setModalState(
                                          () => roleFilter = 'STUDENT');
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (classes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.filter_list,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            const Text(
                              'Filter by Class: ',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: modalClassId,
                                  isDense: true,
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All Classes',
                                          style: TextStyle(fontSize: 13)),
                                    ),
                                    ...classes.map(
                                      (c) => DropdownMenuItem<String?>(
                                        value: c.id,
                                        child: Text(c.name,
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ),
                                    ),
                                  ],
                                  onChanged: (newClassId) {
                                    setModalState(() {
                                      modalClassId = newClassId;
                                    });
                                    setState(() {
                                      _selectedClassId = newClassId;
                                    });
                                    context
                                        .read<RequestComplaintProvider>()
                                        .fetchPotentialRecipients(
                                          classId: newClassId,
                                          force: true,
                                        );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 16),
                      Expanded(
                        child: provider.isLoadingRecipients
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 12),
                                    Text('Loading participants...'),
                                  ],
                                ),
                              )
                            : filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      'No matching participants found',
                                      style: TextStyle(
                                          color: Colors.grey.shade500),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final u = filtered[index];
                                      final isSelected = u.id == _recipientId;
                                      final isTeacher =
                                          u.role?.toLowerCase() == 'teacher';
                                      final isStudent =
                                          u.role?.toLowerCase() == 'student';

                                      return ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 4,
                                        ),
                                        leading: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: isTeacher
                                              ? Colors.blue.shade100
                                              : isStudent
                                                  ? Colors.green.shade100
                                                  : Colors.purple.shade100,
                                          backgroundImage: (u.avatar != null &&
                                                  u.avatar!.isNotEmpty)
                                              ? CachedNetworkImageProvider(
                                                  u.avatar!)
                                              : null,
                                          child: (u.avatar == null ||
                                                  u.avatar!.isEmpty)
                                              ? Text(
                                                  u.name.isNotEmpty
                                                      ? u.name[0].toUpperCase()
                                                      : 'U',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: isTeacher
                                                        ? Colors.blue.shade900
                                                        : isStudent
                                                            ? Colors
                                                                .green.shade900
                                                            : Colors
                                                                .purple.shade900,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                u.name,
                                                style: TextStyle(
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (isTeacher
                                                        ? Colors.blue
                                                        : isStudent
                                                            ? Colors.green
                                                            : Colors.grey)
                                                    .withAlpha(30),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                (u.role ?? 'USER')
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isTeacher
                                                      ? Colors.blue.shade800
                                                      : isStudent
                                                          ? Colors
                                                              .green.shade800
                                                          : Colors
                                                              .grey.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 2),
                                            Text(
                                              [
                                                if (u.designation != null &&
                                                    u.designation!.isNotEmpty)
                                                  u.designation,
                                                if (u.rollNumber != null &&
                                                    u.rollNumber!.isNotEmpty)
                                                  'Roll: ${u.rollNumber}',
                                                if (u.phone != null &&
                                                    u.phone!.isNotEmpty)
                                                  u.phone,
                                                if (u.email != null &&
                                                    u.email!.isNotEmpty)
                                                  u.email,
                                              ].join(' • '),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                        trailing: isSelected
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: AppColors.primary,
                                              )
                                            : null,
                                        onTap: () {
                                          setState(() {
                                            _recipientId = u.id;
                                            _recipientName =
                                                '${u.name} (${u.role?.toUpperCase() ?? 'USER'})';
                                          });
                                          Navigator.pop(ctx);
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
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthNotifier>().user;
    final schoolId = user?.schoolId ?? '';

    // If admin is creating, recipient is mandatory
    if ((user?.role.name.toLowerCase() == 'admin' ||
            user?.role.name.toLowerCase() == 'superadmin') &&
        (_recipientId == null || _recipientId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a participant / recipient.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<RequestComplaintProvider>();
    final success = await provider.createRequestComplaint(
      type: _type,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      priority: _priority,
      recipientId: _recipientId,
      attachments: _attachments,
      schoolId: schoolId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_type created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      final err = provider.errorMessage ?? 'Failed to submit $_type';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<RequestComplaintProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.scaffoldColor,
        title: Text(
          _type == 'REQUEST' ? 'Create Request' : 'File Complaint',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Toggle
              _buildTypeSelector(isDark),
              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  hintText: _type == 'REQUEST'
                      ? 'e.g. Leave request for medical reasons'
                      : 'e.g. Broken bench in room 204',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E232E) : Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (val.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category & Priority Row
              Row(
                children: [
                  // Category Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E232E)
                            : Colors.white,
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _category = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Priority Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: InputDecoration(
                        labelText: 'Priority *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E232E)
                            : Colors.white,
                      ),
                      items: _priorities.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Row(
                            children: [
                              _buildPriorityDot(p),
                              const SizedBox(width: 6),
                              Text(p, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _priority = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Class Filter Dropdown (Optional class filter for narrowing down participants)
              Consumer<ClassSetupNotifier>(
                builder: (context, classNotifier, _) {
                  final classes = classNotifier.classes;
                  if (classes.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedClassId,
                      decoration: InputDecoration(
                        labelText: 'Filter Participants by Class',
                        hintText: 'All Classes',
                        prefixIcon: const Icon(Icons.school_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E232E) : Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Classes'),
                        ),
                        ...classes.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (newClassId) {
                        setState(() {
                          _selectedClassId = newClassId;
                          _recipientId = null;
                          _recipientName = null;
                        });
                        context
                            .read<RequestComplaintProvider>()
                            .fetchPotentialRecipients(
                              classId: newClassId,
                              force: true,
                            );
                      },
                    ),
                  );
                },
              ),

              // Participant / Recipient Selector
              InkWell(
                onTap: provider.isLoadingRecipients
                    ? null
                    : () {
                        _showRecipientPicker();
                      },
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Participant / Recipient *',
                    hintText: 'Select participant (Teacher / Student)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E232E) : Colors.white,
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: provider.isLoadingRecipients
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_recipientId != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _recipientId = null;
                                      _recipientName = null;
                                    });
                                  },
                                ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                  ),
                  child: Text(
                    _recipientName ?? 'Select participant...',
                    style: TextStyle(
                      color: _recipientName != null
                          ? theme.textTheme.bodyLarge?.color
                          : Colors.grey,
                      fontWeight: _recipientName != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe your request or complaint in detail...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E232E) : Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (val.trim().length < 5) {
                    return 'Description must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Attachments Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Attachments',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'file') _pickAndUploadFile();
                      if (val == 'image') _pickAndUploadImage();
                      if (val == 'url') _showAddUrlDialog();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'file',
                        child: Row(
                          children: [
                            Icon(Icons.attach_file, size: 18),
                            SizedBox(width: 8),
                            Text('Upload File (PDF, DOC)'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'image',
                        child: Row(
                          children: [
                            Icon(Icons.image_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Upload Photo'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'url',
                        child: Row(
                          children: [
                            Icon(Icons.link, size: 18),
                            SizedBox(width: 8),
                            Text('Add URL Link'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: theme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'Add Attachment',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isUploading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Uploading attachment...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],

              if (_attachments.isEmpty && !_isUploading) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E232E)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'No attachments added yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ],

              // Attachments list
              ..._attachments.map((att) => _buildAttachmentRow(att, isDark)),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == 'REQUEST'
                        ? AppColors.primary
                        : Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: provider.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _type == 'REQUEST'
                              ? 'Submit Request'
                              : 'Submit Complaint',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildTypeSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232E) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _type = 'REQUEST'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _type == 'REQUEST'
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'REQUEST',
                    style: TextStyle(
                      color: _type == 'REQUEST' ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _type = 'COMPLAINT'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _type == 'COMPLAINT'
                      ? Colors.deepOrange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'COMPLAINT',
                    style: TextStyle(
                      color: _type == 'COMPLAINT' ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityDot(String priority) {
    Color color;
    switch (priority) {
      case 'URGENT':
        color = Colors.red;
        break;
      case 'HIGH':
        color = Colors.orange;
        break;
      case 'MEDIUM':
        color = Colors.amber;
        break;
      default:
        color = Colors.green;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildAttachmentRow(String url, bool isDark) {
    final fileName = url.split('/').last;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            onPressed: () {
              setState(() {
                _attachments.remove(url);
              });
            },
          ),
        ],
      ),
    );
  }
}
