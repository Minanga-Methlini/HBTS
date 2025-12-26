import express from "express";
import cors from "cors";
import dotenv from "dotenv";

import passengerRoutes from "./routes/passenger.routes.js";
import adminRoutes from "./routes/admin.routes.js";

dotenv.config();

const app = express(); // ✅ app FIRST

// =======================
// MIDDLEWARE
// =======================
app.use(cors());
app.use(express.json());

// =======================
// ROUTES
// =======================
app.use("/auth/passenger", passengerRoutes);
app.use("/admin", adminRoutes);

// =======================
// HEALTH CHECK
// =======================
app.get("/", (req, res) => {
  res.send("HBTS Backend is running 🚀");
});

// =======================
// START SERVER
// =======================
const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
