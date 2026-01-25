import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";

<<<<<<< HEAD
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ✅ Load .env from project root (hbts-backend/.env)
dotenv.config({ path: path.join(__dirname, "../.env") });

import http from "http";
import { WebSocketServer } from "ws";

=======
>>>>>>> e20d603 (New updates)
import express from "express";
import cors from "cors";
import http from "http";
import { WebSocketServer } from "ws";

import authRoutes from "./routes/auth.routes.js";
import adminRoutes from "./routes/admin.routes.js";
import tripRoutes from "./routes/trip.routes.js";
import bookingRoutes from "./routes/booking.routes.js";
import notificationRoutes from "./routes/notification.routes.js";
import trackingRoutes from "./routes/tracking.routes.js";
import driverTrackingRoutes from "./routes/driverTracking.routes.js";

import { startExpirePendingBookingsJob } from "./jobs/expirePendingBookings.job.js";
import { initRedis } from "./infra/redis.js";

import { initNotificationWS } from "./ws/notification.ws.js";
import { initTrackingWS } from "./ws/tracking.ws.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ✅ Load .env from project root (hbts-backend/.env)
dotenv.config({ path: path.join(__dirname, "../.env") });

import { initNotificationWS } from "./ws/notification.ws.js";

const app = express();

app.use(
  cors({
    origin: true,
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

app.options("*", cors());
app.use(express.json());

// ✅ Routes
app.use("/api/auth", authRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/trips", tripRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/tracking", trackingRoutes);
app.use("/api/driver-tracking", driverTrackingRoutes);

<<<<<<< HEAD
=======
// ✅ Health
>>>>>>> 13f791f (Add tracking, live location, and token updates)
app.get("/health", (req, res) => res.json({ ok: true }));
app.get("/", (req, res) => res.send("HBTS Backend is running 🚀"));

const PORT = process.env.PORT || 4000;
<<<<<<< HEAD

// ✅ Create HTTP server
const server = http.createServer(app);

// ✅ Attach WebSocket server on a dedicated path
export const wss = new WebSocketServer({
  server,
  path: "/ws/notifications",
});

// ✅ Attach JWT auth + user-client registry
initNotificationWS(wss);

server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
=======
>>>>>>> 13f791f (Add tracking, live location, and token updates)

// ✅ Create HTTP server from express app
const server = http.createServer(app);

// ✅ WS servers (manual upgrade routing)
export const notificationWss = new WebSocketServer({ noServer: true });
export const trackingWss = new WebSocketServer({ noServer: true });

// ✅ Attach handlers
initNotificationWS(notificationWss);
initTrackingWS(trackingWss);

// ✅ Route upgrades by path
server.on("upgrade", (req, socket, head) => {
  try {
    const url = new URL(req.url, "http://localhost");
    const pathname = url.pathname;

    if (pathname === "/ws/notifications") {
      notificationWss.handleUpgrade(req, socket, head, (ws) => {
        notificationWss.emit("connection", ws, req);
      });
      return;
    }

    if (pathname === "/ws/tracking") {
      trackingWss.handleUpgrade(req, socket, head, (ws) => {
        trackingWss.emit("connection", ws, req);
      });
      return;
    }

    socket.destroy();
  } catch (e) {
    socket.destroy();
  }
});

async function start() {
  await initRedis();

  server.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
  });

  console.log("BOOT: starting expirePendingBookings job");
  startExpirePendingBookingsJob();
}

start();
