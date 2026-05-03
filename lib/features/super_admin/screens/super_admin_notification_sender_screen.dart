import 'package:flutter/material.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/services/notification_service.dart';

class SuperAdminNotificationSenderScreen extends StatefulWidget {
  const SuperAdminNotificationSenderScreen({super.key});

  @override
  State<SuperAdminNotificationSenderScreen> createState() =>
      _SuperAdminNotificationSenderScreenState();
}

class _SuperAdminNotificationSenderScreenState
    extends State<SuperAdminNotificationSenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _idController = TextEditingController();

  String _selectedTarget = 'all';
  bool _isSending = false;

  final Map<String, String> _targets = {
    'all': 'Entire Platform',
    'school': 'Specific School',
    'admin': 'Specific Admin',
    'teacher': 'Specific Teacher',
    'student': 'Specific Student',
    'class': 'Specific Class',
    'section': 'Specific Section',
    'subscription': 'Subscription Updates',
    'notice': 'Global Notices',
    'exam': 'Exam Alerts',
    'result': 'Result Alerts',
    'homework': 'Homework Alerts',
    'attendance': 'Attendance Alerts',
    'routine': 'Routine Alerts',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      String topic = _selectedTarget;
      if (_selectedTarget != 'all' &&
          _selectedTarget != 'subscription' &&
          _selectedTarget != 'notice' &&
          _selectedTarget != 'exam' &&
          _selectedTarget != 'result' &&
          _selectedTarget != 'homework' &&
          _selectedTarget != 'attendance' &&
          _selectedTarget != 'routine') {
        if (_idController.text.isEmpty) {
          throw Exception('Please enter the ID for the specific target');
        }
        topic = '${_selectedTarget}_${_idController.text}';
      }

      await NotificationService().triggerNotification(
        title: _titleController.text,
        body: _messageController.text,
        topic: topic,
        data: {
          'type': 'system_alert',
          'sender': 'super_admin',
          'sentAt': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Notification'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create System Announcement',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Send a push notification to specific groups or individuals across the platform.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Notification Title',
                  hintText: 'e.g., System Maintenance Alert',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),

              // Message
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message Body',
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.message),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Message is required'
                    : null,
              ),
              const SizedBox(height: 24),

              const Divider(),
              const SizedBox(height: 24),

              // Target Selection
              const Text(
                'Select Target Audience',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTarget,
                    isExpanded: true,
                    items: _targets.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTarget = val);
                    },
                  ),
                ),
              ),

              if (_selectedTarget != 'all' &&
                  _selectedTarget != 'subscription' &&
                  _selectedTarget != 'notice' &&
                  _selectedTarget != 'exam' &&
                  _selectedTarget != 'result' &&
                  _selectedTarget != 'homework' &&
                  _selectedTarget != 'attendance' &&
                  _selectedTarget != 'routine') ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: 'Enter ${_targets[_selectedTarget]} ID',
                    hintText: 'e.g., UUID or ID string',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.account_balance),
                    helperText: 'Must match the specific ID in the database',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'ID is required' : null,
                ),
              ],

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded),
                            SizedBox(width: 8),
                            Text(
                              'SEND NOTIFICATION',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
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
