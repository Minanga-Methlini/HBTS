import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      children: const [
        Card(child: Center(child: Text("Total Users"))),
        Card(child: Center(child: Text("Reports"))),
        Card(child: Center(child: Text("Analytics"))),
        Card(child: Center(child: Text("Settings"))),
      ],
    );
  }
}
