import 'package:flutter/material.dart';

class SystemStatusScreen extends StatelessWidget {
  const SystemStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("System Status")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusCard("API Server", true),
          _statusCard("Database", true),
          _statusCard("Firebase Notifications", true),
          _statusCard("Storage", true),
          _statusCard("Subscriptions", true),
          _statusCard("Backup Service", false),
        ],
      ),
    );
  }

  Widget _statusCard(String title, bool isOnline) {
    return Card(
      child: ListTile(
        leading: Icon(
          isOnline ? Icons.check_circle : Icons.error,
          color: isOnline ? Colors.green : Colors.red,
        ),
        title: Text(title),
        subtitle: Text(isOnline ? "Operational" : "Issue Detected"),
      ),
    );
  }
}
