import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_api.dart';

class NotificationStore extends ChangeNotifier {
  final List<PassengerNotification> _items = [];
  bool _loading = false;
  Timer? _timer;

  List<PassengerNotification> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  int _typePriority(PassengerNotification n) {
    final t = n.type.toUpperCase();
    final c = n.category.toLowerCase();

    // 1) Trip status updates are highest (your rule)
    if (t.contains("DELAY") || t.contains("CANCEL") || t.contains("STATUS") || c == "system") {
      return 1;
    }

    // 2) Booking confirmations
    if (t.contains("BOOK") || c == "booking") return 2;

    // 3) Payment confirmations
    if (t.contains("PAY") || c == "payment") return 3;

    // 4) Everything else
    return 4;
  }

  void _sort() {
    _items.sort((a, b) {
      // unread first
      if (a.isRead != b.isRead) return a.isRead ? 1 : -1;

      // status updates first
      final pa = _typePriority(a);
      final pb = _typePriority(b);
      if (pa != pb) return pa.compareTo(pb);

      // newest first
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();

    try {
      final raw = await NotificationApi.fetchNotifications();

      final parsed = <PassengerNotification>[];
      for (final e in raw) {
        if (e is Map) {
          parsed.add(PassengerNotification.fromJson(Map<String, dynamic>.from(e)));
        }
      }

      _items
        ..clear()
        ..addAll(parsed);

      _sort();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      try {
        await refresh();
      } catch (_) {
        // keep silent
      }
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> markRead(int id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    if (_items[idx].isRead) return;

    // optimistic update
    _items[idx] = _items[idx].copyWith(isRead: true);
    _sort();
    notifyListeners();

    try {
      await NotificationApi.markAsRead(id.toString());
    } catch (_) {
      // revert if API fails
      _items[idx] = _items[idx].copyWith(isRead: false);
      _sort();
      notifyListeners();
    }
  }
}
