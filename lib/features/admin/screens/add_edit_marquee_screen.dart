import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';

import '../providers/marquee_provider.dart';

class AddEditMarqueeScreen extends StatefulWidget {
  final String schoolId;
  const AddEditMarqueeScreen({super.key, required this.schoolId});

  @override
  State<AddEditMarqueeScreen> createState() => _AddEditMarqueeScreenState();
}

class _AddEditMarqueeScreenState extends State<AddEditMarqueeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  
  String _selectedType = 'TEACHER';
  final List<String> _marqueeTypes = ['TEACHER', 'STUDENT'];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<MarqueeProvider>().addOrUpdateMarquee(
      _textController.text.trim(),
      _selectedType,
      widget.schoolId,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marquee updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<MarqueeProvider>().error ?? 'Failed to update marquee'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<MarqueeProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Edit Marquee'),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Marquee Target',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                items: _marqueeTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Marquee Text',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter marquee scrolling text...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(

                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Marquee',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
