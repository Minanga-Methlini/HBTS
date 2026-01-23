import 'package:flutter/material.dart';
import '../services/admin_api.dart';
import 'bus_card.dart';

class BusHistoryPage extends StatefulWidget {
  const BusHistoryPage({super.key});

  @override
  State<BusHistoryPage> createState() => _BusHistoryPageState();
}

class _BusHistoryPageState extends State<BusHistoryPage> {
  List<Map<String, dynamic>> _buses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await AdminApi.getBusHistory();
      if (!mounted) return;
      setState(() {
        _buses = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bus History")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: _buses.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text("No deleted buses found")),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _buses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            return BusCard(bus: _buses[index]);
                          },
                        ),
                ),
    );
  }
}
