import express from "express";
import { pool } from "../db.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = express.Router();

// 🔐 All admin routes require authentication
router.use(requireAuth);


// ===============================
// ADMIN CHECK MIDDLEWARE
// ===============================
const adminOnly = (req, res, next) => {
  if (req.user.role !== "admin") {
    return res.status(403).json({ message: "Admin access required" });
  }
  next();
};

// ===============================
// GET ALL PASSENGERS (SEARCH)
// GET /admin/passengers?search=
// ===============================
router.get("/passengers", adminOnly, async (req, res) => {
  try {
    const search = req.query.search || "";

    const result = await pool.query(
      `
      SELECT
        u.user_id,
        u.name,
        u.email,
        u.phone,
        u.created_at,
        u.is_verified
      FROM users u
      WHERE u.role_id = 1
        AND (
          u.name ILIKE '%' || $1 || '%'
          OR u.email ILIKE '%' || $1 || '%'
          OR u.phone ILIKE '%' || $1 || '%'
        )
      ORDER BY u.created_at DESC
      `,
      [search]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Get passengers error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// ===============================
// GET SINGLE PASSENGER DETAILS
// GET /admin/passengers/:id
// ===============================
router.get("/passengers/:id", adminOnly, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `
      SELECT
        user_id,
        name,
        email,
        phone,
        created_at,
        is_verified
      FROM users
      WHERE user_id = $1 AND role_id = 1
      `,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Passenger not found" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error("Get passenger error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// ===============================
// GET PASSENGER BOOKINGS
// GET /admin/passengers/:id/bookings
// ===============================
router.get("/passengers/:id/bookings", adminOnly, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `
      SELECT
        b.id,
        b.pickup,
        b.dropoff,
        b.status,
        b.fare,
        b.created_at
      FROM bookings b
      WHERE b.passenger_id = $1
      ORDER BY b.created_at DESC
      `,
      [id]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Get passenger bookings error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// ===============================
// UPDATE PASSENGER
// PUT /admin/passengers/:id
// ===============================
router.put("/passengers/:id", adminOnly, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, phone, is_verified } = req.body;

    const result = await pool.query(
      `
      UPDATE users
      SET
        name = $1,
        email = $2,
        phone = $3,
        is_verified = $4,
        updated_at = NOW()
      WHERE user_id = $5 AND role_id = 1
      RETURNING user_id, name, email, phone, is_verified
      `,
      [name, email, phone, is_verified ?? false, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Passenger not found" });
    }

    res.json({
      message: "Passenger updated successfully",
      passenger: result.rows[0],
    });
  } catch (err) {
    console.error("Update passenger error:", err);
    res.status(500).json({ message: "Server error" });
  }
});


// ===============================
// DELETE PASSENGER
// DELETE /admin/passengers/:id
// ===============================
router.delete("/passengers/:id", adminOnly, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `
      DELETE FROM users
      WHERE user_id = $1 AND role_id = 1
      RETURNING user_id
      `,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Passenger not found" });
    }

    res.json({ message: "Passenger deleted successfully" });
  } catch (err) {
    console.error("Delete passenger error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

export default router;
