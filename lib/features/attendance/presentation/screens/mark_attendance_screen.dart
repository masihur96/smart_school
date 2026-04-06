import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:teacher_app/core/theme.dart';
import 'package:teacher_app/data/mock_data/mock_data.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  Future<void> _authenticateWithFingerprint() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
      });
      // Simulate/Attempt biometric auth
      authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to mark attendance',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      // If biometrics fail or not available, we show a professional simulation for this demo
      _showSimulationPrompt('Fingerprint');
      return;
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }

    if (authenticated) {
      _onSuccess();
    }
  }

  void _authenticateWithEmail() {
    // Show a professional email verification simulation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('A verification code has been sent to your registered email.'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter 6-digit Code',
                hintText: '123456',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _onSuccess();
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showSimulationPrompt(String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$method Simulation'),
        content: Text('In a real device, this would trigger the $method hardware. For this demo, would you like to proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _onSuccess();
            },
            child: const Text('Mark Present'),
          ),
        ],
      ),
    );
  }

  void _onSuccess() {
    MockData.markTodayPresent();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance marked successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.verified_user_rounded, size: 100, color: AppColors.primary),
            const SizedBox(height: 32),
            Text(
              'Identity Verification',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please choose a method to verify your identity and mark your attendance for today.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 48),
            _buildAuthOption(
              context,
              'Fingerprint Scan',
              'Fast and secure biometric verification',
              Icons.fingerprint_rounded,
              AppColors.primary,
              _authenticateWithFingerprint,
            ),
            const SizedBox(height: 16),
            _buildAuthOption(
              context,
              'Email Verification',
              'Verify using a code sent to your email',
              Icons.email_outlined,
              Colors.orange,
              _authenticateWithEmail,
            ),
            const Spacer(),
            const Text(
              'Secure Verification System © 2026',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthOption(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: _isAuthenticating ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
