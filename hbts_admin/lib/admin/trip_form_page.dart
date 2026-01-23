import 'package:flutter/material.dart';
import '../services/admin_api.dart';
import '../theme/app_theme.dart';

class TripFormPage extends StatefulWidget {
  const TripFormPage({super.key, this.trip});

  final Map<String, dynamic>? trip;

  @override
  State<TripFormPage> createState() => _TripFormPageState();
}

class _TripFormPageState extends State<TripFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _operatorIdCtrl = TextEditingController();
  final _tripDateCtrl = TextEditingController();
  final _departureCtrl = TextEditingController();
  final _arrivalCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _buses = [];
  List<Map<String, dynamic>> _drivers = [];

  int? _selectedRouteId;
  int? _selectedBusId;
  int? _selectedDriverId;
  String _selectedStatus = "scheduled";

  int? get _tripId {
    final trip = widget.trip;
    if (trip == null) return null;
    final raw = trip["trip_id"] ?? trip["id"] ?? trip["tripId"];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? "");
  }

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _seedFromTrip();
  }

  @override
  void dispose() {
    _operatorIdCtrl.dispose();
    _tripDateCtrl.dispose();
    _departureCtrl.dispose();
    _arrivalCtrl.dispose();
    super.dispose();
  }

  void _seedFromTrip() {
    final trip = widget.trip;
    if (trip == null) return;
    _selectedRouteId = _parseInt(trip["route_id"]);
    _selectedBusId = _parseInt(trip["bus_id"]);
    _selectedDriverId = _parseInt(trip["driver_id"]);
    _operatorIdCtrl.text = (trip["operator_id"] ?? "").toString();
    _tripDateCtrl.text = _formatDate(trip["trip_date"]);
    _departureCtrl.text = _formatDateTime(trip["departure_time"]);
    _arrivalCtrl.text = _formatDateTime(trip["arrival_time"]);
    final status = trip["status"]?.toString().trim();
    if (status != null && status.isNotEmpty) {
      _selectedStatus = status.toLowerCase();
    }
  }

  Future<void> _loadOptions() async {
    setState(() => _loading = true);
    try {
      final routes = await AdminApi.getRoutes();
      final buses = await AdminApi.getBuses();
      final drivers = await AdminApi.getAssignableDrivers();
      if (!mounted) return;
      setState(() {
        _routes = routes.cast<Map<String, dynamic>>();
        _buses = buses.cast<Map<String, dynamic>>();
        _drivers = drivers.cast<Map<String, dynamic>>();
        if (_selectedBusId != null) {
          _autoFillOperatorFromBus(_selectedBusId);
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  int? _operatorIdForSelectedBus() {
    if (_selectedBusId == null) return null;
    final bus = _buses.firstWhere(
      (b) => _parseInt(b["bus_id"]) == _selectedBusId,
      orElse: () => {},
    );
    return _parseInt(bus["operator_id"]);
  }

  Map<String, dynamic> _buildPayload() {
    final operatorFromBus = _operatorIdForSelectedBus();
    return {
      "routeId": _selectedRouteId,
      "operatorId": operatorFromBus ?? _parseInt(_operatorIdCtrl.text),
      "busId": _selectedBusId,
      "driverId": _selectedDriverId,
      "tripDate": _tripDateCtrl.text.trim(),
      "departureTime": _departureCtrl.text.trim(),
      "arrivalTime": _arrivalCtrl.text.trim(),
      "status": _selectedStatus,
    };
  }

  Future<void> _addRecord() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AdminApi.addTrip(_buildPayload());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Trip added")));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateRecord() async {
    final tripId = _tripId;
    if (tripId == null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AdminApi.updateTrip(tripId, _buildPayload());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Trip updated")));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteRecord() async {
    final tripId = _tripId;
    if (tripId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete trip?"),
        content: const Text("Are you sure you want to delete this record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await AdminApi.deleteTrip(tripId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Trip deleted")));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _routeLabel(Map<String, dynamic> route) {
    final name = route["route_name"] ?? route["name"] ?? "";
    final code = route["route_no"] ?? route["route_code"] ?? "";
    return "${name.toString().trim()} (${code.toString().trim()})"
        .replaceAll(RegExp(r"\\s+\\(\\)"), "")
        .trim();
  }

  String _busLabel(Map<String, dynamic> bus) {
    final plate = bus["license_plate_no"] ?? bus["license_plate"] ?? "-";
    final id = bus["bus_id"] ?? "-";
    return "$plate (ID $id)";
  }

  String _driverLabel(Map<String, dynamic> driver) {
    final name = driver["name"] ??
        driver["full_name"] ??
        driver["driver_name"] ??
        "-";
    final id = driver["driver_id"] ?? driver["id"] ?? "-";
    return "$name (ID $id)";
  }

  void _autoFillOperatorFromBus(int? busId) {
    if (busId == null) return;
    final bus =
        _buses.firstWhere((b) => _parseInt(b["bus_id"]) == busId, orElse: () => {});
    final operatorId = bus["operator_id"];
    if (operatorId != null) {
      _operatorIdCtrl.text = operatorId.toString();
    }
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hint,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _tripId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Trip" : "Add Trip")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _saving,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isEdit)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            "Trip ID: ${_tripId ?? "-"}",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      DropdownButtonFormField<int>(
                        value: _selectedRouteId,
                        items: _routes
                            .map(
                              (r) => DropdownMenuItem<int>(
                                value: _parseInt(r["route_id"]),
                                child: Text(_routeLabel(r)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedRouteId = value),
                        decoration:
                            const InputDecoration(labelText: "Route"),
                        validator: (value) =>
                            value == null ? "Route is required" : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedBusId,
                        items: _buses
                            .map(
                              (b) => DropdownMenuItem<int>(
                                value: _parseInt(b["bus_id"]),
                                child: Text(_busLabel(b)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedBusId = value);
                          _autoFillOperatorFromBus(value);
                        },
                        decoration:
                            const InputDecoration(labelText: "Bus"),
                        validator: (value) =>
                            value == null ? "Bus is required" : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedDriverId,
                        items: _drivers
                            .map(
                              (d) => DropdownMenuItem<int>(
                                value: _parseInt(d["driver_id"] ?? d["id"]),
                                child: Text(_driverLabel(d)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedDriverId = value),
                        decoration:
                            const InputDecoration(labelText: "Driver"),
                        validator: (value) =>
                            value == null ? "Driver is required" : null,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        label: "Operator ID",
                        controller: _operatorIdCtrl,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if ((value ?? "").trim().isEmpty &&
                              _operatorIdForSelectedBus() == null) {
                            return "Operator ID is required";
                          }
                          return null;
                        },
                        hint: "Auto-filled from selected bus",
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        label: "Trip Date",
                        controller: _tripDateCtrl,
                        hint: "YYYY-MM-DD",
                        validator: (value) {
                          if ((value ?? "").trim().isEmpty) {
                            return "Trip date is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        label: "Departure Time",
                        controller: _departureCtrl,
                        hint: "YYYY-MM-DD HH:MM:SS",
                        validator: (value) {
                          if ((value ?? "").trim().isEmpty) {
                            return "Departure time is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        label: "Arrival Time",
                        controller: _arrivalCtrl,
                        hint: "YYYY-MM-DD HH:MM:SS",
                        validator: (value) {
                          if ((value ?? "").trim().isEmpty) {
                            return "Arrival time is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        items: const [
                          DropdownMenuItem(
                            value: "scheduled",
                            child: Text("Scheduled"),
                          ),
                          DropdownMenuItem(
                            value: "in_progress",
                            child: Text("In Progress"),
                          ),
                          DropdownMenuItem(
                            value: "completed",
                            child: Text("Completed"),
                          ),
                          DropdownMenuItem(
                            value: "cancelled",
                            child: Text("Cancelled"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedStatus = value);
                        },
                        decoration:
                            const InputDecoration(labelText: "Status"),
                      ),
                      const SizedBox(height: 18),
                      if (!isEdit)
                        ElevatedButton.icon(
                          onPressed: _addRecord,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text("Add Record"),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isEdit ? _updateRecord : null,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text("Update"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isEdit ? _deleteRecord : null,
                              icon: const Icon(Icons.delete_outline),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side:
                                    const BorderSide(color: AppColors.danger),
                              ),
                              label: const Text("Delete"),
                            ),
                          ),
                        ],
                      ),
                      if (_saving)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

String _formatDate(dynamic value) {
  if (value == null) return "";
  final raw = value.toString();
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final y = parsed.year.toString().padLeft(4, "0");
  final m = parsed.month.toString().padLeft(2, "0");
  final d = parsed.day.toString().padLeft(2, "0");
  return "$y-$m-$d";
}

String _formatDateTime(dynamic value) {
  if (value == null) return "";
  final raw = value.toString();
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final y = parsed.year.toString().padLeft(4, "0");
  final m = parsed.month.toString().padLeft(2, "0");
  final d = parsed.day.toString().padLeft(2, "0");
  final h = parsed.hour.toString().padLeft(2, "0");
  final min = parsed.minute.toString().padLeft(2, "0");
  return "$y-$m-$d $h:$min:00";
}
