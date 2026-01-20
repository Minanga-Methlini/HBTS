import 'package:flutter/material.dart';
import 'dart:math';
import 'customers_page.dart';
import 'drivers_dashboard.dart';
import 'operators_dashboard.dart';
import 'reports_dashboard.dart';
import 'buses_page.dart';
import 'schedule_page.dart';
import 'routes_page.dart';
import 'trips_page.dart';
import '../services/admin_api.dart';
import '../services/driver_admin_api.dart';
import '../theme/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;
  String? _error;
  int _passengerActive = 0;
  int _passengerPending = 0;
  int _passengerRejected = 0;
  int _driverActive = 0;
  int _driverPending = 0;
  int _driverRejected = 0;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    try {
      final passengersFuture = AdminApi.getPassengers("");
      final approvedDriversFuture =
          DriverAdminApi.list(status: "approved");
      final pendingDriversFuture =
          DriverAdminApi.list(status: "pending");
      final rejectedDriversFuture =
          DriverAdminApi.list(status: "rejected");

      final results = await Future.wait([
        passengersFuture,
        approvedDriversFuture,
        pendingDriversFuture,
        rejectedDriversFuture,
      ]);

      final passengers = results[0] as List<dynamic>;
      final approvedDrivers = results[1] as List<dynamic>;
      final pendingDrivers = results[2] as List<dynamic>;
      final rejectedDrivers = results[3] as List<dynamic>;

      final passengerCounts = _countPassengerStatuses(passengers);

      if (!mounted) return;
      setState(() {
        _passengerActive = passengerCounts.active;
        _passengerPending = passengerCounts.pending;
        _passengerRejected = passengerCounts.rejected;
        _driverActive = approvedDrivers.length;
        _driverPending = pendingDrivers.length;
        _driverRejected = rejectedDrivers.length;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  _StatusCounts _countPassengerStatuses(List<dynamic> passengers) {
    var active = 0;
    var pending = 0;
    var rejected = 0;

    for (final item in passengers) {
      if (item is! Map<String, dynamic>) {
        active += 1;
        continue;
      }
      final status = _normalizeStatus(
        item["status"] ??
            item["verification_status"] ??
            item["approval_status"],
      );
      if (status == "pending") {
        pending += 1;
      } else if (status == "rejected") {
        rejected += 1;
      } else {
        active += 1;
      }
    }

    return _StatusCounts(
      active: active,
      pending: pending,
      rejected: rejected,
    );
  }

  String _normalizeStatus(dynamic status) {
    final value = status?.toString().toLowerCase().trim() ?? "";
    if (value.contains("pend")) return "pending";
    if (value.contains("reject") || value.contains("block")) return "rejected";
    if (value.contains("active") ||
        value.contains("approve") ||
        value.contains("verify")) {
      return "active";
    }
    return value.isEmpty ? "active" : value;
  }

  @override
  Widget build(BuildContext context) {
    final groups = [
      _StatusGroup(
        title: "Passengers",
        active: _passengerActive,
        pending: _passengerPending,
        rejected: _passengerRejected,
        page: const CustomersPage(),
      ),
      _StatusGroup(
        title: "Drivers",
        active: _driverActive,
        pending: _driverPending,
        rejected: _driverRejected,
        page: const DriversDashboard(),
      ),
      _StatusGroup(
        title: "Bus Owners",
        active: 12,
        pending: 2,
        rejected: 1,
        page: const OperatorsDashboard(),
      ),
    ];
    final items = [
      _DashboardItem(
        title: "Buses",
        subtitle: "Availability overview",
        icon: Icons.directions_bus_rounded,
        page: const BusesPage(),
        slices: const [
          _ChartSlice(label: "Available", value: 28, color: AppColors.success),
          _ChartSlice(label: "In service", value: 6, color: AppColors.warning),
          _ChartSlice(label: "Unavailable", value: 3, color: AppColors.danger),
        ],
      ),
      _DashboardItem(
        title: "Schedule",
        subtitle: "Daily service status",
        icon: Icons.event_available_rounded,
        page: const SchedulePage(),
        slices: const [
          _ChartSlice(label: "On time", value: 18, color: AppColors.success),
          _ChartSlice(label: "Delayed", value: 5, color: AppColors.warning),
          _ChartSlice(label: "Cancelled", value: 2, color: AppColors.danger),
        ],
      ),
      _DashboardItem(
        title: "Routes",
        subtitle: "Network overview",
        icon: Icons.alt_route_rounded,
        page: const RoutesPage(),
        slices: const [
          _ChartSlice(label: "Active", value: 14, color: AppColors.success),
          _ChartSlice(label: "All routes", value: 19, color: AppColors.warning),
          _ChartSlice(label: "Paused", value: 1, color: AppColors.danger),
        ],
      ),
      _DashboardItem(
        title: "Trips",
        subtitle: "Daily trip stats",
        icon: Icons.route_rounded,
        page: const TripsPage(),
        slices: const [
          _ChartSlice(label: "Completed", value: 96, color: AppColors.success),
          _ChartSlice(label: "In progress", value: 12, color: AppColors.warning),
          _ChartSlice(label: "Cancelled", value: 4, color: AppColors.danger),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('HBTS+ Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppGradients.background,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Operations Overview",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Manage passengers, drivers, and compliance reports.",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Status Snapshot",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null && !_loading)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.danger),
                ),
              ),
            _SnapshotGrid(
              groups: groups,
              items: items,
              onReportTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsDashboard()),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _ReportAction extends StatelessWidget {
  final VoidCallback onPressed;

  const _ReportAction({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.insights_rounded),
        label: const Text("Open Reports"),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _StatusCounts {
  final int active;
  final int pending;
  final int rejected;

  const _StatusCounts({
    required this.active,
    required this.pending,
    required this.rejected,
  });
}

class _DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;
  final List<_ChartSlice> slices;

  _DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
    required this.slices,
  });
}

class _ChartSlice {
  final String label;
  final int value;
  final Color color;

  const _ChartSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _InteractiveDonutChart extends StatelessWidget {
  final double size;
  final List<_ChartSlice> slices;
  final VoidCallback onSliceTap;

  const _InteractiveDonutChart({
    required this.size,
    required this.slices,
    required this.onSliceTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        if (_hitSlice(details.localPosition)) {
          onSliceTap();
        }
      },
      child: CustomPaint(
        size: Size(size, size),
        painter: _InteractiveDonutPainter(slices: slices),
      ),
    );
  }

  bool _hitSlice(Offset position) {
    final center = Offset(size / 2, size / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance < size * 0.22 || distance > size * 0.48) {
      return false;
    }
    final total = slices.fold<int>(0, (sum, s) => sum + s.value);
    if (total == 0) return false;
    return true;
  }
}

class _InteractiveDonutPainter extends CustomPainter {
  final List<_ChartSlice> slices;

  _InteractiveDonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final total = slices.fold<int>(0, (sum, s) => sum + s.value);
    if (total == 0) {
      stroke.color = AppColors.outline;
      canvas.drawCircle(center, radius - 6, stroke);
      return;
    }

    var startAngle = -pi / 2;
    for (final slice in slices) {
      final sweep = (slice.value / total) * pi * 2;
      if (sweep <= 0) continue;
      stroke.color = slice.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 6),
        startAngle,
        sweep,
        false,
        stroke,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveDonutPainter oldDelegate) {
    if (oldDelegate.slices.length != slices.length) return true;
    for (var i = 0; i < slices.length; i++) {
      if (oldDelegate.slices[i].value != slices[i].value) return true;
    }
    return false;
  }
}

class _StatusGroup {
  final String title;
  final int active;
  final int pending;
  final int rejected;
  final Widget page;

  const _StatusGroup({
    required this.title,
    required this.active,
    required this.pending,
    required this.rejected,
    required this.page,
  });

  int get total => active + pending + rejected;
}

class _SnapshotGrid extends StatelessWidget {
  final List<_StatusGroup> groups;
  final List<_DashboardItem> items;
  final VoidCallback onReportTap;

  const _SnapshotGrid({
    required this.groups,
    required this.items,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      ...groups.map(
        (group) => _SnapshotCard(
          title: group.title,
          subtitle: "Active / Pending / Rejected",
          slices: [
            _ChartSlice(
              label: "Active",
              value: group.active,
              color: AppColors.success,
            ),
            _ChartSlice(
              label: "Pending",
              value: group.pending,
              color: AppColors.warning,
            ),
            _ChartSlice(
              label: "Rejected",
              value: group.rejected,
              color: AppColors.danger,
            ),
          ],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => group.page),
          ),
        ),
      ),
      ...items.map(
        (item) => _SnapshotCard(
          title: item.title,
          subtitle: item.subtitle,
          slices: item.slices,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => item.page),
          ),
        ),
      ),
      _ReportCard(onTap: onReportTap),
    ];

    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_ChartSlice> slices;
  final VoidCallback onTap;

  const _SnapshotCard({
    required this.title,
    required this.subtitle,
    required this.slices,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _InteractiveDonutChart(
                  size: 78,
                  slices: slices,
                  onSliceTap: onTap,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              ...slices.map(
                (slice) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _LegendRow(
                    color: slice.color,
                    label: slice.label,
                    value: slice.value,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            "$label: $value",
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ReportCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Reports",
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                "Open analytics dashboard",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  child: const Text("Open"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
