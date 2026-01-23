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

/* =========================
   DRIVERS MANAGEMENT
========================= */
router.get("/drivers", listDrivers);
router.get("/drivers/:id", getDriverById);
router.put("/drivers/:id", updateDriver);
router.put("/drivers/:id/status", updateDriverStatus);

/* =========================
   BUS OWNERS (OPERATORS)
========================= */
router.get("/operators", listOperators);

/* =========================
   BUSES
========================= */
router.get("/buses", listBuses);
router.get("/buses/history", listDeletedBuses);
router.post("/buses", addBus);
router.put("/buses/:id", updateBus);
router.delete("/buses/:id", deleteBus);

/* =========================
   ROUTES
========================= */
router.get("/routes", listRoutes);
router.get("/routes/history", listDeletedRoutes);
router.post("/routes", addRoute);
router.put("/routes/:id", updateRoute);
router.delete("/routes/:id", deleteRoute);

/* =========================
   TRIPS
========================= */
router.get("/trips", listTrips);
router.get("/trips/history", listDeletedTrips);
router.get("/trips/assignable-drivers", listAssignableDrivers);
router.post("/trips", addTrip);
router.put("/trips/:id", updateTrip);
router.delete("/trips/:id", deleteTrip);
router.get("/trips/:id/stops", listTripStops);
router.get("/trips/:id/location-history", listTripLocationHistory);

export default router;
