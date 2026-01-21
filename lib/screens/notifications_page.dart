import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/notification_store.dart';
import '../models/notification_model.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NotificationStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<NotificationStore>().refresh(),
          ),
        ],
      ),
      body: store.loading
          ? const Center(child: CircularProgressIndicator())
          : store.items.isEmpty
              ? const Center(child: Text("No notifications yet"))
              : RefreshIndicator(
                  onRefresh: () => context.read<NotificationStore>().refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: store.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final n = store.items[i];
                      return _NotificationTile(
                        n: n,
                        onTap: () async {
                          await context.read<NotificationStore>().markRead(n.id);

                          if (!context.mounted) return;

                          // ✅ Routing stub (implement later)
                          // Trip updates -> Trip details
                          // Booking/payment -> Booking details
                          final tripId = n.data["tripId"] ?? n.data["trip_id"];
                          final bookingId = n.data["bookingId"] ?? n.data["booking_id"];

                          if (tripId != null) {
                            // Navigator.pushNamed(context, AppRoutes.tripDetails, arguments: tripId);
                            return;
                          }
                          if (bookingId != null) {
                            // Navigator.pushNamed(context, AppRoutes.bookingDetails, arguments: bookingId);
                            return;
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final PassengerNotification n;
  final VoidCallback onTap;

  const _NotificationTile({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !n.isRead;

    final icon = _iconFor(n);
    final accent = _accentFor(n);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread ? Colors.blue.shade100 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),

            // text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title.isNotEmpty ? n.title : "Notification",
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.w900 : FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _timeAgo(n.createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PassengerNotification n) {
    final t = n.type.toUpperCase();
    final c = n.category.toLowerCase();

    if (t.contains("DELAY")) return Icons.schedule_rounded;
    if (t.contains("CANCEL")) return Icons.cancel_rounded;
    if (t.contains("STATUS") || c == "system") return Icons.info_rounded;
    if (c == "payment" || t.contains("PAY")) return Icons.payments_rounded;
    if (t.contains("BOOK") || c == "booking") return Icons.confirmation_number_rounded;

    return Icons.notifications_rounded;
  }

  Color _accentFor(PassengerNotification n) {
    final t = n.type.toUpperCase();
    final c = n.category.toLowerCase();

    if (t.contains("CANCEL")) return Colors.red.shade600;
    if (t.contains("DELAY") || t.contains("STATUS") || c == "system") return Colors.orange.shade700;
    if (c == "payment") return Colors.green.shade700;
    if (c == "booking") return Colors.blue.shade700;

    return Colors.blueGrey;
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    return "${diff.inDays} day${diff.inDays == 1 ? "" : "s"} ago";
  }
}
