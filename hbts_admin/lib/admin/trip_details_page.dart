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
  late Map<String, dynamic> _trip;
  late final TabController _tabController;
  late Future<List<dynamic>> _stopsFuture;
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _trip = Map<String, dynamic>.from(widget.trip);
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
    final raw = _trip["trip_id"] ?? _trip["tripId"] ?? _trip["id"];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? "");
  }

  String _value(String key, {String fallback = "-"}) {
    final v = _trip[key];
    if (v == null || v.toString().trim().isEmpty) return fallback;
    return v.toString();
  }

  String _valueAny(List<String> keys, {String fallback = "-"}) {
    for (final key in keys) {
      final value = _value(key, fallback: "");
      if (value.trim().isNotEmpty) return value;
    }
    return fallback;
  }

  void _applyTripUpdate(Map<String, dynamic> updated) {
    setState(() {
      _trip = {..._trip, ...updated};
      _stopsFuture = _loadStops();
      _historyFuture = _loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripId = _valueAny(["trip_id", "tripId", "id"]);
    final routeName =
        _valueAny(["route_name", "routeName", "name"], fallback: _valueAny([
      "route_code",
      "route_no",
      "routeCode",
    ]));
    final plate =
        _valueAny(["license_plate_no", "license_plate", "plate_no"]);
    final driverName =
        _valueAny(["driver_name", "driverName", "full_name", "name"]);
    final tripDate = _formatDate(_trip["trip_date"] ?? _trip["tripDate"]);
    final departure =
        _formatDateTime(_trip["departure_time"] ?? _trip["departureTime"]);
    final arrival =
        _formatDateTime(_trip["arrival_time"] ?? _trip["arrivalTime"]);
    final status = _valueAny(["status"], fallback: "scheduled");
    final statusLabel = _statusLabel(status);

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
                        _InfoRow(label: "Status", value: statusLabel),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripFormPage(trip: _trip),
                      ),
                    );
                    if (!mounted) return;
                    if (result is Map<String, dynamic>) {
                      _applyTripUpdate(result);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Trip updated")),
                      );
                      return;
                    }
                    if (result == true) {
                      setState(() {
                        _stopsFuture = _loadStops();
                        _historyFuture = _loadHistory();
                      });
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
                  final stopId = stop["stop_id"] ?? stop["stopId"] ?? stop["id"];
                  final name = stop["stop_name"] ??
                      stop["stopName"] ??
                      stop["name"] ??
                      "Stop $stopId";
                  final code = stop["stop_code"] ??
                      stop["stopCode"] ??
                      stop["code"];
                  final order = stop["stop_order"] ??
                      stop["stopOrder"] ??
                      stop["order"];
                  final time =
                      _formatDateTime(stop["scheduled_time"] ?? stop["time"]);
                  final boarding = stop["is_boarding_allowed"] == true;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${order ?? "-"}${order == null ? "" : "."} $name${code != null ? " ($code)" : ""}",
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
                  final lat =
                      (item["lat"] ?? item["latitude"] ?? item["lat_deg"])
                          ?.toString() ??
                          "-";
                  final lng =
                      (item["lng"] ?? item["longitude"] ?? item["lng_deg"])
                          ?.toString() ??
                          "-";
                  final speed = (item["speed"] ?? item["velocity"])
                          ?.toString() ??
                      "-";
                  final time = _formatDateTime(
                    item["recorded_at"] ?? item["recordedAt"] ?? item["time"],
                  );
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

String _statusLabel(String value) {
  final normalized = value.toLowerCase().trim();
  if (normalized.contains("progress")) return "running";
  if (normalized.contains("cancel")) return "cancelled";
  return normalized.isEmpty ? "scheduled" : value;
}
