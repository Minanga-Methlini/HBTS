import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";

import {
  getPassengers,
  getPassengerById,
  addPassenger,
  updatePassenger,
  deletePassenger,
} from "../controllers/adminPassengers.controller.js";
import {
  listDrivers,
  getDriverById,
  updateDriver,
  updateDriverStatus,
} from "../controllers/adminDrivers.controller.js";
import { listOperators } from "../controllers/adminOperators.controller.js";
import {
  addBus,
  deleteBus,
  listBuses,
  listDeletedBuses,
  updateBus,
} from "../controllers/adminBuses.controller.js";
import {
  addRoute,
  deleteRoute,
  listDeletedRoutes,
  listRoutes,
  updateRoute,
} from "../controllers/adminRoutes.controller.js";
import {
  addTrip,
  deleteTrip,
  listDeletedTrips,
  listAssignableDrivers,
  listTripLocationHistory,
  listTrips,
  listTripStops,
  updateTrip,
} from "../controllers/adminTrips.controller.js";

const router = express.Router();

/* =========================
   AUTH & ROLE GUARD
========================= */
router.use(requireAuth);

// admin-only protection
router.use((req, res, next) => {
  if (req.user.role !== "admin") {
    return res.status(403).json({
      message: "Admin access only",
    });
  }
  next();
});

/* =========================
   PASSENGERS CRUD
========================= */

// GET passengers (search)
router.get("/passengers", getPassengers);

// GET single passenger
router.get("/passengers/:id", getPassengerById);

// ADD passenger
router.post("/passengers", addPassenger);

// UPDATE passenger  ✅ FIXED (no email update)
router.put("/passengers/:id", updatePassenger);

// DELETE passenger
router.delete("/passengers/:id", deletePassenger);

export default router;
