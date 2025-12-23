import bcrypt from "bcrypt";
import { pool } from "../db.js";
import { createOtp, verifyOtp } from "../services/otp.service.js";
import {
  signTempToken,
  signAccessToken,
  signRefreshToken,
} from "../services/token.service.js";

async function getRoleId(roleName) {
  const r = await pool.query(
    "SELECT role_id FROM roles WHERE role_name = $1 LIMIT 1",
    [roleName]
  );
  if (r.rowCount === 0) {
    throw new Error(`Role '${roleName}' not found in roles table`);
  }
  return r.rows[0].role_id;
}

/* =========================
   PASSENGER SIGNUP
========================= */

export async function passengerSignup(req, res) {
  try {
    const { fullName, email, phone, password } = req.body;

    if (!fullName || !email || !password) {
      return res
        .status(400)
        .json({ message: "Missing fields (fullName, email, password)" });
    }

    const exists = await pool.query(
      "SELECT 1 FROM users WHERE email=$1 OR phone=$2",
      [email.trim(), phone ?? null]
    );
    if (exists.rowCount > 0) {
      return res.status(409).json({ message: "Email or phone already exists" });
    }

    const passengerRoleId = await getRoleId("passenger");
    const passwordHash = await bcrypt.hash(password, 10);

    const { rows } = await pool.query(
      `INSERT INTO users (name, email, phone, password_hash, role_id, is_verified)
       VALUES ($1, $2, $3, $4, $5, false)
       RETURNING user_id, email, phone`,
      [fullName.trim(), email.trim(), phone ?? null, passwordHash, passengerRoleId]
    );

    const user = rows[0];

    const otpData = await createOtp({
      userId: user.user_id,
      email: user.email,
      phone: user.phone,
      purpose: "SIGNUP_VERIFY",
    });

    return res.status(201).json({
      message: "OTP sent",
      challengeId: otpData.challengeId,
      expiresAt: otpData.expiresAt,
    });
  } catch (e) {
    return res.status(500).json({ message: e.message });
  }
}

export async function passengerVerifySignupOtp(req, res) {
  try {
    const { challengeId, otp } = req.body;
    if (!challengeId || !otp) {
      return res.status(400).json({ message: "Missing challengeId or otp" });
    }

    // get user_id from challenge
    const ch = await pool.query(
      "SELECT user_id FROM otp_challenges WHERE id=$1",
      [challengeId]
    );
    if (ch.rowCount === 0) {
      return res.status(400).json({ message: "Invalid challengeId" });
    }

    const userId = ch.rows[0].user_id;

    // verify otp
    await verifyOtp({ challengeId, otp, purpose: "SIGNUP_VERIFY" });

    // mark verified
    await pool.query(
      "UPDATE users SET is_verified=true, email_verified_at=now(), updated_at=now() WHERE user_id=$1",
      [userId]
    );

    // issue tokens (same as login verify)
    const userRes = await pool.query(
      "SELECT user_id, name, email, phone, role_id FROM users WHERE user_id=$1",
      [userId]
    );
    const user = userRes.rows[0];

    const accessToken = signAccessToken(user);
    const refreshToken = signRefreshToken(user.user_id);

    const tokenHash = await bcrypt.hash(refreshToken, 10);
    await pool.query(
      `INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
       VALUES ($1, $2, now() + interval '30 days')`,
      [user.user_id, tokenHash]
    );

    return res.json({
      message: "Account verified successfully",
      accessToken,
      refreshToken,
      user,
    });
  } catch (e) {
    return res.status(400).json({ message: e.message });
  }
}


/* 
   PASSENGER LOGIN 
   email+password -> OTP + tempToken
 */

export async function passengerLogin(req, res) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: "Missing email or password" });
    }

    // Only verified users can login
    const { rows } = await pool.query(
      "SELECT user_id, name, email, phone, password_hash, role_id, is_verified FROM users WHERE email=$1",
      [email.trim()]
    );
    if (rows.length === 0) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const user = rows[0];

    if (!user.is_verified) {
      return res.status(403).json({ message: "Account not verified" });
    }

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    // Send OTP for 2FA
    const otpData = await createOtp({
      userId: user.user_id,
      email: user.email,
      phone: user.phone,
      purpose: "LOGIN_2FA",
    });

    // temp token used ONLY to call verify-otp endpoint
    const tempToken = signTempToken(user.user_id);

    return res.json({
      message: "OTP sent",
      challengeId: otpData.challengeId,
      tempToken,
      expiresAt: otpData.expiresAt,
    });
  } catch (e) {
    return res.status(500).json({ message: e.message });
  }
}

/*
   PASSENGER LOGIN (STEP 2)
   verify OTP -> access + refresh tokens
*/

export async function passengerVerifyLoginOtp(req, res) {
  try {
    const { challengeId, otp } = req.body;
    const userId = req.userId; // comes from requireTempToken middleware

    if (!challengeId || !otp) {
      return res.status(400).json({ message: "Missing challengeId or otp" });
    }

    await verifyOtp({ challengeId, otp, purpose: "LOGIN_2FA" });

    const { rows } = await pool.query(
      "SELECT user_id, name, email, phone, role_id FROM users WHERE user_id=$1",
      [userId]
    );
    if (rows.length === 0) {
      return res.status(401).json({ message: "User not found" });
    }

    const user = rows[0];

    const accessToken = signAccessToken(user);
    const refreshToken = signRefreshToken(user.user_id);

    // Save refresh token hash
    const tokenHash = await bcrypt.hash(refreshToken, 10);
    await pool.query(
      `INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
       VALUES ($1, $2, now() + interval '30 days')`,
      [user.user_id, tokenHash]
    );

    return res.json({ accessToken, refreshToken, user });
  } catch (e) {
    return res.status(400).json({ message: e.message });
  }
}
