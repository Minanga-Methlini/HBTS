import 'package:flutter/material.dart';
import '../services/admin_api.dart';
import '../theme/app_theme.dart';
import 'trip_form_page.dart';

class TripDetailsPage extends StatefulWidget {
  const TripDetailsPage({super.key, required this.trip});

  final Map<String, dynamic> trip;

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<dynamic>> _stopsFuture;
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _stopsFuture = _loadStops();
    _historyFuture = _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _loadStops() async {
    final tripId = _tripId;
    if (tripId == null) return [];
    return await AdminApi.getTripStops(tripId);
  }

  Future<List<dynamic>> _loadHistory() async {
    final tripId = _tripId;
    if (tripId == null) return [];
    return await AdminApi.getTripLocationHistory(tripId);
  }

  int? get _tripId {
    final raw = widget.trip["trip_id"] ?? widget.trip["id"];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? "");
  }

  String _value(String key, {String fallback = "-"}) {
    final v = widget.trip[key];
    if (v == null || v.toString().trim().isEmpty) return fallback;
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final tripId = _value("trip_id");
    final routeName = _value("route_name", fallback: _value("route_code"));
    final plate = _value("license_plate_no");
    final driverName = _value("driver_name");
    final tripDate = _formatDate(widget.trip["trip_date"]);
    final departure = _formatDateTime(widget.trip["departure_time"]);
    final arrival = _formatDateTime(widget.trip["arrival_time"]);
    final status = _value("status", fallback: "scheduled");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Details"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Details"),
            Tab(text: "Stops"),
            Tab(text: "Location"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routeName.isEmpty ? "Trip $tripId" : routeName,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(label: "Trip ID", value: tripId),
                        const SizedBox(height: 6),
                        _InfoRow(label: "Bus", value: plate),
                        const SizedBox(height: 6),
                        _InfoRow(label: "Driver", value: driverName),
                        const SizedBox(height: 6),
                        _InfoRow(label: "Date", value: tripDate),
                        const SizedBox(height: 6),
                        _InfoRow(label: "Depart", value: departure),
                        const SizedBox(height: 6),
                        _InfoRow(label: "Arrive", value: arrival),
                        const SizedBox(height: 6),
                        _InfoRow(label: "Status", value: status),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripFormPage(trip: widget.trip),
                      ),
                    );
                    if (changed == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Trip"),
                ),
              ],
            ),
          ),
          FutureBuilder<List<dynamic>>(
            future: _stopsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              final stops = snapshot.data ?? [];
              if (stops.isEmpty) {
                return const Center(child: Text("No trip stops found"));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: stops.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final stop = stops[index] as Map<String, dynamic>;
                  final name = stop["stop_name"] ?? "Stop ${stop["stop_id"]}";
                  final code = stop["stop_code"]?.toString();
                  final order = stop["stop_order"]?.toString() ?? "-";
                  final time = _formatDateTime(stop["scheduled_time"]);
                  final boarding = stop["is_boarding_allowed"] == true;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$order. $name${code != null ? " ($code)" : ""}",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text("Scheduled: $time"),
                          Text("Boarding: ${boarding ? "Yes" : "No"}"),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          FutureBuilder<List<dynamic>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Text("No location history found"));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final item = items[index] as Map<String, dynamic>;
                  final lat = item["lat"]?.toString() ?? "-";
                  final lng = item["lng"]?.toString() ?? "-";
                  final speed = item["speed"]?.toString() ?? "-";
                  final time = _formatDateTime(item["recorded_at"]);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Lat: $lat, Lng: $lng",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text("Speed: $speed"),
                          Text("Time: $time"),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

String _formatDate(dynamic value) {
  if (value == null) return "-";
  final raw = value.toString();
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final y = parsed.year.toString().padLeft(4, "0");
  final m = parsed.month.toString().padLeft(2, "0");
  final d = parsed.day.toString().padLeft(2, "0");
  return "$y-$m-$d";
}

String _formatDateTime(dynamic value) {
  if (value == null) return "-";
  final raw = value.toString();
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final y = parsed.year.toString().padLeft(4, "0");
  final m = parsed.month.toString().padLeft(2, "0");
  final d = parsed.day.toString().padLeft(2, "0");
  final h = parsed.hour.toString().padLeft(2, "0");
  final min = parsed.minute.toString().padLeft(2, "0");
  return "$y-$m-$d $h:$min";
}
