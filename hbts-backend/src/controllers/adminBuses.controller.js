import { pool } from "../db.js";

export const listBuses = async (req, res) => {
  try {
    const {
      busId,
      operatorId,
      licensePlateNo,
      routeNo,
      capacity,
      serviceType,
    } = req.query;

    const conditions = [];
    const params = [];

    const pushNumberFilter = (value, column) => {
      if (value == null || value === "") return;
      const parsed = Number.parseInt(value, 10);
      if (Number.isNaN(parsed)) {
        throw new Error(`Invalid ${column} value`);
      }
      conditions.push(`b.${column} = $${params.length + 1}`);
      params.push(parsed);
    };

    pushNumberFilter(busId, "bus_id");
    pushNumberFilter(operatorId, "operator_id");
    pushNumberFilter(capacity, "capacity");

    if (licensePlateNo) {
      conditions.push(
        `LOWER(b.license_plate_no) = LOWER($${params.length + 1})`
      );
      params.push(licensePlateNo);
    }

    if (routeNo) {
      conditions.push(
        `LOWER(b.route_no) = LOWER($${params.length + 1})`
      );
      params.push(routeNo);
    }

    if (serviceType) {
      conditions.push(
        `LOWER(CAST(b.service_type AS TEXT)) = LOWER($${params.length + 1})`
      );
      params.push(serviceType);
    }

    const whereSql = conditions.length
      ? `WHERE ${conditions.join(" AND ")}`
      : "";

    const result = await pool.query(
      `
      SELECT
        b.bus_id,
        b.operator_id,
        b.license_plate_no,
        b.route_no,
        b.capacity,
        b.model,
        b.service_type,
        b.created_at,
        b.updated_at,
        c.name AS operator_name
      FROM buses b
      LEFT JOIN company c ON c.operator_id = b.operator_id
      ${whereSql}
      ORDER BY b.created_at DESC
      `,
      params
    );

    res.json(result.rows);
  } catch (err) {
    const message =
      err?.message?.includes("Invalid") ? err.message : "Failed to load buses";
    if (message.startsWith("Invalid")) {
      return res.status(400).json({ message });
    }
    console.error("List buses error:", err);
    res.status(500).json({ message });
  }
};
