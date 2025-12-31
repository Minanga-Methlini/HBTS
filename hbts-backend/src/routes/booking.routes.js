import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = express.Router();

router.get("/current", requireAuth, async (req, res) => {
  res.json([]);
});

router.get("/history", requireAuth, async (req, res) => {
  res.json([]);
});

export default router;
