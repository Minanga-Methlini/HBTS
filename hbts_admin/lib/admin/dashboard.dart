import 'package:flutter/material.dart';
import 'customers_page.dart';
import 'drivers_dashboard.dart';
import 'reports_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _card(context, 'Customers', const CustomersPage()),
            _card(context, 'Drivers', const DriversDashboard()),
            _card(context, 'Reports', const ReportsPage()),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String title, Widget page) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
