import 'package:flutter/material.dart';
import '../services/admin_api.dart';
import 'customer_details_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> passengers = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPassengers(); // initial load (no search)
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPassengers({String search = ""}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await AdminApi.getPassengers(search);
      setState(() {
        passengers = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _safeStr(dynamic v) => (v == null) ? "-" : v.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customers (Passengers)")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                // simple approach: load every change
                _loadPassengers(search: value.trim());
              },
              decoration: const InputDecoration(
                hintText: "Search passenger by name",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: passengers.isEmpty && !_loading
                ? const Center(child: Text("No passengers found"))
                : ListView.separated(
                    itemCount: passengers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = passengers[index] as Map<String, dynamic>;

                      // Your backend returns: user_id, name, email, phone, is_verified
                      final int userId = (p["user_id"] as num).toInt();

                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(_safeStr(p["name"])),
                        subtitle: Text(
                          "${_safeStr(p["email"])} • ${_safeStr(p["phone"])}",
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailsPage(userId: userId),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
