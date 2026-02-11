import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_app/core/theme.dart';
import 'package:teacher_app/features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Teacher App',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
