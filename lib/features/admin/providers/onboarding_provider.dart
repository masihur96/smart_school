import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';

class OnboardingNotifier extends ChangeNotifier {
  final ClassSetupNotifier classNotifier;
  final SectionSetupNotifier sectionNotifier;
  final SubjectSetupNotifier subjectNotifier;
  final AuthNotifier authNotifier;

  OnboardingNotifier({
    required this.classNotifier,
    required this.sectionNotifier,
    required this.subjectNotifier,
    required this.authNotifier,
  });

  double _progress = 0;
  double get progress => _progress;

  String _statusMessage = '';
  String get statusMessage => _statusMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  // Default Data Configuration
  final List<String> defaultClasses = [
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
  ];

  final List<String> defaultSubjects = [
    'Bangla',
    'English',
    'Mathematics',
    'General Science',
    'Religion',
  ];

  Future<void> startOnboarding(String schoolId) async {
    if (_isLoading) return;

    _isLoading = true;
    _isCompleted = false;
    _error = null;
    _progress = 0;
    _statusMessage = 'Initializing setup...';
    notifyListeners();

    try {
      final totalSteps =
          defaultClasses.length * (1 + 1 + defaultSubjects.length);
      int completedSteps = 0;

      for (int i = 0; i < defaultClasses.length; i++) {
        final className = defaultClasses[i];

        // 1. Create Class
        _statusMessage = 'Creating Class: $className';
        notifyListeners();

        final classSuccess = await classNotifier.addClass(
          className,
          'Default $className',
          schoolId,
        );
        if (!classSuccess) throw Exception('Failed to create class $className');

        completedSteps++;
        _progress = (completedSteps / totalSteps) * 0.95;
        notifyListeners();

        // Get the created class to find its ID
        // Note: classNotifier stores them in its internal list
        final createdClass = classNotifier.classes.firstWhere(
          (c) => c.name == className,
        );

        // 2. Create Section A
        _statusMessage = 'Creating Section A for $className';
        notifyListeners();

        final sectionSuccess = await sectionNotifier.addSection(
          createdClass.id,
          'A',
        );
        if (!sectionSuccess)
          throw Exception('Failed to create section for $className');

        completedSteps++;
        _progress = (completedSteps / totalSteps) * 0.95;
        notifyListeners();

        // 3. Create Subjects
        for (final subjectName in defaultSubjects) {
          _statusMessage = 'Adding Subject: $subjectName to $className';
          notifyListeners();

          final subjectSuccess = await subjectNotifier.addSubject(
            subjectName,
            subjectName.substring(0, 3).toUpperCase(),
            createdClass.id,
            schoolId,
          );
          if (!subjectSuccess)
            throw Exception(
              'Failed to create subject $subjectName for $className',
            );

          completedSteps++;
          _progress = (completedSteps / totalSteps) * 0.95;
          notifyListeners();
        }
      }

      // 4. Verify Subscription
      _statusMessage = 'Verifying subscription status...';
      _progress = 0.95;
      notifyListeners();

      await authNotifier.refreshSubscription();

      _statusMessage = 'Setup complete!';
      _progress = 1.0;
      _isLoading = false;
      _isCompleted = true;
      notifyListeners();
    } catch (e) {
      log('Onboarding error: $e');
      _error = e.toString().contains('Exception: ')
          ? e.toString().split('Exception: ')[1]
          : 'Setup failed. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _isLoading = false;
    _isCompleted = false;
    _error = null;
    _progress = 0;
    _statusMessage = '';
    notifyListeners();
  }
}
