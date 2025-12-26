import db from "../config/db.js";
import bcrypt from "bcrypt";

// ADMIN CHECK
const adminOnly = (req, res) => {
  if (req.user.role !== "admin") {
    res.status(403).json({ message: "Access denied" });
    return false;
  }
  return true;
};

// GET PASSENGERS (SEARCH BY NAME)
export const getPassengers = async (req, res) => {
  if (!adminOnly(req, res)) return;

  const search = req.query.search || "";

  const result = await db.query(
    `SELECT user_id, name, email, phone, is_verified
     FROM users
     WHERE role_id = 1
     AND name ILIKE '%' || $1 || '%'
     ORDER BY created_at DESC`,
    [search]
  );

  res.json(result.rows);
};

// ADD PASSENGER
export const addPassenger = async (req, res) => {
  if (!adminOnly(req, res)) return;

  const { name, email, phone, password } = req.body;
  const hash = await bcrypt.hash(password, 10);

  await db.query(
    `INSERT INTO users
     (name, email, phone, password_hash, role_id, is_verified)
     VALUES ($1,$2,$3,$4,1,true)`,
    [name, email, phone, hash]
  );

  res.status(201).json({ message: "Passenger added" });
};

// UPDATE PASSENGER
export const updatePassenger = async (req, res) => {
  if (!adminOnly(req, res)) return;

  const { id } = req.params;
  const { name, email, phone } = req.body;

  await db.query(
    `UPDATE users
     SET name=$1, email=$2, phone=$3, updated_at=NOW()
     WHERE user_id=$4 AND role_id=1`,
    [name, email, phone, id]
  );

  res.json({ message: "Passenger updated" });
};

// DELETE PASSENGER
export const deletePassenger = async (req, res) => {
  if (!adminOnly(req, res)) return;

  await db.query(
    `DELETE FROM users
     WHERE user_id=$1 AND role_id=1`,
    [req.params.id]
  );

  res.json({ message: "Passenger deleted" });
};
