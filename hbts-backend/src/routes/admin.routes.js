import express from "express";
import { pool } from "../db.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = express.Router();

router.get("/customers", requireAuth, async (req, res) => {
  try {
    // 🔐 Admin-only access
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Forbidden" });
    }

    const result = await pool.query(
      `SELECT user_id, name, email, phone, created_at, bookings
       FROM users
       WHERE role = 'passenger'
       ORDER BY created_at DESC`
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Admin customers error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

export default router;

// GET single customer details
router.get("/customers/:id", requireAuth, async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Forbidden" });
    }

    const { id } = req.params;

    const result = await pool.query(
      `SELECT user_id, name, email, phone, created_at, bookings
       FROM users
       WHERE user_id = $1 AND role = 'passenger'`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Customer not found" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// GET customer booking history
router.get("/customers/:id/bookings", requireAuth, async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Forbidden" });
    }

    const { id } = req.params;

    const result = await pool.query(
      `SELECT booking_id, pickup, dropoff, status, fare, created_at
       FROM bookings
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [id]
    );

    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});
