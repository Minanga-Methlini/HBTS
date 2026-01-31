// src/controllers/trip.controller.js
import { pool } from "../db.js";
import { expirePendingBookingsOnce } from "../jobs/expirePendingBookings.job.js";
import { emitTripStarted } from "../ws/realtime.ws.js";


const TTL_MINUTES = Number(process.env.PENDING_TTL_MINUTES || 10);

/**
 * GET /api/trips?from=Colombo&to=Kandy&date=YYYY-MM-DD
 */
export async function searchTrips(req, res) {
  try {
    const { from, to, date } = req.query;

    if (!from || !to || !date) {
      return res.status(400).json({ message: "from, to and date are required" });
    }

    // Clean expired pending bookings so available seats are accurate
    await expirePendingBookingsOnce();

    const result = await pool.query(
      `
      SELECT
        t.trip_id AS id,
        t.trip_date,
        t.departure_time,
        t.arrival_time,
        t.status,
        r.route_name,
        r.from_location,
        r.to_location,
        b.bus_id,
        b.capacity,
        b.service_type
      FROM trips t
      JOIN routes r ON t.route_id = r.route_id
      JOIN buses b ON t.bus_id = b.bus_id
      WHERE LOWER(r.from_location) = LOWER(TRIM($1))
  AND LOWER(r.to_location)   = LOWER(TRIM($2))
  AND t.trip_date            = $3::date

      ORDER BY t.departure_time
      `,
      [from, to, date]
    );

    return res.json(result.rows);
  } catch (err) {
    console.error("searchTrips error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

/**
 * GET /api/trips/:id
 */
export async function getTripById(req, res) {
  try {
    const { id } = req.params;

    await expirePendingBookingsOnce();

    const result = await pool.query(
      `
      SELECT
        t.trip_id AS id,
        t.trip_date,
        t.departure_time,
        t.arrival_time,
        t.status,
        t.operator_id,
        t.bus_id,
        t.driver_id,
        r.route_name,
        r.from_location,
        r.to_location,
        r.distance_km,
        r.polyline,
        b.capacity,
        b.service_type,
        b.license_plate_no,
        b.model
      FROM trips t
      JOIN routes r ON t.route_id = r.route_id
      JOIN buses b ON t.bus_id = b.bus_id
      WHERE t.trip_id = $1
      `,
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: "Trip not found" });
    }

    return res.json(result.rows[0]);
  } catch (err) {
    console.error("getTripById error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

/**
 * GET /api/trips/:id/seats
 * Returns seat layout with booking status.
 */
export async function getTripSeats(req, res) {
  try {
    const { id: tripId } = req.params;

    // Clean expired pending holds
    await expirePendingBookingsOnce();

    const seats = await pool.query(
      `
      SELECT
        s.seat_id,
        s.seat_label,
        s.seat_row,
        s.seat_col,
        s.seat_type,
        CASE
          WHEN b.booking_id IS NULL THEN false
          ELSE true
        END AS is_booked
      FROM trips t
      JOIN seats s ON s.bus_id = t.bus_id
      LEFT JOIN bookings b
        ON b.trip_id = t.trip_id
       AND b.seat_id = s.seat_id
       AND (
         b.status = 'confirmed'
         OR (b.status = 'pending' AND b.booking_time >= NOW() - ($2::text || ' minutes')::interval)
       )
      WHERE t.trip_id = $1
      ORDER BY s.seat_row, s.seat_col
      `,
      [tripId, String(TTL_MINUTES)]
    );

    return res.json(seats.rows);
  } catch (err) {
    console.error("getTripSeats error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

export async function startTrip(req, res) {
  const tripId = Number(req.params.id);
  if (!Number.isFinite(tripId)) {
    return res.status(400).json({ message: "Invalid trip id" });
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    // Lock the trip row so 2 starts can't race
    const q = await client.query(
      `
      SELECT trip_id, operator_id, bus_id, status, deleted_at
      FROM trips
      WHERE trip_id = $1
      FOR UPDATE
      `,
      [tripId]
    );

    if (!q.rows.length) {
      await client.query("ROLLBACK");
      return res.status(404).json({ message: "Trip not found" });
    }

    const t = q.rows[0];

    if (t.deleted_at) {
      await client.query("ROLLBACK");
      return res.status(400).json({ message: "Trip is deleted" });
    }

    // ✅ Adjust these values to match your trip_status enum
    const alreadyActive = ["started", "ongoing"].includes(String(t.status));
    if (alreadyActive) {
      // idempotent success — still emit? Usually NO (avoid spam)
      await client.query("COMMIT");
      return res.json({
        ok: true,
        idempotent: true,
        trip_id: t.trip_id,
        status: t.status,
      });
    }

    // Optional: only scheduled can start (depends on your rules)
    if (String(t.status) !== "scheduled") {
      await client.query("ROLLBACK");
      return res.status(400).json({ message: `Trip cannot be started from status ${t.status}` });
    }

    const upd = await client.query(
      `
      UPDATE trips
      SET status = 'running'::trip_status,
          updated_at = CURRENT_TIMESTAMP
      WHERE trip_id = $1
      RETURNING trip_id, operator_id, bus_id, status
      `,
      [tripId]
    );

    const startedTrip = upd.rows[0];

    await client.query("COMMIT");

    // ✅ Emit AFTER commit so clients don’t see a trip that isn't committed yet
    emitTripStarted({
      operatorId: startedTrip.operator_id,
      busId: startedTrip.bus_id,
      tripId: startedTrip.trip_id,
    });

    return res.json({ ok: true, idempotent: false, trip: startedTrip });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("startTrip error:", err);
    return res.status(500).json({ message: "Server error" });
  } finally {
    client.release();
  }
}