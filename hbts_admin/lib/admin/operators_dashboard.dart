import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OperatorsDashboard extends StatefulWidget {
  const OperatorsDashboard({super.key});

  @override
  State<OperatorsDashboard> createState() => _OperatorsDashboardState();
}

class _OperatorsDashboardState extends State<OperatorsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _dummyOperators = [
    {
      "operator_id": 1,
      "name": "SL Bus Company",
      "status": "active",
      "fleetSize": 42,
      "drivers": 28,
      "phone": "+94 11 222 3333",
    },
    {
      "operator_id": 2,
      "name": "City Shuttle",
      "status": "active",
      "fleetSize": 25,
      "drivers": 18,
      "phone": "+94 77 555 1212",
    },
    {
      "operator_id": 3,
      "name": "Private Owner Group",
      "status": "inactive",
      "fleetSize": 9,
      "drivers": 6,
      "phone": "+94 71 900 0001",
    },
    {
      "operator_id": 4,
      "name": "Northern Transit",
      "status": "suspended",
      "fleetSize": 12,
      "drivers": 10,
      "phone": "+94 76 210 4321",
    },
  ];

  String _search = "";

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

  List<Map<String, dynamic>> _filtered(String status) {
    return _dummyOperators.where((op) {
      final matchesStatus = op["status"] == status;
      final matchesSearch = _search.isEmpty ||
          op["name"]
              .toString()
              .toLowerCase()
              .contains(_search.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Operators Dashboard"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Active"),
            Tab(text: "Inactive"),
            Tab(text: "Suspended"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search operator...",
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OperatorList(
                  operators: _filtered("active"),
                  badgeColor: AppColors.success,
                ),
                _OperatorList(
                  operators: _filtered("inactive"),
                  badgeColor: AppColors.warning,
                ),
                _OperatorList(
                  operators: _filtered("suspended"),
                  badgeColor: AppColors.danger,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorList extends StatelessWidget {
  const _OperatorList({
    required this.operators,
    required this.badgeColor,
  });

  final List<Map<String, dynamic>> operators;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    if (operators.isEmpty) {
      return const Center(child: Text("No operators found"));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: operators.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final op = operators[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: badgeColor.withOpacity(0.15),
              child: Icon(Icons.apartment, color: badgeColor),
            ),
            title: Text(
              op["name"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("Fleet size: ${op["fleetSize"]}"),
                Text("Drivers: ${op["drivers"]}"),
                Text("Phone: ${op["phone"]}"),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                op["status"].toString().toUpperCase(),
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
