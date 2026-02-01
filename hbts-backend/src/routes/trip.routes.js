// src/routes/trip.routes.js
import { Router } from "express";
<<<<<<< HEAD
=======

>>>>>>> d7249bdd1a77b7faee6d01ff9d46dbdf7ba288de
import {
  searchTrips,
  getTripById,
  getTripSeats,
<<<<<<< HEAD
  pushTripLocation,
} from "../controllers/trip.controller.js";

=======
  startTrip,
  endTrip,
  cancelTrip, 
} from "../controllers/trip.controller.js";

import { requireAuth } from "../middleware/auth.middleware.js"; // ✅ correct file
import { requireRole } from "../middleware/requireRole.js";      // ✅ correct file

import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

// /api/trips?from=&to=&date=
router.get("/", searchTrips);

// /api/trips/:id
router.get("/:id", getTripById);

// /api/trips/:id/seats
router.get("/:id/seats", getTripSeats);
router.post("/:id/location", requireAuth, pushTripLocation);



router.post("/:id/start", requireAuth, requireRole(["driver", "admin", "operator"]), startTrip);
router.post("/:id/end", requireAuth, requireRole(["driver", "admin", "operator"]), endTrip);
router.post("/:id/cancel", requireAuth, requireRole(["driver", "admin", "operator"]), cancelTrip);
router.post("/:id/location", requireAuth, pushTripLocation);


export default router;
