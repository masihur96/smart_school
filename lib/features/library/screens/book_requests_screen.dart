import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import '../data/dummy_library_data.dart';

class BookRequestsScreen extends StatefulWidget {
  const BookRequestsScreen({super.key});

  @override
  State<BookRequestsScreen> createState() => _BookRequestsScreenState();
}

class _BookRequestsScreenState extends State<BookRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final pendingRequests = DummyLibraryData.bookRequests
        .where((req) => req.status == 'pending')
        .toList();
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Requests'),
        backgroundColor: AppColors.primaryTeacher,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: pendingRequests.isEmpty
          ? const Center(child: Text('No pending book requests.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingRequests.length,
              itemBuilder: (context, index) {
                final request = pendingRequests[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.book, color: AppColors.primaryTeacher),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                request.bookTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              request.studentName,
                              style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              dateFormat.format(request.requestDate),
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  DummyLibraryData.declineRequest(request.id);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Request declined.')),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Decline'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  DummyLibraryData.acceptRequest(request.id);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Request accepted!')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Accept'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
