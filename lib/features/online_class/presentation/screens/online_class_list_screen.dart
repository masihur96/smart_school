import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/models/online_class_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

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
  List<OnlineClass> onlineClasses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOnlineClasses();
  }

  Future<void> _loadOnlineClasses() async {
    setState(() {
      isLoading = true;
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://smart-school-backend-production.up.railway.app/online-classes',
        options: Options(
          headers: {
            'accept': '*/*',
            'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkYTBjM2ZmZi1hZTU5LTQ2YTMtYTAzNy0xOWZhNjgwMDNjNmIiLCJyb2xlIjoiYWRtaW4iLCJzY2hvb2xJZCI6IjI5ZjA1ZWRiLThlMGItNDM0Yy1hNDcxLWFhNzc2MzA4YTFjMSIsImNsYXNzSWRzIjpbXSwic2VjdGlvbklkcyI6W10sImlhdCI6MTc4NjY0NTM1NCwiZXhwIjoxNzg2NzMxNzU0fQ.MVNAkFfJ6iuN7TXOrPYYZCyVMKPgp5uaMFBdpHTlP1s',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> listData = data['data'] ?? [];
        
        setState(() {
          onlineClasses = listData.map((json) {
            return OnlineClass(
              id: json['id'] ?? '',
              title: json['title'] ?? '',
              description: json['description'] ?? '',
              meetLink: json['meetLink'] ?? '',
              scheduledTime: json['date'] != null 
                  ? DateTime.parse(json['date']) 
                  : DateTime.now(),
              teacherId: json['hostId'] ?? '',
              teacherName: 'Host', // Default since name is missing in response
              classId: json['classId'],
              sectionId: json['sectionId'],
              subjectId: json['subjectId'],
              createdAt: json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'])
                  : null,
            );
          }).toList();
          onlineClasses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load classes: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteClass(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text('Are you sure you want to delete this class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isLoading = true;
    });

    try {
      final dio = Dio();
      final response = await dio.delete(
        'https://smart-school-backend-production.up.railway.app/online-classes/$id',
        options: Options(
          headers: {
            'accept': '*/*',
            'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkYTBjM2ZmZi1hZTU5LTQ2YTMtYTAzNy0xOWZhNjgwMDNjNmIiLCJyb2xlIjoiYWRtaW4iLCJzY2hvb2xJZCI6IjI5ZjA1ZWRiLThlMGItNDM0Yy1hNDcxLWFhNzc2MzA4YTFjMSIsImNsYXNzSWRzIjpbXSwic2VjdGlvbklkcyI6W10sImlhdCI6MTc4NjY0NTM1NCwiZXhwIjoxNzg2NzMxNzU0fQ.MVNAkFfJ6iuN7TXOrPYYZCyVMKPgp5uaMFBdpHTlP1s',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Class deleted successfully')),
          );
        }
        _loadOnlineClasses();
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete class: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting class: $e')),
        );
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Classes'),
        backgroundColor: widget.isAdminOrTeacher
            ? AppColors.primaryAdmin
            : AppColors.primaryTeacher,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : onlineClasses.isEmpty
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
                    builder: (context) => AddEditOnlineClassScreen(
                      isAdminOrTeacher: widget.isAdminOrTeacher,
                    ),
                  ),
                );
                if (result == true) {
                  _loadOnlineClasses();
                }
              },
              backgroundColor: widget.isAdminOrTeacher
                  ? AppColors.primaryAdmin
                  : AppColors.primaryTeacher,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Class',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildOnlineClassCard(OnlineClass oClass) {
    final formattedDate = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(oClass.scheduledTime);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? AppColors.success.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
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
              if (widget.isAdminOrTeacher)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditOnlineClassScreen(
                            onlineClass: oClass,
                            isAdminOrTeacher: widget.isAdminOrTeacher,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadOnlineClasses();
                      }
                    } else if (value == 'delete') {
                      _deleteClass(oClass.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'By ${oClass.teacherName}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (oClass.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              oClass.description,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchURL(oClass.meetLink),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isAdminOrTeacher
                    ? AppColors.primaryAdmin
                    : AppColors.primaryTeacher,
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
