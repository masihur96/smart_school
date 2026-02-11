import 'package:flutter/material.dart';
import 'package:teacher_app/core/theme.dart';
import 'package:teacher_app/data/mock_data/mock_data.dart';

class HomeworkFeedbackScreen extends StatefulWidget {
  final String homeworkTitle;
  const HomeworkFeedbackScreen({super.key, required this.homeworkTitle});

  @override
  State<HomeworkFeedbackScreen> createState() => _HomeworkFeedbackScreenState();
}

class _HomeworkFeedbackScreenState extends State<HomeworkFeedbackScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var student in MockData.students) {
      _controllers[student['id']] = TextEditingController(
        text: MockData.homeworkFeedback[student['id']] ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Feedback'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.homeworkTitle, style: Theme.of(context).textTheme.titleLarge),
                const Text('Provide feedback for each student below.', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: MockData.students.length,
              itemBuilder: (context, index) {
                final student = MockData.students[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(student['name'][0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            const Text('Submitted', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _controllers[student['id']],
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Add feedback...',
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback saved successfully')),
                );
                Navigator.pop(context);
              },
              child: const Center(child: Text('Save All Feedback')),
            ),
          ),
        ],
      ),
    );
  }
}
