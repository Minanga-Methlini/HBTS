import 'package:flutter/material.dart';

class FullDetailsReportPage extends StatefulWidget {
  const FullDetailsReportPage({super.key});

  @override
  State<FullDetailsReportPage> createState() => _FullDetailsReportPageState();
}

class _FullDetailsReportPageState extends State<FullDetailsReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = "";

  final List<Map<String, dynamic>> passengers = [
    {
      "name": "Alice Perera",
      "email": "alice@example.com",
      "phone": "+94 71 222 3344",
      "trips": 18,
      "status": "verified",
    },
    {
      "name": "Bob Silva",
      "email": "bob@example.com",
      "phone": "+94 77 888 9900",
      "trips": 9,
      "status": "verified",
    },
    {
      "name": "Chathuri Fernando",
      "email": "chathuri@example.com",
      "phone": "+94 70 111 2233",
      "trips": 3,
      "status": "pending",
    },
  ];

  final List<Map<String, dynamic>> drivers = [
    {
      "name": "Kasun Jayasinghe",
      "license": "LIC-DRV-001",
      "phone": "+94 72 555 6677",
      "operator": "SL Bus Company",
      "status": "approved",
      "trips": 25,
    },
    {
      "name": "Nimali Perera",
      "license": "LIC-DRV-002",
      "phone": "+94 71 123 4567",
      "operator": "City Shuttle",
      "status": "pending",
      "trips": 7,
    },
    {
      "name": "Saman Dias",
      "license": "LIC-DRV-003",
      "phone": "+94 75 765 4321",
      "operator": "Private Owner Group",
      "status": "rejected",
      "trips": 0,
    },
  ];

  final List<Map<String, dynamic>> operators = [
    {
      "name": "SL Bus Company",
      "fleetSize": 42,
      "drivers": 28,
      "phone": "+94 11 222 3333",
      "status": "active",
    },
    {
      "name": "City Shuttle",
      "fleetSize": 25,
      "drivers": 18,
      "phone": "+94 77 555 1212",
      "status": "active",
    },
    {
      "name": "Private Owner Group",
      "fleetSize": 9,
      "drivers": 6,
      "phone": "+94 71 900 0001",
      "status": "inactive",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> source, List<String> keys) {
    if (_search.isEmpty) return source;
    final needle = _search.toLowerCase();
    return source.where((item) {
      return keys.any((k) => item[k]?.toString().toLowerCase().contains(needle) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Details Report"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Passengers"),
            Tab(text: "Drivers"),
            Tab(text: "Operators"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search name...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PassengerList(items: _filter(passengers, ["name", "email", "phone"])),
                _DriverList(items: _filter(drivers, ["name", "license", "operator", "phone"])),
                _OperatorList(items: _filter(operators, ["name", "phone"])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassengerList extends StatelessWidget {
  const _PassengerList({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text("No passengers found"));

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final p = items[index];
        return _Tile(
          title: p["name"],
          subtitle: "Email: ${p["email"]}\nPhone: ${p["phone"]}\nTrips: ${p["trips"]}",
          badge: p["status"].toString().toUpperCase(),
          badgeColor: Colors.blue,
        );
      },
    );
  }
}

class _DriverList extends StatelessWidget {
  const _DriverList({required this.items});
  final List<Map<String, dynamic>> items;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text("No drivers found"));

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final d = items[index];
        final color = _statusColor(d["status"]);
        return _Tile(
          title: d["name"],
          subtitle:
              "License: ${d["license"]}\nPhone: ${d["phone"]}\nOperator: ${d["operator"]}\nTrips: ${d["trips"]}",
          badge: d["status"].toString().toUpperCase(),
          badgeColor: color,
        );
      },
    );
  }
}

class _OperatorList extends StatelessWidget {
  const _OperatorList({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text("No operators found"));

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final op = items[index];
        return _Tile(
          title: op["name"],
          subtitle:
              "Fleet size: ${op["fleetSize"]}\nDrivers: ${op["drivers"]}\nPhone: ${op["phone"]}",
          badge: op["status"].toString().toUpperCase(),
          badgeColor: Colors.deepPurple,
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: badgeColor.withOpacity(0.12),
          child: Icon(Icons.info, color: badgeColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badge,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
