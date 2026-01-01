import 'package:flutter/material.dart';
import '../services/notification_api.dart';
import '../widgets/notification_card.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await NotificationApi.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load notifications")),
      );
    }
  }

  Future<void> _handleTap(Map<String, dynamic> n) async {
    if (n['is_read'] != true) {
      await NotificationApi.markAsRead(n['id'].toString());
      _loadNotifications();
    }

    // Optional navigation to booking
    if (n['booking_id'] != null) {
      // Navigator.pushNamed(context, AppRoutes.bookingDetails, arguments: n['booking_id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text("No notifications yet"))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      return NotificationCard(
                        notification: n,
                        onTap: () => _handleTap(n),
                      );
                    },
                  ),
                ),
    );
  }
}
