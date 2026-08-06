import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_school/core/theme.dart';
import 'package:smart_school/data/mock_data/mock_data.dart';
import 'package:smart_school/models/online_class_model.dart';
import 'add_edit_online_class_screen.dart';

class OnlineClassListScreen extends StatefulWidget {
  final bool isAdminOrTeacher;

  const OnlineClassListScreen({
    super.key,
    this.isAdminOrTeacher = true, // Default to true for demo purposes
  });

  @override
  State<OnlineClassListScreen> createState() => _OnlineClassListScreenState();
}

class _OnlineClassListScreenState extends State<OnlineClassListScreen> {
  late List<OnlineClass> onlineClasses;

  @override
  void initState() {
    super.initState();
    _loadOnlineClasses();
  }

  void _loadOnlineClasses() {
    setState(() {
      onlineClasses = MockData.onlineClasses
          .map((json) => OnlineClass.fromJson(json))
          .toList();
      // Sort by scheduled time
      onlineClasses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    });
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Online Classes'),
        backgroundColor: Colors.white,
      ),
      body: onlineClasses.isEmpty
          ? const Center(
              child: Text(
                'No online classes scheduled.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: onlineClasses.length,
              itemBuilder: (context, index) {
                final oClass = onlineClasses[index];
                return _buildOnlineClassCard(oClass);
              },
            ),
      floatingActionButton: widget.isAdminOrTeacher
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditOnlineClassScreen(),
                  ),
                );
                if (result == true) {
                  _loadOnlineClasses();
                }
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Class',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildOnlineClassCard(OnlineClass oClass) {
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(oClass.scheduledTime);
    final isUpcoming = oClass.scheduledTime.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  oClass.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUpcoming ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isUpcoming ? 'Upcoming' : 'Past',
                  style: TextStyle(
                    color: isUpcoming ? AppColors.success : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'By ${oClass.teacherName}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          if (oClass.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              oClass.description,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchURL(oClass.meetLink),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.video_call, color: Colors.white),
              label: const Text(
                'Join Meeting',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
