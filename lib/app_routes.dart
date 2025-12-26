import 'package:flutter/material.dart';

import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/profile_page.dart';
import 'screens/schedule_page.dart';
import 'screens/my_bookings_page.dart';
import 'screens/track_my_booking_page.dart';
import 'screens/track_bus_page.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const profile = '/profile';
  static const schedule = '/schedule';
  static const myBookings = '/my-bookings';
  static const trackMyBooking = '/track-my-booking';
  static const trackBus = '/track-bus';

  static Route<dynamic> onGenerate(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case profile:
        final args = settings.arguments;
        if (args is ProfileArgs) {
          return MaterialPageRoute(builder: (_) => ProfilePage(args: args));
        }
        return _badRoute("Profile args missing");

      case schedule:
        return MaterialPageRoute(builder: (_) => SchedulePage());

      case myBookings:
        return MaterialPageRoute(builder: (_) => MyBookingsPage());

      case trackMyBooking:
        return MaterialPageRoute(builder: (_) => TrackMyBookingPage());

      case trackBus:
        return MaterialPageRoute(builder: (_) => TrackBusPage());

      default:
        return _badRoute("Route not found: ${settings.name}");
    }
  }

  static Route<dynamic> _badRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Navigation error")),
        body: Center(child: Text(message)),
      ),
    );
  }
}

// Profile arguments
class ProfileArgs {
  final String name;
  final String email;
  final String id;
  final String? phone;
  final String? photoUrl;

  ProfileArgs({
    required this.name,
    required this.email,
    required this.id,
    this.phone,
    this.photoUrl,
  });
}
