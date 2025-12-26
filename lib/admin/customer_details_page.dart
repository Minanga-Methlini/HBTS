import 'package:flutter/material.dart';
import '../services/admin_api.dart';

class CustomerDetailsPage extends StatefulWidget {
  final int userId;

  const CustomerDetailsPage({super.key, required this.userId});

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  late Future<Map<String, dynamic>> _customerFuture;
  late Future<List<dynamic>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _customerFuture = AdminApi.fetchCustomerDetails(widget.userId);
    _bookingsFuture = AdminApi.fetchCustomerBookings(widget.userId);
  }

  String _safeStr(dynamic v) => (v == null) ? "-" : v.toString();

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return "-";
    final s = createdAt.toString();
    // Handles both "2025-12-26T..." and "2025-12-26 ..."
    if (s.contains('T')) return s.split('T')[0];
    if (s.contains(' ')) return s.split(' ')[0];
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Details")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _customerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No data found"));
          }

          final user = snapshot.data!;

          return Column(
            children: [
              _customerInfo(user),
              const Divider(),
              Expanded(child: _bookingHistory()),
            ],
          );
        },
      ),
    );
  }

  Widget _customerInfo(Map<String, dynamic> user) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(_safeStr(user["name"])),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_safeStr(user["email"])),
          Text("Phone: ${_safeStr(user["phone"])}"),
          Text("Joined: ${_formatDate(user["created_at"])}"),
          Text("Verified: ${user["is_verified"] == true ? "Yes" : "No"}"),
        ],
      ),
    );
  }

  Widget _bookingHistory() {
    return FutureBuilder<List<dynamic>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text("No booking data"));
        }

        final bookings = snapshot.data!;
        if (bookings.isEmpty) {
          return const Center(child: Text("No bookings found"));
        }

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final b = bookings[index] as Map<String, dynamic>;

            // These keys depend on your backend.
            // If your backend uses different names, tell me the exact JSON and I’ll match it.
            final pickup = _safeStr(b["pickup"]);
            final dropoff = _safeStr(b["dropoff"]);
            final status = _safeStr(b["status"]);
            final fare = _safeStr(b["fare"]);

            return ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text("$pickup → $dropoff"),
              subtitle: Text("Status: $status"),
              trailing: Text("Rs. $fare"),
            );
          },
        );
      },
    );
  }
}
