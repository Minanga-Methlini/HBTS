import 'package:flutter/material.dart';

/// ======================
/// ENUMS & MODELS (UI)
/// ======================

enum BookingStatus {
  scheduled,
  delayed,
  cancelled,
  onboard,
  completed,
}

class Booking {
  final String route;
  final String dateTime;
  final BookingStatus status;
  final List<int> seats;

  Booking({
    required this.route,
    required this.dateTime,
    required this.status,
    required this.seats,
  });
}

/// ======================
/// MAIN PAGE
/// ======================

class PassengerBookingsPage extends StatelessWidget {
  const PassengerBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Bookings"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Current Bookings"),
              Tab(text: "Booking History"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CurrentBookingsTab(),
            BookingHistoryTab(),
          ],
        ),
      ),
    );
  }
}

/// ======================
/// CURRENT BOOKINGS TAB
/// ======================

class CurrentBookingsTab extends StatelessWidget {
  const CurrentBookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = [
      Booking(
        route: "Colombo → Kandy",
        dateTime: "12 Aug 2025 · 6:30 AM",
        status: BookingStatus.onboard,
        seats: [5],
      ),
      Booking(
        route: "Kandy → Jaffna",
        dateTime: "15 Aug 2025 · 9:00 PM",
        status: BookingStatus.delayed,
        seats: [12],
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bookings.length,
      itemBuilder: (_, i) {
        final booking = bookings[i];
        return BookingCard(
          booking: booking,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingDetailsPage(booking: booking),
              ),
            );
          },
        );
      },
    );
  }
}

/// ======================
/// BOOKING HISTORY TAB
/// ======================

class BookingHistoryTab extends StatelessWidget {
  const BookingHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final history = [
      Booking(
        route: "Colombo → Galle",
        dateTime: "02 Jul 2025 · 7:00 AM",
        status: BookingStatus.completed,
        seats: const [],
      ),
      Booking(
        route: "Galle → Colombo",
        dateTime: "10 Jun 2025 · 5:30 PM",
        status: BookingStatus.cancelled,
        seats: const [],
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: history.length,
      itemBuilder: (_, i) {
        return BookingCard(booking: history[i]);
      },
    );
  }
}

/// ======================
/// BOOKING CARD
/// ======================

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.route,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.dateTime,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: booking.status),
            ],
          ),
        ),
      ),
    );
  }
}

/// ======================
/// BOOKING DETAILS PAGE
/// ======================

class BookingDetailsPage extends StatelessWidget {
  final Booking booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking Details")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            booking.route,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(booking.dateTime),
          const SizedBox(height: 16),

          StatusBadge(status: booking.status, large: true),

          const SizedBox(height: 24),
          const Text(
            "Your Seat",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          SeatMapView(selectedSeats: booking.seats),
        ],
      ),
    );
  }
}

/// ======================
/// STATUS BADGE
/// ======================

class StatusBadge extends StatelessWidget {
  final BookingStatus status;
  final bool large;

  const StatusBadge({
    super.key,
    required this.status,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = {
      BookingStatus.scheduled: "Scheduled",
      BookingStatus.delayed: "Delayed",
      BookingStatus.cancelled: "Cancelled",
      BookingStatus.onboard: "Passenger in Bus",
      BookingStatus.completed: "Completed",
    }[status]!;

    final color = {
      BookingStatus.scheduled: Colors.blue,
      BookingStatus.delayed: Colors.orange,
      BookingStatus.cancelled: Colors.red,
      BookingStatus.onboard: Colors.green,
      BookingStatus.completed: Colors.grey,
    }[status]!;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: large ? 14 : 12,
        ),
      ),
    );
  }
}

/// ======================
/// SEAT MAP (READ ONLY)
/// ======================

class SeatMapView extends StatelessWidget {
  final List<int> selectedSeats;

  const SeatMapView({super.key, required this.selectedSeats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 20,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (_, i) {
        final seatNo = i + 1;
        final isMine = selectedSeats.contains(seatNo);

        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isMine ? Colors.blue.shade700 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            seatNo.toString(),
            style: TextStyle(
              color: isMine ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
