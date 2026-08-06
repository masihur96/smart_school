import 'package:flutter/material.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'book_list_screen.dart';
import 'issued_books_screen.dart';

class LibraryDashboardScreen extends StatelessWidget {
  const LibraryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          backgroundColor: AppColors.primaryStudent,
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'All Books', icon: Icon(Icons.library_books)),
              Tab(text: 'Issued Books', icon: Icon(Icons.book)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BookListScreen(),
            IssuedBooksScreen(),
          ],
        ),
      ),
    );
  }
}
