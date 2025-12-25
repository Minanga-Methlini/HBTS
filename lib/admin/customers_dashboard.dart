import 'package:flutter/material.dart';
import '../../services/admin_api.dart';
import '../admin/customer_details_page.dart';

String _search = "";


class CustomersDashboard extends StatefulWidget {
  const CustomersDashboard({super.key});

  @override
  State<CustomersDashboard> createState() => _CustomersDashboardState();
}


class _CustomersDashboardState extends State<CustomersDashboard> {
  late Future<List<dynamic>> _customersFuture;


  @override
  void initState() {
    super.initState();
    _customersFuture = AdminApi.fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _customersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final customers = snapshot.data!;

          if (customers.isEmpty) {
            return const Center(child: Text("No customers found"));
          }
          Padding(
  padding: const EdgeInsets.all(8),
  child: TextField(
    decoration: const InputDecoration(
      prefixIcon: Icon(Icons.search),
      hintText: "Search by name, email or phone",
      border: OutlineInputBorder(),
    ),
    onChanged: (value) {
      setState(() => _search = value.toLowerCase());
    },
  ),
);


          return ListView.separated(
            itemCount: customers.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final user = customers[index];

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(user["name"] ?? "No Name"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user["email"] ?? "No Email"),
                    Text("Phone: ${user["phone"] ?? "-"}"),
                    Text(
                      "Joined: ${user["created_at"].toString().split('T')[0]}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.book_online, size: 18),
                    Text(
                      "${user["bookings"] ?? 0}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                isThreeLine: true,
                onTap: () {
                  // next step: customer details page
                  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CustomerDetailsPage(
        userId: user["user_id"],
      ),
    ),
  );
                                };                },


                
              );
            },
          );
        },
      ),
    );
  }
}
