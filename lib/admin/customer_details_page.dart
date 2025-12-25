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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Details")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _customerFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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
      title: Text(user["name"]),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user["email"]),
          Text("Phone: ${user["phone"] ?? "-"}"),
          Text("Joined: ${user["created_at"].toString().split('T')[0]}"),
        ],
      ),
    );
  }

  Widget _bookingHistory() {
    return FutureBuilder<List<dynamic>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!;

        if (bookings.isEmpty) {
          return const Center(child: Text("No bookings found"));
        }

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final b = bookings[index];
            return ListTile(
              leading: const Icon(Icons.local_taxi),
              title: Text("${b["pickup"]} → ${b["dropoff"]}"),
              subtitle: Text("Status: ${b["status"]}"),
              trailing: Text("Rs. ${b["fare"]}"),
            );
          },
        );
      },
    );
  }
}
