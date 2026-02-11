import 'package:flutter/material.dart';
import 'package:teacher_app/core/theme.dart';
import 'package:teacher_app/data/mock_data/mock_data.dart';
import 'package:teacher_app/features/coursework/presentation/screens/coursework_form_screen.dart';
import 'package:teacher_app/features/coursework/presentation/screens/homework_feedback_screen.dart';

class CourseworkListScreen extends StatefulWidget {
  final int initialIndex;
  final bool isTab;
  const CourseworkListScreen({super.key, this.initialIndex = 0, this.isTab = false});

  @override
  State<CourseworkListScreen> createState() => _CourseworkListScreenState();
}

class _CourseworkListScreenState extends State<CourseworkListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coursework'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Classwork'),
            Tab(text: 'Homework'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('Classwork'),
          _buildList('Homework'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseworkFormScreen(
                type: _tabController.index == 0 ? 'Classwork' : 'Homework',
              ),
            ),
          );
        },
        label: const Text('Add New'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(String type) {
    final items = MockData.coursework.where((item) => item['type'] == type).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Due: ${item['dueDate']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            trailing: type == 'Homework' 
              ? IconButton(
                  icon: const Icon(Icons.comment_outlined, color: AppColors.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeworkFeedbackScreen(homeworkTitle: item['title']),
                      ),
                    );
                  },
                )
              : const Icon(Icons.chevron_right),
            onTap: () {
              // Edit logic could go here
            },
          ),
        );
      },
    );
  }
}
