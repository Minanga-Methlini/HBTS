<<<<<<< HEAD
import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = express.Router();

router.get("/current", requireAuth, async (req, res) => {
  res.json([]);
});

router.get("/history", requireAuth, async (req, res) => {
  res.json([]);
});
=======
// src/routes/booking.routes.js
import { Router } from "express";
import {
  createBooking,
  getMyBookings,
} from "../controllers/booking.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

// Passenger must be logged in
router.post("/", requireAuth, createBooking);
router.get("/me", requireAuth, getMyBookings);
>>>>>>> origin/develop

export default router;
